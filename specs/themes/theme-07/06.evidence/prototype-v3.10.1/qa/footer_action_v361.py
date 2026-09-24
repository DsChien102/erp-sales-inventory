from pathlib import Path
from playwright.sync_api import sync_playwright
import json, re, sys

VERSION = "3.6.1"
ROOT = Path(__file__).resolve().parents[1]
OUT_JSON = ROOT / "qa" / f"FOOTER-ACTION-QA-v{VERSION}.json"
OUT_MD = ROOT / "qa" / f"FOOTER-ACTION-QA-v{VERSION}.md"

def inline(root: Path) -> str:
    h = (root / "index.html").read_text(encoding="utf-8")
    h = re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>', '', h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>', h):
        p = root / fn.split('?')[0]
        rep = f'<style>\n{p.read_text(encoding="utf-8")}\n</style>' if p.exists() else ''
        h = re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>', rep, h, count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>', h):
        p = root / fn.split('?')[0]
        old = f'<script src="{fn}"></script>'
        rep = f'<script>\n{p.read_text(encoding="utf-8")}\n</script>' if p.exists() else ''
        h = h.replace(old, rep)
    return h

checks = []
def check(name, ok, detail):
    checks.append({"name": name, "status": "PASS" if ok else "FAIL", "detail": detail})

with sync_playwright() as pw:
    browser = pw.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
                                 args=['--no-sandbox','--disable-dev-shm-usage'])
    page = browser.new_page(viewport={"width": 1500, "height": 1100})
    page.set_default_timeout(5000)
    page_errors = []
    page.on("pageerror", lambda exc: page_errors.append(str(exc)))
    page.set_content(inline(ROOT), wait_until="load", timeout=30000)
    result = page.evaluate(r'''()=>{
      const out={multi:[],single:[],all:[],scanned:0,runtimeVersion:window.__VET45_PROTOTYPE__?.version||null};
      for(const f of flowCatalog){
        for(const sid of f.screens){
          const sc=screens.find(x=>x.id===sid);
          for(const st of (sc?.states||['READY'])){
            activeFlowId=f.id; activeScreenId=sid; stateByScreen[sid]=st; render(); out.scanned+=1;
            const app=document.getElementById('app-screen');
            const ar=app?.getBoundingClientRect();
            for(const ft of [...document.querySelectorAll('#app-screen .app-actions')].filter(x=>x.offsetParent!==null)){
              const direct=[...ft.children].filter(x=>x.tagName==='BUTTON' && x.offsetParent!==null);
              const nested=[...ft.querySelectorAll('button')].filter(x=>x.offsetParent!==null);
              const fr=ft.getBoundingClientRect();
              const buttons=nested.map((x,idx)=>{
                const r=x.getBoundingClientRect(), cs=getComputedStyle(x);
                return {idx,text:x.innerText.trim(),x:r.x,y:r.y,w:r.width,h:r.height,
                  cls:x.className,color:cs.color,borderColor:cs.borderColor,bg:cs.backgroundColor,
                  primary:x.classList.contains('button--primary')||x.classList.contains('ds24-button--primary'),
                  danger:x.classList.contains('button--danger')||x.classList.contains('ds24-button--danger')||x.classList.contains('ac310-danger-text')||x.classList.contains('v360-session-cancel')||x.dataset.dsPropTone==='VComponentTone.danger'||x.dataset.dsProfile==='button.destructiveSecondary'};
              });
              const row={flow:f.id,screen:sid,state:st,footerCls:ft.className,
                directCount:direct.length,count:nested.length,x:fr.x,y:fr.y,w:fr.width,h:fr.height,
                bottom:fr.bottom,appBottom:ar?.bottom||null,buttons,
                dsLayout:ft.dataset.dsPropLayout||null,dsTone:ft.dataset.dsPropTone||null,
                display:getComputedStyle(ft).display,grid:getComputedStyle(ft).gridTemplateColumns};
              out.all.push(row);
              if(nested.length===1) out.single.push(row);
              if(nested.length>=2) out.multi.push(row);
            }
          }
        }
      }
      return out;
    }''')
    browser.close()

multi = result["multi"]
single = result["single"]
all_rows = result["all"]

# The current declared matrix contains 17 two-action footer occurrences.
check("runtime_version", result["runtimeVersion"] == VERSION,
      f"runtime={result['runtimeVersion']} expected={VERSION}")
check("no_browser_page_errors", len(page_errors) == 0, f"errors={len(page_errors)}")
check("dual_footer_occurrences", len(multi) == 17, f"observed={len(multi)} expected=17")
check("no_footer_with_3plus_actions", all(r["count"] <= 2 for r in all_rows),
      f"max={max([r['count'] for r in all_rows] or [0])}")

