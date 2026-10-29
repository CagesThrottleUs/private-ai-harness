// opencode plugin — Senior Dialogue consent ledger bridge
//
// Copied (not symlinked) into ~/.config/opencode/plugin/ by
// install-opencode.sh, which substitutes __CONSENT_SCRIPT_PATH__ with the
// absolute path to this checkout's
// skills/senior-dialogue/scripts/dialogue-consent.py.
//
// Maps opencode's blocking hooks onto the script's host-agnostic events:
//   - chat.message        → "prompt" (a typed human turn whose first line is
//                           the agreement token followed by decision ids)
//   - tool.execute.after  → "answer" (only for the built-in `question` tool)
//   - tool.execute.before → "guard"  (throwing an Error blocks the tool call)
//
// Every call is synchronous with a 5 s timeout. A missing python3, a crash, or
// a timeout records nothing and never blocks: the script's contract is
// "recording fails safe, guard fails open".

import { spawnSync } from "node:child_process"

const SCRIPT = "__CONSENT_SCRIPT_PATH__"
const ASK_TOOLS = new Set(["question"])

function runScript(event, payload) {
  const result = spawnSync(
    "python3",
    [SCRIPT, "hook", "--host", "opencode", "--event", event],
    { input: JSON.stringify(payload), encoding: "utf8", timeout: 5000 },
  )
  if (result.error || typeof result.stdout !== "string") return {}
  const text = result.stdout.trim()
  if (!text) return {}
  try {
    return JSON.parse(text)
  } catch {
    return {}
  }
}

export const PrivateAiHarnessDialogueConsent = async ({ directory }) => ({
  "chat.message": async (input, output) => {
    const parts = Array.isArray(output?.parts) ? output.parts : []
    const prompt = parts
      .filter((part) => part?.type === "text" && !part?.synthetic)
      .map((part) => part.text ?? "")
      .join("\n")
    if (prompt) runScript("prompt", { cwd: directory, session_id: input?.sessionID, prompt })
  },
  "tool.execute.before": async (input, output) => {
    const decision = runScript("guard", {
      cwd: directory,
      session_id: input?.sessionID,
      tool_name: input?.tool,
      tool_input: output?.args,
    })
    if (decision?.permissionDecision === "deny") {
      throw new Error(decision.permissionDecisionReason || "Denied by private-ai-harness dialogue-consent guard")
    }
  },
  "tool.execute.after": async (input, output) => {
    if (!ASK_TOOLS.has(input?.tool)) return
    runScript("answer", {
      cwd: directory,
      session_id: input?.sessionID,
      tool_name: input?.tool,
      tool_input: input?.args,
      tool_response: output?.output,
    })
  },
})
