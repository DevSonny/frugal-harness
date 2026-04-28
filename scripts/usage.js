#!/usr/bin/env node
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

const HOME = os.homedir();
const argv = new Set(process.argv.slice(2));
const STATUSLINE = argv.has("--statusline");

const CLAUDE_SESSION_LIMIT = intEnv("CLAUDE_SESSION_LIMIT", 475);
const CLAUDE_WEEKLY_LIMIT = intEnv("CLAUDE_WEEKLY_LIMIT", 2700);

const C = {
  gn: "\x1b[32m",
  yl: "\x1b[33m",
  rd: "\x1b[31m",
  cy: "\x1b[36m",
  mg: "\x1b[35m",
  dm: "\x1b[2m",
  rs: "\x1b[0m",
};

function intEnv(name, fallback) {
  const value = Number.parseInt(process.env[name] || "", 10);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function readJson(file, fallback = null) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return fallback;
  }
}

function* walkFiles(root, predicate) {
  let entries;
  try {
    entries = fs.readdirSync(root, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    const file = path.join(root, entry.name);
    if (entry.isDirectory()) {
      yield* walkFiles(file, predicate);
    } else if (!predicate || predicate(file)) {
      yield file;
    }
  }
}

function parseJsonLines(file, onObject) {
  let text;
  try {
    text = fs.readFileSync(file, "utf8");
  } catch {
    return;
  }
  for (const line of text.split(/\r?\n/)) {
    if (!line) continue;
    try {
      onObject(JSON.parse(line));
    } catch {
      // Ignore partial or malformed log lines.
    }
  }
}

function colorPct(remaining) {
  if (remaining >= 50) return C.gn;
  if (remaining >= 20) return C.yl;
  return C.rd;
}

function bar(remaining) {
  const used = Math.max(0, Math.min(100, 100 - remaining));
  const filled = Math.min(20, Math.floor(used / 5));
  return `${colorPct(remaining)}${"█".repeat(filled)}${C.rs}${"░".repeat(20 - filled)}`;
}

function fmtK(value) {
  const n = Number(value || 0);
  if (!Number.isFinite(n) || n <= 0) return "0";
  if (n >= 1_000_000) return `${trim1(n / 1_000_000)}M`;
  if (n >= 1_000) return `${trim1(n / 1_000)}k`;
  return String(Math.round(n));
}

function trim1(n) {
  return n.toFixed(1).replace(/\.0$/, "");
}

function pctLeft(usedPercent) {
  const used = Math.max(0, Math.min(100, Math.floor(Number(usedPercent || 0))));
  return 100 - used;
}

function formatReset(seconds) {
  const n = Number(seconds);
  if (!Number.isFinite(n) || n <= 0) return "?";
  const d = new Date(n * 1000);
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  const hh = String(d.getHours()).padStart(2, "0");
  const mi = String(d.getMinutes()).padStart(2, "0");
  return `${mm}/${dd} ${hh}:${mi}`;
}

function ageMinutes(epochMs) {
  if (!epochMs) return "?";
  return Math.max(0, Math.floor((Date.now() - epochMs) / 60_000));
}

function readTomlRootString(file, key) {
  let text;
  try {
    text = fs.readFileSync(file, "utf8");
  } catch {
    return "";
  }
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    if (line.startsWith("[")) break;
    const match = line.match(new RegExp(`^${key}\\s*=\\s*["']?([^"'#]+)["']?`));
    if (match) return match[1].trim();
  }
  return "";
}

function claudeStats() {
  const root = path.join(HOME, ".claude", "projects");
  const now = Date.now();
  const cutoff5h = now - 5 * 3600 * 1000;
  const cutoff7d = now - 7 * 86400 * 1000;
  const stats = { sMsgs: 0, wMsgs: 0, sIn: 0, sOut: 0, wIn: 0, wOut: 0 };

  for (const file of walkFiles(root, (f) => f.endsWith(".jsonl"))) {
    parseJsonLines(file, (obj) => {
      if (obj.type !== "assistant" || !obj.timestamp) return;
      const ts = Date.parse(obj.timestamp);
      if (!Number.isFinite(ts) || ts < cutoff7d) return;
      const usage = obj.message && obj.message.usage ? obj.message.usage : {};
      const input =
        Number(usage.input_tokens || 0) +
        Number(usage.cache_read_input_tokens || 0) +
        Number(usage.cache_creation_input_tokens || 0);
      const output = Number(usage.output_tokens || 0);
      stats.wMsgs += 1;
      stats.wIn += input;
      stats.wOut += output;
      if (ts >= cutoff5h) {
        stats.sMsgs += 1;
        stats.sIn += input;
        stats.sOut += output;
      }
    });
  }

  stats.sLeft = 100 - Math.min(100, Math.floor((stats.sMsgs * 100) / CLAUDE_SESSION_LIMIT));
  stats.wLeft = 100 - Math.min(100, Math.floor((stats.wMsgs * 100) / CLAUDE_WEEKLY_LIMIT));
  return stats;
}

