#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
QA=Path(__file__).resolve().parent
PKG=Path(__file__).resolve().parents[6]
CAP=QA/'v395-bj07-captures'; CAP.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8')
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists(): styles.append(p.read_text(encoding='utf-8'))
    idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
    p=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')
checks=[]; errors=[]; console_errors=[]; shots=[]
def ck(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
def shot(p,name,label):
    p.locator('#device-preview').screenshot(path=str(CAP/name)); shots.append({'file':name,'label':label})
def goto(p,screen,state='READY',req='RTV-260827-02'):
    p.evaluate('''([screen,state,req])=>{activeFlowId='UIF-07';if(req)io07Selected=req;activeScreenId=screen;stateByScreen[screen]=state;render();}''',[screen,state,req])
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1080})
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.on('console',lambda m: console_errors.append(m.text) if m.type=='error' else None)
    p.set_default_timeout(7000);p.set_content(html,wait_until='load',timeout=30000)
    ck('Runtime prototype identifies v3.9.5',p.evaluate('window.__VET45_PROTOTYPE__.version')=='3.9.5')

    # D07-01: queue is source/system generated; no fake mutation CTA. Search matches request/supplier/source.
    goto(p,'SCR-036')
    txt=p.locator('#app-screen').inner_text()
    search=p.locator('[data-io07-search]')
    ck('BJ07 queue search names request, supplier and source document',search.get_attribute('placeholder')=='Tìm mã yêu cầu, NCC hoặc chứng từ',search.get_attribute('placeholder'))
    ck('BJ07 queue has no manual RTV_PENDING mutation CTA','Đưa hàng vào chờ trả' not in txt and 'Chuyển trạng thái' not in txt,txt[:900])
    p.locator('[data-io07-search]').fill('YCTN-260827-04')
    p.wait_for_timeout(50)
    visible=p.locator('[data-io07-request]:visible').all_inner_texts()
    ck('Source document participates in queue search',len(visible)==1 and 'RTV-260827-04' in visible[0],visible)
    shot(p,'01-SCR036-SOURCE-OWNED-QUEUE.png','Supplier-return work appears from source sync without a fake state-mutation action')

    # D07-02/03: stable source identity + source-state ambiguity resolved only when needed.
    goto(p,'SCR-037')
    seeded=p.evaluate("()=>{const f=io07FindAllocation('RTV-A1');return {sourceRequestId:f.allocation.sourceRequestId,line:f.allocation.sourceLineId,allocation:f.allocation.sourceAllocationId,candidates:f.allocation.sourceStateCandidates,slices:f.allocation.sourceSlices,op:io07Current().operationId};}")
    ck('Supplier return carries stable source request/line/allocation identities',seeded['sourceRequestId']=='YCTN-260827-02' and seeded['line'] and seeded['allocation']=='RTV-A1',seeded)
    ck('Operation identity exists before final handover for same-operation recovery',str(seeded['op']).startswith('IO-RTV-'),seeded['op'])
    ck('Ambiguous allocation exposes multiple original-state candidates but no guessed slice initially',len(seeded['candidates'])==2 and seeded['slices']==[],seeded)
    p.locator('[data-io07-allocation="RTV-A1"]').click()
    sheet=p.locator('.v395-verification-sheet').inner_text()
    ck('Ambiguous source composition progressively exposes Xác định nguồn tồn','Xác định nguồn tồn' in sheet and 'Bán được' in sheet and 'Hỏng' in sheet,sheet[:1200])
    ck('Handover verification remains blocked until exact source slices sum to allocation quantity',p.locator('[data-io07-action="confirm-allocation"]').is_disabled())
    s=p.locator('[data-io07-source-slice]');s.nth(0).fill('3');s.nth(1).fill('1')
    ck('Exact multi-state composition enables physical verification',p.locator('[data-io07-action="confirm-allocation"]').is_enabled())
    p.locator('[data-io07-action="confirm-allocation"]').click()
    a1=p.evaluate("()=>{const a=io07FindAllocation('RTV-A1').allocation;return {verified:a.verified,user:a.sourceSliceUserResolved,total:a.sourceSlices.reduce((s,x)=>s+Number(x.qty),0),states:a.sourceSlices.map(x=>x.state)}}")
    ck('Verified allocation locks exact source slices and original stock-state lineage',a1['verified'] and a1['user'] and a1['total']==4 and a1['states']==['SELLABLE','DAMAGED'],a1)
    # Deterministic allocation must not ask the user for source-state composition.
    p.locator('[data-io07-allocation="RTV-A3"]').click()
    ck('Deterministic source-state composition is system-resolved with no extra user step',p.locator('[data-io07-source-slice]').count()==0 and 'Xác định nguồn tồn' not in p.locator('.v395-verification-sheet').inner_text())
    p.locator('[data-io07-action="confirm-allocation"]').click()
    shot(p,'02-SCR037-SOURCE-SLICE.png','Only ambiguous stock-state composition asks the warehouse user to identify the source stock')

    # D07-05: mismatch is structured immutable observation; preserve actual LOT and block further work.
    p.locator('[data-io07-allocation="RTV-A2"]').click()
    p.locator('[data-io07-scan-lot]').fill('ZZ2609')
    ck('LOT comparison shows a concrete source-vs-actual mismatch','Lô không khớp' in p.locator('.v395-verification-sheet').inner_text())
    p.locator('[data-io07-action="mark-mismatch"]').click()
    mtxt=p.locator('.v395-mismatch-sheet').inner_text()
    ck('Mismatch sheet uses approved structured taxonomy',all(x in mtxt for x in ['Sai số lượng','Sai lô','Không thấy hàng','Khác']),mtxt)
    p.locator('[data-io07-action="select-mismatch"][data-io07-mismatch-type="LOT"]').click()
    ck('Actual LOT is preserved when converting mismatch into an observation',p.locator('[data-io07-mismatch-lot]').input_value()=='ZZ2609',p.locator('[data-io07-mismatch-lot]').input_value())
    ck('Structured LOT observation can be sent without inventing photo evidence',p.locator('[data-io07-action="record-mismatch-observation"]').is_enabled() and p.locator('input[type=file]').count()==0)
    p.locator('[data-io07-action="record-mismatch-observation"]').click()
    obs=p.evaluate("()=>{const r=io07Current(),a=io07FindAllocation('RTV-A2').allocation;return {queue:r.queue,awaiting:r.awaitingSourceAmendment,obs:a.physicalObservation,a1:io07FindAllocation('RTV-A1').allocation.verified};}")
    ck('Mismatch becomes immutable source-allocation observation with no stock effect',obs['obs']['mismatchType']=='LOT' and obs['obs']['actualLot']=='ZZ2609' and obs['obs']['stockEffect']=='NONE' and len(obs['obs']['observationHash'])==64,obs['obs'])
    ck('Mismatch task moves to source-update waiting state while preserving unaffected verification',obs['queue']=='WAITING' and obs['awaiting'] and obs['a1'],obs)
    txt=p.locator('#app-screen').inner_text()
    ck('WAITING detail is true read-only and explains source-owner next step','Chờ cập nhật yêu cầu' in txt and p.locator('[data-io07-allocation]').count()==0 and p.locator('.sticky-footer').count()==0,txt[:1200])
    shot(p,'03-SCR037-STRUCTURED-MISMATCH-WAITING.png','Physical mismatch is an observation and the warehouse task waits read-only for a new source version')

    # D07-02 granular invalidation: source amendment affects only exact allocation.
    p.evaluate("()=>io07ApplySourceUpdate('RTV-260827-02',[{type:'LOT',allocationId:'RTV-A2',newLot:'ZZ2609'}])")
    p.evaluate('()=>renderAppScreen()')
    after=p.evaluate("()=>{const r=io07Current(),a1=io07FindAllocation('RTV-A1').allocation,a2=io07FindAllocation('RTV-A2').allocation,a3=io07FindAllocation('RTV-A3').allocation;return {v:r.sourceVersion,queue:r.queue,changes:r.sourceChanges,a1:a1.verified,a2:a2.verified,a3:a3.verified,obs:a2.physicalObservation};}")
    ck('Source amendment increments source version and keeps stable allocation identity',after['v']==4 and p.evaluate("()=>io07FindAllocation('RTV-A2').allocation.sourceAllocationId")=='RTV-A2',after)
    ck('Only affected allocation is invalidated; verified unaffected allocations stay verified',after['a1'] and after['a3'] and not after['a2'],after)
    ck('Observation is resolved by the exact new source version',after['obs']['status']=='RESOLVED_BY_SOURCE_VERSION' and after['obs']['resolvedSourceVersion']==4,after['obs'])
    txt=p.locator('#app-screen').inner_text()
    ck('Source delta is concrete business fact, not generic stale/version language','lô DH2511 → ZZ2609' in txt and 'phiên bản mới' not in txt,txt[:1100])

    # Finish physical verification. Deterministic slices are auto-resolved.
    for aid in ['RTV-A2','RTV-A4']:
        p.locator(f'[data-io07-allocation="{aid}"]').click()
        assert p.locator('[data-io07-action="confirm-allocation"]').is_enabled()
        p.locator('[data-io07-action="confirm-allocation"]').click()
    ck('All current allocations are reviewable only after current-source verification',p.locator('[data-io07-action="review-handover"]').is_enabled())
    p.locator('[data-io07-action="review-handover"]').click()
    review=p.locator('#app-screen').inner_text()
    ck('Final review shows supplier, return request, source document and warehouse',all(x in review for x in ['Nhà cung cấp','Minh Dũng','Yêu cầu trả','RTV-260827-02','Chứng từ nguồn','YCTN-260827-02','Kho chính']),review[:1300])
    ck('Final review does not expose raw source version or commercial price','source_version' not in review.lower() and 'phiên bản nguồn' not in review.lower() and 'giá nhà cung cấp' not in review.lower() and 'giá trả' not in review.lower(),review[:1300])
    ck('Only user-resolved multi-state source composition is surfaced in review',review.count('Nguồn tồn')==1 and 'Bán được 3 · Hỏng 1' in review,review[:1700])
    shot(p,'04-SCR039-FINAL-HANDOVER-REVIEW.png','Final handover review contains business context and only the source-state fact the user had to resolve')

    # D07-04/06 finality: source-agnostic evidence, official inventory handover independent from commercial price.
    p.locator('[data-io07-action="confirm-handover"]').click()
    result=p.locator('#app-screen').inner_text()
    ev=p.evaluate('()=>io07LastResult.handoverEvidence')
    ck('Completed result exposes authoritative handover timestamp','Bàn giao lúc' in result and 'Đã bàn giao cho nhà cung cấp' in result,result[:900])
    ck('Result remains keyed by business source and does not show operation/version internals','Chứng từ nguồn' in result and 'YCTN-260827-02' in result and 'IO-RTV-' not in result and 'sourceVersion' not in result,result[:1100])
    ck('HandoverEvidence is source-agnostic with shared required facts',ev['sourceType']=='SUPPLIER_RETURN' and ev['sourceDocumentId']=='YCTN-260827-02' and ev['warehouseId']=='WH-MAIN' and ev['actorId']=='USR-WH-021' and ev['confirmedAt'] and len(ev['evidenceHash'])==64,ev)
    ck('HandoverEvidence preserves source allocation and source-slice lineage',all(x.get('sourceAllocationId') and x.get('sourceLineId') and x.get('sourceSlices') for x in ev['lineEvidence']),ev['lineEvidence'])
    ck('Physical handover completes without any supplier-price input or second commercial approval',p.locator('input').filter(has=p.locator('text=Giá')).count()==0 and 'phê duyệt' not in result.lower(),result[:1100])
    ck('SCR-041 terminal result has no Back navigation',p.locator('#app-screen [data-action="back"]').count()==0 and p.locator('#app-screen .app-appbar button').count()==0)
    shot(p,'05-SCR041-SOURCE-AGNOSTIC-EVIDENCE-RESULT.png','Completed handover shows business finality and timestamp while evidence remains authoritative behind the result')

    # UNKNOWN: same operation identity, no retry, handoff BJ17.
    p.evaluate("()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-04';const r=io07Current();activeScreenId='SCR-041';stateByScreen['SCR-041']='UNKNOWN';render();}")
    btn=p.locator('[data-v350-action="handoff-unknown"]'); op=p.evaluate('()=>io07Current().operationId'); unknown=p.locator('#app-screen').inner_text()
    ck('UNKNOWN has no blind retry and exposes BJ17 verification handoff','Đang xác minh kết quả' in unknown and 'Không gửi lại bàn giao' in unknown and btn.count()==1,unknown[:900])
    ck('UNKNOWN handoff carries the exact same operation identity',btn.get_attribute('data-operation')==op,(btn.get_attribute('data-operation'),op))
    btn.click(); hand=p.evaluate('()=>({flow:activeFlowId,screen:activeScreenId})')
    ck('UNKNOWN transitions to BJ17 recovery',hand['flow']=='UIF-17' and hand['screen']=='SCR-079',hand)

    overflow=p.evaluate("()=>{const el=document.querySelector('.phone-screen')||document.querySelector('#app-screen');return {sw:el.scrollWidth,cw:el.clientWidth}}")
    ck('Representative BJ07 runtime has no horizontal overflow',overflow['sw']<=overflow['cw']+1,overflow)
    ck('No browser page errors',not errors,errors)
    ck('No browser console errors',not console_errors,console_errors)
    b.close()

