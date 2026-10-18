#!/usr/bin/env python3
"""T7-P A9: gỡ BJ-15 / v320 / v351 / legacy-sheet-cleanup khỏi core.js; chuyển cf* + ac310ProductRow."""
from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"
CORE = APP / "core.js"
BACKUP = APP / "core.js.before-a9"
SHARED = APP / "shared-control.js"

if not BACKUP.exists():
    shutil.copy2(CORE, BACKUP)

text = BACKUP.read_text(encoding="utf-8")
lines = text.split("\n")


def find(pat: str, start: int = 0) -> int:
    for i in range(start, len(lines)):
        if pat in lines[i]:
            return i
    raise SystemExit(f"not found: {pat!r} from {start}")


def find_re(pat: str, start: int = 0) -> int:
    rx = re.compile(pat)
    for i in range(start, len(lines)):
        if rx.search(lines[i]):
            return i
    raise SystemExit(f"not found re: {pat!r} from {start}")


def cut(a: int, b: int, repl: list[str] | None = None) -> None:
    global lines
    lines = lines[:a] + (repl or []) + lines[b:]


# --- 1. Extract cf* helpers for shared-control ---
cf_start = find("/* cfMoney…cfSecondary dùng chung BJ-12/15 (T7-P A8) */")
cf_end = find("/* cf12ReviewCard → app/bj11.js or bj12.js (T7-P A8) */")
cf_helpers = "\n".join(lines[cf_start + 1 : cf_end]).strip() + "\n"

# --- 2. Extract ac310ProductRow ---
pr_i = find("function ac310ProductRow(")
# find end of function (next line starting with /* or function at same level)
pr_end = pr_i + 1
while pr_end < len(lines) and not (
    lines[pr_end].startswith("/*") or lines[pr_end].startswith("function ")
):
    pr_end += 1
ac310_product_row = "\n".join(lines[pr_i:pr_end]).strip() + "\n"

# --- Apply cuts from bottom to top so indices stay valid ---

# legacy-sheet-cleanup block
ls = find("/* ===== legacy-sheet-cleanup (từ v381) ===== */")
ls_end = find("/* ===== legacy-cross-theme-copy (từ v390) ===== */")
cut(ls, ls_end, ["/* legacy-sheet-cleanup → bj15.js sheets (T7-P A9) */", ""])

# v351 entire block
v351 = find("/* ===== v351-list-chip-navigation-correction.js ===== */")
v360 = find("/* ===== v360-full-theme-completion.js ===== */")
cut(v351, v360, ["/* v351 → bj09.js / bj15.js (T7-P A9) */", ""])

# v350 BJ15 section: from "// BJ15 — report filters" through renderers SCR-058 assignment end
bj15_v350 = find("// BJ15 — report filters constrain actual datasets")
bj16_v350 = find("// BJ16 / BJ17 — context integrity")
cut(
    bj15_v350,
    bj16_v350,
    [
        "// BJ15 → app/bj15.js (T7-P A9)",
        "",
    ],
)

# getCf15Rows update
for i, line in enumerate(lines):
    if "getCf15Rows" in line:
        lines[i] = (
            "    getCf15Rows(mode=typeof cf15DateMode!=='undefined'?cf15DateMode:'BUSINESS')"
            "{return (typeof bj15Movements==='function'?bj15Movements(mode):[]).map(x=>x.id);},"
        )
        break

# v320 entire block
v320 = find("/* ===== v320-audit-control-ui-correction.js ===== */")
v340 = find("/* v340 BJ-08 moved/removed (T7-P A7) */")
cut(v320, v340, ["/* v320 → bj09.js / bj15.js (T7-P A9) */", ""])

# v310 bind SCR-054..059
bind054 = find('renderers["SCR-054"]=ac310Render054;')
# remove through SCR-059 line
bind_end = find('renderers["SCR-059"]=')
cut(
    bind054,
    bind_end + 1,
    [
        '/* SCR-054…059 → app/bj15.js (T7-P A9); SCR-056 = flowScreen */',
        'renderers["SCR-056"]=flowScreen("SCR-056");',
    ],
)

# Remove BJ15 ac310 functions: from ac310ModeChoice through ac310Render058
mode = find("/* ------------------------------ BJ15 ----------------------------------- */")
bj16 = find("/* --------------------------- BJ16 / BJ17 ------------------------------- */")
cut(mode, bj16, ["/* BJ15 ac310* → app/bj15.js (T7-P A9) */", ""])

# Remove ac310Render056 (BJ09 branch) and ac310StateLabel
st_label = find("function ac310StateLabel(")
# remove ac310StateLabel one-liner
cut(st_label, st_label + 1, ["/* ac310StateLabel removed (T7-P A9) */"])
r056 = find("function ac310Render056(state){")
# find end — next /* ------------------------------ BJ10
bj10 = find("/* ------------------------------ BJ10 ----------------------------------- */")
cut(r056, bj10, ["/* ac310Render056 → bj09.js / bj15.js (T7-P A9) */", ""])