function codexStats() {
  const root = path.join(HOME, ".codex", "sessions");
  let latest = null;

  for (const file of walkFiles(root, (f) => path.basename(f).startsWith("rollout-") && f.endsWith(".jsonl"))) {
    parseJsonLines(file, (obj) => {
      const payload = obj.payload || {};
      if (obj.type !== "token_count" && payload.type !== "token_count") return;
      const rateLimits = payload.rate_limits;
      if (!rateLimits || !rateLimits.primary || !rateLimits.secondary) return;
      const ts = Date.parse(obj.timestamp || "");
      if (!Number.isFinite(ts)) return;
      if (!latest || ts > latest.ts) {
        latest = { ts, file, payload, rateLimits };
      }
    });
  }

  if (!latest) return null;
  const configModel = readTomlRootString(path.join(HOME, ".codex", "config.toml"), "model");
  return {
    ageMin: ageMinutes(latest.ts),
    model: latest.payload.model || configModel || "unknown",
    plan: latest.rateLimits.plan_type || "unknown",
    primaryLeft: pctLeft(latest.rateLimits.primary.used_percent),
    primaryReset: latest.rateLimits.primary.resets_at,
    secondaryLeft: pctLeft(latest.rateLimits.secondary.used_percent),
    secondaryReset: latest.rateLimits.secondary.resets_at,
    sourceFile: latest.file,
    tokenUsage: latest.payload.info && latest.payload.info.total_token_usage ? latest.payload.info.total_token_usage : null,
  };
}

function geminiStats() {
  const settings = readJson(path.join(HOME, ".gemini", "settings.json"), {});
  const model = settings && settings.model && settings.model.name ? settings.model.name : "gemini-2.5-flash-lite";
  const today = new Date().toISOString().slice(0, 10);
  const root = path.join(HOME, ".gemini", "tmp");
  const stats = { model, calls: 0, today: 0, in: 0, out: 0, cached: 0, todayIn: 0, todayOut: 0 };

  for (const file of walkFiles(root, (f) => f.includes(`${path.sep}chats${path.sep}`) && f.endsWith(".json"))) {
    const data = readJson(file);
    if (!data || !Array.isArray(data.messages)) continue;
    const dateMatch = path.basename(file).match(/\d{4}-\d{2}-\d{2}/);
    const fileDate = dateMatch ? dateMatch[0] : "";
    for (const msg of data.messages) {
      if (!msg || msg.type !== "gemini") continue;
      const tokens = msg.tokens || {};
      const input = Number(tokens.input || 0);
      const output = Number(tokens.output || 0);
      const cached = Number(tokens.cached || 0);
      stats.calls += 1;
      stats.in += input;
      stats.out += output;
      stats.cached += cached;
      if (fileDate === today) {
        stats.today += 1;
        stats.todayIn += input;
        stats.todayOut += output;
      }
    }
  }
  return stats;
}

function costFromTokens(input, cached, cacheCreation, output, inputRate, cachedRate, cacheCreationRate, outputRate) {
  const cost =
    (Number(input || 0) * inputRate +
      Number(cached || 0) * cachedRate +
      Number(cacheCreation || 0) * cacheCreationRate +
      Number(output || 0) * outputRate) /
    1_000_000;
  return Number.isFinite(cost) ? cost : null;
}

function formatCost(cost) {
  return cost === null ? "?" : `$${cost.toFixed(2)}`;
}

