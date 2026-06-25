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
const CLAUDE_SESSION_OUT_LIMIT = intEnv("CLAUDE_SESSION_OUT_LIMIT", 500000);
const CLAUDE_WEEKLY_OUT_LIMIT = intEnv("CLAUDE_WEEKLY_OUT_LIMIT", 3000000);

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

  stats.sLeft = 100 - Math.min(100, Math.floor((stats.sOut * 100) / CLAUDE_SESSION_OUT_LIMIT));
  stats.wLeft = 100 - Math.min(100, Math.floor((stats.wOut * 100) / CLAUDE_WEEKLY_OUT_LIMIT));
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
      if (!rateLimits || !rateLimits.primary) return;
      const ts = Date.parse(obj.timestamp || "");
      if (!Number.isFinite(ts)) return;
      if (!latest || ts > latest.ts) {
        latest = { ts, file, payload, rateLimits };
      }
    });
  }

  const cfgPath = path.join(HOME, ".codex", "config.toml");
  const configModel = readTomlRootString(cfgPath, "model");
  const effortRaw = readTomlRootString(cfgPath, "model_reasoning_effort") || "medium";
  const effortMap = { low: "lo", medium: "med", high: "hi", xhigh: "xhi" };
  const configEffort = effortMap[effortRaw.toLowerCase()] || effortRaw;

  if (!latest) return { model: configModel || "unknown", effort: configEffort, noData: true };
  const rl = latest.rateLimits;
  return {
    ageMin: ageMinutes(latest.ts),
    model: latest.payload.model || configModel || "unknown",
    effort: configEffort,
    plan: rl.plan_type || "unknown",
    limitReached: !!rl.rate_limit_reached_type,
    primaryLeft: pctLeft(rl.primary.used_percent),
    primaryReset: rl.primary.resets_at,
    primaryWindowMin: rl.primary.window_minutes || 10080,
    secondaryLeft: rl.secondary ? pctLeft(rl.secondary.used_percent) : null,
    secondaryReset: rl.secondary ? rl.secondary.resets_at : null,
    sourceFile: latest.file,
    tokenUsage: latest.payload.info && latest.payload.info.total_token_usage ? latest.payload.info.total_token_usage : null,
  };
}

function shrinkAgyModel(raw) {
  if (!raw) return "?";
  const m = raw.match(/^(.+?)\s*\(([^)]+)\)\s*$/);
  if (!m) return raw;
  const name = m[1].trim()
    .replace(/^Gemini /, "")
    .replace(/^Claude /, "")
    .replace(/ /g, "");
  const effortMap = { Low: "Lo", Medium: "Med", High: "Hi", Thinking: "Think" };
  const effort = effortMap[m[2]] || m[2];
  return `${name}/${effort}`;
}

function agyStats() {
  const cfg = readJson(path.join(HOME, ".gemini", "antigravity-cli", "settings.json"));
  if (!cfg) return null;
  return { model: cfg.model || "?", short: shrinkAgyModel(cfg.model) };
}


function codexEffectiveLeft(codex) {
  if (codex.primaryReset && codex.primaryReset < Date.now() / 1000) return 100;
  return codex.primaryLeft;
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
  const agy = agyStats();
  console.log(line);
  console.log(` CLI USAGE  (${nowStr})`);
  console.log(line);
  const apiCache = loadClaudeApiCache();
  const claudeSession = apiCache ? apiCache.sessionLeft : claude.sLeft;
  const claudeWeek    = apiCache ? apiCache.weekLeft    : claude.wLeft;
  const claudeSource  = apiCache ? `API · cached ${ageMinutes(apiCache.ts)}m ago` : "local token estimate";
  console.log(`${C.cy}Claude Code${C.rs}  ${C.dm}(${claudeSource} · exact: /usage)${C.rs}`);
  console.log(`   Session:    ${bar(claudeSession)}  ${colorPct(claudeSession)}${claudeSession}%${C.rs} left`);
  console.log(`   Weekly:     ${bar(claudeWeek)}  ${colorPct(claudeWeek)}${claudeWeek}%${C.rs} left`);
  console.log(`   ${C.dm}Tokens 5h:  in ${fmtK(claude.sIn)} / out ${fmtK(claude.sOut)}  (${claude.sMsgs} msgs)${C.rs}`);
  console.log(`   ${C.dm}Tokens 7d:  in ${fmtK(claude.wIn)} / out ${fmtK(claude.wOut)}  (${claude.wMsgs} msgs)${C.rs}`);

  console.log("");
  if (codex) {
    if (codex.plan === "free") {
      console.log(`${C.cy}Codex CLI${C.rs}  ${C.rd}unsubscribed${C.rs}  ${C.dm}(exact: /status)${C.rs}`);
    } else {
      const hit = codex.limitReached ? `  ${C.rd}⚠ LIMIT REACHED${C.rs}` : "";
      console.log(`${C.cy}Codex CLI${C.rs}  ${C.dm}(${codex.plan} · ${codex.model} · data from ${codex.ageMin}m ago · exact: /status)${C.rs}${hit}`);
      if (codex.secondaryLeft !== null) {
        const sessLeft = codexEffectiveLeft(codex);
        console.log(`   Session:   ${bar(sessLeft)}  ${colorPct(sessLeft)}${sessLeft}%${C.rs} left  (resets ${formatReset(codex.primaryReset)})`);
        console.log(`   Weekly:    ${bar(codex.secondaryLeft)}  ${colorPct(codex.secondaryLeft)}${codex.secondaryLeft}%${C.rs} left  (resets ${formatReset(codex.secondaryReset)})`);
      } else {
        const wkLeft = codexEffectiveLeft(codex);
        console.log(`   Weekly:    ${bar(wkLeft)}  ${colorPct(wkLeft)}${wkLeft}%${C.rs} left  (resets ${formatReset(codex.primaryReset)})`);
      }
      if (codex.ageMin > 120) {
        console.log(`   ${C.dm}⚠ Data: ${codex.ageMin}m ago — run codex TUI to refresh${C.rs}`);
      }
    }
  } else {
    console.log(`${C.cy}Codex CLI${C.rs}  ${C.dm}(no rate_limits data found)${C.rs}`);
  }

  console.log("");
  if (agy) {
    console.log(`${C.cy}agy${C.rs}  ${C.dm}(${agy.model})${C.rs}`);
    console.log(`   Model:  ${C.mg}${agy.short}${C.rs}  ${C.dm}(change: agy → /model)${C.rs}`);
    console.log(`   ${C.dm}Usage:  Run /usage inside agy to view live quota limits${C.rs}`);
  } else {
    console.log(`${C.cy}agy${C.rs}  ${C.dm}(not configured)${C.rs}`);
  }

  console.log(line);
}

