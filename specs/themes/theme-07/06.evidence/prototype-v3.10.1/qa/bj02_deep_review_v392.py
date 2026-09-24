#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,tempfile

ROOT=Path(__file__).resolve().parents[1]
QA=Path(__file__).resolve().parent
PKG=Path(__file__).resolve().parents[6]
CAP=QA/'v392-bj02-captures'; CAP.mkdir(exist_ok=True)

idx=(ROOT/'index.html').read_text(encoding='utf-8')
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists():
        styles.append(p.read_text(encoding='utf-8'))
        idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
    p=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')

app=(ROOT/'app.js').read_text(encoding='utf-8')
v392=(ROOT/'v392-bj02-semantic-hardening.js').read_text(encoding='utf-8')
bj=(PKG/'specs/themes/theme-07/srs/02-business-journeys/02-BJ-02-nhan-hang-mua.md').read_text(encoding='utf-8')
ucdir=PKG/'specs/themes/theme-07/srs/05-use-cases/BJ-02-nhan-hang-mua'
ucs='\n'.join(x.read_text(encoding='utf-8') for x in sorted(ucdir.glob('*.md')))
bc=(PKG/'specs/themes/theme-07/srs/06-shared-behavioral-contracts.md').read_text(encoding='utf-8')
data=(PKG/'specs/themes/theme-07/srs/04-data-entities.md').read_text(encoding='utf-8')
dec=(PKG/'specs/themes/theme-07/know-how/decisions/decision-register.md').read_text(encoding='utf-8')
flow=(PKG/'specs/themes/theme-07/prototype/flows/UIF-02-BJ-02.md').read_text(encoding='utf-8')
reg=json.loads((PKG/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf-8'))
wb=json.loads((ROOT/'workbench-data.json').read_text(encoding='utf-8'))

checks=[]; errors=[]; shots=[]
def ck(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
def shot(p,name,label):
    p.locator('#device-preview').screenshot(path=str(CAP/name)); shots.append({'file':name,'label':label})
def goto(p,screen,state='READY',mode='document'):
    p.evaluate('''([screen,state,mode])=>{activeFlowId='UIF-02';flowMode=mode;resetBj02Receipt(mode);activeScreenId=screen;stateByScreen[screen]=state;render();}''',[screen,state,mode])

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1080}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)

    ck('Runtime package identifies v3.9.2','v3.9.2' in idx)

    # Capability-aware entry.
    goto(p,'SCR-006','READY','document')
    ck('Quick entry is visible when capability exists',p.locator('[data-flow="quick"]').count()==1)
    p.evaluate("()=>{window.VET45_BJ02_V392.capabilities.quickReceipt=false;render();}")
    ck('Quick entry is hidden without capability',p.locator('[data-flow="quick"]').count()==0)
    p.evaluate("()=>{window.VET45_BJ02_V392.capabilities.quickReceipt=true;window.VET45_BJ02_V392.quickBlocker='Thiếu cấu hình nhận nhanh';render();}")
    q=p.locator('[data-flow="quick"]')
    ck('Temporary Quick blocker keeps a disabled Navigation Row',q.count()==1 and q.is_disabled() and 'Thiếu cấu hình nhận nhanh' in q.inner_text())
    p.evaluate("()=>{window.VET45_BJ02_V392.quickBlocker=null;render();}")

    # Quick header semantic surface.
    goto(p,'SCR-008','READY','quick')
    txt=p.locator('#app-screen').inner_text()
    ck('Quick uses read-only warehouse/date facts',p.locator('[data-ds-component="VTextField"] input[readonly]').count()>=2 and 'Kho nhận' in txt and 'Ngày nhận' in txt)
    ck('Quick does not expose a date picker or generic note',p.locator('[data-ds-component="VDatePicker"]').count()==0 and p.locator('textarea').count()==0)
    file_input=p.locator('[data-bj02-evidence-file]')
    ck('Delivery evidence accepts multiple refs without BJ02 hard-coded accept list',file_input.get_attribute('multiple') is not None and file_input.get_attribute('accept') is None)
    ck('Delivery evidence wording is business-oriented','Chứng từ giao nhận' in txt and 'DOCX' not in txt and '10 MB' not in txt,txt)
    p.locator('[data-bj02-open-supplier-sheet]').click()
    sheet=p.locator('.bj02-select-sheet').inner_text()
    ck('Supplier picker identifies Supplier by name + code without phone','NCC-0018' in sheet and not re.search(r'\b0\d{8,10}\b',sheet),sheet)
    p.locator('[data-bj02-supplier-option="SUP-MINH-DUNG"]').click()
    with tempfile.NamedTemporaryFile(suffix='.pdf',delete=False) as f:
        f.write(b'prototype evidence'); evidence_file=f.name
    file_input=p.locator('[data-bj02-evidence-file]'); file_input.set_input_files(evidence_file)
    ck('Quick continue becomes enabled only after Supplier + evidence',not p.locator('[data-v392-quick-continue]').is_disabled())
    shot(p,'01-SCR008-QUICK-EVIDENCE-OWNERSHIP.png','Quick receipt uses server-owned context, delivery evidence and ownership assertion')
    p.locator('[data-v392-quick-continue]').click()
    assertion=p.evaluate('()=>bj02Header.ownershipAssertion')
    ck('Quick continue creates structured ownership assertion',assertion and assertion.get('status')=='ASSERTED' and (assertion.get('version') or assertion.get('assertionVersion')) and (assertion.get('evidenceRefs') or assertion.get('evidence_refs')),assertion)
    ck('Quick continues to actual receipt items after assertion',p.evaluate('()=>activeScreenId')=='SCR-009')

    # Quantity semantics / base-UOM over-source.
    p.evaluate('''()=>{flowMode='document';selectedDocumentId='PN-260816-04';resetBj02Receipt('document');const l=bj02Lines[0];l.status='COMPLETED';l.lots=[{id:'T1',code:'N1',expiry:'09/2027',expiryPrecision:'MONTH',manufactureDate:'',manufacturePrecision:'DAY',accepted:118,quarantine:5,damaged:0,rejected:0,totalReceived:123}];activeScreenId='SCR-010';stateByScreen['SCR-010']='READY';render();}''')
    vals=p.evaluate('''()=>{const l=bj02Lines[0];return {acceptedBase:lineAcceptedBase(l),allowanceBase:documentLineAllowanceBase(l),approval:bj02RequiresApproval(),feedback:documentVarianceFeedback(l)}}''')
    ck('Over-source uses accepted physical, not only Đạt',vals['approval'] and vals['acceptedBase']==1230 and vals['allowanceBase']==1200 and 'vượt' in vals['feedback'].lower(),vals)
    txt=p.locator('#app-screen').inner_text()
    ck('Review does not present a cross-UOM numeric aggregate','đơn vị giao dịch' not in txt and 'Mặt hàng đã xử lý' in txt and 'Dòng nhận hàng' in txt,txt[:900])
    shot(p,'02-SCR010-ACCEPTED-PHYSICAL-OVER-SOURCE.png','Review routes over-source from accepted physical base quantity')

    # Rejected quantity does not enter inventory or trigger over-source by itself.
    vals=p.evaluate('''()=>{const l=bj02Lines[0];l.lots=[{id:'T2',code:'N1',expiry:'09/2027',expiryPrecision:'MONTH',manufactureDate:'',manufacturePrecision:'DAY',accepted:118,quarantine:0,damaged:0,rejected:5,totalReceived:123}];return {acceptedBase:lineAcceptedBase(l),allowanceBase:documentLineAllowanceBase(l),approval:bj02RequiresApproval(),feedback:documentVarianceFeedback(l)}}''')
    ck('Rejected quantity does not increase accepted physical or over-source',vals['acceptedBase']==1180 and vals['allowanceBase']==1200 and not vals['approval'],vals)

    # Risk normalization.
    risk=p.evaluate('''()=>{flowMode='quick';resetBj02Receipt('quick');const l=hydrateReceiptLine({id:'Q1',productId:'P-NOB-DHPP',uomId:'UOM-BOX',uom:'hộp',trackingPolicy:'NONE',accepted:2,quarantine:0,damaged:0,rejected:0,status:'COMPLETED',conversionRatioSnapshot:10,priceBasisSnapshot:productById('P-NOB-DHPP').priceBasisSnapshot});bj02Lines=[l];return {base:lineAcceptedBase(l),risk:receiptRiskValue()};}''')
    ck('Approval risk normalizes accepted physical to base UOM',risk['base']==20 and risk['risk']==170000,risk)

    # LOT precision and rejected helper.
    p.evaluate("()=>{flowMode='document';selectedDocumentId='PN-260816-04';resetBj02Receipt('document');beginLineEditor('DOC-04-01');activeScreenId='SCR-084';stateByScreen['SCR-084']='READY';lineEditorDraft.lots[0].rejected=2;lineEditorDraft.lots[0].totalReceived=2;render();}")
    txt=p.locator('#app-screen').inner_text()
    ck('LOT editor exposes DAY/MONTH/YEAR precision',p.locator('[data-v392-lot-precision]').count()>=1 and all(x in txt for x in ['Ngày / tháng / năm','Tháng / năm','Năm']))
    ck('Rejected quantity explicitly says it does not enter inventory','2 hộp từ chối · không vào tồn' in txt,txt[-1000:])
    ck('Derived summary says Tổng kiểm nhận, not Tổng thực nhận','Tổng kiểm nhận' in txt and 'Tổng thực nhận' not in txt)
    shot(p,'03-SCR084-LOT-PRECISION-QUANTITY.png','One-line editor preserves LOT date precision and quantity semantics')

    # Explicit source change confirmation.
    p.evaluate("()=>{flowMode='document';selectedDocumentId='PN-260816-04';resetBj02Receipt('document');bj02Lines.forEach((x,i)=>{x.status='COMPLETED';x.accepted=1;x.totalReceived=1;if(x.trackingPolicy==='LOT'){x.lots=[emptyLot('L'+i)];x.lots[0].code='LOT-'+i;x.lots[0].accepted=1;x.lots[0].totalReceived=1;}});activeScreenId='SCR-010';stateByScreen['SCR-010']='READY';render();}")
    p.locator('[data-v392-change-source]').click()
    dialog=p.locator('.confirm-dialog').inner_text()
    ck('Changing document after item data requires explicit destructive confirmation','Đổi chứng từ sẽ xóa dữ liệu nhận hàng đang nhập' in dialog and p.locator('[data-v392-confirm-source-change]').count()==1,dialog)
    shot(p,'04-SCR010-CHANGE-SOURCE-CONFIRM.png','Changing source is explicit and resets the draft safely')
    p.locator('button[data-v392-cancel-source-change]').click()

    # Approval has evidence, submission identity, aggregate risk.
    p.evaluate('''()=>{flowMode='quick';bj02Header={supplierId:'SUP-MINH-DUNG',supplier:'Minh Dũng',businessDate:'2026-09-16',evidence:'bien-ban.pdf',evidenceRefs:[{id:'EV-1',name:'bien-ban.pdf',type:'DELIVERY_DOCUMENT'}],ownershipAssertion:{status:'ASSERTED',version:'OWN-v1',evidenceRefs:['EV-1']}};bj02Lines=[hydrateReceiptLine({id:'Q1',productId:'P-AMX-LA',uomId:'UOM-BOTTLE',uom:'chai',trackingPolicy:'NONE',accepted:3,quarantine:0,damaged:0,rejected:0,status:'COMPLETED',conversionRatioSnapshot:1,priceBasisSnapshot:productById('P-AMX-LA').priceBasisSnapshot})];activeScreenId='SCR-011';stateByScreen['SCR-011']='APPROVAL_REQUIRED';render();}''')
    txt=p.locator('#app-screen').inner_text()
    ck('Approver sees sender and submitted_at',all(x in txt for x in ['Người gửi','Nguyễn Văn An','Gửi lúc']))
    ck('Approver sees aggregate risk total, not unit-cost details','Tổng giá trị rủi ro' in txt and '360.000' in txt and 'Price basis' not in txt,txt[:1200])
    ck('Approver can preview immutable delivery evidence',p.locator('[data-v392-open-evidence]').count()==1)
    p.locator('[data-v392-open-evidence]').click(); ev=p.locator('.v392-evidence-sheet').inner_text()
    ck('Evidence preview names the delivery document','bien-ban.pdf' in ev and 'Chứng từ giao nhận' in ev,ev)
    shot(p,'05-SCR011-APPROVAL-EVIDENCE-RISK.png','Approver has previewable evidence, sender/submitted_at and aggregate risk')
    p.locator('[data-v392-close-evidence]').last.click()

    # Zero accepted physical guard for Quick.
    p.evaluate('''()=>{flowMode='quick';bj02Header={supplierId:'SUP-MINH-DUNG',supplier:'Minh Dũng',businessDate:'2026-09-16',evidence:'bien-ban.pdf',evidenceRefs:[{id:'EV-1',name:'bien-ban.pdf',type:'DELIVERY_DOCUMENT'}],ownershipAssertion:{status:'ASSERTED',version:'OWN-v1',evidenceRefs:['EV-1']}};bj02Lines=[hydrateReceiptLine({id:'Q1',productId:'P-AMX-LA',uomId:'UOM-BOTTLE',uom:'chai',trackingPolicy:'NONE',accepted:0,quarantine:0,damaged:0,rejected:2,status:'COMPLETED',conversionRatioSnapshot:1,priceBasisSnapshot:productById('P-AMX-LA').priceBasisSnapshot})];activeScreenId='SCR-010';stateByScreen['SCR-010']='READY';render();}''')
    txt=p.locator('#app-screen').inner_text()
    ck('Quick zero accepted physical is blocked','Chưa có hàng vào tồn' in txt and p.locator('footer .button--primary').is_disabled(),txt[:900])

    # Document zero-impact result semantics.
    p.evaluate("()=>{flowMode='document';selectedDocumentId='PN-260816-04';resetBj02Receipt('document');bj02Lines.forEach(x=>{x.status='NOT_RECEIVED';x.accepted=x.quarantine=x.damaged=x.rejected=x.totalReceived=0;x.lots=[];});activeScreenId='SCR-012';stateByScreen['SCR-012']='COMPLETED';render();}")
    txt=p.locator('#app-screen').inner_text()
    ck('Document zero-impact result does not claim stock increased','Đã ghi nhận kết quả lần nhận' in txt and 'Không có hàng vào tồn vật lý' in txt,txt[:700])

    # UNKNOWN explicit verification and evidence-backed recovery.
    p.evaluate("()=>{activeScreenId='SCR-012';stateByScreen['SCR-012']='UNKNOWN';render();}")
    ck('UNKNOWN offers verification, not retry',p.locator('[data-v350-action="bj02-verify-unknown"]').count()==1 and 'thực hiện lại' in p.locator('#app-screen').inner_text())
    p.locator('[data-v350-action="bj02-verify-unknown"]').click()
    ck('UNKNOWN verification enters SCR-013 with same flow identity',p.evaluate('()=>activeScreenId')=='SCR-013' and p.evaluate('()=>activeFlowId')=='UIF-02')
    txt=p.locator('#app-screen').inner_text()
    ck('Uncertain recovery does not fabricate committed movement','Chưa có bằng chứng xác nhận biến động tồn kho đã được ghi' in txt and 'Biến động tồn kho đã được ghi' not in txt,txt[-1200:])
    shot(p,'06-SCR013-AUTHORITATIVE-RECOVERY.png','Recovery only shows evidence proven for the same receipt operation')

    # Representative geometry.
    overflow=p.evaluate("()=>{const el=document.querySelector('.phone-screen')||document.querySelector('#app-screen');return {sw:el.scrollWidth,cw:el.clientWidth}}"); ck('Representative BJ02 runtime has no horizontal overflow',overflow['sw']<=overflow['cw']+1,overflow)
    ck('BJ02 active Product UI has no known English leakage',all(x not in p.locator('#app-screen').inner_text() for x in ['Preview','source-version','movement authoritative']))
    ck('No browser errors',not errors,errors)
    b.close()

# Static contract checks.
ck('Decision register carries continuous BJ02 semantic locks 116-121',all(f'T7-DR-{n}' in dec for n in range(116,122)))
ck('T7-DR-024 no longer says only Đạt enters inventory','Vào tồn vật lý = Đạt + Cách ly + Hỏng' in dec and 'Theme 7 chỉ ghi nhận lượng đạt' not in dec)
ck('Shared Attachment Policy owns technical file constraints','Shared Attachment Evidence Contract v3.9.2' in bc and 'UI không tự tạo danh sách file extension/size/count' in bc)
ck('Data contract includes source remainder, ownership and LOT precision',all(x in data for x in ['remaining_receivable_qty_snapshot','ownership_assertion_snapshot','precision: DAY|MONTH|YEAR']))
ck('BJ02 business doc defines delivery evidence without hard-coded technical limits','Chứng từ giao nhận' in bj and 'Shared Attachment Policy' in bj)
ck('Active BJ02 UCs encode tenant business date and ownership/evidence guards','tenant business date' in ucs and 'ownership_assertion' in ucs and 'remaining_receivable_qty' in ucs)
ck('UIF-02 defines both derived quantity semantics','Tổng kiểm nhận = Đạt + Cách ly + Hỏng + Từ chối' in flow and 'Vào tồn vật lý = Đạt + Cách ly + Hỏng' in flow)
ck('Runtime source has no sourceExpected or priceBasisVnd assumptions','sourceExpected' not in app and 'priceBasisVnd' not in app)
ck('v3.9.2 runtime removes hard-coded DOCX/10MB UI assumptions','DOCX' not in v392 and '10 MB' not in v392)
ck('Registry/workbench identify v3.9.2 semantic baseline',reg.get('version')=='3.9.2' and wb.get('version')=='3.9.2')
for sid in ['SCR-006','SCR-007','SCR-008','SCR-009','SCR-084','SCR-010','SCR-011','SCR-012','SCR-013']:
    rr=next(x for x in reg['screens'] if x['id']==sid)
    ck(f'{sid} carries v3.9.2 deep-review trace',rr.get('deep_review',{}).get('version')=='3.9.2')

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':'3.9.2','scope':'Wave 2 / BJ02 deep review','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors,'captures':shots}
(QA/'BJ02-DEEP-REVIEW-QA-v3.9.2.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ02 Deep Review QA — v3.9.2','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','', 'Scope: approved Wave 2 / BJ02 semantic hardening and fresh-eye runtime verification.','']
lines += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if x['note'] not in ('',None) and len(str(x['note']))<170 else '') for x in checks]
lines += ['', '## Captures','']+[f'- `{x["file"]}` — {x["label"]}' for x in shots]
(QA/'BJ02-DEEP-REVIEW-QA-v3.9.2.md').write_text('\n'.join(lines)+'\n')
(CAP/'manifest.json').write_text(json.dumps(shots,ensure_ascii=False,indent=2)+'\n')
print(status,res['passed'],res['total'],'errors',len(errors),'captures',len(shots))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
    raise SystemExit(1)
