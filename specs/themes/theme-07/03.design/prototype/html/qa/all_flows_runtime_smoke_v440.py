from pathlib import Path
import re, json
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
html=(ROOT/'index.html').read_text(encoding='utf-8')
# Inline all local styles/scripts in document order so test matches actual layering.
def css_repl(m):
    rel=m.group(1); p=ROOT/rel
    return f'<style data-src="{rel}">\n{p.read_text(encoding="utf-8")}\n</style>' if p.is_file() else m.group(0)
html=re.sub(r'<link[^>]+rel=["\']stylesheet["\'][^>]+href=["\']([^"\']+)["\'][^>]*>', css_repl, html)
def js_repl(m):
    rel=m.group(1); p=ROOT/rel
    return f'<script data-src="{rel}">\n{p.read_text(encoding="utf-8")}\n</script>' if p.is_file() else m.group(0)
html=re.sub(r'<script[^>]+src=["\']([^"\']+)["\'][^>]*></script>', js_repl, html)
errors=[]; failures=[]; total=0
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1680,'height':1000}); p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load')
    flows=p.evaluate('flowCatalog.map(f=>({id:f.id,screens:f.screens}))')
    for f in flows:
        for s in f['screens']:
            total+=1
            try:
                p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=stateByScreen[x.s]||"READY"; render();}',{'u':f['id'],'s':s})
                app=p.locator('#app-screen')
                text=app.inner_text().strip()
                if not text: failures.append(f"{f['id']}/{s}: empty")
                if 'undefined' in text.lower(): failures.append(f"{f['id']}/{s}: undefined leak")
                box=app.bounding_box()
                if box and box['width']>403: failures.append(f"{f['id']}/{s}: app width {box['width']}")
            except Exception as e:
                failures.append(f"{f['id']}/{s}: {e}")
    # Verify v430 is really loaded in this full-stack smoke.
    if p.evaluate('typeof window.__VET45_V430__')!='object': failures.append('v430 runtime marker missing')
    if p.evaluate('typeof window.__VET45_V431__')!='object': failures.append('v431 runtime marker missing')
    if p.evaluate('typeof window.__VET45_V440__')!='object': failures.append('v440 runtime marker missing')
    version=p.evaluate('window.__VET45_PROTOTYPE__ && window.__VET45_PROTOTYPE__.version')
    if version!='4.4.0': failures.append(f'prototype version marker={version!r}')
    b.close()
failures += ['pageerror: '+e for e in errors]
status='PASS' if not failures else 'FAIL'
report={'id':'ALL-FLOWS-RUNTIME-SMOKE-v4.4.0','status':status,'renders':total,'browser_errors':len(errors),'failures':failures}
(OUT/'ALL-FLOWS-RUNTIME-SMOKE-v4.4.0.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'ALL-FLOWS-RUNTIME-SMOKE-v4.4.0.md').write_text(f'# All-flow Runtime Smoke v4.4.0\n\n**Result: {status} · {total} renders · browser errors {len(errors)}**\n\n## Failures\n\n'+ ('- None.\n' if not failures else '\n'.join('- '+x for x in failures)+'\n'),encoding='utf-8')
print(status,total,'renders','errors',len(errors))
if failures:
    print('\n'.join(failures[:100])); raise SystemExit(1)
