from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
css=(ROOT/'v294-product-lot-hierarchy.css').read_text(encoding='utf-8')
app=(ROOT/'app.js').read_text(encoding='utf-8')
idx=(ROOT/'index.html').read_text(encoding='utf-8')
source_idx=idx
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    fp=ROOT/fn
    if fp.exists():
        styles.append(fp.read_text(encoding='utf-8'))
        idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf-8")}</script>')
checks=[];errors=[]
def ck(name,ok,note=''):
    checks.append({'name':name,'pass':bool(ok),'note':note})
ck('v2.9.4 layer contains no raw colors',not re.search(r'#[0-9A-Fa-f]{3,8}\b|rgba?\s*\(',css))
ck('v2.9.4 CSS loads after v2.9.3',source_idx.find('v294-product-lot-hierarchy.css')>source_idx.find('v293-grouped-collection-density.css'))
ck('Product header is a composition, not a new core DS component','data-layout-pattern="Product group header"' in app and 'data-composed-from="VIcon,VText,VBadge"' in app)
ck('Actionable child uses nested row composition','data-layout-pattern="Nested navigation row"' in app and 'class="io07-allocation-row"' in app)
prep=app[app.index('function io07PreparationGroups'):app.index('function io07ReviewGroups')]
ck('SCR037 no longer renders Product/LOT as the same List Row component','ds24ListRow({' not in prep and 'io07ProductGroupHeader' in prep and 'io07AllocationActionRow' in prep)
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1600,'height':900});p.set_default_timeout(5000);p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)
    p.evaluate("()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=false;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07VerifySheetOpen=false;render();}")
    coll=p.locator('#app-screen .io07-product-list.io07-grouped-collection')
    headers=p.locator('#app-screen .io07-product-header[data-layout-role="rtv-product-summary"]')
    rows=p.locator('#app-screen .io07-allocation-row')
    ck('SCR037 uses one collection for all Product/UOM groups',coll.count()==1,coll.count())
    ck('SCR037 renders three Product/UOM headers',headers.count()==3,headers.count())
    ck('SCR037 renders four nested LOT/non-LOT rows',rows.count()==4,rows.count())
    ck('Product headers use package icon while LOT rows do not',headers.locator('[data-ds-icon="VIcons.inventory"]').count()==3 and rows.locator('[data-ds-icon="VIcons.inventory"]').count()==0)
    style=p.evaluate('''()=>{const h=document.querySelector('.io07-product-header');const r=document.querySelector('.io07-allocation-row');const hs=getComputedStyle(h),rs=getComputedStyle(r);return {hb:hs.backgroundColor,rb:rs.backgroundColor,hr:hs.borderRadius,rr:rs.borderRadius,rbt:rs.borderTopWidth,rh:r.offsetHeight,rw:r.offsetWidth};}''')
    ck('Product and LOT have distinct visual surfaces',style['hb']!=style['rb'],style)
    ck('LOT rows are flat, not rounded cards',style['rr']=='0px' and style['rbt']=='0px',style)
    ck('Actionable LOT rows preserve 44px minimum target',style['rh']>=44 and style['rw']==370,style)
    ck('Nested hierarchy connector is present',p.locator('#app-screen .io07-allocation-list').first.evaluate("e=>getComputedStyle(e,'::before').content!=='none'"))
    labels=rows.locator('strong').all_inner_texts()
    ck('Child labels identify LOT/non-LOT semantics',labels[:3]==['Lô DH2507','Lô DH2511','Lô DH2507'] and labels[-1]=='Không theo lô',labels)
    rows.first.click();p.wait_for_timeout(20)
    ck('Nested LOT row still opens physical verification sheet',p.locator('.io07-verification-sheet').count()==1)
    p.evaluate("()=>{io07VerifySheetOpen=false;activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});r.reviewSourceVersion=r.sourceVersion;activeScreenId='SCR-039';stateByScreen['SCR-039']='READY';render();}")
    review_headers=p.locator('#app-screen .io07-product-header[data-layout-role="rtv-review-product"]')
    kv=p.locator('#app-screen .io07-review-kv [data-ds-component="DS v2 / Key-value Row"]')
    ck('SCR039 reuses the same Product group header hierarchy',review_headers.count()==3,review_headers.count())
    ck('SCR039 keeps canonical Key-value evidence rows 338x44',kv.count()==4 and kv.evaluate_all('els=>els.every(e=>e.offsetWidth===338&&e.offsetHeight===44)'),kv.count())
    p.evaluate("()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07LastResult={operationId:'IO-RTV-QA',requestId:r.id,supplier:r.supplier,source:r.source,sourceVersion:r.sourceVersion,warehouse:r.warehouse,lines:io07Allocations(r).map(({group,allocation:a})=>({name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty}))};activeScreenId='SCR-041';stateByScreen['SCR-041']='COMPLETED';render();}")
    result_headers=p.locator('#app-screen .io07-product-header[data-layout-role="rtv-review-product"]')
    ck('SCR041 reuses the same Product group header hierarchy',result_headers.count()==3,result_headers.count())
    reach=p.evaluate('''()=>{const c=document.querySelector('.app-content');const last=document.querySelector('.io07-review-product:last-child');if(!c||!last)return {ok:false};c.scrollTop=c.scrollHeight;const lr=last.getBoundingClientRect(),fr=document.querySelector('.app-actions')?.getBoundingClientRect();return {ok:!fr||lr.bottom<=fr.top+1,scrollTop:c.scrollTop,lastBottom:lr.bottom,footerTop:fr?.top};}''')
    ck('SCR041 final evidence remains scroll-reachable above sticky footer',reach['ok'],reach)
    geom=p.evaluate("()=>{const a=document.querySelector('#app-screen'),c=a.querySelector('.app-content');return {app:[a.offsetWidth,a.offsetHeight],overflow:c.scrollWidth-c.clientWidth};}")
    ck('Product viewport remains 402x874 with no horizontal overflow',geom['app']==[402,874] and geom['overflow']<=1,geom)
    ck('No browser errors',not errors,errors[:10])
    b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'PRODUCT-LOT-HIERARCHY-QA-v2.9.4.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'PRODUCT-LOT-HIERARCHY-QA-v2.9.4.md').write_text('\n'.join(['# Product / LOT Hierarchy QA - v2.9.4','',f'**Result: {status} - {res["passed"]}/{res["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} - {x["name"]}: {x["note"]}' for x in checks])+'\n',encoding='utf-8')
print(status,res['passed'],res['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
