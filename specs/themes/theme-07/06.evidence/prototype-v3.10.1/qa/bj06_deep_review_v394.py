#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,base64,time
ROOT=Path(__file__).resolve().parents[1]
QA=Path(__file__).resolve().parent
PKG=Path(__file__).resolve().parents[6]
CAP=QA/'v394-bj06-captures'; CAP.mkdir(exist_ok=True)
# tiny valid PNG for content-hash evidence test
EVID=CAP/'qa-lot-evidence.png'
EVID.write_bytes(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9Zc1sAAAAASUVORK5CYII='))
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
def goto(p,screen,state='READY',req=None,line=None):
    p.evaluate('''([screen,state,req,line])=>{activeFlowId='UIF-06';if(req)io06SelectedRequestId=req;if(line)io06ActiveLineId=line;activeScreenId=screen;stateByScreen[screen]=state;render();}''',[screen,state,req,line])
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1080})
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.on('console',lambda m: console_errors.append(m.text) if m.type=='error' else None)
    p.set_default_timeout(6000); p.set_content(html,wait_until='load',timeout=30000)
    ck('Runtime package identifies v3.9.4','v3.9.4' in idx)

    # A1: waiting request is true read-only/non-actionable.
    goto(p,'SCR-030','READY')
    waiting=p.locator('[aria-disabled="true"]',has_text='RET-260827-07')
    ck('WAITING request row is status-only and disabled',waiting.count()==1 and 'Chờ duyệt lô' in waiting.inner_text(),waiting.inner_text() if waiting.count() else '')
    before=p.evaluate('()=>activeScreenId'); waiting.click(force=True); after=p.evaluate('()=>activeScreenId')
    ck('WAITING request cannot reopen editing flow',before==after=='SCR-030',(before,after))
    shot(p,'01-SCR030-WAITING-READONLY.png','Waiting return request is visible but non-actionable')

    # D06-01 + D06-02: current authorization upper bound, partial physical qty, declared condition is read-only context.
    goto(p,'SCR-032','READY','RET-260827-03','RET-L1A')
    txt=p.locator('#app-screen').inner_text()
    qty=p.locator('[data-io06-qty]')
    ck('ReturnExchangeLine current authorization is the input max',qty.get_attribute('max')=='3' and 'Được phép nhận lần này' in txt and '3 hộp' in txt,(qty.get_attribute('max'),txt[:700]))
    ck('Transaction UOM precision is carried to quantity input',qty.get_attribute('step')=='1',qty.get_attribute('step'))
    ck('Declared return condition is read-only comparison context','Tình trạng khai báo' in txt and 'Còn nguyên bao bì' in txt and p.locator('[data-io06-class]').count()==0,txt[:900])
    qty.fill('2'); p.locator('[data-io06-select-actual-lot="DH2507"]').click()
    p.locator('[data-io06-action="save-return-line"]').click()
    vals=p.evaluate("()=>{const l=io06FindLine('RET-L1A');return {qty:l.qty,verified:l.verified,max:l.authorizedQuantity,remaining:l.remaining};}")
    ck('Physical partial receipt line can be verified below authorization',vals['qty']==2 and vals['verified'] and vals['max']==3 and vals['remaining']==4,vals)
    goto(p,'SCR-032','READY','RET-260827-03','RET-L1A')
    shot(p,'02-SCR032-AUTHORIZED-PARTIAL.png','Current authorization and declared condition remain clear at line verification')

    # D06-03/04/A5: new LOT completion + minimal reason + real content hash.
    p.locator('[data-io06-select-other-lot]').click()
    p.locator('[data-io06-actual-lot]').fill('NEW2609')
    txt=p.locator('#app-screen').inner_text()
    ck('Wrong-LOT defaults to the approved minimal reason taxonomy','Khách trả lô khác lô đã giao' in txt and 'Không xác định được lô gốc' not in txt and 'Chứng từ/lịch sử lô không khớp' not in txt,txt[-1200:])
    ck('Unknown/new LOT progressively requests LOT attributes','Thông tin lô mới' in txt and p.locator('[data-v394-new-lot-expiry]').count()==1)
    # expiry policy is required, so evidence alone is not enough.
    p.locator('[data-io06-evidence-file]').set_input_files(str(EVID))
    p.wait_for_function("()=>!!io06ActiveLine().evidenceHash")
    ev=p.evaluate("()=>({id:io06ActiveLine().evidenceId,version:io06ActiveLine().evidenceVersion,hash:io06ActiveLine().evidenceHash})")
    ck('Evidence is bound by id/version/content hash (SHA-256 when secure context is available)',bool(ev['id']) and ev['version']>=1 and str(ev['hash']).startswith(('sha256:','fnv1a:')),ev)
    ck('New LOT required expiry blocks save until attribute completion',p.locator('[data-io06-action="save-return-exception"]').is_disabled())
    p.locator('[data-v394-new-lot-expiry]').fill('2027-12-31')
    # re-render not needed for model, but button disabled was computed before input; force render to verify contract-driven state.
    p.evaluate('()=>renderAppScreen()')
    ck('New LOT becomes eligible after required expiry is supplied',not p.locator('[data-io06-action="save-return-exception"]').is_disabled())
    shot(p,'03-SCR032-NEW-LOT-EVIDENCE.png','New LOT completion and content-bound evidence for wrong-LOT approval')

    # D06-05/A4: per-line approval case can coexist and approver sees business evidence, not raw IDs.
    multi=p.evaluate('''()=>{
      const r=io06Requests.find(x=>x.id==='RET-260827-03');
      const prep=(id,lot)=>{const l=io06FindLine(id);l.qty=1;l.actualLot=lot;l.actualLotMode='OTHER';l.reasonCode='RETURNED_DIFFERENT_LOT';l.evidenceFile=id+'.png';l.evidenceData='data:image/png;base64,AA==';l.evidenceId='EV-'+id;l.evidenceVersion=1;l.evidenceHash='sha256:'+id.padEnd(64,'0').slice(0,64);l.newLotExpiry='2028-01-31';l.verified=true;return io06CreateCase(r,l)};
      const a=prep('RET-L1A','NL-A'),b=prep('RET-L1B','NL-B');
      return {a:{id:a.id,scope:a.approvalScope,line:a.subjectLineId,hash:a.subjectSnapshotHash,status:a.status},b:{id:b.id,scope:b.approvalScope,line:b.subjectLineId,hash:b.subjectSnapshotHash,status:b.status},pending:io06ApprovalCases.filter(c=>c.requestId===r.id&&c.status==='PENDING').length};
    }''')
    ck('One receipt operation supports concurrent LINE_EXCEPTION cases',multi['pending']>=2 and multi['a']['scope']=='LINE_EXCEPTION' and multi['b']['scope']=='LINE_EXCEPTION' and multi['a']['line']!=multi['b']['line'] and multi['a']['hash'] and multi['b']['hash'],multi)
    # Use canonical seeded case for clean approver presentation.
    p.evaluate("()=>{io06SelectedRequestId='RET-260827-07';io06SelectedApprovalCaseId='EX-06-001';io06ApproverListMode=false;activeFlowId='UIF-06';activeScreenId='SCR-034';stateByScreen['SCR-034']='READY';render();}")
    txt=p.locator('#app-screen').inner_text()
    ck('Approver sees maker/source/order/product/UOM/qty/LOT/reason/evidence',all(x in txt for x in ['Người gửi','Nguyễn Minh','Yêu cầu trả','RET-260827-07','Đơn bán','SO-260820-08','Nobivac DHPPi','3 hộp','Lô đã giao','DH2507','Lô thực nhận','DH2509','Khách trả lô khác lô đã giao','Ảnh nhãn lô thực nhận']),txt[:1800])
    ck('Raw approval case ID/hash are not default Product UI','EX-06-001' not in txt and 'subject_snapshot_hash' not in txt and 'hash:' not in txt,txt[:1400])
    shot(p,'04-SCR034-BUSINESS-EVIDENCE.png','Approver decision surface is business-evidence-first')
    # Evidence mutation supersedes the active case snapshot.
    supersede=p.evaluate('''()=>{const l=io06FindLine('RET-L6'),c=io06ApprovalCases.find(x=>x.id==='EX-06-001');c.status='APPROVED';l.evidenceVersion=(l.evidenceVersion||1)+1;l.evidenceHash='sha256:changed-content';io06SetLineDirty(l);return {status:c.status,current:l.exceptionCaseId};}''')
    ck('Changing approval evidence supersedes prior case/snapshot',supersede['status']=='SUPERSEDED' and supersede['current'] is None,supersede)

    # D06-06: expiry is system-derived whole-line and not an editable classification bucket.
    goto(p,'SCR-033','READY','RET-260827-05','RET-L4')
    txt=p.locator('#app-screen').inner_text()
    ck('Expired LOT is system-derived for the whole line','Hết hạn' in txt and '4 hộp' in txt and p.locator('[data-io06-class-line="RET-L4"]').count()==0,txt[:1100])
    expired=p.evaluate("()=>io06FindLine('RET-L4').classification")
    ck('Expired line cannot be split into sellable/quarantine/damaged',expired=={'sellable':0,'quarantine':0,'damaged':0,'expired':4},expired)
    shot(p,'05-SCR033-SYSTEM-EXPIRED.png','Expired quantity is a system fact, not a user allocation input')
    # Non-expired line exposes exactly three editable buckets.
    p.locator('[data-io06-class-line="RET-L5"]').click()
    keys=p.locator('[data-io06-class]').evaluate_all("els=>els.map(e=>e.dataset.io06Class)")
    sheet=p.locator('.io06-classification-sheet').inner_text()
    ck('Non-expired classification has exactly three user inputs',keys==['sellable','quarantine','damaged'] and 'Tình trạng khai báo' in sheet,keys)
    ck('EXPIRED has no editable input on non-expired line','expired' not in keys,keys)
    p.locator('[data-io06-class="sellable"]').fill('5')
    p.locator('[data-io06-action="close-classification-item"]').click()
    ck('Routine physical classification needs no reason/evidence/approval',p.locator('[data-io06-action="confirm-classification"]').is_enabled())
    p.locator('[data-io06-action="confirm-classification"]').click()
    txt=p.locator('#app-screen').inner_text()
    ck('Completed result uses source request/order and authoritative classified timestamp','Yêu cầu trả' in txt and 'RET-260827-05' in txt and 'Đơn bán' in txt and 'SO-260815-19' in txt and 'Phân loại lúc' in txt,txt[:1200])
    ck('Result does not invent a return-receipt business number','RR-' not in txt,txt[:1000])
    shot(p,'06-SCR035-SOURCE-KEYED-RESULT.png','Completed result is keyed by source return request and SalesOrder')

    # D06-07/A6: UNKNOWN keeps exact operation identity and hands off to BJ17.
    p.evaluate("()=>{const r=io06Requests.find(x=>x.id==='RET-260827-03');io06SelectedRequestId=r.id;activeFlowId='UIF-06';activeScreenId='SCR-035';stateByScreen['SCR-035']='UNKNOWN';render();}")
    btn=p.locator('[data-v350-action="handoff-unknown"]')
    op=p.evaluate("()=>io06CurrentRequest().operationId")
    txt=p.locator('#app-screen').inner_text()
    ck('UNKNOWN prohibits blind retry and exposes verification handoff','Đang xác minh kết quả' in txt and 'Không gửi lại thao tác' in txt and btn.count()==1,txt[:900])
    ck('UNKNOWN handoff carries exact same operation identity',btn.get_attribute('data-operation')==op,(btn.get_attribute('data-operation'),op))
    btn.click()
    handoff=p.evaluate('()=>({flow:activeFlowId,screen:activeScreenId})')
    ck('UNKNOWN transitions to BJ17 recovery flow',handoff['flow']=='UIF-17' and handoff['screen']=='SCR-079',handoff)

    overflow=p.evaluate("()=>{const el=document.querySelector('.phone-screen')||document.querySelector('#app-screen');return {sw:el.scrollWidth,cw:el.clientWidth}}")
    ck('Representative runtime has no horizontal overflow',overflow['sw']<=overflow['cw']+1,overflow)
    ck('No browser page errors',not errors,errors)
    # Chromium logs can contain benign resource chatter; only JavaScript console errors are blockers here.
    ck('No browser console errors',not console_errors,console_errors)
    b.close()

