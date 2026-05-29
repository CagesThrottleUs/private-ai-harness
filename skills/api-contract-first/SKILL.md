---
name: api-contract-first
description: >
  Use when a writing-plans task creates a new API endpoint or gRPC service — before any handler code is written. Produces an OpenAPI 3.1 spec (REST) or .proto file (gRPC), sets up Spectral linting, configures Prism mock server for parallel frontend/backend development, and adds a spec lint job to CI. Runs api-contract-reviewer agent before the spec is approved. The spec is the design. The handler is the implementation of the design.
---

# API Contract First

Write the contract before the code. The API shape is the most important architectural decision for any service — it determines how consumers build, how you evolve, and what breaks when you change it. An API discovered by reading the handler is an API designed by accident.

## References

- **OpenAPI Specification** (spec.openapis.org/oas/v3.2.0) — REST contract format; JSON Schema for payloads
- **Stripe API design** — spec reviewed before any handler; Prism mock enables parallel consumer development
- **Kubernetes API design** — KEP design details define exact resource schema before any Go struct is written
- **Google protobuf style guide** (protobuf.dev/best-practices/dos-donts/) — proto-first design; versioned packages; `reserved` for deleted fields
- **Spectral** (stoplight.io/open-source/spectral) — OpenAPI/AsyncAPI linter; `.spectral.yaml` custom rulesets
- **Prism** (stoplight.io/open-source/prism) — mock HTTP server from OpenAPI spec; enables frontend/backend parallelism

---

## The Iron Law

**Versioning gate:** For externally-facing APIs, confirm a versioning strategy ADR exists in `wiki/architecture/`. If not, invoke `api-versioning` skill first. The OpenAPI spec must reference the chosen versioning scheme.

<HARD-GATE>
Do NOT write a handler, controller, route, or gRPC service implementation before the API spec exists and has been reviewed. The spec defines the contract. The handler implements the contract. Writing the handler first inverts this — the API becomes whatever was convenient to implement, not whatever consumers need.
</HARD-GATE>

---

## When to Use

**Required** when a task creates a new externally-visible API surface: HTTP endpoint, gRPC method, WebSocket, GraphQL schema.

**Skip for:** internal helpers, DB queries, background jobs, adding a parameter to an existing endpoint (spec already exists — update it, don't create a new one).

**Infer + confirm:**
> "This adds a parameter to `GET /users` — the OpenAPI spec already covers that path. Skipping api-contract-first (I'll note the parameter addition in the existing spec). OK?"

---

## Protocol Detection

Choose based on what the HLD §4 (Technology Selection) specifies:

| Signals in HLD/spec | Protocol | Format |
|--------------------|---------|--------|
| REST, HTTP, JSON | REST | OpenAPI 3.1 YAML |
| gRPC, protobuf | gRPC | `.proto` file |
| Both (gateway pattern) | REST + gRPC | OpenAPI 3.1 + `.proto` |

If not specified in HLD, ask once: "Is this a REST or gRPC API?"

---

## Process

1. **Read HLD** — extract API surface from §5.1 (Actual Design), technology selection from §4
2. **Read spec** — extract every REQ-NNN with an API acceptance criterion
3. **Ask** (if not determinable) — REST or gRPC?
4. **Write the contract file** — OpenAPI 3.1 or `.proto`, every endpoint, all responses
5. **Set up Spectral** — `.spectral.yaml` with ruleset and custom rules
6. **Set up Prism** (REST only) — mock server command documented
7. **Add CI lint job** — spec linting in CI pipeline
8. **Run `api-contract-reviewer` agent** — fix all Critical and Important findings
9. **Human gate** — spec reviewed before any handler task begins
10. **Wire spec into `writing-plans`** — handler task explicitly references spec path

---

## REST: OpenAPI 3.1 Spec

Save to: `api/openapi.yaml` (single file, or `api/<resource>.yaml` per resource for large APIs)

````yaml
openapi: "3.1.0"

info:
  title: "[Service Name] API"
  version: "1.0.0"
  description: |
    [One paragraph: what this API does, who the primary consumers are,
    and the authentication mechanism. Reference the HLD for architecture context.]
  contact:
    name: "[Team Name]"

# List all servers — enables Prism to know the base URL
servers:
  - url: "https://api.example.com/v1"
    description: Production
  - url: "https://staging.api.example.com/v1"
    description: Staging
  - url: "http://localhost:3000"
    description: Local development

# Security applies globally — override per-endpoint if some are public
security:
  - bearerAuth: []

tags:
  - name: "[Resource]"
    description: "[One sentence describing this resource group]"

paths:
  # ---- Resource Collection ----
  /resources:
    get:
      operationId: listResources
      summary: List all resources
      description: |
        Returns a paginated list of resources. Results are sorted by createdAt descending.
        [Additional behavior: filtering, cursor pagination, etc.]
      tags: ["[Resource]"]
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
          description: Maximum number of results per page
        - name: cursor
          in: query
          schema:
            type: string
          description: Pagination cursor from previous response
      responses:
        "200":
          description: Success
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ResourceList"
              examples:
                success:
                  value:
                    items:
                      - id: "01234567-89ab-cdef-0123-456789abcdef"
                        name: "Example Resource"
                        createdAt: "2026-01-15T09:30:00Z"
                    nextCursor: "eyJpZCI6IjAxMjM0..."}
        "401":
          $ref: "#/components/responses/Unauthorized"
        "422":
          $ref: "#/components/responses/UnprocessableEntity"
        "500":
          $ref: "#/components/responses/InternalError"

    post:
      operationId: createResource
      summary: Create a resource
      tags: ["[Resource]"]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/CreateResourceRequest"
            examples:
              valid:
                value:
                  name: "My Resource"
      responses:
        "201":
          description: Resource created
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Resource"
        "400":
          $ref: "#/components/responses/BadRequest"
        "401":
          $ref: "#/components/responses/Unauthorized"
        "422":
          $ref: "#/components/responses/UnprocessableEntity"
        "500":
          $ref: "#/components/responses/InternalError"

  # ---- Resource Instance ----
  /resources/{resourceId}:
    parameters:
      - name: resourceId
        in: path
        required: true
        schema:
          type: string
          format: uuid
    get:
      operationId: getResource
      summary: Get a resource by ID
      tags: ["[Resource]"]
      responses:
        "200":
          description: Success
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Resource"
        "401":
          $ref: "#/components/responses/Unauthorized"
        "404":
          $ref: "#/components/responses/NotFound"
        "500":
          $ref: "#/components/responses/InternalError"

