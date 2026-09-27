from pathlib import Path
from playwright.sync_api import sync_playwright

CHILD=Path(__file__).resolve().parents[1]
PARENT=Path('/mnt/data/v142_work/VET45-Theme7-Prototype-Harness-v1.4.1/specs/themes/theme-07/prototype/html')
OUT=Path(__file__).resolve().parent

def bundle(root):
    idx=(root/'index.html').read_text(encoding='utf8')
    css=(root/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(root/'styles.css').read_text(encoding='utf8')
    data=(root/'workbench-data.js').read_text(encoding='utf8')
    app=(root/'app.js').read_text(encoding='utf8')
    return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')

parent_html=bundle(PARENT); child_html=bundle(CHILD)
flows=['UIF-01','UIF-04','UIF-13']
checks=[]; diffs=[]
def ck(n,c): checks.append((n,bool(c)))

def catalog(page,html,flow):
    page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(20)
    return page.evaluate('(f)=>flowCatalog.find(x=>x.id===f)?.screens||[]',flow)

def render_text(page,html,flow,sid):
    page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(20)
    page.evaluate('(x)=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]="READY";render();}',{'f':flow,'s':sid}); page.wait_for_timeout(10)
    return page.locator('#app-screen').inner_text().strip()

with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=b.new_page(viewport={'width':1400,'height':1000}); errors=[]; page.on('pageerror',lambda e:errors.append(str(e)))
    for flow in flows:
        pc=catalog(page,parent_html,flow); cc=catalog(page,child_html,flow)
        ck(f'{flow} screen topology identical',pc==cc)
        for sid in pc:
            pt=render_text(page,parent_html,flow,sid); ct=render_text(page,child_html,flow,sid)
            same=pt==ct; ck(f'{flow}/{sid} rendered text identical',same)
            if not same: diffs.append((flow,sid,pt,ct))
    ck('No page JavaScript errors during protected regression',not errors)
    b.close()

passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Protected Flow Regression v1.4.2','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',
       '- Parent: cumulative v1.4.1.',
       '- Protected runtime surfaces: UIF01/BJ01, UIF04/BJ04, UIF13/BJ13.',
       '- Checks exact screen topology and exact READY-state rendered text per screen.',
       '- Purpose: prove semantic corrections did not leak into flows intentionally left unchanged.','',
       '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if diffs:
    lines += ['','## Differences']
    for flow,sid,pt,ct in diffs:
        lines.append(f'- {flow}/{sid}: parent/child text differs')
(OUT/'REGRESSION-PROTECTED-FLOWS-v1.4.2.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