# Static semantic traceability checks.
dec=(PKG/'specs/themes/theme-07/know-how/decisions/decision-register.md').read_text(encoding='utf-8')
data=(PKG/'specs/themes/theme-07/srs/04-data-entities.md').read_text(encoding='utf-8')
bc=(PKG/'specs/themes/theme-07/srs/06-shared-behavioral-contracts.md').read_text(encoding='utf-8')
flow=(PKG/'specs/themes/theme-07/prototype/flows/UIF-06-BJ-06.md').read_text(encoding='utf-8')
v394=(ROOT/'v394-bj06-semantic-hardening.js').read_text(encoding='utf-8')
reg=json.loads((PKG/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf-8'))
wb=json.loads((ROOT/'workbench-data.json').read_text(encoding='utf-8'))
ck('Decision register contains approved BJ06 locks T7-DR-131..137',all(f'T7-DR-{n}' in dec for n in range(131,138)))
ck('ApprovalCase supports OPERATION and LINE_EXCEPTION subject scope',all(x in data for x in ['approval_scope','subject_line_id','subject_snapshot_hash','SUPERSEDED']) and 'LINE_EXCEPTION' in data)
ck('BC-IO-07 binds physical receipt to current authorized return quantity','authorized_return_quantity' in bc and 'remaining_authorized_quantity' in bc and 'partial' in bc.lower())
ck('BC-IO-08 makes expiry system-derived and routine classification approval-free','SYSTEM_DERIVED' in bc and 'expired' in bc.lower() and 'không yêu cầu reason/evidence/approval' in bc.lower())
ck('BC-IC-06 supports per-line immutable approval subject hash','LINE_EXCEPTION' in bc and 'subject_snapshot_hash' in bc)
ck('UIF-06 documents same-operation UNKNOWN recovery and no blind retry','không blind retry' in flow and 'operation identity' in flow.lower() and 'BJ17' in flow)
ck('Runtime reason taxonomy excludes source-integrity blockers from approvable reasons',all(x in v394 for x in ['RETURNED_DIFFERENT_LOT','Khách trả lô khác lô đã giao']) and 'ORIGINAL_UNKNOWN' not in v394 and 'HISTORY_MISMATCH' not in v394)
ck('Runtime evidence contract uses SHA-256 content binding',"crypto.subtle.digest('SHA-256'" in v394 and "'fnv1a:'" in v394 and 'evidenceVersion' in v394 and 'evidenceHash' in v394)
ck('BJ06 current screens carry v3.9.4 deep-review trace',all(s.get('deep_review',{}).get('version')=='3.9.4' for s in reg['screens'] if s['id'] in {f'SCR-{i:03d}' for i in range(30,36)}))
ck('Current workbench/result contract contains no synthetic RR receipt identity','RR-260817-03' not in json.dumps(wb,ensure_ascii=False) and 'Return receipt' not in json.dumps([s for s in reg['screens'] if s['id']=='SCR-035'],ensure_ascii=False))
ck('Presentation registries identify v3.9.4',reg.get('version')=='3.9.4' and wb.get('version')=='3.9.4')
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':'3.9.4','scope':'Wave 2 / BJ06 deep review','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors,'consoleErrors':console_errors,'captures':shots}
(QA/'BJ06-DEEP-REVIEW-QA-v3.9.4.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# BJ06 Deep Review QA — v3.9.4','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','','Scope: approved Wave 2 / BJ06 decisions T7-DR-131..137, Atomic Change Set propagation, runtime verification and fresh-eye review.','']
for x in checks:
    note=x['note']; lines.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{note}`' if note not in ('',None) and len(str(note))<170 else ''))
lines += ['','## Captures','']+[f'- `{x["file"]}` — {x["label"]}' for x in shots]
(QA/'BJ06-DEEP-REVIEW-QA-v3.9.4.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(CAP/'manifest.json').write_text(json.dumps(shots,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(status,res['passed'],res['total'],'pageErrors',len(errors),'consoleErrors',len(console_errors),'captures',len(shots))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
    raise SystemExit(1)
