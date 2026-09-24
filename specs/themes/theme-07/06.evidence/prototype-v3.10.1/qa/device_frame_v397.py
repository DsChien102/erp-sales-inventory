from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
CAP=OUT/'v395-device-captures'; CAP.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text()
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists():
        styles.append(p.read_text())
        idx=idx.replace(f'<link rel="stylesheet" href="{fn}" />','')
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>', html):
    p=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>', f'<script>{p.read_text()}</script>' if p.exists() else '')
checks=[]; errors=[]; screen_results=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1600,'height':900})
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)
    # Canonical shared shell metrics after v2.9.3 correction.
    p.evaluate("()=>{activeFlowId='UIF-06';activeScreenId='SCR-030';stateByScreen['SCR-030']='READY';render();fitReviewDeviceToViewport();}")
    metrics=p.evaluate('''()=>{const d=document.querySelector('#device-preview'),a=document.querySelector('#app-screen');const ds=getComputedStyle(d),dr=d.getBoundingClientRect(),ar=a.getBoundingClientRect();const scale=parseFloat(ds.getPropertyValue('--vet45-review-scale'))||1;return {deviceOffset:[d.offsetWidth,d.offsetHeight],deviceClient:[d.clientWidth,d.clientHeight],appOffset:[a.offsetWidth,a.offsetHeight],border:[parseFloat(ds.borderLeftWidth),parseFloat(ds.borderRightWidth),parseFloat(ds.borderTopWidth),parseFloat(ds.borderBottomWidth)],scale,alignment:{left:Math.abs(ar.left-(dr.left+parseFloat(ds.borderLeftWidth)*scale)),right:Math.abs(ar.right-(dr.right-parseFloat(ds.borderRightWidth)*scale)),top:Math.abs(ar.top-(dr.top+parseFloat(ds.borderTopWidth)*scale)),bottom:Math.abs(ar.bottom-(dr.bottom-parseFloat(ds.borderBottomWidth)*scale))}}}''')
    chk('Decorative phone border-box is 418x890',metrics['deviceOffset']==[418,890],metrics)
    chk('Decorative phone content-box is exact Product 402x874',metrics['deviceClient']==[402,874],metrics)
    chk('Product app remains exact 402x874',metrics['appOffset']==[402,874],metrics)
    chk('Product app aligns inside bezel on all four edges',all(v<=0.6 for v in metrics['alignment'].values()),metrics['alignment'])
    # Every active flow/screen must preserve the shared shell; additionally check every direct 370px content child has symmetric 16px edges.
    results=p.evaluate('''()=>{const out=[];for(const f of flowCatalog){for(const sid of f.screens){activeFlowId=f.id;activeScreenId=sid;const states=(screens.find(x=>x.id===sid)?.states)||['READY'];let st=states.includes('READY')?'READY':states.find(x=>!['LOADING','PROCESSING'].includes(x))||states[0];stateByScreen[sid]=st;if(f.id==='UIF-03'&&sid==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}if(f.id==='UIF-13'&&sid==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}if(f.id==='UIF-14'&&sid==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}if(f.id==='UIF-08'&&sid==='SCR-044')stateByScreen[sid]='BLIND_COUNT';if(f.id==='UIF-08'&&sid==='SCR-045')stateByScreen[sid]='RECOUNT_REQUIRED';if(f.id==='UIF-08'&&sid==='SCR-046')stateByScreen[sid]='APPROVAL_REQUIRED';render();const d=document.querySelector('#device-preview'),a=document.querySelector('#app-screen'),c=a?.querySelector('.app-content'),b=a?.querySelector('.body-stack');const ds=getComputedStyle(d),dr=d.getBoundingClientRect(),ar=a.getBoundingClientRect(),scale=parseFloat(ds.getPropertyValue('--vet45-review-scale'))||1;const direct370=b?[...b.children].filter(e=>!e.hidden&&Math.abs(e.offsetWidth-370)<.5):[];const edgeFailures=direct370.map(e=>{const r=e.getBoundingClientRect();return {left:(r.left-ar.left)/scale,right:(ar.right-r.right)/scale,cls:e.className}}).filter(x=>Math.abs(x.left-16)>.6||Math.abs(x.right-16)>.6);out.push({flow:f.id,screen:sid,state:stateByScreen[sid],deviceClient:[d.clientWidth,d.clientHeight],app:[a.offsetWidth,a.offsetHeight],content:c?[c.clientWidth,c.scrollWidth]:null,alignment:{left:Math.abs(ar.left-(dr.left+parseFloat(ds.borderLeftWidth)*scale)),right:Math.abs(ar.right-(dr.right-parseFloat(ds.borderRightWidth)*scale)),bottom:Math.abs(ar.bottom-(dr.bottom-parseFloat(ds.borderBottomWidth)*scale))},edgeFailures});}}return out;}''')
    screen_results=results
    bad=[r for r in results if r['deviceClient']!=[402,874] or r['app']!=[402,874] or (r['content'] and r['content'][1]>r['content'][0]+1) or any(v>.6 for v in r['alignment'].values()) or r['edgeFailures']]
    chk('All 89 canonical route occurrences preserve exact unclipped Product shell',len(results)==89 and not bad, bad[:10])
    # Explicitly assert the screen that exposed the regression.
    p.evaluate("()=>{activeFlowId='UIF-06';activeScreenId='SCR-030';stateByScreen['SCR-030']='READY';render();}")
    edge=p.evaluate('''()=>{const a=document.querySelector('#app-screen').getBoundingClientRect(),r=document.querySelector('.io06-queue .ds24-list-row').getBoundingClientRect(),d=document.querySelector('#device-preview'),scale=parseFloat(getComputedStyle(d).getPropertyValue('--vet45-review-scale'))||1;return {left:(r.left-a.left)/scale,right:(a.right-r.right)/scale}}''')
    chk('SCR-030 List Row has symmetric 16px Product edge',abs(edge['left']-16)<=.6 and abs(edge['right']-16)<=.6,edge)
    p.locator('#device-preview').screenshot(path=str(CAP/'SCR030-CORRECTED.png'))
    chk('No browser errors',not errors,errors[:8])
    b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'screensChecked':len(screen_results),'browserErrors':errors}
(OUT/'DEVICE-FRAME-QA-v3.9.7.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
(OUT/'DEVICE-FRAME-QA-v3.9.7.md').write_text('\n'.join(['# Device Frame QA — v3.9.7','',f'**Result: {status} · {res["passed"]}/{res["total"]} · {len(screen_results)} screens checked**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}: {x["note"]}' for x in checks])+'\n')
print(status,res['passed'],res['total'],'screens',len(screen_results),'errors',len(errors))
raise SystemExit(0 if status=='PASS' else 1)
