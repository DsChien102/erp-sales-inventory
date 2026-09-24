from pathlib import Path
from playwright.sync_api import sync_playwright
CHILD=Path(__file__).resolve().parents[1]
PARENT=Path('/mnt/data/v144_work/VET45-Theme7-Prototype-Harness-v1.4.3/specs/themes/theme-07/prototype/html')
OUT=Path(__file__).resolve().parent
PROTECTED=['UIF-01','UIF-02','UIF-04','UIF-05','UIF-06','UIF-07','UIF-08','UIF-09','UIF-10','UIF-11','UIF-12','UIF-13','UIF-14','UIF-15','UIF-16','UIF-17']
def bundle(root):
    idx=(root/'index.html').read_text(encoding='utf8'); css=(root/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(root/'styles.css').read_text(encoding='utf8'); data=(root/'workbench-data.js').read_text(encoding='utf8'); app=(root/'app.js').read_text(encoding='utf8')
    return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
ph=bundle(PARENT); ch=bundle(CHILD); checks=[]; diffs=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def screens(page,html,f): page.goto('about:blank'); page.set_content(html,wait_until='load'); return page.evaluate('(f)=>flowCatalog.find(x=>x.id===f)?.screens||[]',f)
def text(page,html,f,s):
    page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(15); page.evaluate('(x)=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]="READY";render();}',{'f':f,'s':s}); page.wait_for_timeout(10); t=page.locator('#app-screen').inner_text().strip(); g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); return t,g
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':1400,'height':1000}); page.on('pageerror',lambda e:errors.append(str(e)))
    for f in PROTECTED:
        ps=screens(page,ph,f); cs=screens(page,ch,f); ck(f'{f} topology identical',ps==cs)
        for sid in ps:
            pt,_=text(page,ph,f,sid); ct,cg=text(page,ch,f,sid); same=pt==ct; ck(f'{f}/{sid} READY text identical',same); ck(f'{f}/{sid} horizontal safe',cg['sw']<=cg['cw']+1)
            if not same: diffs.append((f,sid,pt,ct))
    ck('No page JS errors',not errors); b.close()
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Protected Flow Regression v1.4.4','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', '- Parent: v1.4.3.', '- Protected: every UIF except target UIF03, including shared-screen UIF13.', '- Exact READY rendered text + topology + horizontal safety.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if diffs: lines+=['','## Differences']+[f'- {f}/{s}' for f,s,_,_ in diffs]
(OUT/'REGRESSION-PROTECTED-FLOWS-v1.4.4.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'diffs',len(diffs))
if diffs:
    for f,s,pt,ct in diffs[:10]: print('\nDIFF',f,s,'\nPARENT:',pt[:500],'\nCHILD:',ct[:500])
if failed: raise SystemExit(1)
