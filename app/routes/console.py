"""Operator console: a human-facing HTML dashboard + activity JSON feed."""

from __future__ import annotations

from flask import Blueprint, jsonify

from app import activity

console_bp = Blueprint("console", __name__)


@console_bp.route("/api/activity", methods=["GET"])
def api_activity():
    """JSON feed the console polls: running stats + recent requests."""
    return jsonify(activity.snapshot())


@console_bp.route("/console", methods=["GET"])
def console():
    """Self-contained operator dashboard (no build step, no external assets)."""
    return _CONSOLE_HTML, 200, {"Content-Type": "text/html; charset=utf-8"}


_CONSOLE_HTML = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PathfinderLM — Operator Console</title>
<style>
  :root { --bg:#0f1117; --card:#1a1d27; --line:#2a2f3d; --fg:#e6e8ee;
          --muted:#8b93a7; --ok:#36d399; --warn:#fbbd23; --err:#f87272; --accent:#6e40c9; }
  * { box-sizing:border-box; }
  body { margin:0; background:var(--bg); color:var(--fg);
         font:14px/1.5 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace; }
  header { padding:16px 22px; border-bottom:1px solid var(--line);
           display:flex; align-items:center; gap:12px; flex-wrap:wrap; }
  header h1 { font-size:16px; margin:0; letter-spacing:.5px; }
  .dot { width:9px; height:9px; border-radius:50%; display:inline-block; }
  .wrap { padding:22px; max-width:1100px; margin:0 auto; }
  .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(150px,1fr)); gap:12px; }
  .card { background:var(--card); border:1px solid var(--line); border-radius:10px; padding:14px 16px; }
  .card .k { color:var(--muted); font-size:11px; text-transform:uppercase; letter-spacing:.6px; }
  .card .v { font-size:22px; margin-top:4px; }
  h2 { font-size:13px; color:var(--muted); text-transform:uppercase; letter-spacing:.6px;
       margin:26px 0 10px; }
  table { width:100%; border-collapse:collapse; }
  th,td { text-align:left; padding:8px 10px; border-bottom:1px solid var(--line); vertical-align:top; }
  th { color:var(--muted); font-weight:600; font-size:11px; text-transform:uppercase; }
  td.q { max-width:420px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  .pill { padding:1px 8px; border-radius:999px; font-size:12px; }
  .s200 { background:rgba(54,211,153,.15); color:var(--ok); }
  .s4, .s5 { background:rgba(248,114,114,.15); color:var(--err); }
  textarea { width:100%; background:#0c0e14; color:var(--fg); border:1px solid var(--line);
             border-radius:8px; padding:10px; font:inherit; resize:vertical; }
  button { background:var(--accent); color:#fff; border:0; border-radius:8px;
           padding:9px 16px; font:inherit; cursor:pointer; margin-top:8px; }
  button:disabled { opacity:.5; cursor:default; }
  #answer { white-space:pre-wrap; background:var(--card); border:1px solid var(--line);
            border-radius:10px; padding:14px 16px; margin-top:12px; min-height:20px; }
  .muted { color:var(--muted); }
  a { color:var(--accent); }
</style>
</head>
<body>
<header>
  <span id="livedot" class="dot" style="background:var(--muted)"></span>
  <h1>PathfinderLM — Operator Console</h1>
  <span class="muted" id="sub">connecting…</span>
