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
checks=[];errors=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
# Static gates for the new layer.
css=(ROOT/'v290-bj07-figma-ds.css').read_text(encoding='utf-8')
chk('BJ07 CSS has no raw hex/rgb colors',not re.search(r'#[0-9a-fA-F]{3,8}\b|rgba?\s*\(',css))
selectors=[]
for m in re.finditer(r'(^|\})\s*([^@][^\{]+)\{',css,re.M):
    sel=m.group(2).strip()
    if sel and not sel.startswith('/*'): selectors.append(sel)
chk('BJ07 CSS selectors are UIF-07 scoped',all('body[data-active-uif="UIF-07"]' in x for x in selectors),[x for x in selectors if 'body[data-active-uif="UIF-07"]' not in x][:5])
app=(ROOT/'app.js').read_text(encoding='utf-8')
chk('BJ07 no longer renders legacy io07-allocation-row', 'class="io07-allocation-row' not in app[app.find('function render036IO07'):app.find('// ============================================================================\n// v1.7.0')])
chk('BJ07 normal sheet declares canonical VBottomSheet node', 'data-figma-node="4695:6353"' in app[app.find('function io07VerificationSheet'):app.find('function io07OpenVerification')])
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1600,'height':900});p.set_default_timeout(5000);p.on('pageerror',lambda e:errors.append(str(e)));p.set_content(html,wait_until='load',timeout=30000)
    # Queue
    p.evaluate("()=>{activeFlowId='UIF-07';activeScreenId='SCR-036';stateByScreen['SCR-036']='READY';io07QueueFilter='ALL';io07Query='';render();}")
    chk('Queue defaults to Tất cả',p.locator('[data-io07-filter="ALL"].is-selected').count()==1)
    sh=p.locator('#app-screen .ds24-search-header'); app=p.locator('#app-screen')
    shgeo=p.evaluate("()=>{const a=document.querySelector('#app-screen').getBoundingClientRect(),s=document.querySelector('#app-screen .ds24-search-header'),r=s.getBoundingClientRect();return {w:s.offsetWidth,left:r.left-a.left,right:a.right-r.right}}")
    chk('Queue Search & Filter Header follows canonical 402px full-width geometry',shgeo['w']==402 and abs(shgeo['left'])<.5 and abs(shgeo['right'])<.5,shgeo)
    chk('Queue has no persistent Purchase-handoff subtitle','Yêu cầu do Mua hàng chuyển sang Kho' not in p.locator('#app-screen').inner_text())
    nav=p.locator('#app-screen .io07-queue-section [data-ds-prop-type="Navigation"]')
    status=p.locator('#app-screen .io07-queue-section [data-ds-prop-type="Status"]')
    chk('Actionable/ready queue records are canonical Navigation Default rows',nav.count()==3 and nav.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / List Row'&&e.dataset.dsPropDensity==='Default'&&e.offsetHeight===76)"),nav.count())
    chk('Waiting queue records are canonical Status Default rows',status.count()==1 and status.evaluate_all("els=>els.every(e=>e.dataset.dsPropDensity==='Default'&&e.offsetHeight===76)"),status.count())
    chk('Waiting row has no chevron and is not a button',status.locator('.ds24-list-row__trailing .icon').count()==0 and status.evaluate('(e)=>e.tagName')=='DIV')
    chk('Navigation rows all expose chevron',nav.evaluate_all("els=>els.every(e=>e.querySelector('.ds24-list-row__trailing .icon'))"))
    chk('Source-cancelled request is absent from active queue','RTV-260903-06' not in p.locator('#app-screen').inner_text())
    nav.first.click();p.wait_for_timeout(10)
    chk('Queue actionable row opens SCR037',p.evaluate('()=>activeScreenId')=='SCR-037')
    p.locator('#app-screen [data-back]').click();p.wait_for_timeout(10)
    chk('SCR037 Back returns to supplier-return queue, not another shared screen',p.evaluate('()=>activeScreenId')=='SCR-036')
    # Search no result
    p.locator('[data-io07-search]').fill('khong-co-yeu-cau');p.wait_for_timeout(20)
    chk('Queue search exposes no-result state',p.locator('[data-io07-filter-empty]').is_visible())
    p.locator('[data-io07-search]').fill('');p.wait_for_timeout(20)
    # Preparation
    p.evaluate("()=>{activeFlowId='UIF-07';activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07Selected='RTV-260827-02';io07VerifySheetOpen=false;io07Allocations(io07Current()).forEach(x=>{x.allocation.verified=false;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});render();}")
    reqctx=p.locator('[data-layout-role="rtv-request-context"]')
    parents=p.locator('[data-layout-role="rtv-product-summary"]')
    alloc=p.locator('#app-screen .io07-allocation-list > [data-ds-prop-type="Navigation"]')
    chk('Preparation request context is Status Compact 52px',reqctx.count()==1 and reqctx.get_attribute('data-ds-prop-density')=='Compact' and reqctx.evaluate('(e)=>e.offsetHeight')==52)
    chk('Product+UOM parents are Status Compact 52px',parents.count()==3 and parents.evaluate_all("els=>els.every(e=>e.dataset.dsPropType==='Status'&&e.dataset.dsPropDensity==='Compact'&&e.offsetHeight===52)"),parents.count())
    chk('All source allocations are uniform Navigation Default 76px',alloc.count()==4 and alloc.evaluate_all("els=>els.every(e=>e.dataset.dsPropDensity==='Default'&&e.offsetHeight===76)"),alloc.count())
    chk('Same product different UOM remains separate',sum('Nobivac DHPPi' in x for x in parents.all_inner_texts())==2,parents.all_inner_texts())
    chk('Allocation rows contain exact source qty/UOM without editable qty inputs',p.locator('#app-screen .io07-allocation-list input').count()==0 and '4 hộp' in alloc.nth(0).inner_text() and '6 lọ' in alloc.nth(2).inner_text())
    prepfit=p.evaluate("()=>{const c=document.querySelector('#app-screen .app-content');return [c.scrollHeight,c.clientHeight]}")
    chk('Default preparation stays within one Product viewport before overlays',prepfit[0]<=prepfit[1]+1,prepfit)
    # Sheet exactness
    alloc.first.click();p.wait_for_timeout(20)
    sheet=p.locator('.io07-verification-sheet')
    backdrop=p.locator('.io07-verify-backdrop')
    chk('Verification uses canonical VBottomSheet and full 402px shell',sheet.count()==1 and sheet.get_attribute('data-figma-node')=='4695:6353' and sheet.evaluate('(e)=>e.offsetWidth')==402)
    chk('Verification overlay spans full Product canvas',backdrop.evaluate('(e)=>[e.offsetWidth,e.offsetHeight]')==[402,874],backdrop.evaluate('(e)=>[e.offsetWidth,e.offsetHeight]'))
    chk('VBottomSheet handle is exact 48x4',sheet.locator('.sheet-handle').evaluate('(e)=>[e.offsetWidth,e.offsetHeight]')==[48,4])
    chk('Normal VBottomSheet contains no X close CTA',sheet.locator('[aria-label="Đóng"],.sheet-close,.app-icon-button').count()==0)
    chk('Sheet content-hugs within one viewport',sheet.evaluate('(e)=>e.offsetHeight')<520,sheet.evaluate('(e)=>e.offsetHeight'))
    chk('LOT verification uses canonical VTextField',sheet.locator('[data-ds-component="VTextField"][data-figma-node="522:7186"]').count()==1)
    chk('Sheet uses exactly one Primary action',sheet.locator('.button--primary').count()==1)
    p.locator('[data-io07-scan-lot]').fill('SAI-LOT');p.wait_for_timeout(20)
    chk('Mismatched typed LOT blocks primary and shows Danger feedback',p.locator('[data-io07-action="confirm-allocation"]').is_disabled() and 'LOT không khớp' in sheet.inner_text())
    chk('Typed mismatch does not mutate source LOT',p.evaluate("()=>io07FindAllocation('RTV-A1').allocation.lot")=='DH2507')
    p.locator('[data-io07-scan-lot]').fill('DH2507');p.wait_for_timeout(20);p.locator('[data-io07-action="confirm-allocation"]').click();p.wait_for_timeout(20)
    chk('Confirm exact LOT marks only selected allocation verified',p.evaluate("()=>io07FindAllocation('RTV-A1').allocation.verified===true&&io07FindAllocation('RTV-A2').allocation.verified===false"))
    # Source-update granular invalidation fixture
    p.evaluate("()=>{io07Selected='RTV-260827-04';activeScreenId='SCR-037';stateByScreen['SCR-037']='SOURCE_UPDATED';io07VerifySheetOpen=false;render();}")
    changed=p.evaluate("()=>({a5:io07FindAllocation('RTV-A5').allocation.verified,a5affected:io07FindAllocation('RTV-A5').allocation.affectedByChange,a6:io07FindAllocation('RTV-A6').allocation.verified})")
    chk('Source delta resets affected evidence only',changed=={'a5':False,'a5affected':True,'a6':True},changed)
    chk('Source delta uses one compact warning banner',p.locator('#app-screen .v-banner--warning[data-ds-prop-density="Compact"]').count()==1)
    # Physical mismatch blocks handover
    p.locator('[data-io07-allocation="RTV-A5"]').click();p.wait_for_timeout(10);p.locator('[data-io07-action="mark-mismatch"]').click();p.wait_for_timeout(10)
    chk('Physical mismatch blocks review CTA',p.locator('[data-io07-action="review-handover"]').is_disabled())
    chk('Mismatch copy returns ownership to source without warehouse substitution','Kho không sửa số lượng hoặc lô' in p.locator('#app-screen').inner_text())
    # Many allocation stress: uniform rows + vertical scroll + no horizontal overflow.
    stress=p.evaluate('''()=>{io07Selected='RTV-260827-02';const g=io07Current().groups[0];const base=g.allocations[0];while(g.allocations.length<12){const i=g.allocations.length;g.allocations.push({...base,id:'RTV-STRESS-'+i,lot:'ST'+String(i).padStart(2,'0'),qty:1,verified:false,physicalMismatch:false,affectedByChange:false});}activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07VerifySheetOpen=false;render();const rows=[...document.querySelectorAll('.io07-allocation-list > [data-ds-prop-type="Navigation"]')],c=document.querySelector('.app-content');return {count:rows.length,all76:rows.every(x=>x.offsetHeight===76),x:c.scrollWidth-c.clientWidth,scroll:c.scrollHeight>c.clientHeight};}''')
    chk('Many-LOT stress remains uniform rows with vertical scroll only',stress['count']>=14 and stress['all76'] and stress['x']<=1 and stress['scroll'],stress)
    # Reset original first group to 2 allocations for final review and verify all.
    p.evaluate('''()=>{const r=io07Current();r.groups[0].allocations=r.groups[0].allocations.filter(a=>['RTV-A1','RTV-A2'].includes(a.id));io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});r.reviewSourceVersion=r.sourceVersion;activeScreenId='SCR-039';stateByScreen['SCR-039']='READY';render();}''')
    chk('Final review has exactly four factual Info Rows',p.locator('.io07-handover-context .ds24-info-row').count()==4)
    chk('Final review groups Product+UOM with Compact Status rows',p.locator('[data-layout-role="rtv-review-product"]').count()==3 and p.locator('[data-layout-role="rtv-review-product"]').evaluate_all("els=>els.every(e=>e.offsetHeight===52&&e.dataset.dsPropType==='Status')"))
    kv=p.locator('#app-screen .io07-review-kv .ds24-key-value-row')
    chk('Final review uses one canonical Key-value row per allocation',kv.count()==4 and kv.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / Key-value Row'&&e.dataset.dsPropState==='Default'&&e.offsetHeight===44)"),kv.count())
    chk('Final review does not expose cross-UOM aggregate total','Tổng' not in p.locator('#app-screen').inner_text())
    chk('Final review has one primary commit and no confirmation modal',p.locator('#app-screen .app-actions .button--primary').count()==1 and p.locator('#app-screen [role="dialog"]').count()==0)
    reviewfit=p.evaluate("()=>{const c=document.querySelector('#app-screen .app-content');return [c.scrollHeight,c.clientHeight]}")
    chk('Default final review fits without unnecessary vertical scroll',reviewfit[0]<=reviewfit[1]+1,reviewfit)
    p.locator('#app-screen [data-back]').click();p.wait_for_timeout(10)
    chk('SCR039 Back returns to SCR037 preparation',p.evaluate('()=>activeScreenId')=='SCR-037')
    p.evaluate("()=>{const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});r.reviewSourceVersion=r.sourceVersion;activeScreenId='SCR-039';stateByScreen['SCR-039']='READY';render();}")
    # Stale final review
    p.evaluate("()=>{io07Current().sourceVersion+=1;}");p.locator('[data-io07-action="confirm-handover"]').click();p.wait_for_timeout(10)
    chk('Source version change blocks commit on same review',p.evaluate("()=>stateByScreen['SCR-039']")=='SOURCE_CHANGED' and 'Cần kiểm lại trước khi bàn giao' in p.locator('#app-screen').inner_text())
    chk('Stale review offers safe return to preparation',p.locator('[data-io07-action="back-to-preparation"]').count()==1)
    # Successful commit from fresh current source.
    p.evaluate('''()=>{const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false});r.reviewSourceVersion=r.sourceVersion;activeScreenId='SCR-039';stateByScreen['SCR-039']='READY';renderAppScreen();}''')
    before=p.evaluate("()=>io07LastResult?.requestId||null")
    p.locator('[data-io07-action="confirm-handover"]').click();p.wait_for_timeout(20)
    chk('Actual handover is the commit transition to SCR041',before is None and p.evaluate('()=>activeScreenId')=='SCR-041' and p.evaluate("()=>stateByScreen['SCR-041']")=='COMPLETED')
    chk('Completed task leaves active queue',p.evaluate("()=>io07Current().completed") is True)
    chk('Completed result is terminal with no Back',p.locator('#app-screen [data-back]').count()==0)
    chk('Completed result uses Product+UOM + allocation Key-value evidence',p.locator('#app-screen [data-layout-role="rtv-review-product"]').count()==3 and p.locator('#app-screen .io07-review-kv .ds24-key-value-row').count()==4)
    chk('Visible completed copy hides technical operation id','IO-RTV-' not in p.locator('#app-screen').inner_text())
    # UNKNOWN
    p.evaluate("()=>{activeScreenId='SCR-041';stateByScreen['SCR-041']='UNKNOWN';renderAppScreen();}")
    txt=p.locator('#app-screen').inner_text()
    chk('UNKNOWN has no blind retry CTA','Thử lại' not in txt and 'Gửi lại' not in txt and p.locator('[data-io07-action="confirm-handover"]').count()==0)
    chk('UNKNOWN only exposes safe queue exit',p.locator('[data-io07-action="result-to-rtv-queue"]').count()==1)
    # Permission masking
    p.evaluate("()=>{stateByScreen['SCR-041']='PERMISSION_DENIED';renderAppScreen();}")
    txt=p.locator('#app-screen').inner_text()
    chk('Permission result does not expose supplier/source detail','Minh Dũng' not in txt and 'YCTN-' not in txt)
    # Representative geometry states
    geo=p.evaluate('''()=>{const out=[];for(const cfg of [['SCR-036','READY'],['SCR-037','READY'],['SCR-039','SOURCE_CHANGED'],['SCR-041','UNKNOWN']]){activeFlowId='UIF-07';activeScreenId=cfg[0];stateByScreen[cfg[0]]=cfg[1];io07VerifySheetOpen=false;render();const a=document.querySelector('#app-screen'),c=a.querySelector('.app-content'),b=a.querySelector('.body-stack');out.push({s:cfg[0],state:cfg[1],app:[a.offsetWidth,a.offsetHeight],x:c?c.scrollWidth-c.clientWidth:0,bx:b?b.scrollWidth-b.clientWidth:0});}return out;}''')
    chk('BJ07 representative states stay 402x874 without horizontal overflow',all(x['app']==[402,874] and x['x']<=1 for x in geo),geo)
    chk('No browser errors',not errors,errors[:10])
    b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'BJ07-FIGMA-DS-QA-v2.9.0.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'BJ07-FIGMA-DS-QA-v2.9.0.md').write_text('\n'.join(['# BJ07 Figma DS + UX QA — v2.9.0','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}: {x["note"]}' for x in checks])+'\n',encoding='utf-8')
print(status,res['passed'],res['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