# ---- Reusable Components ----
components:
  schemas:
    Resource:
      type: object
      required: [id, name, createdAt]
      properties:
        id:
          type: string
          format: uuid
          readOnly: true
          description: Unique identifier. Server-generated.
          examples: ["01234567-89ab-cdef-0123-456789abcdef"]
        name:
          type: string
          minLength: 1
          maxLength: 255
          description: Display name for the resource.
          examples: ["My Resource"]
        createdAt:
          type: string
          format: date-time
          readOnly: true
          description: ISO 8601 UTC timestamp of creation.
          examples: ["2026-01-15T09:30:00Z"]

    ResourceList:
      type: object
      required: [items]
      properties:
        items:
          type: array
          items:
            $ref: "#/components/schemas/Resource"
        nextCursor:
          type: string
          nullable: true
          description: Pass as `cursor` parameter to get next page. Absent if no more results.

    CreateResourceRequest:
      type: object
      required: [name]
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 255

    Error:
      type: object
      required: [code, message]
      properties:
        code:
          type: string
          description: Machine-readable error code.
          examples: ["VALIDATION_ERROR", "NOT_FOUND", "UNAUTHORIZED"]
        message:
          type: string
          description: Human-readable error message.
        details:
          type: object
          description: Additional error context. Shape varies by error code.

  responses:
    BadRequest:
      description: Invalid request format or parameters
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"
    Unauthorized:
      description: Missing or invalid authentication token
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"
    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"
    UnprocessableEntity:
      description: Request is well-formed but fails business validation
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"
    InternalError:
      description: Unexpected server error
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT bearer token. Obtain via /auth/token.
````

---

## gRPC: Protocol Buffer Definition

Save to: `proto/[package]/v1/[service].proto`

**Package versioning convention:** use `v1`, `v2`, etc. as last part of package. Breaking changes → new version package.

```protobuf
syntax = "proto3";

// Package follows reverse-domain naming with version suffix
package example.v1;

// Language-specific generated code paths
option go_package = "github.com/org/repo/gen/go/example/v1;examplev1";
option java_package = "com.example.v1";
option java_multiple_files = true;

// [ServiceName]Service — [one sentence describing the service]
service ResourceService {
  // GetResource retrieves a single resource by ID.
  rpc GetResource(GetResourceRequest) returns (GetResourceResponse);

  // ListResources returns a paginated list of resources.
  rpc ListResources(ListResourcesRequest) returns (ListResourcesResponse);

  // CreateResource creates a new resource.
  rpc CreateResource(CreateResourceRequest) returns (CreateResourceResponse);
}

// ---- Request/Response messages (one per method) ----

message GetResourceRequest {
  string resource_id = 1;  // Required. UUID format.
}

message GetResourceResponse {
  Resource resource = 1;
}

message ListResourcesRequest {
  int32 page_size = 1;   // Default: 20. Max: 100.
  string page_token = 2; // From previous response. Empty = first page.
}

message ListResourcesResponse {
  repeated Resource resources = 1;
  string next_page_token = 2;  // Empty if no more results.
}

message CreateResourceRequest {
  string name = 1;  // Required. 1-255 characters.
}

message CreateResourceResponse {
  Resource resource = 1;
}

// ---- Domain messages ----

message Resource {
  string id = 1;          // UUID. Server-generated. Immutable.
  string name = 2;        // Display name. 1-255 characters.
  string created_at = 3;  // RFC 3339 UTC timestamp. Immutable.
}
```

