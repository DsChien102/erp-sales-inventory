#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
QA=Path(__file__).resolve().parent
PKG=Path(__file__).resolve().parents[6]
CAP=QA/'v393-bj05-captures';CAP.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text()
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists(): styles.append(p.read_text());idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
    p=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text()}</script>' if p.exists() else '')
checks=[];errors=[];shots=[]
def ck(n,ok,note=''): checks.append({'name':n,'pass':bool(ok),'note':note})
def shot(p,name,label): p.locator('#device-preview').screenshot(path=str(CAP/name));shots.append({'file':name,'label':label})
def goto(p,screen,state='READY'):
    p.evaluate('''([screen,state])=>{activeFlowId='UIF-05';activeScreenId=screen;stateByScreen[screen]=state;render();}''',[screen,state])
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1080});p.on('pageerror',lambda e:errors.append(str(e)));p.set_default_timeout(5000);p.set_content(html,wait_until='load',timeout=30000)
    ck('Runtime package identifies v3.9.3','v3.9.3' in idx)
    goto(p,'SCR-027')
    txt=p.locator('#app-screen').inner_text()
    ck('Product context does not badge raw remaining quantity','Còn cần lấy' in txt and not p.locator('.bj05-pick-product-row .ds24-badge').count(),txt[:700])
    p.locator('[data-io05-pick-allocation="AL-21-01"]').click()
    fld=p.locator('[data-io05-pick-draft]')
    ck('Pick input uses quantity precision contract',fld.get_attribute('step')=='1' and fld.get_attribute('max')=='4')
    p.locator('[data-io05-open-override="AL-21-01"]').click()
    sheet=p.locator('.bj05-lot-sheet').inner_text()
    ck('LOT candidates use server pickable quantity and preserve expiry precision','HSD 09/2027 · Có thể lấy 18 hộp' in sheet and 'HSD 2027 · Có thể lấy 22 hộp' in sheet,sheet)
    shot(p,'01-SCR027-LOT-PICKABLE-PRECISION.png','LOT candidate uses server pickable quantity and original expiry precision')
    p.locator('[data-io05-select-lot="DH2511"]').click();p.locator('[data-io05-override-reason]').fill('Lô gần khu lấy hàng hơn');p.locator('[data-io05-action="confirm-lot-override"]').click()
    # reopen editor; correction pending, fill repick qty. save must not clear it.
    p.locator('[data-io05-pick-allocation="AL-21-01"]').click();p.locator('[data-io05-pick-draft]').fill('4');p.locator('[data-io05-action="update-pick-allocation"]').click()
    corr=p.evaluate("()=>io05CurrentAllocation().physicalCorrection")
    ck('Changing LOT creates structured pending physical correction',corr and corr.get('status')=='PENDING' and corr.get('oldLot')=='DH2507' and corr.get('newLot')=='DH2511',corr)
    # editor closed, reopen to get explicit confirmation
    p.locator('[data-io05-pick-allocation="AL-21-01"]').click()
    ck('Entering picked quantity does not auto-clear physical correction',p.locator('[data-io05-action="confirm-physical-correction"]').count()==1)
    shot(p,'02-SCR027-PHYSICAL-CORRECTION.png','Physical correction requires explicit actor assertion')
    p.locator('[data-io05-action="confirm-physical-correction"]').click()
    corr=p.evaluate("()=>io05CurrentAllocation().physicalCorrection")
    ck('Explicit correction confirmation records actor and time',corr.get('status')=='CONFIRMED' and corr.get('actor') and corr.get('confirmedAt'),corr)

    # Partial handover history preservation on a controlled allocation.
    vals=p.evaluate('''()=>{const o=io05Orders.find(x=>x.id==='SO-260827-21');o.queue='ACTIONABLE';o.closed=false;o.reviewSourceVersion=o.sourceVersion;const l=o.lines[0];l.requestedQty=20;l.deliveredQty=0;const a=l.allocations[0];a.allocatedQty=4;a.allocatedBaseQty=4;a.pickedQty=4;a.consumedQty=0;a.physicalCorrection=null;a.lot='DH2507';io05HandoverByAllocation={};io05HandoverByAllocation[a.id]=2;for(const x of l.allocations.slice(1))io05HandoverByAllocation[x.id]=0;for(const ll of o.lines.slice(1))for(const x of ll.allocations)io05HandoverByAllocation[x.id]=0;const before={allocated:a.allocatedQty,picked:a.pickedQty,requested:l.requestedQty};const r=io05ApplyHandover();return {before,after:{allocated:a.allocatedQty,picked:a.pickedQty,consumed:a.consumedQty,requested:l.requestedQty,delivered:l.deliveredQty,remaining:io05LineRemaining(l)},result:r};}''')
    ck('Partial handover increments consumed without shrinking allocated/picked/requested',vals['after']['allocated']==vals['before']['allocated']==4 and vals['after']['picked']==vals['before']['picked']==4 and vals['after']['requested']==vals['before']['requested']==20 and vals['after']['consumed']==2 and vals['after']['delivered']==2,vals)
    ev=vals['result']['evidence']
    ck('Handover writes immutable evidence identity/actor/source/allocation version',all(ev.get(k) for k in ['handoverId','operationId','sourceId','sourceVersion','actorId','confirmedAt','allocationSetId','allocationVersion','evidenceHash']) and len(ev.get('lines',[]))==1,ev)
    p.evaluate("()=>{activeScreenId='SCR-029';stateByScreen['SCR-029']='PARTIAL_COMPLETED';render();}")
    txt=p.locator('#app-screen').inner_text()
    ck('Result shows authoritative handover timestamp','Bàn giao lúc' in txt and '16/09/2026' in txt,txt[:800])
    shot(p,'03-SCR029-PARTIAL-IMMUTABLE.png','Partial handover result includes authoritative handover timestamp')

    # UNKNOWN locks queue and prevents retry.
    p.evaluate("()=>{const o=io05Orders.find(x=>x.id==='SO-260827-21');o.closed=false;o.queue='ACTIONABLE';io05SelectedOrderId=o.id;activeScreenId='SCR-029';stateByScreen['SCR-029']='UNKNOWN';render();}")
    ck('UNKNOWN marks fulfillment VERIFYING and preserves exact operation identity',p.evaluate("()=>io05CurrentOrder().queue")=='VERIFYING' and p.locator('[data-v350-action=\"handoff-unknown\"]').get_attribute('data-operation')==p.evaluate("()=>io05CurrentOrder().operationId"))
    shot(p,'04-SCR029-UNKNOWN-VERIFYING.png','UNKNOWN freezes handover finality')
    p.evaluate("()=>{activeFlowId='UIF-05';activeScreenId='SCR-025';stateByScreen['SCR-025']='READY';render();}")
    row=p.locator('[data-io05-order="SO-260827-21"]')
    ck('VERIFYING queue row is non-actionable and distinct from waiting',row.get_attribute('aria-disabled')=='true' and 'Đang xác minh bàn giao' in row.inner_text(),row.inner_text())
    before=p.evaluate('()=>activeScreenId');row.click(force=True);after=p.evaluate('()=>activeScreenId')
    ck('VERIFYING order cannot reopen pick/handover',before==after=='SCR-025',(before,after))
    shot(p,'05-SCR025-VERIFYING-NONACTIONABLE.png','Verification task is disabled in BJ05 queue')

    # Integrated Warehouse Home is covered by the v3.9.3 post-render semantic patch and static trace below.
    overflow=p.evaluate("()=>{const el=document.querySelector('.phone-screen')||document.querySelector('#app-screen');return {sw:el.scrollWidth,cw:el.clientWidth}}")
    ck('Representative runtime has no horizontal overflow',overflow['sw']<=overflow['cw']+1,overflow)
    ck('No browser errors',not errors,errors)
    b.close()
