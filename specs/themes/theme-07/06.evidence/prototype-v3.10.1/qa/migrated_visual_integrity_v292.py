from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8'); styles=[]
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line: idx=idx.replace(line+'\n','').replace(line,'')
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
 p=ROOT/fn
 if p.exists(): styles.append(p.read_text(encoding='utf-8')); idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']: html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf-8")}</script>')
flows=['UIF-01','UIF-02','UIF-04','UIF-05','UIF-06','UIF-07','UIF-08']; errors=[]; rows=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);p=b.new_page(viewport={'width':1600,'height':900});p.on('pageerror',lambda e:errors.append(str(e)));p.set_content(html,wait_until='load',timeout=30000)
 for fid in flows:
  ids=p.evaluate('fid=>flowCatalog.find(f=>f.id===fid).screens',fid)
  for sid in ids:
   # Minimal deterministic state normalization; no business mutation other than choosing existing fixture context.
   setup=""
   if fid=='UIF-01': setup="if(typeof bj01SelectedProductId!=='undefined')bj01SelectedProductId='P-001';"
   elif fid=='UIF-05': setup="if(typeof io05SelectedOrderId!=='undefined')io05SelectedOrderId='SO-260827-21';if(typeof io05ActiveLineId!=='undefined')io05ActiveLineId='PK-21-01';if(typeof io05ActiveAllocationId!=='undefined')io05ActiveAllocationId='AL-21-01';io05PickEditorOpen=false;io05OverrideOpen=false;"
   elif fid=='UIF-06': setup="io06SelectedRequestId=(['SCR-031','SCR-032'].includes('"+sid+"'))?'RET-260827-03':'RET-260827-05';io06ClassificationOpen=false;if('"+sid+"'==='SCR-032')io06ActiveLineId='RET-L1A';"
   elif fid=='UIF-07': setup="io07Selected='RTV-260827-02';io07VerifySheetOpen=false;"
   state='READY'
   if fid=='UIF-08' and sid=='SCR-044': state='BLIND_COUNT'
   if fid=='UIF-08' and sid=='SCR-045': state='RECOUNT_REQUIRED'
   if fid=='UIF-08' and sid=='SCR-046': state='APPROVAL_REQUIRED'
   if fid=='UIF-06' and sid=='SCR-034': state='TASK_LIST'
   p.evaluate("([fid,sid,state,setup])=>{activeFlowId=fid;eval(setup);activeScreenId=sid;stateByScreen[sid]=state;render();}",[fid,sid,state,setup]);p.wait_for_timeout(6)
   m=p.evaluate('''()=>{const root=document.querySelector('#app-screen'),content=root?.querySelector('.app-content');
     const visible=e=>{const s=getComputedStyle(e),r=e.getBoundingClientRect();return s.display!=='none'&&s.visibility!=='hidden'&&r.width>0&&r.height>0};
     const inXScroller=e=>{let a=e.parentElement;while(a&&a!==root){const s=getComputedStyle(a);if((s.overflowX==='auto'||s.overflowX==='scroll')&&a.scrollWidth>a.clientWidth+1)return true;a=a.parentElement;}return false};
     const clips=[...root.querySelectorAll('p,span,strong,small,h1,h2,h3,h4,label,button')].filter(visible).filter(e=>!inXScroller(e)).map(e=>{const s=getComputedStyle(e);return {t:(e.textContent||'').trim().slice(0,80),sw:e.scrollWidth,cw:e.clientWidth,sh:e.scrollHeight,ch:e.clientHeight,ov:s.overflow,to:s.textOverflow,ws:s.whiteSpace};}).filter(x=>(x.sw>x.cw+1||x.sh>x.ch+1)&&(x.ov==='hidden'||x.ov==='clip')&&x.to!=='ellipsis');
     const serif=[...root.querySelectorAll('p,span,strong,small,h1,h2,h3,h4,label,button,input,textarea')].filter(visible).map(e=>({t:(e.textContent||e.value||'').trim().slice(0,50),f:getComputedStyle(e).fontFamily})).filter(x=>/Times|serif/i.test(x.f)&&!/sans-serif/i.test(x.f));
     const rr=root.getBoundingClientRect();const out=[...root.querySelectorAll('*')].filter(visible).map(e=>{const r=e.getBoundingClientRect();return {n:e.className?.toString().slice(0,80)||e.tagName,l:r.left-rr.left,r:r.right-rr.left,t:r.top-rr.top,b:r.bottom-rr.top};}).filter(x=>x.l<-1||x.r>403);
     return {app:[root.offsetWidth,root.offsetHeight],x:content?content.scrollWidth-content.clientWidth:0,clips,serif,out:out.slice(0,10)};}''')
   rows.append({'flow':fid,'screen':sid,'state':state,**m})
 b.close()
checks=[
 {'name':'All migrated canonical screens rendered','pass':len(rows)==33,'note':len(rows)},
 {'name':'All migrated screens remain exact 402x874','pass':all(x['app']==[402,874] for x in rows),'note':[x for x in rows if x['app']!=[402,874]]},
 {'name':'No migrated screen has root content horizontal overflow','pass':all(x['x']<=1 for x in rows),'note':[x for x in rows if x['x']>1]},
 {'name':'No unintended clipped text outside ellipsis/scrollers','pass':all(not x['clips'] for x in rows),'note':[{'flow':x['flow'],'screen':x['screen'],'clips':x['clips']} for x in rows if x['clips']]},
 {'name':'No serif fallback leaks into Product UI','pass':all(not x['serif'] for x in rows),'note':[{'flow':x['flow'],'screen':x['screen'],'serif':x['serif']} for x in rows if x['serif']]},
 {'name':'No Product child extends outside 402px canvas','pass':all(not x['out'] for x in rows),'note':[{'flow':x['flow'],'screen':x['screen'],'out':x['out']} for x in rows if x['out']]},
 {'name':'No browser errors','pass':not errors,'note':errors[:10]},
]
status='PASS' if all(c['pass'] for c in checks) else 'FAIL';res={'status':status,'passed':sum(c['pass'] for c in checks),'total':len(checks),'screens':rows,'checks':checks,'browserErrors':errors}
(OUT/'MIGRATED-VISUAL-INTEGRITY-QA-v2.9.2.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'MIGRATED-VISUAL-INTEGRITY-QA-v2.9.2.md').write_text('\n'.join(['# Migrated Product Visual Integrity QA — v2.9.2','',f'**Result: {status} · {sum(c["pass"] for c in checks)}/{len(checks)} · {len(rows)} screens**','']+[f'- {"PASS" if c["pass"] else "FAIL"} — {c["name"]}: {c["note"]}' for c in checks])+'\n',encoding='utf-8')
print(status,sum(c['pass'] for c in checks),len(checks),'screens',len(rows))
for c in checks:
 if not c['pass']:print('FAIL',c['name'],c['note'])
raise SystemExit(0 if status=='PASS' else 1)
