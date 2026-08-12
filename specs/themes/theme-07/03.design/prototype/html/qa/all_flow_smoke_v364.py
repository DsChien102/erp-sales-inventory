from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8')
# Inline exactly the stylesheets declared by the current Product harness.
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists():
        styles.append(p.read_text(encoding='utf-8'))
        idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>', html):
    p=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>', f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')

errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100})
    p.set_default_timeout(5000)
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)
    result=p.evaluate('''()=>{const out=[];for(const f of flowCatalog){for(const sid of f.screens){activeFlowId=f.id;activeScreenId=sid;const states=(screens.find(x=>x.id===sid)?.states)||['READY'];let st=states.includes('READY')?'READY':states.find(x=>!['LOADING','PROCESSING'].includes(x))||states[0];stateByScreen[sid]=st;if(f.id==='UIF-03'&&sid==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}if(f.id==='UIF-13'&&sid==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}if(f.id==='UIF-14'&&sid==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}if(f.id==='UIF-08'&&sid==='SCR-044')stateByScreen[sid]='BLIND_COUNT';if(f.id==='UIF-08'&&sid==='SCR-045')stateByScreen[sid]='RECOUNT_REQUIRED';if(f.id==='UIF-08'&&sid==='SCR-046')stateByScreen[sid]='APPROVAL_REQUIRED';render();const root=document.querySelector('#app-screen'),scaffold=root?.querySelector('.v-page-scaffold'),content=root?.querySelector('.app-content'),stack=root?.querySelector('.body-stack');out.push({f:f.id,s:sid,state:stateByScreen[sid],text:(root?.innerText||'').trim().length,template:scaffold?.dataset.figmaTemplate||'',app:[root?.offsetWidth||0,root?.offsetHeight||0],x:content?(content.scrollWidth-content.clientWidth):0,bx:stack?(stack.scrollWidth-stack.clientWidth):0});}}return out;}''')
    b.close()

fail=[x for x in result if not x['text'] or not x['template'] or x['app']!=[402,874] or x['x']>.5]
status='PASS' if len(result)==89 and not fail and not errors else 'FAIL'
report=['# All-flow Runtime Smoke v3.6.4','',f'**Result: {status} · {len(result)} active flow/screen renders**','',f'- Empty/template/geometry/Product-overflow failures: **{len(fail)}**',f'- Browser errors: **{len(errors)}**']
if fail:
    report+=['','## Failures','']+[f"- {x['f']}/{x['s']} state={x['state']} text={x['text']} template={x['template']} app={x['app']} x={x['x']} bx={x['bx']}" for x in fail]
(OUT/'ALL-FLOWS-RUNTIME-SMOKE-v3.6.4.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
(OUT/'ALL-FLOWS-RUNTIME-SMOKE-v3.6.4.json').write_text(json.dumps({'status':status,'renders':len(result),'failures':fail,'errors':errors},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(status,len(result),'renders','fail',len(fail),'errors',len(errors))
if status!='PASS': raise SystemExit(1)
