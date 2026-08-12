from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf8'); css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8'); data=(ROOT/'workbench-data.js').read_text(encoding='utf8'); app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':1680,'height':1000}); errors=[]; page.on('pageerror',lambda e:errors.append(str(e))); page.set_content(html,wait_until='load'); page.wait_for_timeout(50)
    flows=page.evaluate('flowCatalog.map(f=>({id:f.id,screens:f.screens}))'); total=0; failures=[]
    for flow in flows:
        for sid in flow['screens']:
            total+=1
            try:
                page.evaluate('(x)=>{activeFlowId=x.f;activeScreenId=x.s;if(x.f==="UIF-02"&&x.s==="SCR-009"){flowMode="document";resetBj02Receipt("document");}render();}',{'f':flow['id'],'s':sid})
                txt=page.locator('#app-screen').inner_text().strip(); g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
                if not txt: failures.append(f"{flow['id']}/{sid}: empty render")
                if g['sw']>g['cw']+1: failures.append(f"{flow['id']}/{sid}: horizontal overflow {g}")
            except Exception as e: failures.append(f"{flow['id']}/{sid}: {e}")
    failures.extend('pageerror: '+e for e in errors); b.close()
status=not failures
lines=['# All-flow Runtime Smoke v1.4.2','',f'**Result: {"PASS" if status else "FAIL"} · {total} flow/screen renders checked**','', '- Renders every registered screen through every UIF that owns it.', '- Checks non-empty render, no page-level JavaScript exception and no horizontal overflow.', '- This is a runtime/isolation guard; semantic correctness is covered separately.','', '## Failures','']
lines += ['- None.'] if not failures else [f'- {x}' for x in failures]
(OUT/'ALL-FLOWS-RUNTIME-SMOKE-v1.4.2.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print('PASS' if status else 'FAIL',total,'renders')
if failures:
    print('\n'.join(failures[:40])); raise SystemExit(1)
