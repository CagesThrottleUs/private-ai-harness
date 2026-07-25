---
name: infrastructure-as-code
description: >
  Use when a service needs infrastructure provisioned (compute, databases, queues, networking, object storage). Generates Terraform (default) or Pulumi structure with pinned provider versions, remote state backend with locking, typed input variables with descriptions, CI plan+apply pipeline, tfsec security scan, and environment separation (staging/production). Runs iac-reviewer agent before committing. ClickOps and manual provisioning are the IaC equivalent of deploying without a rollback procedure.
---

# Infrastructure as Code

ClickOps dies at 2am when you need to provision a new environment and can't remember which settings you used. Manually-provisioned infrastructure drifts from what was intended — a rule here, a firewall exception there, until no one knows what's running. IaC makes infrastructure auditable, reproducible, and version-controlled.

## References

- **HashiCorp Terraform** (developer.hashicorp.com/terraform) — HCL, 4800+ providers, largest ecosystem. Default choice.
- **Pulumi** (pulumi.com) — TypeScript/Python/Go for infrastructure, encrypted secrets in state, built-in unit tests. Better for developer-heavy teams.
- **tfsec** (github.com/aquasecurity/tfsec) — Terraform static security analysis (OWASP, CIS benchmarks)
- **Checkov** (checkov.io) — multi-cloud IaC security scanner (Terraform, CloudFormation, Kubernetes)
- **Terraform Best Practices 2025** — pin provider versions, remote state, semantic versioning on modules

---

## When to Use

**Required** when the feature needs:
- New compute resource (EC2, ECS, Lambda, App Service, Cloud Run)
- New database instance (RDS, Cloud SQL, Cosmos DB, MongoDB Atlas)
- New object storage (S3, GCS, Azure Blob)
- New networking (VPC, subnet, security group, load balancer)
- New queue or event bus (SQS, Pub/Sub, Service Bus)

**Skip** for: application code changes with no infrastructure change, features using existing infrastructure with no new resources needed.

**Infer + confirm:**
> "This adds a new background worker that uses the existing DB and queue — no new infrastructure needed. Skipping IaC. OK, or does this need a new queue?"

---

## Tool Selection

| Tool | Use when |
|------|---------|
| **Terraform** (default) | Ops-oriented teams, need widest provider ecosystem, HCL is acceptable |
| **Pulumi** | Developer-heavy team, TypeScript/Python preferred, encrypted secrets important, want unit tests for infrastructure |
| **AWS CDK** | AWS-only, TypeScript/Python, strong CDK construct ecosystem |
| **OpenTofu** | Terraform-compatible but open-source (MPL-licensed) without HashiCorp dependency |

---

## Terraform Structure

```
infra/
├── .terraform-version        ← pin exact Terraform version (e.g., "1.9.5")
├── versions.tf               ← required_providers with version constraints
├── main.tf                   ← provider config, primary resources
├── variables.tf              ← input variables with type + description + sensitive
├── outputs.tf                ← values exported to other stacks or CI
├── backend.tf                ← remote state configuration
├── environments/
│   ├── staging.tfvars        ← staging-specific variable values
│   └── production.tfvars     ← production-specific variable values
└── modules/
    └── [service-name]/       ← reusable module if applicable
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Golden-path modules & self-service (CNCF L4)

The highest-leverage IaC is the IaC a service *doesn't hand-write*. At CNCF
Platform Engineering maturity Level 4, developers **instantiate curated,
versioned modules from a registry** rather than authoring root infrastructure —
the platform team curates a library of Terraform modules (and Kubernetes
controllers/CRDs) that encode the paved-road defaults, and a new service's
`main.tf` is a thin module call, not a bespoke resource graph.

```hcl
# A service root that CONSUMES a golden-path module — not bespoke resources
module "service" {
  source  = "app.terraform.io/acme/service/aws"  # curated private registry
  version = "3.2.0"                               # pinned, semver-ranged module
  name    = "orders-api"
  size    = "small"                               # paved-road t-shirt sizes
  # compliant defaults (encryption, tagging, network policy) live in the module
}
```

Why this is the self-service target, not just DRY:
- **Self-service:** a developer provisions a compliant service by calling a
  module — no platform ticket, no copy-pasted HCL. This is what "self-service
  infrastructure" in the maturity model actually means.
- **Compliant by construction:** encryption, tagging, network policy, and
  resource limits are baked into the module and enforced by policy-as-code
  (tfsec / OPA / Conftest) in the module's own CI, so a self-service consumer
  **cannot** provision non-compliant infra. The guardrail is inside the road.
- **Curated + versioned:** modules are pinned by semver; the platform team ships
  new module versions, consumers adopt them deliberately. This is how a fleet of
  services stays consistent without a human reviewing every plan.
- `service-scaffolding` generates the module *call*; this skill defines the
  module *library* the call consumes.

**Honest maturity note:** consuming a curated module registry with policy
enforcement is L3→L4. A single bespoke root module hand-written per service is
L2. State which one this is — do not label bespoke HCL "self-service."

### `versions.tf` — always pin

```hcl
terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"  # minor version constraint — safe for non-breaking updates
    }
    # Add other providers as needed
  }
}
```

### `backend.tf` — remote state with locking

**AWS (S3 + DynamoDB):**
```hcl
terraform {
  backend "s3" {
    bucket         = "[your-terraform-state-bucket]"
    key            = "[service-name]/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "[your-terraform-lock-table]"  # prevents concurrent applies
  }
}
```

**GCP (GCS):**
```hcl
terraform {
  backend "gcs" {
    bucket = "[your-terraform-state-bucket]"
    prefix = "[service-name]/terraform"
  }
}
```

**Azure (Blob Storage):**
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "[your-tfstate-rg]"
    storage_account_name = "[your-tfstate-sa]"
    container_name       = "tfstate"
    key                  = "[service-name].tfstate"
  }
}
```

