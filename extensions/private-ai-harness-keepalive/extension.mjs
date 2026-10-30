// private-ai-harness keepalive — GitHub Copilot CLI extension.
//
// Keeps the main session's prompt cache warm while you are away, so your next
// message pays a cache read instead of a full cache rebuild. The harness plugin
// is loaded live from its checkout, and Copilot loads plugin extensions from
// extensions/, so there is no install step.
//
// When: one short message at (cacheExpiresAt − lead) whenever the main agent is
// between turns, including while background agents or shells run. Expiry,
// context size and prices come from each main-agent `assistant.usage` event.
//
// Stop rule (ski rental): stop once keepalive spend + the next keepalive would
// exceed min(cap, rebuild saved), where rebuild saved = context × (cache-write −
// cache-read price). Then compact and wait for your next message, which resets
// the spend.
//
// Commands: /break:long  compact now; keepalives pause until you type again.
//           /break:off   no keepalives for the rest of this session.
// Config:   PRIVATE_AI_HARNESS_KEEPALIVE=off disables the extension.
//           Cap and lead: PRIVATE_AI_HARNESS_KEEPALIVE_CAP_USD and
//           PRIVATE_AI_HARNESS_KEEPALIVE_LEAD_SECONDS, or
//           ~/.private-ai-harness/keepalive.json {"capUsd": 1, "leadSeconds": 30}.
// Log:      ~/.private-ai-harness/keepalive.jsonl
// Selftest: node extension.mjs --selftest
import { spawn } from "node:child_process";
import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const SOURCE = "agent-keepalive";
const TAG = "[keepalive]";
const PROMPT = `${TAG} Cache keepalive while the user is away. Reply with exactly: ok. ` +
  `If a task_complete tool is available, call it with summary "ok (keepalive)". Call no other tools.`;
const COMPACT_INSTRUCTIONS = "The user stepped away. Preserve open tasks, agreed decisions, " +
  "file paths, commands, and the next step so work resumes without re-explaining.";
const DEFAULTS = Object.freeze({ capUsd: 1, leadSeconds: 30 });
// An autopilot continuation can follow a turn end; never fire right after one.
const MIN_QUIET_MS = 15_000;
const COMPACT_TIMEOUT_MS = 60_000;
const CONFIG_REFRESH_MS = 15_000;
const NANO_AIU_PER_USD = 1e11;
const HOME = join(homedir(), ".private-ai-harness");
const LOG_FILE = join(HOME, "keepalive.jsonl");
const CONFIG_FILE = join(HOME, "keepalive.json");
const OFF_DIR = join(HOME, "keepalive-off");
const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");

// ── Pure decision logic (covered by --selftest) ───────────────────────────────

export function tokenPrices(copilotUsage) {
  const prices = { read: null, write: null };
  for (const d of copilotUsage?.tokenDetails ?? []) {
    if (!(d?.batchSize > 0) || typeof d.costPerBatch !== "number") continue;
    const usdPerToken = d.costPerBatch / d.batchSize / NANO_AIU_PER_USD;
    if (d.tokenType === "cache_read") prices.read = usdPerToken;
    if (d.tokenType === "cache_write") prices.write = usdPerToken;
  }
  return prices;
}

export function callCostUsd(copilotUsage) {
  if (typeof copilotUsage?.totalNanoAiu === "number") return copilotUsage.totalNanoAiu / NANO_AIU_PER_USD;
  const details = copilotUsage?.tokenDetails;
  if (!Array.isArray(details)) return null;
  const nano = details.reduce((sum, d) => sum + (d.batchSize > 0 ? d.tokenCount * d.costPerBatch / d.batchSize : 0), 0);
  return nano / NANO_AIU_PER_USD;
}

export function stopLimitUsd({ context, prices, capUsd }) {
  if (!(context > 0) || prices.read == null || prices.write == null) return null;
  return Math.min(capUsd, context * (prices.write - prices.read));
}