horiz_bad=[]; geometry_bad=[]; order_bad=[]; bleed_bad=[]; class_bad=[]; danger_bad=[]
for r in multi:
    b=r["buttons"]
    if len(b)!=2 or abs(b[0]["y"]-b[1]["y"])>1.5:
        horiz_bad.append(r)
    # canonical 402x92 footer, content buttons 181/8/181 and 44px high
    if not (abs(r["w"]-402)<=0.5 and abs(r["h"]-92)<=0.5 and
            all(abs(x["w"]-181)<=0.75 and abs(x["h"]-44)<=0.5 for x in b) and
            abs((b[1]["x"]-(b[0]["x"]+b[0]["w"]))-8)<=0.75):
        geometry_bad.append(r)
    primary_idx=[i for i,x in enumerate(b) if x["primary"]]
    if primary_idx and primary_idx[-1] != 1:
        order_bad.append(r)
    if r["bottom"] > r["appBottom"] + 0.75:
        bleed_bad.append(r)
    if "v361-dual-footer" not in r["footerCls"] or r["dsLayout"] != "Dual":
        class_bad.append(r)
    if any(x["danger"] for x in b):
        if r["dsTone"] != "Danger" or "v361-dual-footer--danger" not in r["footerCls"]:
            danger_bad.append(r)

check("dual_actions_horizontal", not horiz_bad, f"violations={len(horiz_bad)}")
check("dual_footer_exact_geometry", not geometry_bad, f"violations={len(geometry_bad)}")
check("secondary_or_destructive_left_primary_right", not order_bad, f"violations={len(order_bad)}")
check("no_footer_bleed_outside_product_viewport", not bleed_bad, f"violations={len(bleed_bad)}")
check("dual_footer_ds_metadata", not class_bad, f"violations={len(class_bad)}")
check("danger_dual_footer_semantics", not danger_bad, f"violations={len(danger_bad)}")

# Single-action footer regression: primary single CTA should remain a full-width 370x44 action when present.
single_primary = [r for r in single if r["buttons"] and r["buttons"][0]["primary"]]
single_bad=[r for r in single_primary if not (abs(r["buttons"][0]["w"]-370)<=0.75 and abs(r["buttons"][0]["h"]-44)<=0.5)]
check("single_primary_footer_regression", not single_bad,
      f"checked={len(single_primary)} violations={len(single_bad)}")

status = "PASS" if all(c["status"]=="PASS" for c in checks) else "FAIL"
summary = {
    "version": VERSION,
    "status": status,
    "scope": "All declared Theme 7 route-state renders; Sticky Footer single/dual action geometry and semantics.",
    "routeStatesScanned": result["scanned"],
    "visibleFooterOccurrences": len(all_rows),
    "dualFooterOccurrences": len(multi),
    "singleFooterOccurrences": len(single),
    "checks": checks,
    "dualFooterMatrix": [{k:r[k] for k in ["flow","screen","state","footerCls","dsLayout","dsTone"]} | {"buttons":[{"text":b["text"],"w":b["w"],"h":b["h"],"primary":b["primary"],"danger":b["danger"]} for b in r["buttons"]]} for r in multi],
    "violations": {
        "horizontal": [{"flow":r["flow"],"screen":r["screen"],"state":r["state"]} for r in horiz_bad],
        "geometry": [{"flow":r["flow"],"screen":r["screen"],"state":r["state"]} for r in geometry_bad],
        "order": [{"flow":r["flow"],"screen":r["screen"],"state":r["state"]} for r in order_bad],
        "bleed": [{"flow":r["flow"],"screen":r["screen"],"state":r["state"]} for r in bleed_bad],
        "dsMetadata": [{"flow":r["flow"],"screen":r["screen"],"state":r["state"]} for r in class_bad],
        "dangerSemantics": [{"flow":r["flow"],"screen":r["screen"],"state":r["state"]} for r in danger_bad],
        "singleRegression": [{"flow":r["flow"],"screen":r["screen"],"state":r["state"]} for r in single_bad],
        "browserErrors": page_errors,
    }
}
OUT_JSON.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
md = [
    f"# Footer Action QA — v{VERSION}", "",
    f"**Status: {status}**", "",
    "Scope: all declared Theme 7 route-state renders. Validates the canonical DS dual Sticky Footer rule: `Secondary/Destructive | Primary`, 402×92 footer, 181/8/181 actions, 44 px action height, and no bezel/footer bleed.", "",
    f"- Route-state renders scanned: **{result['scanned']}**",
    f"- Visible footer occurrences: **{len(all_rows)}**",
    f"- Dual-footer occurrences: **{len(multi)}**",
    f"- Single-footer occurrences: **{len(single)}**",
    f"- Browser page errors: **{len(page_errors)}**", "",
    "## Checks", ""
]
for c in checks:
    md.append(f"- **{c['status']}** — `{c['name']}` — {c['detail']}")
md += ["", "## Dual-footer states", "", "| Flow | Screen | State | Left | Right | Tone |", "|---|---|---|---|---|---|"]
for r in multi:
    b=r["buttons"]
    md.append(f"| {r['flow']} | {r['screen']} | {r['state']} | {b[0]['text']} | {b[1]['text']} | {r['dsTone']} |")
OUT_MD.write_text("\n".join(md)+"\n", encoding="utf-8")

print(json.dumps({"status":status,"checks":len(checks),"passed":sum(c['status']=='PASS' for c in checks),"dual":len(multi),"browserErrors":len(page_errors)}, ensure_ascii=False))
sys.exit(0 if status=="PASS" else 1)
