from pathlib import Path
from playwright.sync_api import sync_playwright

CHILD=Path(__file__).resolve().parents[1]
PARENT=Path('/mnt/data/v143_parent/VET45-Theme7-Prototype-Harness-v1.4.2/specs/themes/theme-07/prototype/html')
OUT=Path(__file__).resolve().parent

PROTECTED=['UIF-08','UIF-09','UIF-10','UIF-11','UIF-12','UIF-13','UIF-14','UIF-15','UIF-16','UIF-17']

def bundle(root):
    idx=(root/'index.html').read_text(encoding='utf8')
    css=(root/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(root/'styles.css').read_text(encoding='utf8')
    data=(root/'workbench-data.js').read_text(encoding='utf8')
    app=(root/'app.js').read_text(encoding='utf8')
    return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')

parent_html=bundle(PARENT); child_html=bundle(CHILD)
checks=[]; diffs=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def catalog(page,html,flow):
    page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(20)
    return page.evaluate('(f)=>flowCatalog.find(x=>x.id===f)?.screens||[]',flow)
def render_text(page,html,flow,sid):
    page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(20)
    page.evaluate('(x)=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]="READY";render();}',{'f':flow,'s':sid}); page.wait_for_timeout(12)
    txt=page.locator('#app-screen').inner_text().strip()
    g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
    return txt,g

with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=b.new_page(viewport={'width':1400,'height':1000}); page.on('pageerror',lambda e:errors.append(str(e)))
    for flow in PROTECTED:
        pc=catalog(page,parent_html,flow); cc=catalog(page,child_html,flow)
        ck(f'{flow} screen topology identical',pc==cc)
        for sid in pc:
            pt,pg=render_text(page,parent_html,flow,sid); ct,cg=render_text(page,child_html,flow,sid)
            same=pt==ct
            ck(f'{flow}/{sid} READY rendered text identical',same)
            ck(f'{flow}/{sid} child horizontal safety',cg['sw']<=cg['cw']+1)
            if not same: diffs.append((flow,sid,pt,ct))
    ck('No page JavaScript errors during protected regression',not errors)
    b.close()

passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Protected Non-target Flow Regression v1.4.3','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',
       '- Parent: cumulative v1.4.2.',
       '- Protected runtime flows: UIF08/UIF09/UIF10/UIF11/UIF12/UIF13/UIF14/UIF15/UIF16/UIF17.',
       '- Checks exact screen topology, exact READY-state rendered text and child horizontal safety.',
       '- Purpose: prove entry/journey corrections in Inventory Operations + BJ03 do not leak into valuation/audit/control flows outside scope.','',
       '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if diffs:
    lines += ['','## Differences']+[f'- {flow}/{sid}: parent/child READY text differs' for flow,sid,_,_ in diffs]
if errors:
    lines += ['','## Page errors']+[f'- {x}' for x in errors]
(OUT/'REGRESSION-PROTECTED-FLOWS-v1.4.3.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'diffs',len(diffs))
if failed:
    print('\n'.join(failed[:80])); raise SystemExit(1)