# Remove ac310ProductRow from core (moved to shared)
pr_i = find("function ac310ProductRow(")
pr_end = pr_i + 1
while pr_end < len(lines) and not (
    lines[pr_end].startswith("/*") or lines[pr_end].startswith("function ")
):
    pr_end += 1
cut(pr_i, pr_end, ["/* ac310ProductRow → app/shared-control.js (T7-P A9) */"])

# Remove UIF-15 listeners (v1.8.0 block) — keep structure if only UIF-15 remains
# The block starts at "// v1.8.0 — targeted interactions"
v18 = find("// v1.8.0 — targeted interactions for UIF12 / UIF15")
flow_sel = find("const flowSelectorEl=document.getElementById(\"flow-selector\");")
cut(
    v18,
    flow_sel,
    [
        "// v1.8.0 UIF-12 → bj12.js (A8); UIF-15 → bj15.js (T7-P A9)",
        "",
    ],
)

# Remove render056IC09
r056ic = find("function render056IC09(state){")
# next comment block
next_moved = find("/* render036IC10 moved", r056ic)
cut(r056ic, next_moved, ["/* render056IC09 → app/bj09.js (T7-P A9) */", ""])

# Remove cf15 state + renderers from app.js section
cf15_let = find("let cf15ReportType = \"INVENTORY\";")
# ends before const renderers =
rend = find("const renderers = {", cf15_let)
cut(
    cf15_let,
    rend,
    [
        "/* cf15* state + render054…059CF15 → app/bj15.js (T7-P A9) */",
        "",
    ],
)

# Fix renderers literal — remove SCR-054…059
for i, line in enumerate(lines):
    if line.startswith("const renderers = {"):
        lines[i] = re.sub(
            r',"SCR-054":render054CF15,"SCR-055":render055CF15,"SCR-056":render056CF15,'
            r'"SCR-057":render057CF15,"SCR-058":render058CF15,"SCR-059":render059CF15',
            "",
            line,
        )
        if "SCR-054" in lines[i]:
            raise SystemExit(f"failed to strip SCR-054…059 from renderers literal: {lines[i][:200]}")
        break
else:
    raise SystemExit("renderers literal not found")

# Remove cf* helpers from core
cf_start = find("/* cfMoney…cfSecondary dùng chung BJ-12/15 (T7-P A8) */")
cf_end = find("/* cf12ReviewCard → app/bj11.js or bj12.js (T7-P A8) */")
cut(
    cf_start,
    cf_end,
    ["/* cfMoney…cfSecondary → app/shared-control.js (T7-P A9) */"],
)

CORE.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {CORE} ({len(lines)} lines)")

# --- shared-control.js ---
shared = SHARED.read_text(encoding="utf-8")
header_old = """/* shared-control.js — helpers dùng chung cụm kiểm soát BJ-08/09/10/11/12/15/16/17 (T7-P A7/A8).
 * A7: ac310Tone / CleanText / SanitizeMarkup / Return / InfoSurface / RecordRow.
 * A8: SectionTitle / KeyValueSurface / ListSurface / RadioSurface / Audit* / SummaryMetrics / Field / ApprovalFooter.
 * Còn ở core.js chờ A9–A10: ac310ProductRow, ac310ModeChoice, ac310EvidenceRows, ac310CaseRows,
 * ac310Cf15ProductSheet, ac310StateLabel, ac321CanonicalChips, ac310Base (+ ac310BaseRenderers).
 */"""
header_new = """/* shared-control.js — helpers dùng chung cụm kiểm soát BJ-08/09/10/11/12/15/16/17 (T7-P A7–A9).
 * A7: ac310Tone / CleanText / SanitizeMarkup / Return / InfoSurface / RecordRow.
 * A8: SectionTitle / KeyValueSurface / ListSurface / RadioSurface / Audit* / SummaryMetrics / Field / ApprovalFooter.
 * A9: cfMoney…cfSecondary, ac310ProductRow.
 * Còn ở core.js chờ A10: ac310EvidenceRows, ac310CaseRows, ac321CanonicalChips, ac310Base (+ ac310BaseRenderers).
 */"""
if header_old not in shared:
    raise SystemExit("shared-control header mismatch")
shared = shared.replace(header_old, header_new)
if "function ac310ProductRow" not in shared:
    shared = shared.rstrip() + "\n\n" + ac310_product_row
if "const cfMoney" not in shared and "function cfMoney" not in shared:
    shared = shared.rstrip() + "\n\n/* cf* — BJ-12 / BJ-15 (T7-P A9) */\n" + cf_helpers
SHARED.write_text(shared if shared.endswith("\n") else shared + "\n", encoding="utf-8")
print(f"Wrote {SHARED}")
print("OK")