# static semantic checks
app=(ROOT/'app.js').read_text();dec=(PKG/'specs/themes/theme-07/know-how/decisions/decision-register.md').read_text();data=(PKG/'specs/themes/theme-07/srs/04-data-entities.md').read_text();bc=(PKG/'specs/themes/theme-07/srs/06-shared-behavioral-contracts.md').read_text();flow=(PKG/'specs/themes/theme-07/prototype/flows/UIF-05-BJ-05.md').read_text();v393=(ROOT/'v393-bj05-semantic-hardening.js').read_text()
ck('Decision register contains BJ05 locks T7-DR-122..130',all(f'T7-DR-{n}' in dec for n in range(122,131)))
ck('PickAllocation stores allocated/picked/consumed separately',all(x in data for x in ['allocated_base_quantity','picked_base_quantity','consumed_base_quantity','physical_correction_assertion']))
ck('HandoverEvidence is an explicit immutable entity','ENT-IO-11' in data and 'HandoverEvidence' in data and 'immutable' in data.lower())
ck('Behavioral contract prohibits rewriting pick/allocation history','không rewrite `allocated_base_quantity`/`picked_base_quantity`/source requested' in bc)
ck('Runtime no longer mutates legacy required/qty/picked fields in BJ05','line.required' not in app[app.index('const io05Orders=['):app.index('function io06EvidenceSvg')] and 'allocation.qty=' not in app[app.index('const io05Orders=['):app.index('function io06EvidenceSvg')])
ck('UIF-05 documents UNKNOWN verification lock','Đang xác minh bàn giao' in flow and 'không blind retry' in flow)
ck('Integrated Warehouse Home patch freezes the verifying pick task','PICK-SO26082721' in v393 and 'aria-disabled' in v393 and 'Đang xác minh bàn giao' in v393)
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':'3.9.3','scope':'Wave 2 / BJ05 deep review','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors,'captures':shots}
(QA/'BJ05-DEEP-REVIEW-QA-v3.9.3.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ05 Deep Review QA — v3.9.3','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','','Scope: approved Wave 2 / BJ05 semantic hardening and fresh-eye runtime verification.','']
lines += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if x['note'] not in ('',None) and len(str(x['note']))<170 else '') for x in checks]
lines += ['','## Captures','']+[f'- `{x["file"]}` — {x["label"]}' for x in shots]
(QA/'BJ05-DEEP-REVIEW-QA-v3.9.3.md').write_text('\n'.join(lines)+'\n')
(CAP/'manifest.json').write_text(json.dumps(shots,ensure_ascii=False,indent=2)+'\n')
print(status,res['passed'],res['total'],'errors',len(errors),'captures',len(shots))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
    raise SystemExit(1)
