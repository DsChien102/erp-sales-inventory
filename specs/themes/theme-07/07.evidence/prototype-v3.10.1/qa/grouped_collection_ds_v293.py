from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
css=(ROOT/'v293-grouped-collection-density.css').read_text(encoding='utf-8')
app=(ROOT/'app.js').read_text(encoding='utf-8')
idx=(ROOT/'index.html').read_text(encoding='utf-8')
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
ck('v2.9.3 CSS has no raw colors',not re.search(r'#[0-9A-Fa-f]{3,8}\b|rgba?\s*\(',css))
ck('Grouped surface helper is Layout composition, not invented DS component','data-layout-pattern="Grouped surface"' in app and 'data-figma-reference="4518:1545"' in app)
ck('Live canonical component refs retained',all(x in app for x in ['data-figma-node="525:519"','data-figma-node="525:351"','data-figma-node="525:358"']))
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1600,'height':900})
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)

    # BJ07 preparation
    p.evaluate("()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=false;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07VerifySheetOpen=false;render();}")
    coll=p.locator('#app-screen .io07-product-list.ds24-grouped-collection')
    sub=p.locator('#app-screen .io07-product-group.ds24-grouped-subgroup')
    prod=p.locator('#app-screen [data-layout-role="rtv-product-summary"]')
    lot=p.locator('#app-screen .io07-allocation-list > [data-ds-component="DS v2 / List Row"]')
    ck('SCR037 has one grouped collection, not one outer surface per Product',coll.count()==1 and sub.count()==3 and sub.evaluate_all("els=>els.every(e=>getComputedStyle(e).borderTopStyle==='none'&&getComputedStyle(e).backgroundColor==='rgba(0, 0, 0, 0)')"),{'collection':coll.count(),'groups':sub.count()})
    ck('SCR037 Product+UOM uses exact Status/Compact 370x52',prod.count()==3 and prod.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / List Row'&&e.dataset.dsPropType==='Status'&&e.dataset.dsPropDensity==='Compact'&&e.offsetWidth===370&&e.offsetHeight===52)"),prod.count())
    ck('SCR037 allocation uses exact Navigation/Default 370x76',lot.count()>=3 and lot.evaluate_all("els=>els.every(e=>e.dataset.dsPropType==='Navigation'&&e.dataset.dsPropDensity==='Default'&&e.offsetWidth===370&&e.offsetHeight===76)"),lot.count())
    ck('SCR037 Product badges are semantic progress, not raw quantities',prod.locator('.ds24-badge').evaluate_all("els=>els.every(e=>/đã kiểm$/.test(e.textContent.trim()))"),prod.locator('.ds24-badge').all_inner_texts())
    lot.first.click();p.wait_for_timeout(20)
    ck('SCR037 verification sheet uses semantic status badge',p.locator('.io07-verification-sheet [data-layout-role="rtv-verify-product"] .ds24-badge').inner_text().strip() in {'Cần kiểm','Đã kiểm'})
    ck('SCR037 verification quantity is Info Row data',p.locator('.io07-verification-sheet .ds24-info-row').evaluate_all("els=>els.some(e=>e.textContent.includes('Cần chuẩn bị'))"))

    # BJ07 review
    p.evaluate("()=>{io07VerifySheetOpen=false;activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});r.reviewSourceVersion=r.sourceVersion;activeScreenId='SCR-039';stateByScreen['SCR-039']='READY';render();}")
    coll=p.locator('#app-screen .io07-review-products.ds24-grouped-collection')
    sub=p.locator('#app-screen .io07-review-product.ds24-grouped-subgroup')
    prod=p.locator('#app-screen [data-layout-role="rtv-review-product"]')
    kv=p.locator('#app-screen .io07-review-kv [data-ds-component="DS v2 / Key-value Row"]')
    ck('SCR039 uses one grouped review surface',coll.count()==1 and sub.count()==3,{'collection':coll.count(),'groups':sub.count()})
    ck('SCR039 repeated Product subgroups have no independent card boundary',sub.evaluate_all("els=>els.every(e=>getComputedStyle(e).borderTopStyle==='none'&&getComputedStyle(e).backgroundColor==='rgba(0, 0, 0, 0)')"))
    ck('SCR039 Product rows are exact Status/Compact and semantically Đã kiểm',prod.count()==3 and prod.evaluate_all("els=>els.every(e=>e.offsetWidth===370&&e.offsetHeight===52&&e.dataset.dsPropType==='Status'&&e.dataset.dsPropDensity==='Compact'&&e.querySelector('.ds24-badge')?.textContent.trim()==='Đã kiểm')"))
    ck('SCR039 allocation evidence is exact Key-value 338x44',kv.count()>=3 and kv.evaluate_all('els=>els.every(e=>e.offsetWidth===338&&e.offsetHeight===44)'),kv.count())
    raw_badges=p.locator('#app-screen .io07-review-products .ds24-badge').all_inner_texts()
    ck('SCR039 has no raw quantity VBadge',not any(re.fullmatch(r'\s*\d+(?:[.,]\d+)?\s+(?:hộp|lọ|chai|gói|cái)\s*',x,re.I) for x in raw_badges),raw_badges)

    # BJ07 result and footer reachability
    p.evaluate("()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07LastResult={operationId:'IO-RTV-QA',requestId:r.id,supplier:r.supplier,source:r.source,sourceVersion:r.sourceVersion,warehouse:r.warehouse,lines:io07Allocations(r).map(({group,allocation:a})=>({name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty}))};activeScreenId='SCR-041';stateByScreen['SCR-041']='COMPLETED';render();}")
    result_prod=p.locator('#app-screen [data-layout-role="rtv-review-product"]')
    ck('SCR041 Product badge is semantic Đã bàn giao',result_prod.count()==3 and result_prod.locator('.ds24-badge').evaluate_all("els=>els.every(e=>e.textContent.trim()==='Đã bàn giao')"))
    reach=p.evaluate('''()=>{const c=document.querySelector('.app-content');const last=document.querySelector('.io07-review-product:last-child');if(!c||!last)return {ok:false};c.scrollTop=c.scrollHeight;const lr=last.getBoundingClientRect(),fr=document.querySelector('.app-actions')?.getBoundingClientRect();return {ok:!fr||lr.bottom<=fr.top+1,scrollTop:c.scrollTop,scrollHeight:c.scrollHeight,clientHeight:c.clientHeight,lastBottom:lr.bottom,footerTop:fr?.top};}''')
    ck('SCR041 last evidence can scroll fully above sticky footer',reach['ok'],reach)

    # BJ05 handover
    p.evaluate("()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';const o=io05CurrentOrder();o.lines.forEach(l=>l.allocations.forEach(a=>a.picked=Math.min(Number(a.qty||0),Math.max(1,Number(a.picked||0)))));activeScreenId='SCR-028';stateByScreen['SCR-028']='PARTIAL_ALLOWED';render();}")
    coll=p.locator('#app-screen .bj05-handover-list.ds24-grouped-collection')
    sub=p.locator('#app-screen .bj05-handover-product.ds24-grouped-subgroup')
    prod=p.locator('#app-screen [data-layout-role="bj05-handover-product-summary"]')
    kv=p.locator('#app-screen .bj05-handover-allocation [data-ds-component="DS v2 / Key-value Row"]')
    fields=p.locator('#app-screen .bj05-handover-allocation [data-ds-component="VTextField"]')
    ck('SCR028 uses one handover grouped collection, no per-Product outer card',coll.count()==1 and sub.count()>=1 and sub.evaluate_all("els=>els.every(e=>getComputedStyle(e).borderTopStyle==='none'&&getComputedStyle(e).backgroundColor==='rgba(0, 0, 0, 0)')"),{'collection':coll.count(),'groups':sub.count()})
    ck('SCR028 Product summary is exact Status/Compact with semantic Đã lấy',prod.count()>=1 and prod.evaluate_all("els=>els.every(e=>e.offsetWidth===370&&e.offsetHeight===52&&e.dataset.dsPropType==='Status'&&e.querySelector('.ds24-badge')?.textContent.trim()==='Đã lấy')"))
    ck('SCR028 allocation fact rows remain exact Key-value 338x44',kv.count()>=1 and kv.evaluate_all('els=>els.every(e=>e.offsetWidth===338&&e.offsetHeight===44)'),kv.count())
    ck('SCR028 editable actual fields remain 338px canonical controls',fields.count()>=1 and fields.evaluate_all('els=>els.every(e=>e.offsetWidth===338)'),fields.count())
    ck('SCR028 Product badges do not carry raw quantities',not any(re.fullmatch(r'\s*\d+(?:[.,]\d+)?\s+(?:hộp|lọ|chai|gói|cái)\s*',x,re.I) for x in prod.locator('.ds24-badge').all_inner_texts()),prod.locator('.ds24-badge').all_inner_texts())

    # BJ06 result
    p.evaluate("()=>{activeFlowId='UIF-06';io06SelectedRequestId='RET-260827-05';const r=io06CurrentRequest();r.classified=true;activeScreenId='SCR-035';stateByScreen['SCR-035']='COMPLETED';render();}")
    coll=p.locator('#app-screen .io06-result-groups.ds24-grouped-collection')
    sub=p.locator('#app-screen .io06-result-group.ds24-grouped-subgroup')
    prod=p.locator('#app-screen [data-layout-role="io06-result-product-summary"]')
    info=p.locator('#app-screen .io06-result-rows [data-ds-component="DS v2 / Info Row"]')
    ck('SCR035 uses one result grouped collection, no per-Product outer cards',coll.count()==1 and sub.count()>=1 and sub.evaluate_all("els=>els.every(e=>getComputedStyle(e).borderTopStyle==='none'&&getComputedStyle(e).backgroundColor==='rgba(0, 0, 0, 0)')"),{'collection':coll.count(),'groups':sub.count()})
    ck('SCR035 Product rows are exact Status/Compact with semantic classification status',prod.count()>=1 and prod.evaluate_all("els=>els.every(e=>e.offsetWidth===370&&e.offsetHeight===52&&e.dataset.dsPropType==='Status'&&e.querySelector('.ds24-badge')?.textContent.trim()==='Đã phân loại')"))
    ck('SCR035 child evidence is canonical Info Row 338x44',info.count()>=1 and info.evaluate_all('els=>els.every(e=>e.offsetWidth===338&&e.offsetHeight===44)'),info.count())
    h=p.locator('#app-screen .io06-result .ds24-section-title > h2').evaluate('(e)=>{const s=getComputedStyle(e),r=e.getBoundingClientRect();return {font:s.fontSize,line:s.lineHeight,left:r.left,textAlign:s.textAlign}}')
    ck('SCR035 nested section title remains H4 16/22, not result H2',h['font']=='16px' and h['line']=='22px',h)

    # shared geometry
    geom=p.evaluate("()=>{const a=document.querySelector('#app-screen'),c=a.querySelector('.app-content');return {app:[a.offsetWidth,a.offsetHeight],overflow:c.scrollWidth-c.clientWidth};}")
    ck('Product viewport remains exact 402x874 with no horizontal overflow',geom['app']==[402,874] and geom['overflow']<=1,geom)
    ck('No browser errors',not errors,errors[:10])
    b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'GROUPED-COLLECTION-DS-QA-v2.9.3.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'GROUPED-COLLECTION-DS-QA-v2.9.3.md').write_text('\n'.join(['# Grouped Collection / Figma DS QA — v2.9.3','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}: {x["note"]}' for x in checks])+'\n',encoding='utf-8')
print(status,res['passed'],res['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