export function nextCostUsd({ context, prices, lastKeepaliveUsd }) {
  if (lastKeepaliveUsd > 0) return lastKeepaliveUsd;
  if (!(context > 0) || prices.read == null) return null;
  return context * prices.read;
}

// Returns "wait" | "missed" | "no-price" | "stop" | "send".
export function decide(s) {
  if (s.off || s.paused || s.sending) return "wait";
  if (!s.expiresAtMs || s.expiresAtMs === s.handledExpiryMs) return "wait";
  if (!s.betweenTurns) return "wait";
  if (s.now >= s.expiresAtMs) return "missed";
  if (s.now < s.expiresAtMs - s.leadMs || s.now - s.lastTurnEnd < MIN_QUIET_MS) return "wait";
  if (s.limit == null || s.next == null) return "no-price";
  return s.spent + s.next > s.limit ? "stop" : "send";
}

export function isHumanMessage(data) {
  const source = data?.source;
  if (source && source !== "user") return false;
  if (data?.isAutopilotContinuation) return false;
  return !String(data?.content ?? "").startsWith(TAG);
}

export function compactSucceeded(result) {
  return result?.success === true && !result.aborted && !result.cancelled && result.tokensRemoved > 0;
}

export function loadConfig(env = {}, fileText = null) {
  let file = {};
  try { file = fileText ? JSON.parse(fileText) ?? {} : {}; } catch { file = {}; }
  const pick = (envKey, fileKey, fallback, min, max) => {
    const raw = env[envKey] ?? file[fileKey];
    const n = Number(raw);
    return raw != null && raw !== "" && Number.isFinite(n) && n >= min && n <= max ? n : fallback;
  };
  return {
    enabled: String(env.PRIVATE_AI_HARNESS_KEEPALIVE ?? "").toLowerCase() !== "off",
    capUsd: pick("PRIVATE_AI_HARNESS_KEEPALIVE_CAP_USD", "capUsd", DEFAULTS.capUsd, 0, 1000),
    leadSeconds: pick("PRIVATE_AI_HARNESS_KEEPALIVE_LEAD_SECONDS", "leadSeconds", DEFAULTS.leadSeconds, 5, 3600),
  };
}

// ── Runtime ───────────────────────────────────────────────────────────────────

const usd = (x) => (x == null ? "?" : `$${x.toFixed(3)}`);
const readText = (path) => { try { return readFileSync(path, "utf8"); } catch { return null; } };

