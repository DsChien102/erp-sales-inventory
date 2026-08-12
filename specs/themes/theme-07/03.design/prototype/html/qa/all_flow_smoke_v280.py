from pathlib import Path
from playwright.sync_api import sync_playwright
import json

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
        idx=idx.replace(line+'\n','').replace(line,'')
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css','v272-detail-composition-fidelity.css','v273-ui-hardening.css','v274-figma-ds-hard-gate.css','v275-cross-bj-ds-fidelity.css','v276-bj05-compact-detail.css','v280-bj05-sheet-bj06-figma-ds.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
data=(ROOT/'workbench-data.js').read_text()
fmap=(ROOT/'figma-ds-runtime-map.js').read_text()
app=(ROOT/'app.js').read_text()
html=idx
for x in cssfiles:
    html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
          .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>')
          .replace('<script src="app.js"></script>',f'<script>{app}</script>'))

errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100})
    p.set_default_timeout(5000)
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)
    result=p.evaluate('''()=>{const out=[];for(const f of flowCatalog){for(const sid of f.screens){activeFlowId=f.id;activeScreenId=sid;const states=(screens.find(x=>x.id===sid)?.states)||['READY'];let st=states.includes('READY')?'READY':states.find(x=>!['LOADING','PROCESSING'].includes(x))||states[0];stateByScreen[sid]=st;if(f.id==='UIF-03'&&sid==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}if(f.id==='UIF-13'&&sid==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}if(f.id==='UIF-14'&&sid==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}if(f.id==='UIF-08'&&sid==='SCR-044')stateByScreen[sid]='BLIND_COUNT';if(f.id==='UIF-08'&&sid==='SCR-045')stateByScreen[sid]='RECOUNT_REQUIRED';if(f.id==='UIF-08'&&sid==='SCR-046')stateByScreen[sid]='APPROVAL_REQUIRED';render();const root=document.querySelector('#app-screen');out.push({f:f.id,s:sid,state:stateByScreen[sid],text:(root?.innerText||'').trim().length,template:root?.querySelector('.v-page-scaffold')?.dataset.figmaTemplate||'',overflow:(root?.querySelector('.v-page-scaffold')?.scrollWidth||0)-(root?.querySelector('.v-page-scaffold')?.clientWidth||0)});}}return out;}''')
    b.close()

fail=[x for x in result if not x['text'] or not x['template'] or x['overflow']>.5]
status='PASS' if len(result)==85 and not fail and not errors else 'FAIL'
report=['# All-flow Runtime Smoke v2.8.0','',f'**Result: {status} · {len(result)} active flow/screen renders**','',f'- Empty/template/overflow failures: **{len(fail)}**',f'- Browser errors: **{len(errors)}**']
if fail:
    report+=['','## Failures','']+[f"- {x['f']}/{x['s']} state={x['state']} text={x['text']} template={x['template']} overflow={x['overflow']}" for x in fail]
(OUT/'ALL-FLOWS-RUNTIME-SMOKE-v2.8.0.md').write_text('\n'.join(report)+'\n')
(OUT/'ALL-FLOWS-RUNTIME-SMOKE-v2.8.0.json').write_text(json.dumps({'status':status,'renders':len(result),'failures':fail,'errors':errors},ensure_ascii=False,indent=2)+'\n')
print(status,len(result),'renders','fail',len(fail),'errors',len(errors))
if status!='PASS':
    raise SystemExit(1)