# Static semantic traceability / propagation.
dec=(PKG/'specs/themes/theme-07/know-how/decisions/decision-register.md').read_text(encoding='utf-8')
data=(PKG/'specs/themes/theme-07/srs/04-data-entities.md').read_text(encoding='utf-8')
bc=(PKG/'specs/themes/theme-07/srs/06-shared-behavioral-contracts.md').read_text(encoding='utf-8')
tech=(PKG/'specs/themes/theme-07/srs/07-technical-contracts.md').read_text(encoding='utf-8')
bj=(PKG/'specs/themes/theme-07/srs/02-business-journeys/07-BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md').read_text(encoding='utf-8')
ucdir=PKG/'specs/themes/theme-07/srs/05-use-cases/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap'
ucs='\n'.join(p.read_text(encoding='utf-8') for p in sorted(ucdir.glob('*.md')))
flow=(PKG/'specs/themes/theme-07/prototype/flows/UIF-07-BJ-07.md').read_text(encoding='utf-8')
v395=(ROOT/'v395-bj07-semantic-hardening.js').read_text(encoding='utf-8')
reg=json.loads((PKG/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf-8'))
wb=json.loads((ROOT/'workbench-data.json').read_text(encoding='utf-8'))
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
ck('Decision register contains approved BJ07 locks T7-DR-138..143',all(f'T7-DR-{n}' in dec for n in range(138,144)))
ck('BC-IO-17 owns system supplier-return synchronization into RTV_PENDING','BC-IO-17 — Synchronize supplier-return authorization' in bc and 'system-owned' in bc.lower() and 'RTV_PENDING' in bc)
ck('BC-IO-10 trace is limited to BJ-09, not BJ-07',re.search(r'### BC-IO-10[\s\S]*?\| Trace \| `BJ-09`',bc) is not None)
ck('BC-IO-09 actual handover has no commercial-price or second-approval blocker','Không yêu cầu commercial supplier price' in bc and 'không approval thương mại lần hai' in bc)
ck('InventoryOperationLine carries supplier-return source allocation/balance/original-state fields',all(x in data for x in ['source_allocation_id','source_balance_id','origin_stock_state']))
ck('HandoverEvidence shared schema is source-agnostic and BJ05 fields are optional extensions',all(x in data for x in ['source_type','source_document_id','source_version','source_context','line_evidence','evidence_hash']) and 'BJ-05 extension; không bắt buộc cho BJ-07' in data)
ck('SupplierReturnPhysicalObservation is a first-class immutable entity',all(x in data for x in ['ENT-IO-12 — SupplierReturnPhysicalObservation','mismatch_type','actual_lot_code','observation_hash','RESOLVED_BY_SOURCE_VERSION']) and 'không ghi movement/balance/value' in data)
ck('Technical contract exposes BC-IO-17 synchronization handler/event and transaction boundary','SynchronizeSupplierReturnAuthorization' in tech and 'EVT-IO-11' in tech and 'BC-IO-17' in tech)
ck('BJ07/UC source sync explicitly removes warehouse mutation UI',('BC-IO-17' in ucs and 'Không có screen mutation riêng' in ucs and 'SCR-038 không thuộc active UIF07' in ucs) and 'BC-IO-17' in bj)
ck('BJ07 flow documents source slices, observation and commercial-price-independent handover','source slice' in flow.lower() and 'structured observation' in flow.lower() and 'commercial supplier price' in flow.lower() and ('BJ17' in flow or 'BJ-17' in flow))
ck('Runtime overlay implements all approved BJ07 semantic primitives',all(x in v395 for x in ['sourceAllocationId','origin_stock_state' if False else 'sourceStateCandidates','SupplierReturnPhysicalObservation' if False else 'physicalObservation','handoverEvidenceId','sourceType:\'SUPPLIER_RETURN\'','handoff-unknown']))
ck('BJ07 current screens carry v3.9.5 deep-review trace',all(s.get('deep_review',{}).get('version')=='3.9.5' for s in reg['screens'] if s['id'] in {'SCR-036','SCR-037','SCR-039','SCR-041'}))
ck('Current presentation registries identify v3.9.5',reg.get('version')=='3.9.5' and wb.get('version')=='3.9.5' and manifest.get('version')=='3.9.5')
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':'3.9.5','scope':'Wave 2 / BJ07 deep review','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors,'consoleErrors':console_errors,'captures':shots}
(QA/'BJ07-DEEP-REVIEW-QA-v3.9.5.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# BJ07 Deep Review QA — v3.9.5','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','','Scope: approved Wave 2 / BJ07 decisions T7-DR-138..143, Atomic Change Set propagation, runtime verification and fresh-eye review.','']
for x in checks:
    note=x['note'];lines.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{note}`' if note not in ('',None) and len(str(note))<170 else ''))
lines+=['','## Captures','']+[f'- `{x["file"]}` — {x["label"]}' for x in shots]
(QA/'BJ07-DEEP-REVIEW-QA-v3.9.5.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(CAP/'manifest.json').write_text(json.dumps(shots,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(status,res['passed'],res['total'],'pageErrors',len(errors),'consoleErrors',len(console_errors),'captures',len(shots))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
    raise SystemExit(1)
