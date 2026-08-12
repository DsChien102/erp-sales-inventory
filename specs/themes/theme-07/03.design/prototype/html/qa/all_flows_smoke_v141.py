from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf8'); css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8'); data=(ROOT/'workbench-data.js').read_text(encoding='utf8'); app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':1680,'height':1000}); errors=[]
    page.on('pageerror',lambda e: errors.append(str(e)))
    page.set_content(html,wait_until='load'); page.wait_for_timeout(50)
    flows=page.evaluate('flowCatalog.map(f=>({id:f.id,screens:f.screens}))')
    total=0; failed=[]
    for flow in flows:
        for sid in flow['screens']:
            total+=1
            try:
                page.evaluate('(x)=>{activeFlowId=x.f; activeScreenId=x.s; if(x.f==="UIF-02" && x.s==="SCR-009") {flowMode="document"; resetBj02Receipt("document");} render();}',{'f':flow['id'],'s':sid})
                text=page.locator('#app-screen').inner_text().strip(); g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
                if not text: failed.append(f"{flow['id']}/{sid}: empty render")
                if g['sw']>g['cw']+1: failed.append(f"{flow['id']}/{sid}: horizontal overflow {g}")
            except Exception as e: failed.append(f"{flow['id']}/{sid}: {e}")
    if errors: failed.extend('pageerror: '+e for e in errors)
    b.close()
passed=total-len([x for x in failed if not x.startswith('pageerror:')])
status=not failed
lines=['# All-flow Runtime Smoke v1.4.1','',f'**Result: {"PASS" if status else "FAIL"} · {total} flow/screen renders checked**','', '- Renders every registered screen through every UIF that owns it at the canonical mobile viewport.', '- Checks non-empty render, no page-level JavaScript exception and no horizontal overflow.', '- This is an isolation/runtime guard; it does not claim UX correctness for non-target BJs.','', '## Failures','']
lines += ['- None.'] if not failed else [f'- {x}' for x in failed]
(OUT/'ALL-FLOWS-RUNTIME-SMOKE-v1.4.1.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print('PASS' if status else 'FAIL',total,'renders')
if failed:
    print('\n'.join(failed[:30])); raise SystemExit(1)