**Proto evolution rules (from protobuf.dev/best-practices/):**
- NEVER re-use a field number — use `reserved N;` when deleting a field
- NEVER rename a field without aliasing — wire format uses numbers, not names
- New fields are always `optional` in proto3 (default behavior)
- Adding a field is backward-compatible; removing one is not (unless reserved)
- Breaking change → new version package (`v2`), not field removal

---

## Spectral Ruleset

Save to: `.spectral.yaml`

```yaml
extends: ["spectral:oas"]

rules:
  # Every operation must have a description
  operation-description:
    given: "$.paths[*][get,post,put,patch,delete]"
    message: "Operation '{{property}}' must have a description"
    then:
      field: description
      function: truthy
    severity: error

  # Every operation must have an operationId (for SDK generation)
  operation-operationId:
    given: "$.paths[*][get,post,put,patch,delete]"
    message: "Operation must have an operationId"
    then:
      field: operationId
      function: truthy
    severity: error

  # All 2xx responses must have a content schema
  response-success-schema:
    given: "$.paths[*][*].responses[2xx].content"
    message: "Success response must define a schema"
    then:
      function: truthy
    severity: warn

  # 4xx and 5xx responses must reference the Error schema
  error-response-schema:
    given: "$.paths[*][*].responses[4xx,5xx].content.application/json"
    message: "Error response must reference the Error component schema"
    then:
      field: schema
      function: truthy
    severity: error

  # All properties must have descriptions
  property-description:
    given: "$.components.schemas[*].properties[*]"
    message: "Property '{{property}}' must have a description"
    then:
      field: description
      function: truthy
    severity: warn
```

**Run:**
```bash
npx @stoplight/spectral-cli lint api/openapi.yaml --ruleset .spectral.yaml
# Zero output = PASS. Any error = fix before handler.
```

---

## Prism Mock Server (REST only)

Spin up a mock server from the spec — enables frontend/backend parallel development:

```bash
# Install once
npm install -g @stoplight/prism-cli

# Start mock server (dynamic mode — returns example data from spec)
prism mock api/openapi.yaml --port 4010

# With validation (rejects requests that don't match the spec)
prism mock api/openapi.yaml --port 4010 --validate-request

# As Docker container
docker run --rm -p 4010:4010 stoplight/prism:4 mock -h 0.0.0.0 /tmp/openapi.yaml -v /path/to/api/openapi.yaml:/tmp/openapi.yaml
```

Frontend developers use `http://localhost:4010` as their base URL while backend implements the spec. Both are building against the same contract simultaneously.

---

## CI Spec Lint Job

Add to existing CI config (via `ci-pipeline-setup`):

**GitHub Actions:**
```yaml
# Adds to .github/workflows/ci.yml
  api-spec-lint:
    name: API Contract Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install -g @stoplight/spectral-cli
      - run: spectral lint api/openapi.yaml --ruleset .spectral.yaml --fail-on-unmatched-pattern
      # For gRPC — validate proto syntax
      # - run: buf lint proto/
```

**GitLab CI:**
```yaml
api-spec-lint:
  stage: lint
  image: node:20-alpine
  script:
    - npm install -g @stoplight/spectral-cli
    - spectral lint api/openapi.yaml --ruleset .spectral.yaml
```

---

## Self-Review: Run `api-contract-reviewer` Agent

After writing the spec, before any handler code:

```
Agent(api-contract-reviewer, {
  SPEC_PATH: "api/openapi.yaml",         // or "proto/example/v1/service.proto"
  PROTOCOL: "rest",                       // or "grpc"
  SPEC_SOURCE_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md",
  HLD_PATH: ".ai/hld/YYYY-MM-DD-<feature>.md"  // optional
})
```

Fix all **Critical** findings (missing error responses, missing auth, breaking changes). Fix **Important** findings (missing examples, missing descriptions). Advisory may be deferred.

---

## Human Gate

After `api-contract-reviewer` passes, present spec for human review:

> "API spec written to `api/openapi.yaml`. Spectral lint passes. Prism mock server available at `prism mock api/openapi.yaml --port 4010`.
>
> Key design decisions: [list 3-5 choices made — error format, pagination style, versioning, auth mechanism].
>
> Please review before handler implementation begins."

<HARD-GATE>
Do NOT invoke handler implementation tasks until the human approves the spec. "Looks good" counts. Silence does not.
</HARD-GATE>

---

## Transition to Handler Implementation

After spec approval:
1. Each `writing-plans` handler task references: `"Implement to spec: api/openapi.yaml#paths/resources/get"`
2. Handler code must match spec exactly — no "undocumented" response codes
3. Integration tests for this endpoint use the spec as the contract (Prism validation mode, or Pact)
4. Any spec change requires re-running `api-contract-reviewer` before implementation continues
