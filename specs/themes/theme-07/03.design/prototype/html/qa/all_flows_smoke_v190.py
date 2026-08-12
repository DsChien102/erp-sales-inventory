from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text(); html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':1680,'height':1000}); errors=[]; p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load'); flows=p.evaluate('flowCatalog.map(f=>({id:f.id,screens:f.screens}))'); fail=[]; total=0
 for f in flows:
  for s in f['screens']:
   total+=1
   try:
    p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;if(x.u==="UIF-03"&&x.s==="SCR-017"){val03SelectedReceiptId="VAL03-R1";val03ReviewSourceVersion=val03Current().sourceVersion;}if(x.u==="UIF-13"&&x.s==="SCR-088"){val13SelectedTaskId="LC13-001";if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}if(x.u==="UIF-14"&&x.s==="SCR-076"){val14SelectedRunId="COST-0826";val14PublishReviewVersion=val14Current().inputVersion;}if(x.u==="UIF-08"&&x.s==="SCR-044")stateByScreen[x.s]="BLIND_COUNT";if(x.u==="UIF-08"&&x.s==="SCR-045")stateByScreen[x.s]="RECOUNT_REQUIRED";if(x.u==="UIF-08"&&x.s==="SCR-046")stateByScreen[x.s]="APPROVAL_REQUIRED";if((x.u==="UIF-08"&&x.s==="SCR-047")||((x.u==="UIF-09"||x.u==="UIF-10")&&x.s==="SCR-041"))stateByScreen[x.s]="COMPLETED";if(x.u==="UIF-12"&&x.s==="SCR-071")stateByScreen[x.s]="COMPLETED";if(x.u==="UIF-15"){cf15ReportType="INVENTORY";cf15Product="ALL";if(x.s==="SCR-059")stateByScreen[x.s]="COMPLETED";}render();}',{'u':f['id'],'s':s})
    text=p.locator('#app-screen').inner_text().strip();
    if not text: fail.append(f"{f['id']}/{s}: empty")
    if 'undefined' in text.lower(): fail.append(f"{f['id']}/{s}: undefined leak")
   except Exception as e: fail.append(f"{f['id']}/{s}: {e}")
 fail += ['pageerror: '+e for e in errors]; b.close()
lines=['# All-flow Runtime Smoke v1.9.0','',f'**Result: {"PASS" if not fail else "FAIL"} · {total} active flow/screen renders**','','## Failures','']+(['- None.'] if not fail else [f'- {x}' for x in fail]); (OUT/'ALL-FLOWS-RUNTIME-SMOKE-v1.9.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8'); print(('PASS' if not fail else 'FAIL'),total,'renders')
if fail: print('\n'.join(fail[:80])); raise SystemExit(1)