**Local state = never in production.** It cannot be shared across the team and is lost when the developer's machine is lost.

### `variables.tf` — all variables typed and documented

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment (staging | production)"
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be 'staging' or 'production'."
  }
}

variable "service_name" {
  type        = string
  description = "Name of the service — used to prefix all resource names"
}

variable "db_password" {
  type        = string
  description = "Database master password — must be set via environment variable TF_VAR_db_password"
  sensitive   = true  # prevents value from appearing in plan output or logs
}

variable "instance_count" {
  type        = number
  description = "Number of service instances to run"
  default     = 2
}
```

### `outputs.tf` — export what other stacks or CI need

```hcl
output "service_endpoint" {
  description = "HTTPS endpoint for the service"
  value       = aws_lb.main.dns_name
}

output "database_endpoint" {
  description = "Database connection endpoint (without credentials)"
  value       = aws_db_instance.main.endpoint
  sensitive   = false  # endpoint is not a secret; credentials are separate
}
```

---

## CI Integration

```yaml
# Adds to .github/workflows/ci.yml
  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.9"

      # Security scan — before plan
      - name: tfsec Security Scan
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          working_directory: infra/
          format: sarif
          sarif_file: tfsec.sarif
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: tfsec.sarif

      - name: Terraform Init
        run: terraform init
        working-directory: infra/
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Terraform Plan (staging)
        run: terraform plan -var-file="environments/staging.tfvars" -out=staging.tfplan
        working-directory: infra/
        env:
          TF_VAR_db_password: ${{ secrets.STAGING_DB_PASSWORD }}

      - name: Upload plan for review
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan
          path: infra/staging.tfplan

  terraform-apply:
    name: Terraform Apply
    needs: [terraform-plan, deploy-staging]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.9"
      - name: Terraform Apply
        run: |
          terraform init
          terraform apply -var-file="environments/production.tfvars" -auto-approve
        working-directory: infra/
        env:
          TF_VAR_db_password: ${{ secrets.PRODUCTION_DB_PASSWORD }}
```

---

## Environment Separation

```hcl
# environments/staging.tfvars
environment    = "staging"
instance_count = 1
db_instance    = "db.t3.micro"

# environments/production.tfvars
environment    = "production"
instance_count = 3
db_instance    = "db.t3.medium"
```

**Never put secrets in `.tfvars`.** Use `TF_VAR_*` environment variables injected from CI secrets.

---

## Pulumi Alternative (TypeScript)

```typescript
// infra/index.ts
import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

const config = new pulumi.Config();
const dbPassword = config.requireSecret("dbPassword");  // encrypted in state

const db = new aws.rds.Instance("main-db", {
    engine: "postgres",
    engineVersion: "15.3",
    instanceClass: "db.t3.micro",
    allocatedStorage: 20,
    dbName: "myapp",
    username: "admin",
    password: dbPassword,
    skipFinalSnapshot: true,
    tags: { Environment: pulumi.getStack() },
});

export const dbEndpoint = db.endpoint;
```

---

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review

## Self-Review: Run `iac-reviewer` Agent

```
Agent(iac-reviewer, {
  IAC_DIR: "infra/",
  TOOL: "terraform"  // or "pulumi"
})
```

Fix all **Critical** findings before committing.