</header>
<div class="wrap">

  <div class="grid">
    <div class="card"><div class="k">Status</div><div class="v" id="status">—</div></div>
    <div class="card"><div class="k">Model</div><div class="v" id="model">—</div></div>
    <div class="card"><div class="k">Ollama</div><div class="v" id="ollama">—</div></div>
    <div class="card"><div class="k">Index</div><div class="v" id="index">—</div></div>
    <div class="card"><div class="k">Requests</div><div class="v" id="total">0</div></div>
    <div class="card"><div class="k">Errors</div><div class="v" id="errors">0</div></div>
    <div class="card"><div class="k">Avg latency</div><div class="v" id="avg">0<span class="muted" style="font-size:13px">ms</span></div></div>
    <div class="card"><div class="k">Uptime</div><div class="v" id="uptime">0s</div></div>
  </div>

  <h2>Ask the coach</h2>
  <textarea id="q" rows="2" placeholder="e.g. How do I build a consistent morning routine?"></textarea>
  <button id="ask">Ask</button>
  <div id="answer" class="muted">Answers appear here.</div>

  <h2>Recent requests</h2>
  <table>
    <thead><tr><th>Time</th><th>Question</th><th>Status</th><th>Latency</th><th>Sources</th></tr></thead>
    <tbody id="rows"><tr><td colspan="5" class="muted">No requests yet.</td></tr></tbody>
  </table>

  <p class="muted" style="margin-top:24px">
    Endpoints: <a href="/health">/health</a> · <a href="/api/activity">/api/activity</a> ·
    <a href="/metrics">/metrics</a> · <a href="/">/</a>
  </p>
</div>

<script>
const $ = id => document.getElementById(id);
function fmtAge(s){ if(s<60)return s+"s"; if(s<3600)return Math.floor(s/60)+"m "+(s%60)+"s";
  return Math.floor(s/3600)+"h "+Math.floor((s%3600)/60)+"m"; }
function timeStr(ts){ return new Date(ts*1000).toLocaleTimeString(); }

async function poll(){
  try {
    const [h, a] = await Promise.all([
      fetch("/health").then(r=>r.json()),
      fetch("/api/activity").then(r=>r.json())
    ]);
    $("livedot").style.background = "var(--ok)";
    $("sub").textContent = "provider: " + h.provider;
    $("status").textContent = h.status;
    $("model").textContent = h.model;
    $("ollama").innerHTML = h.ollama ? '<span style="color:var(--ok)">reachable</span>'
                                     : '<span style="color:var(--err)">down</span>';
    $("index").innerHTML = h.index ? '<span style="color:var(--ok)">loaded</span>'
                                   : '<span style="color:var(--warn)">none</span>';
    $("total").textContent = a.stats.total;
    $("errors").textContent = a.stats.errors;
    $("avg").innerHTML = a.stats.avg_latency_ms + '<span class="muted" style="font-size:13px">ms</span>';
    $("uptime").textContent = fmtAge(a.stats.uptime_s);
    const rows = a.recent.map(r => {
      const cls = r.status===200 ? "s200" : (r.status<500?"s4":"s5");
      const q = (r.question||"").replace(/</g,"&lt;") || '<span class="muted">(none)</span>';
      return `<tr><td>${timeStr(r.ts)}</td><td class="q" title="${q}">${q}</td>`+
             `<td><span class="pill ${cls}">${r.status}</span></td>`+
             `<td>${r.latency_ms}ms</td><td>${r.sources}</td></tr>`;
    }).join("");
    $("rows").innerHTML = rows || '<tr><td colspan="5" class="muted">No requests yet.</td></tr>';
  } catch(e) {
    $("livedot").style.background = "var(--err)";
    $("sub").textContent = "disconnected";
  }
}

$("ask").onclick = async () => {
  const q = $("q").value.trim();
  if(!q) return;
  $("ask").disabled = true; $("answer").className=""; $("answer").textContent = "Thinking…";
  try {
    const r = await fetch("/ask", {method:"POST", headers:{"Content-Type":"application/json"},
                                   body: JSON.stringify({question:q})});
    const d = await r.json();
    $("answer").textContent = d.answer || ("Error: " + (d.error||"unknown"));
  } catch(e){ $("answer").textContent = "Request failed: " + e; }
  $("ask").disabled = false; poll();
};
$("q").addEventListener("keydown", e => { if(e.key==="Enter" && (e.metaKey||e.ctrlKey)) $("ask").click(); });

poll(); setInterval(poll, 2000);
</script>
</body>
</html>"""