function claudeSessionCost(transcriptPath) {
  if (!transcriptPath || !fs.existsSync(transcriptPath)) return null;
  const totals = { input: 0, output: 0, cacheRead: 0, cacheCreation: 0 };
  parseJsonLines(transcriptPath, (obj) => {
    if (obj.type !== "assistant") return;
    const usage = obj.message && obj.message.usage ? obj.message.usage : {};
    totals.input += Number(usage.input_tokens || 0);
    totals.output += Number(usage.output_tokens || 0);
    totals.cacheRead += Number(usage.cache_read_input_tokens || 0);
    totals.cacheCreation += Number(usage.cache_creation_input_tokens || 0);
  });
  return costFromTokens(totals.input, totals.cacheRead, totals.cacheCreation, totals.output, 3.0, 0.3, 3.75, 15.0);
}

function codexSessionCost(codex) {
  if (!codex || !codex.tokenUsage) return null;
  const input = Number(codex.tokenUsage.input_tokens || 0);
  const cached = Number(codex.tokenUsage.cached_input_tokens || 0);
  const output = Number(codex.tokenUsage.output_tokens || 0);
  const uncached = Math.max(0, input - cached);
  return costFromTokens(uncached, cached, 0, output, 5.0, 0.5, 0, 30.0);
}

function latestGeminiSessionCost() {
  const root = path.join(HOME, ".gemini", "tmp");
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  let latest = null;

  for (const file of walkFiles(root, (f) => f.includes(`${path.sep}chats${path.sep}`) && path.basename(f).startsWith("session-") && f.endsWith(".json"))) {
    let stat;
    try {
      stat = fs.statSync(file);
    } catch {
      continue;
    }
    if (stat.mtimeMs < todayStart.getTime()) continue;
    if (!latest || stat.mtimeMs > latest.mtimeMs) latest = { file, mtimeMs: stat.mtimeMs };
  }

  if (!latest) return 0;
  const data = readJson(latest.file);
  if (!data || !Array.isArray(data.messages)) return 0;
  const totals = { input: 0, output: 0, cached: 0 };
  for (const msg of data.messages) {
    if (!msg || msg.type !== "gemini") continue;
    const tokens = msg.tokens || {};
    totals.input += Number(tokens.input || 0);
    totals.output += Number(tokens.output || 0);
    totals.cached += Number(tokens.cached || 0);
  }
  const uncached = Math.max(0, totals.input - totals.cached);
  return costFromTokens(uncached, totals.cached, 0, totals.output, 0.1, 0.01, 0, 0.4);
}

