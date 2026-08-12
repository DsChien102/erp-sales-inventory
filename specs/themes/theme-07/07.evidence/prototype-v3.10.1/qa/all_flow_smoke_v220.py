from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); fmap=(ROOT/'figma-ds-runtime-map.js').read_text(); app=(ROOT/'app.js').read_text()
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
errors=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load')
 result=p.evaluate('''()=>{const out=[];for(const f of flowCatalog){for(const sid of f.screens){activeFlowId=f.id;activeScreenId=sid;const states=(screens.find(x=>x.id===sid)?.states)||['READY'];let st=states.includes('READY')?'READY':states.find(x=>!['LOADING','PROCESSING'].includes(x))||states[0];stateByScreen[sid]=st;if(f.id==='UIF-03'&&sid==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}if(f.id==='UIF-13'&&sid==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}if(f.id==='UIF-14'&&sid==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}if(f.id==='UIF-08'&&sid==='SCR-044')stateByScreen[sid]='BLIND_COUNT';if(f.id==='UIF-08'&&sid==='SCR-045')stateByScreen[sid]='RECOUNT_REQUIRED';if(f.id==='UIF-08'&&sid==='SCR-046')stateByScreen[sid]='APPROVAL_REQUIRED';render();const root=document.querySelector('#app-screen');out.push({f:f.id,s:sid,state:stateByScreen[sid],text:(root?.innerText||'').trim().length,template:root?.querySelector('.v-page-scaffold')?.dataset.figmaTemplate||''});}}return out;}''')
 b.close()
fail=[x for x in result if not x['text'] or not x['template']]
status='PASS' if len(result)==85 and not fail and not errors else 'FAIL'
report=['# All-flow Runtime Smoke v2.2.0','',f'**Result: {status} · {len(result)} active flow/screen renders**','',f'- Empty/template failures: **{len(fail)}**',f'- Browser errors: **{len(errors)}**']
if fail: report+=['','## Failures','']+[f"- {x['f']}/{x['s']} state={x['state']} text={x['text']} template={x['template']}" for x in fail]
(OUT/'ALL-FLOWS-RUNTIME-SMOKE-v2.2.0.md').write_text('\n'.join(report)+'\n')
print(status,len(result),'renders','fail',len(fail),'errors',len(errors))
if status!='PASS': raise SystemExit(1)