const CLAUDE_API_CACHE = path.join(HOME, ".cache", "frugal-harness", "claude-api.json");

function saveClaudeApiCache(sessionLeft, weekLeft) {
  try {
    fs.mkdirSync(path.dirname(CLAUDE_API_CACHE), { recursive: true });
    fs.writeFileSync(CLAUDE_API_CACHE, JSON.stringify({ sessionLeft, weekLeft, ts: Date.now() }));
  } catch {}
}

function loadClaudeApiCache() {
  try {
    const obj = JSON.parse(fs.readFileSync(CLAUDE_API_CACHE, "utf8"));
    if (typeof obj.sessionLeft === "number" && typeof obj.weekLeft === "number") return obj;
  } catch {}
  return null;
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
  const agy = agyStats();

  const rl = input && input.rate_limits;
  const apiSession = (rl && rl.five_hour && typeof rl.five_hour.used_percentage === "number")
    ? Math.max(0, 100 - Math.floor(rl.five_hour.used_percentage)) : null;
  const apiWeek = (rl && rl.seven_day && typeof rl.seven_day.used_percentage === "number")
    ? Math.max(0, 100 - Math.floor(rl.seven_day.used_percentage)) : null;

  if (apiSession !== null || apiWeek !== null) {
    const prev = loadClaudeApiCache() || {};
    saveClaudeApiCache(
      apiSession !== null ? apiSession : prev.sessionLeft,
      apiWeek   !== null ? apiWeek   : prev.weekLeft
    );
  }

  const apiCache = loadClaudeApiCache();
  const claudeSession = apiSession !== null ? apiSession : (apiCache ? apiCache.sessionLeft : claude.sLeft);
  const claudeWeek    = apiWeek   !== null ? apiWeek   : (apiCache ? apiCache.weekLeft    : claude.wLeft);

  const parts = [];
  if (projectDir) parts.push(`${C.cy}${path.basename(projectDir)}${C.rs}`);
  if (modelName) parts.push(`${C.mg}${modelName}${C.rs}`);
  if (branch) parts.push(`${C.gn}⎇ ${branch}${C.rs}`);
  parts.push(`${C.dm}Claude${C.rs} ${colorPct(claudeSession)}session ${claudeSession}%${C.rs} ${colorPct(claudeWeek)}week ${claudeWeek}%${C.rs}`);
  if (codex) {
    const modelTag = `${C.mg}${codex.model}/${codex.effort}${C.rs}`;
    if (codex.noData) {
      parts.push(`${C.dm}Codex${C.rs} ${modelTag}`);
    } else if (codex.plan === "free") {
      parts.push(`${C.dm}Codex${C.rs} ${modelTag} ${C.rd}unsubscribed${C.rs}`);
    } else {
      const hit = codex.limitReached ? `${C.rd}LIMIT${C.rs} ` : "";
      let s = `${C.dm}Codex${C.rs} ${modelTag} ${hit}`;
      if (codex.secondaryLeft !== null) {
        const sessLeft = codexEffectiveLeft(codex);
        s += `${colorPct(sessLeft)}session ${sessLeft}%${C.rs} ${colorPct(codex.secondaryLeft)}wk ${codex.secondaryLeft}%${C.rs}`;
      } else {
        const wkLeft = codexEffectiveLeft(codex);
        s += `${colorPct(wkLeft)}wk ${wkLeft}%${C.rs}`;
      }
      parts.push(s);
    }
  } else {
    parts.push(`${C.dm}Codex${C.rs} ?`);
  }
  if (agy) {
    parts.push(`${C.dm}agy${C.rs} ${C.mg}${agy.short}${C.rs}`);
  }
  console.log(parts.join("  "));

  const claudeCost = claudeSessionCost(transcriptPath);
  const codexCost = codexSessionCost(codex);
  const totalCost = claudeCost !== null ? claudeCost + (codexCost ?? 0) : null;
  console.log(
    `  Claude ${C.yl}${formatCost(claudeCost)}${C.rs}  ` +
      `Codex ${C.yl}${formatCost(codexCost)}${C.rs}  ` +
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
