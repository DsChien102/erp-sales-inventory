from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8'); styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists():
        styles.append(p.read_text(encoding='utf-8'))
        idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf-8")}</script>')
checks=[]; errors=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
css=(ROOT/'v292-product-hierarchy-surfaces.css').read_text(encoding='utf-8')
chk('v2.9.2 correction CSS has no raw color literals',not re.search(r'#[0-9a-fA-F]{3,8}\b|rgba?\s*\(',css))
chk('v2.9.2 CSS only targets migrated UIF05/06/07',all(('UIF-05' in x or 'UIF-06' in x or 'UIF-07' in x) for x in re.findall(r'body[^\{]+\{',css)), '')
app=(ROOT/'app.js').read_text(encoding='utf-8')
chk('Raw BJ07 Product heading helper is retired','function io07ProductHeading' not in app and 'io07-product-heading' not in app)
chk('BJ07 Product summary reuses canonical Status/Compact List Row','function io07ProductSummaryRow' in app and 'ds24ContextStatusRow' in app[app.find('function io07ProductSummaryRow'):app.find('function io07PreparationGroups')])
chk('No raw VSection+VText+VBadge Product header markup remains','data-composed-from="VText,VBadge' not in app[app.find('function io07ProductSummaryRow'):app.find('function io07SourceDelta')])

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1600,'height':900}); p.set_default_timeout(5000)
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)

    # Queue remains the v2.9.1-correct homogeneous collection.
    p.evaluate("()=>{activeFlowId='UIF-07';activeScreenId='SCR-036';stateByScreen['SCR-036']='READY';io07QueueFilter='ALL';io07Query='';render();}")
    rows=p.locator('#app-screen .io07-queue > .ds24-list-row')
    chk('SCR036 remains one flat request collection',rows.count()==4 and p.locator('#app-screen .io07-queue-section').count()==0,rows.count())
    chk('Queue rows remain Navigation/Default 370x76',rows.evaluate_all("els=>els.every(e=>e.dataset.dsPropType==='Navigation'&&e.dataset.dsPropDensity==='Default'&&e.offsetWidth===370&&e.offsetHeight===76)"))
    waiting=p.locator('[data-io07-request="RTV-260903-05"]')
    chk('Waiting queue peer remains Disabled Navigation with chevron',waiting.count()==1 and waiting.get_attribute('data-ds-prop-state')=='Disabled' and waiting.locator('.ds24-list-row__trailing .icon').count()==1)

    # Preparation: real component parent + coherent surface + lower-level allocations.
    p.evaluate("()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=false;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07VerifySheetOpen=false;render();}")
    groups=p.locator('#app-screen .io07-product-group'); parents=p.locator('[data-layout-role="rtv-product-summary"]'); alloc=p.locator('#app-screen .io07-allocation-list > .ds24-list-row')
    chk('SCR037 renders one coherent surface per Product+UOM',groups.count()==3 and groups.evaluate_all("els=>els.every(e=>e.offsetWidth===370&&getComputedStyle(e).backgroundColor!=='rgba(0, 0, 0, 0)'&&getComputedStyle(e).borderTopStyle!=='none')"),groups.count())
    chk('Product+UOM parent is canonical List Row Status/Compact',parents.count()==3 and parents.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / List Row'&&e.dataset.dsPropType==='Status'&&e.dataset.dsPropDensity==='Compact'&&e.offsetWidth===338&&e.offsetHeight===52)"),parents.count())
    chk('Product summary carries real VBadge trailing status',parents.evaluate_all("els=>els.every(e=>!!e.querySelector('[data-ds-component=\"VBadge\"]'))"))
    chk('LOT/non-LOT children remain Navigation/Default',alloc.count()==4 and alloc.evaluate_all("els=>els.every(e=>e.dataset.dsPropType==='Navigation'&&e.dataset.dsPropDensity==='Default'&&e.offsetWidth===338&&e.offsetHeight===76)"),alloc.count())
    chk('Parent and child have distinct density and visual weight',parents.first.evaluate('(e)=>e.offsetHeight')==52 and alloc.first.evaluate('(e)=>e.offsetHeight')==76)
    ptxt=parents.all_inner_texts()
    chk('Same product with different UOM remains separate',sum('Nobivac DHPPi' in x for x in ptxt)==2 and any('hộp' in x for x in ptxt) and any('lọ' in x for x in ptxt),ptxt)
    geom=p.evaluate("()=>{const a=document.querySelector('#app-screen'),c=a.querySelector('.app-content');return {app:[a.offsetWidth,a.offsetHeight],x:c.scrollWidth-c.clientWidth}}"); chk('Preparation stays 402x874 with no horizontal overflow',geom['app']==[402,874] and geom['x']<=1,geom)
    # many-lot stress still a collection, never stacked inline forms.
    stress=p.evaluate('''()=>{const r=io07Current(),g=r.groups[0],base=g.allocations[0];while(g.allocations.length<10){const i=g.allocations.length;g.allocations.push({...base,id:'V292-STRESS-'+i,lot:'S'+String(i).padStart(2,'0'),verified:false,physicalMismatch:false,affectedByChange:false});}renderAppScreen();const rs=[...document.querySelectorAll('.io07-allocation-list > .ds24-list-row')],c=document.querySelector('.app-content');return {count:rs.length,all76:rs.every(e=>e.offsetHeight===76&&e.offsetWidth===338),fields:document.querySelectorAll('.io07-allocation-list input').length,scroll:c.scrollHeight>c.clientHeight,x:c.scrollWidth-c.clientWidth};}''')
    chk('Many-LOT stress remains compact vertical rows',stress['count']>=12 and stress['all76'] and stress['fields']==0 and stress['scroll'] and stress['x']<=1,stress)
    # restore the mutated stress fixture without re-executing global scripts.
    p.evaluate("()=>{const r=io07Current();r.groups[0].allocations=r.groups[0].allocations.filter(a=>['RTV-A1','RTV-A2'].includes(a.id));renderAppScreen();}")

    # Verification overlay remains canonical VBottomSheet.
    p.evaluate("()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07VerifySheetOpen=false;render();io07OpenVerification('RTV-A1');renderAppScreen();}")
    sheet=p.locator('.io07-verification-sheet')
    chk('Verification stays canonical VBottomSheet 402px',sheet.count()==1 and sheet.get_attribute('data-figma-node')=='4695:6353' and sheet.evaluate('(e)=>e.offsetWidth')==402)
    chk('Normal VBottomSheet has 48x4 handle and no close X',sheet.locator('.sheet-handle').evaluate('(e)=>[e.offsetWidth,e.offsetHeight]')==[48,4] and sheet.locator('[aria-label="Đóng"],.sheet-close,.app-icon-button').count()==0)

    # Final review: same coherent pattern with Key-value children.
    p.evaluate('''()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});r.reviewSourceVersion=r.sourceVersion;activeScreenId='SCR-039';stateByScreen['SCR-039']='READY';io07VerifySheetOpen=false;render();}''')
    rg=p.locator('.io07-review-product'); rp=p.locator('[data-layout-role="rtv-review-product"]'); kv=p.locator('.io07-review-kv .ds24-key-value-row')
    chk('SCR039 Product groups are coherent bordered 370px surfaces',rg.count()==3 and rg.evaluate_all("els=>els.every(e=>e.offsetWidth===370&&getComputedStyle(e).backgroundColor!=='rgba(0, 0, 0, 0)'&&getComputedStyle(e).borderTopStyle!=='none')"),rg.count())
    chk('Final-review Product parent is Status/Compact List Row 338x52',rp.count()==3 and rp.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / List Row'&&e.dataset.dsPropType==='Status'&&e.dataset.dsPropDensity==='Compact'&&e.offsetWidth===338&&e.offsetHeight===52)"),rp.count())
    badges=rp.locator('.ds24-badge').all_inner_texts(); chk('Product quantities stay exact Product+UOM scoped',badges==['6 hộp','6 lọ','5 hộp'],badges)
    chk('Allocation evidence remains canonical Key-value Row 338x44',kv.count()==4 and kv.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / Key-value Row'&&e.offsetWidth===338&&e.offsetHeight===44)"),kv.count())
    chk('Final review contains no cross-UOM grand total','Tổng' not in p.locator('#app-screen').inner_text())
    chk('Final review retains exactly one primary commit',p.locator('#app-screen .app-actions .button--primary').count()==1)
    finalgeom=p.evaluate("()=>{const c=document.querySelector('#app-screen .app-content');return {x:c.scrollWidth-c.clientWidth}}"); chk('Final review has no horizontal overflow',finalgeom['x']<=1,finalgeom)

    # Commit/result/finality.
    p.locator('[data-io07-action="confirm-handover"]').click(); p.wait_for_timeout(20)
    chk('Confirm transitions to terminal SCR041',p.evaluate('()=>activeScreenId')=='SCR-041' and p.evaluate("()=>stateByScreen['SCR-041']")=='COMPLETED')
    crp=p.locator('[data-layout-role="rtv-review-product"]'); ckv=p.locator('.io07-review-kv .ds24-key-value-row')
    chk('Completed result reuses exact same Product summary primitive',crp.count()==3 and crp.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / List Row'&&e.dataset.dsPropType==='Status'&&e.dataset.dsPropDensity==='Compact'&&e.offsetWidth===338)"))
    chk('Completed result keeps allocation facts below parent',ckv.count()==4)
    chk('Completed result has no Back',p.locator('#app-screen [data-back]').count()==0)
    reach=p.evaluate('''()=>{const c=document.querySelector('#app-screen .app-content');c.scrollTop=c.scrollHeight;const last=[...document.querySelectorAll('#app-screen .io07-review-product')].at(-1),footer=document.querySelector('#app-screen .app-actions');const lr=last.getBoundingClientRect(),fr=footer.getBoundingClientRect();return {reachable:lr.bottom<=fr.top+1,scrollTop:c.scrollTop,max:c.scrollHeight-c.clientHeight};}''')
    chk('Last result surface remains reachable above sticky footer',reach['reachable'],reach)
    p.evaluate("()=>{stateByScreen['SCR-041']='UNKNOWN';renderAppScreen();}"); txt=p.locator('#app-screen').inner_text(); chk('UNKNOWN keeps no blind retry','Thử lại' not in txt and 'Gửi lại' not in txt)
    chk('No browser errors',not errors,errors[:10])
    b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'BJ07-FIGMA-DS-QA-v2.9.2.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'BJ07-FIGMA-DS-QA-v2.9.2.md').write_text('\n'.join(['# BJ07 Figma DS + Product hierarchy QA — v2.9.2','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}: {x["note"]}' for x in checks])+'\n',encoding='utf-8')
print(status,res['passed'],res['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
