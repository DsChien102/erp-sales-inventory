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
css=(ROOT/'v291-bj07-ux-correction.css').read_text(encoding='utf-8')
chk('v2.9.1 CSS has no raw hex/rgb colors',not re.search(r'#[0-9a-fA-F]{3,8}\b|rgba?\s*\(',css))
selectors=[]
for m in re.finditer(r'(^|\})\s*([^@][^\{]+)\{',css,re.M):
    sel=m.group(2).strip()
    if sel and not sel.startswith('/*'): selectors.append(sel)
chk('v2.9.1 CSS selectors are UIF-07 scoped',all('body[data-active-uif="UIF-07"]' in x for x in selectors),[x for x in selectors if 'body[data-active-uif="UIF-07"]' not in x][:5])
app=(ROOT/'app.js').read_text(encoding='utf-8')
chunk=app[app.find('function io07QueueList'):app.find('// ============================================================================\n// v1.7.0')]
chk('Queue code no longer creates status-heading collections','io07-queue-section' not in chunk)
chk('Normal verification still declares canonical VBottomSheet','data-figma-node="4695:6353"' in app[app.find('function io07VerificationSheet'):app.find('function io07OpenVerification')])

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1600,'height':900}); p.set_default_timeout(5000)
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)
    # Queue: one homogeneous list.
    p.evaluate("()=>{activeFlowId='UIF-07';activeScreenId='SCR-036';stateByScreen['SCR-036']='READY';io07QueueFilter='ALL';io07Query='';render();}")
    chk('Queue defaults to Tất cả',p.locator('[data-io07-filter="ALL"].is-selected').count()==1)
    queue=p.locator('#app-screen .io07-queue')
    rows=queue.locator(':scope > .ds24-list-row')
    chk('SCR036 contains one flat request list',queue.count()==1 and p.locator('#app-screen .io07-queue-section').count()==0,queue.count())
    chk('All four queue records use Navigation Default 370x76',rows.count()==4 and rows.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / List Row'&&e.dataset.dsPropType==='Navigation'&&e.dataset.dsPropDensity==='Default'&&e.offsetWidth===370&&e.offsetHeight===76)"),rows.count())
    chk('No stage heading is inserted between queue records',p.locator('#app-screen .io07-queue h2,#app-screen .io07-queue .ds24-section-title').count()==0)
    stage_text=p.locator('#app-screen .io07-queue .ds24-badge').all_inner_texts()
    chk('Work stages are trailing VBadge only',stage_text==['Cần chuẩn bị','Cần kiểm lại','Sẵn sàng','Chờ cập nhật'],stage_text)
    waiting=queue.locator('[data-io07-request="RTV-260903-05"]')
    chk('Waiting record keeps same Navigation anatomy and chevron',waiting.count()==1 and waiting.get_attribute('data-ds-prop-type')=='Navigation' and waiting.get_attribute('data-ds-prop-state')=='Disabled' and waiting.locator('.ds24-list-row__trailing .icon').count()==1)
    chk('Waiting record is non-interactive Disabled state',waiting.is_disabled())
    chk('Source-cancelled request is absent','RTV-260903-06' not in p.locator('#app-screen').inner_text())
    enabled=queue.locator(':scope > button:not([disabled])')
    enabled.first.click();p.wait_for_timeout(10)
    chk('Actionable request opens SCR037',p.evaluate('()=>activeScreenId')=='SCR-037')
    p.locator('#app-screen [data-back]').click();p.wait_for_timeout(10)
    chk('SCR037 Back returns to SCR036',p.evaluate('()=>activeScreenId')=='SCR-036')
    p.locator('[data-io07-search]').fill('khong-co-yeu-cau');p.wait_for_timeout(15)
    chk('Queue search retains no-result behavior',p.locator('[data-io07-filter-empty]').is_visible())

    # Preparation hierarchy.
    p.evaluate("()=>{activeFlowId='UIF-07';activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07Selected='RTV-260827-02';io07VerifySheetOpen=false;io07Allocations(io07Current()).forEach(x=>{x.allocation.verified=false;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});render();}")
    reqctx=p.locator('[data-layout-role="rtv-request-context"]')
    parents=p.locator('[data-layout-role="rtv-product-summary"]')
    alloc=p.locator('#app-screen .io07-allocation-list > [data-ds-prop-type="Navigation"]')
    chk('Request context is Status Compact 52px',reqctx.count()==1 and reqctx.get_attribute('data-ds-prop-type')=='Status' and reqctx.get_attribute('data-ds-prop-density')=='Compact' and reqctx.evaluate('(e)=>e.offsetHeight')==52)
    chk('Product+UOM parents are structural VSection headings',parents.count()==3 and parents.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='VSection'&&!e.dataset.dsPropType&&e.offsetHeight>=44)"),parents.count())
    chk('Product headings use H4 + caption + VBadge composition',parents.evaluate_all("els=>els.every(e=>e.querySelector('[data-ds-prop-variant=\"VTextVariant.headingH4\"]')&&e.querySelector('[data-ds-prop-variant=\"VTextVariant.caption\"]')&&e.querySelector('.ds24-badge'))"))
    chk('Exact allocations are uniform Navigation Default rows',alloc.count()==4 and alloc.evaluate_all("els=>els.every(e=>e.dataset.dsPropDensity==='Default'&&e.offsetWidth===370&&e.offsetHeight===76)"),alloc.count())
    chk('Product parent and LOT child have distinct visual surfaces',parents.first.evaluate("e=>getComputedStyle(e).borderTopStyle==='none'&&getComputedStyle(e).backgroundColor==='rgba(0, 0, 0, 0)'") and alloc.first.evaluate("e=>getComputedStyle(e).borderTopStyle!=='none'"))
    ptxt=parents.all_inner_texts()
    chk('Same Product with different UOM remains separate',sum('Nobivac DHPPi' in x for x in ptxt)==2 and any('hộp' in x for x in ptxt) and any('lọ' in x for x in ptxt),ptxt)
    chk('Preparation has no duplicated editable quantity forms',p.locator('#app-screen .io07-allocation-list input').count()==0)
    chk('Default allocation copy omits low-value Chưa kiểm repetition','Chưa kiểm' not in ' '.join(p.locator('#app-screen .io07-allocation-list').all_inner_texts()))
    prep=p.evaluate("()=>{const c=document.querySelector('#app-screen .app-content');return {scroll:c.scrollHeight,client:c.clientHeight,x:c.scrollWidth-c.clientWidth}}")
    chk('Default preparation remains compact and no horizontal overflow',prep['x']<=1 and prep['scroll']<=prep['client']+1,prep)
    # many LOT stress
    stress=p.evaluate('''()=>{const r=io07Current(),g=r.groups[0],base=g.allocations[0];while(g.allocations.length<12){const i=g.allocations.length;g.allocations.push({...base,id:'RTV-STRESS-'+i,lot:'ST'+String(i).padStart(2,'0'),qty:1,verified:false,physicalMismatch:false,affectedByChange:false});}render();const rows=[...document.querySelectorAll('.io07-allocation-list > [data-ds-prop-type="Navigation"]')],c=document.querySelector('.app-content');return {count:rows.length,all76:rows.every(e=>e.offsetHeight===76),scroll:c.scrollHeight>c.clientHeight,x:c.scrollWidth-c.clientWidth};}''')
    chk('Many-LOT stress scales as vertical list only',stress['count']>=14 and stress['all76'] and stress['scroll'] and stress['x']<=1,stress)
    p.evaluate("()=>{const r=io07Current();r.groups[0].allocations=r.groups[0].allocations.filter(a=>['RTV-A1','RTV-A2'].includes(a.id));render();}")

    # Bottom sheet remains DS-canonical behavior.
    p.locator('[data-io07-allocation="RTV-A1"]').click();p.wait_for_timeout(15)
    sheet=p.locator('.io07-verification-sheet'); backdrop=p.locator('.io07-verify-backdrop')
    chk('Verification uses canonical 402px VBottomSheet',sheet.count()==1 and sheet.get_attribute('data-figma-node')=='4695:6353' and sheet.evaluate('(e)=>e.offsetWidth')==402)
    chk('VBottomSheet handle is 48x4 and has no X',sheet.locator('.sheet-handle').evaluate('(e)=>[e.offsetWidth,e.offsetHeight]')==[48,4] and sheet.locator('[aria-label="Đóng"],.sheet-close,.app-icon-button').count()==0)
    chk('Sheet overlay spans full Product canvas',backdrop.evaluate('(e)=>[e.offsetWidth,e.offsetHeight]')==[402,874])
    p.locator('[data-io07-scan-lot]').fill('SAI-LOT');p.wait_for_timeout(10)
    chk('LOT mismatch blocks primary without mutating source',p.locator('[data-io07-action="confirm-allocation"]').is_disabled() and p.evaluate("()=>io07FindAllocation('RTV-A1').allocation.lot")=='DH2507')
    p.locator('[data-io07-scan-lot]').fill('DH2507');p.locator('[data-io07-action="confirm-allocation"]').click();p.wait_for_timeout(10)
    chk('Exact LOT confirms only selected allocation',p.evaluate("()=>io07FindAllocation('RTV-A1').allocation.verified===true&&io07FindAllocation('RTV-A2').allocation.verified===false"))

    # Source update and mismatch ownership.
    p.evaluate("()=>{io07Selected='RTV-260827-04';activeScreenId='SCR-037';stateByScreen['SCR-037']='SOURCE_UPDATED';io07VerifySheetOpen=false;render();}")
    changed=p.evaluate("()=>({a5:io07FindAllocation('RTV-A5').allocation.verified,a5affected:io07FindAllocation('RTV-A5').allocation.affectedByChange,a6:io07FindAllocation('RTV-A6').allocation.verified})")
    chk('Source delta invalidates affected evidence only',changed=={'a5':False,'a5affected':True,'a6':True},changed)
    chk('Source delta uses one compact Warning banner',p.locator('#app-screen .v-banner--warning[data-ds-prop-density="Compact"]').count()==1)
    p.locator('[data-io07-allocation="RTV-A5"]').click();p.locator('[data-io07-action="mark-mismatch"]').click();p.wait_for_timeout(10)
    chk('Physical mismatch blocks final review',p.locator('[data-io07-action="review-handover"]').is_disabled())

    # Final review composition.
    p.evaluate('''()=>{io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});r.reviewSourceVersion=r.sourceVersion;activeScreenId='SCR-039';stateByScreen['SCR-039']='READY';io07VerifySheetOpen=false;render();}''')
    chk('Final review context is exactly three decision-relevant Info Rows',p.locator('.io07-handover-context .ds24-info-row').count()==3)
    rparents=p.locator('[data-layout-role="rtv-review-product"]')
    chk('Final review Product+UOM uses structural headings',rparents.count()==3 and rparents.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='VSection'&&!e.dataset.dsPropType)"),rparents.count())
    badges=[x.strip() for x in rparents.locator('.ds24-badge').all_inner_texts()]
    chk('Product summary quantities are scoped per exact Product+UOM',badges==['6 hộp','6 lọ','5 hộp'],badges)
    kv=p.locator('#app-screen .io07-review-kv .ds24-key-value-row')
    chk('Final review has one canonical Key-value row per allocation',kv.count()==4 and kv.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / Key-value Row'&&e.dataset.dsPropState==='Default'&&e.offsetHeight===44)"),kv.count())
    chk('Final review has no cross-UOM grand total','Tổng' not in p.locator('#app-screen').inner_text())
    chk('Final review has one primary commit and no confirmation modal',p.locator('#app-screen .app-actions .button--primary').count()==1 and p.locator('#app-screen [role="dialog"]').count()==0)
    rf=p.evaluate("()=>{const c=document.querySelector('#app-screen .app-content');return {scroll:c.scrollHeight,client:c.clientHeight,x:c.scrollWidth-c.clientWidth}}")
    chk('Default final review is scan-dense without unnecessary vertical scroll',rf['x']<=1 and rf['scroll']<=rf['client']+1,rf)
    p.locator('#app-screen [data-back]').click();p.wait_for_timeout(10)
    chk('SCR039 Back returns to SCR037',p.evaluate('()=>activeScreenId')=='SCR-037')

    # Commit/finality.
    p.evaluate('''()=>{const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});r.reviewSourceVersion=r.sourceVersion;activeScreenId='SCR-039';stateByScreen['SCR-039']='READY';render();}''')
    p.locator('[data-io07-action="confirm-handover"]').click();p.wait_for_timeout(15)
    chk('Actual handover transitions to terminal COMPLETED result',p.evaluate('()=>activeScreenId')=='SCR-041' and p.evaluate("()=>stateByScreen['SCR-041']")=='COMPLETED')
    chk('Completed task leaves active queue',p.evaluate('()=>io07Current().completed') is True)
    chk('Completed result has no Back',p.locator('#app-screen [data-back]').count()==0)
    chk('Completed result reuses three Product headings and four allocation rows',p.locator('[data-layout-role="rtv-review-product"]').count()==3 and p.locator('.io07-review-kv .ds24-key-value-row').count()==4)
    align=p.evaluate("()=>({hero:getComputedStyle(document.querySelector('.io07-result > .result-hero')).textAlign,product:getComputedStyle(document.querySelector('.io07-result [data-layout-role=rtv-review-product]')).textAlign})")
    chk('Result separates centered finality from left-aligned factual evidence',align['hero']=='center' and align['product']=='left',align)
    reach=p.evaluate('''()=>{const c=document.querySelector('#app-screen .app-content');c.scrollTop=c.scrollHeight;const last=[...document.querySelectorAll('#app-screen .io07-review-product')].at(-1),footer=document.querySelector('#app-screen .app-actions');const lr=last.getBoundingClientRect(),fr=footer.getBoundingClientRect();return {bottom:lr.bottom,footerTop:fr.top,scrollTop:c.scrollTop,max:c.scrollHeight-c.clientHeight,reachable:lr.bottom<=fr.top+1};}''')
    chk('Last completed evidence row remains reachable above sticky footer',reach['reachable'],reach)
    chk('Visible result hides technical operation id','IO-RTV-' not in p.locator('#app-screen').inner_text())
    p.evaluate("()=>{stateByScreen['SCR-041']='UNKNOWN';renderAppScreen();}")
    txt=p.locator('#app-screen').inner_text()
    chk('UNKNOWN has no blind retry and only safe queue exit','Thử lại' not in txt and 'Gửi lại' not in txt and p.locator('[data-io07-action="result-to-rtv-queue"]').count()==1)
    p.evaluate("()=>{stateByScreen['SCR-041']='PERMISSION_DENIED';renderAppScreen();}")
    txt=p.locator('#app-screen').inner_text()
    chk('Permission result masks supplier/source details','Minh Dũng' not in txt and 'YCTN-' not in txt)

    geo=p.evaluate('''()=>{const out=[];for(const cfg of [['SCR-036','READY'],['SCR-037','READY'],['SCR-039','SOURCE_CHANGED'],['SCR-041','UNKNOWN']]){activeFlowId='UIF-07';activeScreenId=cfg[0];stateByScreen[cfg[0]]=cfg[1];io07VerifySheetOpen=false;render();const a=document.querySelector('#app-screen'),c=a.querySelector('.app-content');out.push({s:cfg[0],app:[a.offsetWidth,a.offsetHeight],x:c?c.scrollWidth-c.clientWidth:0});}return out;}''')
    chk('Representative BJ07 states stay 402x874 with no horizontal overflow',all(x['app']==[402,874] and x['x']<=1 for x in geo),geo)
    chk('No browser errors',not errors,errors[:10])
    b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'BJ07-FIGMA-DS-QA-v2.9.1.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'BJ07-FIGMA-DS-QA-v2.9.1.md').write_text('\n'.join(['# BJ07 Figma DS + UX QA — v2.9.1','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}: {x["note"]}' for x in checks])+'\n',encoding='utf-8')
print(status,res['passed'],res['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