function gitBranch(cwd) {
  if (!cwd) return "";
  try {
    return execFileSync("git", ["-C", cwd, "--no-optional-locks", "branch", "--show-current"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    try {
      return execFileSync("git", ["-C", cwd, "--no-optional-locks", "rev-parse", "--short", "HEAD"], {
        encoding: "utf8",
        stdio: ["ignore", "pipe", "ignore"],
      }).trim();
    } catch {
      return "";
    }
  }
}

function readStdin() {
  try {
    return fs.readFileSync(0, "utf8");
  } catch {
    return "";
  }
}

function printDashboard() {
  const line = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  const now = new Date();
  const nowStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")} ${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
  const claude = claudeStats();
  const codex = codexStats();
  const gemini = geminiStats();

  console.log(line);
  console.log(` CLI USAGE  (${nowStr})`);
  console.log(line);
  console.log(`${C.cy}Claude Code${C.rs}  ${C.dm}(rolling window from project JSONL)${C.rs}`);
  console.log(`   Session 5h: ${bar(claude.sLeft)}  ${colorPct(claude.sLeft)}${claude.sLeft}%${C.rs} left  (${claude.sMsgs}/${CLAUDE_SESSION_LIMIT} msgs used)`);
  console.log(`   Weekly 7d:  ${bar(claude.wLeft)}  ${colorPct(claude.wLeft)}${claude.wLeft}%${C.rs} left  (${claude.wMsgs}/${CLAUDE_WEEKLY_LIMIT} msgs used)`);
  console.log(`   Tokens 5h:   in ${fmtK(claude.sIn)} / out ${fmtK(claude.sOut)}`);
  console.log(`   Tokens 7d:   in ${fmtK(claude.wIn)} / out ${fmtK(claude.wOut)}`);
  console.log(`   ${C.dm}Limits (approx): session=${CLAUDE_SESSION_LIMIT} msgs / week=${CLAUDE_WEEKLY_LIMIT} msgs.${C.rs}`);
  console.log(`   ${C.dm}Calibrate: CLAUDE_SESSION_LIMIT=N CLAUDE_WEEKLY_LIMIT=N usage${C.rs}`);

  console.log("");
  if (codex) {
    console.log(`${C.cy}Codex CLI${C.rs}  ${C.dm}(${codex.plan} · ${codex.model} · data from ${codex.ageMin}m ago)${C.rs}`);
    console.log(`   5h limit:  ${bar(codex.primaryLeft)}  ${colorPct(codex.primaryLeft)}${codex.primaryLeft}%${C.rs} left  (resets ${formatReset(codex.primaryReset)})`);
    console.log(`   Weekly:    ${bar(codex.secondaryLeft)}  ${colorPct(codex.secondaryLeft)}${codex.secondaryLeft}%${C.rs} left  (resets ${formatReset(codex.secondaryReset)})`);
  } else {
    console.log(`${C.cy}Codex CLI${C.rs}  ${C.dm}(no rate_limits data found)${C.rs}`);
  }

  console.log("");
  console.log(`${C.cy}Gemini CLI${C.rs}  ${C.dm}(${gemini.model})${C.rs}`);
  console.log(`   Today:     ${gemini.today} API calls — in ${fmtK(gemini.todayIn)} / out ${fmtK(gemini.todayOut)}`);
  console.log(`   All time:  ${gemini.calls} API calls — in ${fmtK(gemini.in)} / out ${fmtK(gemini.out)} / cached ${fmtK(gemini.cached)}`);
  console.log(`   ${C.dm}(Google quota is server-side only)${C.rs}`);
  console.log(line);
}

function printStatusline() {
  const input = readJsonFromString(readStdin(), {});
  const projectDir = input && input.workspace ? input.workspace.project_dir : "";
  const modelName = input && input.model ? input.model.display_name : "";
  const cwd = input && input.cwd ? input.cwd : process.cwd();
  const transcriptPath = input && input.transcript_path ? input.transcript_path : "";
  const branch = gitBranch(cwd);
  const claude = claudeStats();
  const codex = codexStats();
  const gemini = geminiStats();

  const parts = [];
  if (projectDir) parts.push(`${C.cy}${path.basename(projectDir)}${C.rs}`);
  if (modelName) parts.push(`${C.mg}${modelName}${C.rs}`);
  if (branch) parts.push(`${C.gn}⎇ ${branch}${C.rs}`);
  parts.push(`${C.dm}Claude${C.rs} ${colorPct(claude.sLeft)}session ${claude.sLeft}%${C.rs} ${colorPct(claude.wLeft)}week ${claude.wLeft}%${C.rs}`);
  if (codex) {
    parts.push(`${C.dm}Codex${C.rs} ${colorPct(codex.primaryLeft)}5h ${codex.primaryLeft}%${C.rs} ${colorPct(codex.secondaryLeft)}week ${codex.secondaryLeft}%${C.rs}`);
  } else {
    parts.push(`${C.dm}Codex${C.rs} ?`);
  }
  parts.push(`${C.dm}Gemini${C.rs} ${gemini.today} calls today`);
  console.log(parts.join("  "));

  const claudeCost = claudeSessionCost(transcriptPath);
  const codexCost = codexSessionCost(codex);
  const geminiCost = latestGeminiSessionCost();
  const totalCost =
    claudeCost === null || codexCost === null || geminiCost === null
      ? null
      : claudeCost + codexCost + geminiCost;
  console.log(
    `  Claude ${C.yl}${formatCost(claudeCost)}${C.rs}  ` +
      `Codex ${C.yl}${formatCost(codexCost)}${C.rs}  ` +
      `Gemini ${C.yl}${formatCost(geminiCost)}${C.rs}  ` +
      `\x1b[1;37mTotal ${formatCost(totalCost)}${C.rs}`
  );
}

function readJsonFromString(text, fallback) {
  try {
    return JSON.parse(text);
  } catch {
    return fallback;
  }
}

if (STATUSLINE) {
  printStatusline();
} else {
  printDashboard();
}
