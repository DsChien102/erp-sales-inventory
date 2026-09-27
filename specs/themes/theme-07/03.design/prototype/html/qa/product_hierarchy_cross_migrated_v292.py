from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8');styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
 p=ROOT/fn
 if p.exists(): styles.append(p.read_text(encoding='utf-8')); idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']: html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf-8")}</script>')
checks=[];errors=[]
def ck(name,ok,note=''):checks.append({'name':name,'pass':bool(ok),'note':note})
app=(ROOT/'app.js').read_text(encoding='utf-8')
ck('No migrated raw Product text+badge header implementation remains',all(x not in app for x in ['io07-product-heading','bj05-handover-product__head','<div class="io06-result-product">']))
ck('No raw VSection + VText,VBadge product composition remains in active migrated helpers','data-composed-from="VText,VBadge' not in app[app.find('function io07QueueList'):app.find('// ============================================================================\n// v1.7.0')])
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);p=b.new_page(viewport={'width':1600,'height':900});p.set_default_timeout(5000);p.on('pageerror',lambda e:errors.append(str(e)));p.set_content(html,wait_until='load',timeout=30000)
 # BJ01: already canonical.
 p.evaluate("()=>{activeFlowId='UIF-01';bj01SelectedProductId='P-001';activeScreenId='SCR-003';stateByScreen['SCR-003']='READY';render();}")
 r=p.locator('[data-ds-role="inventory-product-summary"]');ck('BJ01 Product identity remains List Row Status/Compact',r.count()==1 and r.get_attribute('data-ds-prop-type')=='Status' and r.get_attribute('data-ds-prop-density')=='Compact')
 # BJ02: actual line editor canonical context.
 p.evaluate("()=>{activeFlowId='UIF-02';flowMode='document';resetBj02Receipt('document');beginLineEditor(bj02Lines[0].id);}");r=p.locator('[data-ds-role="receiving-line-product-summary"]');ck('BJ02 Product identity remains List Row Status/Compact',r.count()==1 and r.get_attribute('data-ds-prop-type')=='Status' and r.get_attribute('data-ds-prop-density')=='Compact')
 # BJ04: reservation rows remain standard status rows; no new custom header.
 p.evaluate("()=>{activeFlowId='UIF-04';activeScreenId='SCR-021';stateByScreen['SCR-021']='PARTIAL';render();}");ck('BJ04 uses canonical List Rows and has no raw product-heading artifact',p.locator('#app-screen [data-ds-component="DS v2 / List Row"]').count()>0 and p.locator('#app-screen .io07-product-heading,#app-screen .io06-result-product,#app-screen .bj05-handover-product__head').count()==0)
 # BJ05 final handover group.
 p.evaluate("()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';const o=io05CurrentOrder();o.lines.forEach(l=>l.allocations.forEach(a=>a.picked=Math.min(Number(a.qty||0),Math.max(1,Number(a.picked||0)))));activeScreenId='SCR-028';stateByScreen['SCR-028']='PARTIAL_ALLOWED';render();}")
 r=p.locator('[data-layout-role="bj05-handover-product-summary"]');groups=p.locator('.bj05-handover-product')
 ck('BJ05 handover Product identity is canonical Status/Compact row',r.count()>0 and r.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / List Row'&&e.dataset.dsPropType==='Status'&&e.dataset.dsPropDensity==='Compact'&&e.offsetWidth===338&&e.offsetHeight===52)"),r.evaluate_all("els=>els.map(e=>({c:e.dataset.dsComponent,t:e.dataset.dsPropType,d:e.dataset.dsPropDensity,w:e.offsetWidth,h:e.offsetHeight}))"))
 ck('BJ05 Product summaries live inside coherent bordered surfaces',groups.count()>0 and groups.evaluate_all("els=>els.every(e=>e.offsetWidth===370&&getComputedStyle(e).backgroundColor!=='rgba(0, 0, 0, 0)'&&getComputedStyle(e).borderTopStyle!=='none')"),groups.count())
 ck('BJ05 allocation identity uses Key-value Row rather than raw text header',p.locator('.bj05-handover-allocation > .ds24-key-value-row').count()>0 and p.locator('.bj05-handover-allocation__head').count()==0)
 # BJ06 result.
 p.evaluate("()=>{activeFlowId='UIF-06';io06SelectedRequestId='RET-260827-05';const r=io06CurrentRequest();r.classified=true;activeScreenId='SCR-035';stateByScreen['SCR-035']='COMPLETED';render();}")
 r=p.locator('[data-layout-role="io06-result-product-summary"]');groups=p.locator('.io06-result-group')
 ck('BJ06 result Product identity is canonical Status/Compact row',r.count()>0 and r.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / List Row'&&e.dataset.dsPropType==='Status'&&e.dataset.dsPropDensity==='Compact'&&e.offsetWidth===338&&e.offsetHeight===52)"),r.count())
 ck('BJ06 Product result groups use coherent 370px surfaces',groups.count()>0 and groups.evaluate_all("els=>els.every(e=>e.offsetWidth===370&&getComputedStyle(e).backgroundColor!=='rgba(0, 0, 0, 0)'&&getComputedStyle(e).borderTopStyle!=='none')"),groups.count())
 ck('BJ06 free-text result Product header is absent',p.locator('.io06-result-product').count()==0)
 ck('BJ06 child result facts are canonical 338px Info Rows',p.locator('.io06-result-rows .ds24-info-row').count()>0 and p.locator('.io06-result-rows .ds24-info-row').evaluate_all('els=>els.every(e=>e.offsetWidth===338)'))
 # BJ07 prep and result already validated deeper; assert shared pattern.
 p.evaluate("()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07VerifySheetOpen=false;render();}")
 r=p.locator('[data-layout-role="rtv-product-summary"]');ck('BJ07 preparation Product parent is Status/Compact inside group',r.count()==3 and r.evaluate_all("els=>els.every(e=>e.dataset.dsPropType==='Status'&&e.dataset.dsPropDensity==='Compact'&&e.closest('.io07-product-group'))"))
 # BJ08 representative: ensure current DS composition remains intact and no forbidden artifact.
 p.evaluate("()=>{activeFlowId='UIF-08';activeScreenId='SCR-042';stateByScreen['SCR-042']=screens.find(s=>s.id==='SCR-042')?.defaultState||'READY';render();}")
 ck('BJ08 representative remains free of retired Product-header artifacts',p.locator('#app-screen .io07-product-heading,#app-screen .io06-result-product,#app-screen .bj05-handover-product__head').count()==0)
 # Whole migrated scope: exact canvas and no forbidden retired DOM artifacts.
 migrated=['UIF-01','UIF-02','UIF-04','UIF-05','UIF-06','UIF-07','UIF-08']; results=[]
 for fid in migrated:
  ids=p.evaluate('fid=>flowCatalog.find(f=>f.id===fid).screens',fid)
  for sid in ids:
   p.evaluate("([fid,sid])=>{activeFlowId=fid;activeScreenId=sid;stateByScreen[sid]=screens.find(s=>s.id===sid)?.defaultState||'READY';if(fid==='UIF-07')io07VerifySheetOpen=false;if(fid==='UIF-06')io06ClassificationOpen=false;if(fid==='UIF-05'){io05PickEditorOpen=false;io05OverrideOpen=false;}render();}",[fid,sid]);p.wait_for_timeout(4)
   m=p.evaluate("()=>{const a=document.querySelector('#app-screen'),c=a?.querySelector('.app-content');return {w:a?.offsetWidth,h:a?.offsetHeight,x:c?c.scrollWidth-c.clientWidth:0,forbidden:document.querySelectorAll('#app-screen .io07-product-heading,#app-screen .io06-result-product,#app-screen .bj05-handover-product__head').length};}")
   results.append({'flow':fid,'screen':sid,**m})
 ck('All migrated default screens remain 402x874',all(x['w']==402 and x['h']==874 for x in results),[x for x in results if x['w']!=402 or x['h']!=874])
 ck('All migrated default screens have no horizontal app-content overflow',all(x['x']<=1 for x in results),[x for x in results if x['x']>1])
 ck('Retired free-floating Product header artifacts appear in zero migrated renders',all(x['forbidden']==0 for x in results),[x for x in results if x['forbidden']])
 ck('No browser errors',not errors,errors[:10])
 b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL';res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'migratedScreenRenders':len(results),'browserErrors':errors}
(OUT/'PRODUCT-HIERARCHY-CROSS-MIGRATED-QA-v2.9.2.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'PRODUCT-HIERARCHY-CROSS-MIGRATED-QA-v2.9.2.md').write_text('\n'.join(['# Product Hierarchy Cross-migrated QA — v2.9.2','',f'**Result: {status} · {res["passed"]}/{res["total"]} · {res["migratedScreenRenders"]} migrated default renders**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}: {x["note"]}' for x in checks])+'\n',encoding='utf-8')
print(status,res['passed'],res['total'],'renders',len(results),'errors',len(errors))
for x in checks:
 if not x['pass']:print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