function detectCliVersion() {
  try {
    const url = import.meta.resolve("@github/copilot-sdk/extension");
    return url.match(/\/(\d+\.\d+\.\d+[^/]*)\/copilot-sdk\//)?.[1] ?? "unknown";
  } catch { return "unknown"; }
}

function withTimeout(promise, ms) {
  let timer;
  const timeout = new Promise((_, reject) => { timer = setTimeout(() => reject(new Error(`timed out after ${ms / 1000}s`)), ms); });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

function beep() {
  try {
    const child = spawn("bash", [join(REPO_ROOT, "scripts", "hook-beep.sh")], { stdio: ["pipe", "ignore", "ignore"], detached: true });
    child.on("error", () => {});
    child.stdin.on("error", () => {});
    child.stdin.end(JSON.stringify({ hook_event_name: "Notification" }));
    child.unref();
  } catch { /* sound is best-effort */ }
}

async function main() {
  const { joinSession } = await import("@github/copilot-sdk/extension");
  let sessionId = null;
  const log = (entry) => {
    try {
      mkdirSync(HOME, { recursive: true });
      appendFileSync(LOG_FILE, JSON.stringify({ at: new Date().toISOString(), session: sessionId, ...entry }) + "\n");
    } catch { /* logging is best-effort */ }
  };

  let config = loadConfig(process.env, readText(CONFIG_FILE));
  let configReadAt = Date.now();
  if (!config.enabled) {
    const session = await joinSession({});
    sessionId = session.sessionId;
    log({ kind: "disabled" });
    return;
  }

  const cliVersion = detectCliVersion();
  const st = {
    expiresAtMs: null, handledExpiryMs: null, betweenTurns: false, lastTurnEnd: 0,
    context: 0, prices: { read: null, write: null },
    spent: 0, count: 0, inKeepalive: false, keepaliveTurnUsd: 0,
    paused: false, off: false, sending: false, pendingCompact: null, compacting: false,
  };
  let session;

  const note = (message, level = "info") => { session.log(`keepalive: ${message}`, { level }).catch(() => {}); };

  async function compact(reason) {
    const api = session.rpc?.history;
    const fail = (detail) => {
      log({ kind: "compact-failed", reason, detail, cliVersion });
      note(`automatic compaction failed (${detail}) on Copilot CLI ${cliVersion}. Run /compact yourself.`, "warning");
      beep();
    };
    if (typeof api?.compact !== "function") return fail("history.compact is not available");
    try {
      const res = await withTimeout(api.compact({ customInstructions: COMPACT_INSTRUCTIONS, trigger: "manual" }), COMPACT_TIMEOUT_MS);
      if (!compactSucceeded(res)) {
        const { success, aborted, cancelled, tokensRemoved } = res ?? {};
        return fail(`unexpected result ${JSON.stringify({ success, aborted, cancelled, tokensRemoved })}`);
      }
      log({ kind: "compacted", reason, tokensRemoved: res.tokensRemoved, messagesRemoved: res.messagesRemoved, cliVersion });
      note(`compacted (${reason}); ${res.tokensRemoved} tokens removed. Keepalives resume after your next message.`);
    } catch (err) {
      fail(String(err?.message ?? err));
    }
  }

  function onEvent(e) {
    if (e.agentId) return; // subagent calls never refresh the main session's cache
    const d = e.data ?? {};
    switch (e.type) {
      case "assistant.turn_start":
        st.betweenTurns = false;
        break;
      case "assistant.turn_end":
        st.betweenTurns = true;
        st.lastTurnEnd = Date.now();
        break;
      case "assistant.usage": {
        const expires = Date.parse(d.cacheExpiresAt ?? "");
        if (Number.isFinite(expires)) st.expiresAtMs = expires;
        if (d.inputTokens > 0) st.context = d.inputTokens;
        const p = tokenPrices(d.copilotUsage);
        if (p.read != null) st.prices.read = p.read;
        if (p.write != null) st.prices.write = p.write;
        if (st.inKeepalive) {
          const cost = callCostUsd(d.copilotUsage);
          if (cost != null) { st.spent += cost; st.keepaliveTurnUsd += cost; }
        }
        break;
      }
      case "user.message":
        if (d.source === SOURCE) {
          st.inKeepalive = true;
        } else if (isHumanMessage(d)) {
          Object.assign(st, { spent: 0, count: 0, inKeepalive: false, keepaliveTurnUsd: 0, paused: false });
        }
        break;
    }
  }

  async function tick() {
    const now = Date.now();
    if (now - configReadAt >= CONFIG_REFRESH_MS) {
      config = loadConfig(process.env, readText(CONFIG_FILE));
      configReadAt = now;
    }
    if (st.pendingCompact && st.betweenTurns && !st.compacting) {
      const reason = st.pendingCompact;
      st.pendingCompact = null;
      st.compacting = true;
      try { await compact(reason); } finally { st.compacting = false; }
      return;
    }
    const limit = stopLimitUsd({ context: st.context, prices: st.prices, capUsd: config.capUsd });
    const next = nextCostUsd({ context: st.context, prices: st.prices, lastKeepaliveUsd: st.count > 0 ? st.keepaliveTurnUsd : null });
    const action = decide({ ...st, now, leadMs: config.leadSeconds * 1000, limit, next });
    if (action === "wait") return;
    st.handledExpiryMs = st.expiresAtMs;
    const detail = { context: st.context, spent: st.spent, next, limit, count: st.count, expiresAt: new Date(st.expiresAtMs).toISOString() };
    if (action === "missed" || action === "no-price") {
      log({ kind: action, ...detail, prices: st.prices });
      return;
    }
    if (action === "stop") {
      st.paused = true;
      log({ kind: "stop", ...detail });
      if (st.count > 0) {
        note(`stopping after ${st.count} keepalive(s): ${usd(st.spent)} spent, next ${usd(next)} would pass ${usd(limit)}. Compacting.`);
        st.pendingCompact = "keepalive limit";
      }
      return;
    }
    st.count += 1;
    st.keepaliveTurnUsd = 0;
    st.sending = true;
    log({ kind: "send", ...detail, count: st.count });
    note(`${st.count} · ${usd(st.spent)} spent · next ~${usd(next)} · stop at ${usd(limit)}`);
    try {
      await session.send({ prompt: PROMPT, source: SOURCE });
    } catch (err) {
      log({ kind: "send-error", detail: String(err?.message ?? err) });
    } finally {
      st.sending = false;
    }
  }

  session = await joinSession({
    commands: [
      {
        name: "break:long",
        description: "Compact now and pause cache keepalives until your next message",
        handler: () => {
          st.paused = true;
          st.pendingCompact = "break:long";
          log({ kind: "break-long" });
          if (!st.betweenTurns) note("compaction will run when the current turn ends.");
        },
      },
      {
        name: "break:off",
        description: "Stop cache keepalives for the rest of this session",
        handler: () => {
          st.off = true;
          try {
            mkdirSync(OFF_DIR, { recursive: true });
            writeFileSync(join(OFF_DIR, session.sessionId), new Date().toISOString() + "\n");
          } catch { /* the in-memory flag still holds for this process */ }
          log({ kind: "break-off" });
          note("off for the rest of this session.");
        },
      },
    ],
  });
  sessionId = session.sessionId;
  st.off = existsSync(join(OFF_DIR, sessionId));
  const compactApi = typeof session.rpc?.history?.compact;
  log({ kind: "joined", cliVersion, off: st.off, compactApi, capUsd: config.capUsd, leadSeconds: config.leadSeconds });
  if (compactApi !== "function") {
    note(`history.compact is missing on Copilot CLI ${cliVersion}; /break:long and the keepalive limit will ask you to run /compact.`, "warning");
  }

  session.on((e) => { try { onEvent(e); } catch (err) { log({ kind: "event-error", detail: String(err?.message ?? err) }); } });
  let ticking = false;
  setInterval(() => {
    if (ticking) return;
    ticking = true;
    tick().catch((err) => log({ kind: "tick-error", detail: String(err?.message ?? err) })).finally(() => { ticking = false; });
  }, 1_000);
}

// ── Selftest ──────────────────────────────────────────────────────────────────

function selftest() {
  const failures = [];
  let total = 0;
  const check = (name, cond) => { total += 1; if (!cond) failures.push(name); };
  const near = (a, b) => Math.abs(a - b) < 1e-9;
  // Opus 5.5 on Copilot, per token: cache read $0.20/M, cache write $5/M (measured 2026-10-30).
  const detail = (tokenType, tokenCount, usdPerMillion) =>
    ({ tokenType, tokenCount, batchSize: 1_000_000, costPerBatch: usdPerMillion * NANO_AIU_PER_USD });
  const usage = { totalNanoAiu: 4_198_960_000, tokenDetails: [detail("input", 4, 4), detail("cache_read", 193_218, 0.2), detail("cache_write", 166, 5), detail("output", 125, 20)] };
  const prices = tokenPrices(usage);

  check("prices: cache read per token", near(prices.read, 0.2e-6));
  check("prices: cache write per token", near(prices.write, 5e-6));
  check("prices: missing details give nulls", tokenPrices(undefined).read === null && tokenPrices({}).write === null);
  check("cost: totalNanoAiu converts to USD", near(callCostUsd(usage), 0.0419896));
  check("cost: falls back to token details", Math.abs(callCostUsd({ tokenDetails: usage.tokenDetails }) - 0.0419896) < 1e-5);
  check("cost: no usage gives null", callCostUsd(undefined) === null);

  check("limit: rebuild saved below cap", Math.abs(stopLimitUsd({ context: 193_218, prices, capUsd: 1 }) - 0.92745) < 1e-4);
  check("limit: cap binds for large context", stopLimitUsd({ context: 400_000, prices, capUsd: 1 }) === 1);
  check("limit: unknown write price gives null", stopLimitUsd({ context: 1000, prices: { read: 1e-7, write: null }, capUsd: 1 }) === null);
  check("next: uses last keepalive cost", nextCostUsd({ context: 1, prices, lastKeepaliveUsd: 0.05 }) === 0.05);
  check("next: estimates from context first", near(nextCostUsd({ context: 100_000, prices, lastKeepaliveUsd: null }), 0.02));

  const base = { now: 1_000_000, expiresAtMs: 1_020_000, handledExpiryMs: null, betweenTurns: true, lastTurnEnd: 700_000,
    leadMs: 30_000, spent: 0, next: 0.04, limit: 0.93, paused: false, off: false, sending: false };
  check("decide: send inside the lead window", decide(base) === "send");
  check("decide: wait before the lead window", decide({ ...base, expiresAtMs: 1_100_000 }) === "wait");
  check("decide: wait mid-turn", decide({ ...base, betweenTurns: false }) === "wait");
  check("decide: wait right after a turn ends", decide({ ...base, lastTurnEnd: 995_000 }) === "wait");
  check("decide: stop when the next keepalive passes the limit", decide({ ...base, spent: 0.9 }) === "stop");
  check("decide: missed after expiry", decide({ ...base, now: 1_020_000 }) === "missed");
  check("decide: no-price without a limit", decide({ ...base, limit: null }) === "no-price");
  check("decide: each expiry handled once", decide({ ...base, handledExpiryMs: 1_020_000 }) === "wait");
  check("decide: paused, off and sending wait",
    ["paused", "off", "sending"].every((k) => decide({ ...base, [k]: true }) === "wait"));

  let spent = 0;
  let sends = 0;
  while (decide({ ...base, spent, next: 0.042, limit: 0.92745 }) === "send") { spent += 0.042; sends += 1; }
  check("ski rental: 22 keepalives at 193k context, then stop", sends === 22);

  check("human: typed message", isHumanMessage({ content: "hi" }) && isHumanMessage({ source: "user", content: "hi" }));
  check("human: keepalive is not human", !isHumanMessage({ source: SOURCE, content: PROMPT }));
  check("human: autopilot continuation is not human", !isHumanMessage({ isAutopilotContinuation: true, content: "x" }));
  check("human: system source is not human", !isHumanMessage({ source: "system", content: "x" }));

  check("compact: success", compactSucceeded({ success: true, tokensRemoved: 10 }));
  check("compact: aborted, cancelled, nothing removed or missing fail",
    [{ success: true, aborted: true, tokensRemoved: 1 }, { success: true, cancelled: true, tokensRemoved: 1 },
      { success: true, tokensRemoved: 0 }, { success: false, tokensRemoved: 5 }, undefined].every((r) => !compactSucceeded(r)));

  const cfg = loadConfig({ PRIVATE_AI_HARNESS_KEEPALIVE_CAP_USD: "0.5" }, '{"capUsd": 2, "leadSeconds": 60}');
  check("config: env beats file, file beats default", cfg.capUsd === 0.5 && cfg.leadSeconds === 60 && cfg.enabled);
  check("config: invalid values fall back", loadConfig({ PRIVATE_AI_HARNESS_KEEPALIVE_LEAD_SECONDS: "1" }, "not json").leadSeconds === 30);
  check("config: kill switch", !loadConfig({ PRIVATE_AI_HARNESS_KEEPALIVE: "OFF" }).enabled);

  if (failures.length) {
    console.error(`keepalive selftest: ${failures.length}/${total} failed\n- ${failures.join("\n- ")}`);
    return 1;
  }
  console.log(`keepalive selftest: ${total}/${total} passed`);
  return 0;
}

if (process.argv.includes("--selftest")) process.exit(selftest());
else await main();
