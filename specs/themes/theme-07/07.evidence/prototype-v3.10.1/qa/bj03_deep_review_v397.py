#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]
QA=Path(__file__).resolve().parent
PKG=Path(__file__).resolve().parents[6]
CAP=QA/'v397-bj03-captures'; CAP.mkdir(exist_ok=True)

def read(rel): return (PKG/rel).read_text(encoding='utf-8')
def jread(rel): return json.loads((PKG/rel).read_text(encoding='utf-8'))
def find_id(o,target):
    if isinstance(o,dict):
        if o.get('id')==target:return o
        for v in o.values():
            r=find_id(v,target)
            if r:return r
    elif isinstance(o,list):
        for v in o:
            r=find_id(v,target)
            if r:return r
    return None

def inline_html():
    h=(ROOT/'index.html').read_text(encoding='utf-8')
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
        p=ROOT/fn.split('?')[0]
        h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text(encoding="utf-8")}</style>' if p.exists() else '',h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
        p=ROOT/fn.split('?')[0]
        h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')
    return h

checks=[]; errors=[]; console_errors=[]; shots=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':note})
def shot(p,name,label):
    p.locator('#device-preview').screenshot(path=str(CAP/name)); shots.append({'file':name,'label':label})

# ---------- Static semantic / traceability ----------
bj=read('specs/themes/theme-07/srs/02-business-journeys/03-BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan.md')
bc=read('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md')
data=read('specs/themes/theme-07/srs/04-data-entities.md')
tech=read('specs/themes/theme-07/srs/07-technical-contracts.md')
dec=read('specs/themes/theme-07/know-how/decisions/decision-register.md')
flow=read('specs/themes/theme-07/prototype/flows/UIF-03-BJ-03.md')
s14=read('specs/themes/theme-07/prototype/contracts/screens/SCR-014.md')
s15=read('specs/themes/theme-07/prototype/contracts/screens/SCR-015.md')
s16=read('specs/themes/theme-07/prototype/contracts/screens/SCR-016.md')
s17=read('specs/themes/theme-07/prototype/contracts/screens/SCR-017.md')
s19=read('specs/themes/theme-07/prototype/contracts/screens/SCR-019.md')
uc1=read('specs/themes/theme-07/srs/05-use-cases/BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan/UC-03-01-chon-pham-vi-can-dinh-gia.md')
uc2=read('specs/themes/theme-07/srs/05-use-cases/BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan/UC-03-02-xac-dinh-gia-nhap-thuc-te.md')
uc3=read('specs/themes/theme-07/srs/05-use-cases/BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan/UC-03-03-xac-nhan-gia-tri.md')
reg=jread('specs/themes/theme-07/prototype/contracts/screen-registry.json')
wb=jread('specs/themes/theme-07/prototype/html/workbench-data.json')
acts=jread('specs/themes/theme-07/prototype/contracts/action-registry.json')
contracts=jread('specs/themes/theme-07/harness/contract-registry.json')
manifest=jread('specs/themes/theme-07/prototype/html/manifest.json')

ck('Approved BJ03 decisions T7-DR-150..156 are registered',all(f'T7-DR-{i}' in dec for i in range(150,157)))
ck('Decision register identifies direct valuation amendment v4.2.2','DIRECT_VALUATION_DEEP_REVIEW_AMENDMENT' in dec and 'v4.2.2' in dec)
ck('Valuation basis is anchored to receipt item/commercial source line','valuation_basis_key' in bj and 'receipt_item_ref' in bj and 'không tự động dùng chung' in bj)
ck('Complete DirectCostBasis contains component provenance','DirectCostBasis' in bj and all(x in bj for x in ['discount','VAT','FX']))
ck('Exact valuation scope remains technical line/LOT/state/quantity','technical' in bj.lower() and 'LOT/non-LOT' in bj and 'physical state' in bj)
ck('Transaction UOM and base-UOM normalization are explicit in data model',all(x in data for x in ['transaction_uom_id','transaction_uom_snapshot','conversion_to_base','conversion_version','confirmed_base_quantity']))
ck('Direct cost stores both transaction-UOM and base-UOM unit cost',all(x in data for x in ['confirmed_direct_unit_cost_transaction','normalized_direct_unit_cost_base']))
ck('OfficialCostVersion is VND per base UOM','`unit_cost`' in data and '**VND / base UOM**' in data and 'base_uom_id' in data and 'base_uom_version' in data)
ck('ReceiptValuation persists complete basis identity/version/hash/snapshot',all(x in data for x in ['valuation_basis_key','basis_version','basis_hash','direct_cost_basis_snapshot']))
ck('ReceiptValuation persists authoritative allocated value and cumulative value',all(x in data for x in ['confirmed_value_amount','cumulative_scope_value_after']))
ck('Evidence hash binds complete basis, not one filename/document','evidence_hash' in data and 'complete DirectCostBasis' in data)
ck('Partial allocation/rounding cumulative semantics are explicit','cumulative' in bj.lower() and 'không phụ thuộc cách chia' in bj.lower())
ck('BC-IV-01 rechecks selected basis and scope tokens',all(x in bc for x in ['basis_version','basis_hash','scope_version']))
ck('BC-IV-01 writes receipt-business-date value movement','business_date=receipt_business_date' in bc and 'recorded_at=commit time' in bc)
ck('BC-IV-05 is non-mutating complete-basis preview','BC-IV-05' in bc and 'candidate `DirectCostBasis`' in bc and ('không mutation' in bc.lower() or 'read-only' in bc.lower()))
ck('Technical API-Q-11 returns basis/scope freshness tokens',all(x in tech for x in ['valuation_basis_key/basis_version/basis_hash/scope_version/calculation_hash','API-Q-11']))
ck('Technical confirm does not trust client unit-cost multiplication','không tin client `unit_cost × quantity`' in tech)
ck('Initial Official Cost bootstrap is compare-and-create atomic','compare-and-create' in data and 'ALREADY_INITIALIZED' in data)
ck('Initial Official Cost effective_from is winning server commit time','effective_from' in data and 'server commit time' in data)
ck('Direct value movement uses receipt period and blocks silent locked-period back-post','receipt_business_date` của receipt source' in data and 'không back-post âm thầm' in data)
ck('Late components route to BJ13 rather than rewriting confirmed receipt valuation','BJ13' in bj and 'không rewrite' in bj.lower())
ck('UC03-01 preview/query does not use business UNKNOWN','không có business `UNKNOWN`' in uc1)
ck('UC03-02 preview/query does not use business UNKNOWN','không có business `UNKNOWN`' in uc2)
ck('UC03-03 owns final mutation/finality','BC-IV-01' in uc3 and 'API-C-20' in uc3)
ck('SCR-016 is retired from active flow','không thuộc active' in flow.lower() and 'SCR-016' in flow)
ck('SCR-015 contract separates presentation group from valuation basis','valuation basis/source item' in s15 and 'Product+transaction UOM' in s15)
ck('SCR-017 shows transaction cost and normalized base consequence','transaction UOM' in s17 and 'base-UOM' in s17)
ck('SCR-017 explicitly removes normal READY badge','badge “Sẵn sàng”' in s17)
ck('SCR-019 is command-authoritative result surface','authoritative' in s19.lower() and 'Ngày nghiệp vụ' in s19 and 'Ghi nhận lúc' in s19)
ck('Registry removes active UC mapping from historical SCR-016',find_id(reg,'SCR-016')['related_use_cases']==[],find_id(reg,'SCR-016')['related_use_cases'])
ck('Workbench removes historical SCR-016 from UIF active mapping',find_id(wb,'SCR-016')['uifs']==[] and find_id(wb,'SCR-016')['uc']==[],find_id(wb,'SCR-016'))
ck('Action registry binds confirm to basis/scope recheck','basis_version/basis_hash' in find_id(acts,'ACT-03-CONFIRM-COST')['confirmation'])
ck('Harness includes BC-IV-05 preview contract',find_id(contracts,'BC-IV-05') is not None)
ck('Harness includes API-Q-11 preview operation',find_id(contracts,'API-Q-11') is not None)
ck('Harness BC-IV-01 mutation story is UC-03-03 only',find_id(contracts,'BC-IV-01')['stories']==['UC-03-03'],find_id(contracts,'BC-IV-01')['stories'])
ck('Current manifest identifies v3.9.7 BJ03 hardening',manifest.get('version')=='3.9.7' and manifest.get('parentVersion')=='3.9.6' and manifest.get('productApproval')=='BJ03_DEEP_REVIEW_QA_v3.9.7')

# ---------- Runtime / UX ----------
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1080})
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.on('console',lambda m: console_errors.append(m.text) if m.type=='error' else None)
    p.set_default_timeout(8000); p.set_content(inline_html(),wait_until='load',timeout=30000)
    ck('Runtime identifies v3.9.7',p.evaluate('window.__VET45_PROTOTYPE__.version')=='3.9.7')
    ck('v3.9.7 BJ03 trace helper is loaded',p.evaluate('typeof window.val03V397')=='object')

    # Worklist mixed state: R4 has one actionable + one waiting basis and must remain actionable.
    p.evaluate("()=>{activeFlowId='UIF-03';activeScreenId='SCR-014';stateByScreen['SCR-014']='READY';render();}")
    row=p.locator('[data-val03-receipt="VAL03-R4"]')
    ck('Mixed actionable/waiting receipt remains actionable',row.count()==1 and not row.is_disabled() and 'Có thể xử lý' in row.inner_text(),row.inner_text() if row.count() else 'missing')
    shot(p,'01-SCR014-WORKLIST.png','BJ03 worklist — receipt with mixed basis state stays actionable')

    # Scope hierarchy and complete basis evidence.
    p.evaluate("()=>{val03SelectedReceiptId='VAL03-R1';activeScreenId='SCR-015';stateByScreen['SCR-015']='READY';render();}")
    txt=p.locator('#app-screen').inner_text()
    ck('Scope screen uses Product/UOM hierarchy and exact LOT/state children','Nobivac DHPPi' in txt and 'SP-00142 · hộp' in txt and 'Lô DH2507' in txt and 'Đủ điều kiện bán · Chờ giá 50 hộp' in txt,txt[:1200])
    ck('Scope screen labels conflict as business evidence issue','Cần đối chiếu' in txt and 'Amoxicillin LA' in txt,txt[:1200])
    p.locator('[data-val03-slice="VAL03-S1"]').click()
    p.locator('[data-val03-action="open-evidence-sheet"]').first.click()
    sheet=p.locator('.val03-evidence-sheet').inner_text()
    ck('Evidence sheet presents complete basis rather than one raw document','Căn cứ giá và cách tính' in sheet and 'Thành phần của căn cứ' in sheet and 'Chiết khấu phiếu đã phân bổ' in sheet and 'Chi phí mua đã có' in sheet,sheet[:1800])
    ck('Evidence sheet exposes transaction-UOM and base-UOM consequence','81.700 đ/hộp' in sheet and '8.170 đ/lọ' in sheet,sheet[:1600])
    shot(p,'02-SCR015-DIRECT-COST-BASIS.png','BJ03 contextual DirectCostBasis/provenance sheet')
    p.locator('[data-val03-action="close-evidence-sheet"]').last.click()
    p.locator('[data-val03-action="open-review"]').click()
    review=p.locator('#app-screen').inner_text()
    ck('Review shows transaction unit cost and normalized base consequence','Giá nhập thực tế' in review and '81.700 đ/hộp' in review and 'Quy đổi lọ' in review and '8.170 đ/lọ' in review,review[:1600])
    ck('Review does not use normal-state Sẵn sàng badge','Sẵn sàng' not in review,review[:1600])
    ck('Review names complete basis as Căn cứ giá','Căn cứ giá' in review and 'Căn cứ tổng hợp PO-2608-041' in review,review[:1500])
    shot(p,'03-SCR017-REVIEW.png','BJ03 review — transaction and normalized base cost without normal READY badge')

    # Financial masking: protected values must not exist in DOM.
    p.evaluate("()=>{stateByScreen['SCR-017']='FINANCIAL_MASKED';render();}")
    masked=p.locator('#app-screen').inner_text()
    ck('Financial masked review contains no protected price/value facts','81.700' not in masked and '8.170' not in masked and '4.085.000' not in masked and 'không có quyền' in masked.lower(),masked[:900])

    # Conflict: no preselection and reason required before review.
    p.goto('about:blank')
    p.set_content(inline_html(),wait_until='load',timeout=30000)
    p.evaluate("()=>{activeFlowId='UIF-03';val03SelectedReceiptId='VAL03-R1';activeScreenId='SCR-015';stateByScreen['SCR-015']='READY';render();}")
    p.locator('[data-val03-slice="VAL03-S4"]').click(); p.locator('[data-val03-action="open-evidence-sheet"]').last.click()
    opts=p.locator('[data-val03-source="VAL03-G2"]')
    ck('Conflicting complete bases are not preselected',opts.count()==2 and p.locator('[data-val03-source="VAL03-G2"][aria-pressed="true"]').count()==0)
    ck('Conflict resolution requires explicit complete-basis choice and reason',p.locator('[data-val03-reason="VAL03-G2"]').count()==1 and p.locator('[data-val03-action="close-evidence-sheet"]').last.is_disabled())
    opts.nth(0).click(); p.fill('[data-val03-reason="VAL03-G2"]','Theo đơn mua đã duyệt')
    ck('Conflict can proceed only after basis choice + reason',not p.locator('[data-val03-action="close-evidence-sheet"]').last.is_disabled())
    p.locator('[data-val03-action="close-evidence-sheet"]').last.click(); p.locator('[data-val03-action="open-review"]').click()
    p.evaluate('()=>val03ApplySourceUpdate("VAL03-G2",122000)')
    p.locator('[data-val03-action="confirm-value"]').click()
    stale=p.locator('#app-screen').inner_text()
    ck('Selected basis change rejects stale review before mutation',p.evaluate("stateByScreen['SCR-017']")=='SOURCE_CHANGED' and 'đã thay đổi' in stale.lower() and p.evaluate('activeScreenId')=='SCR-017',stale[:1200])
    ck('Stale selected basis does not navigate to result',p.evaluate('activeScreenId')!='SCR-019')
    shot(p,'04-SCR017-STALE-BASIS.png','BJ03 stale basis — selected-set confirmation blocked before mutation')

    # Deterministic cumulative allocation helper.
    cumulative=p.evaluate('''()=>{const g=val03Receipts[0].groups[0],s=g.slices[0];const save={oq:s.originalQty,cq:s.confirmedQty,cv:s.confirmedValue,av:s.scopeAllocatedValue};s.originalQty=3;s.confirmedQty=0;s.confirmedValue=0;s.scopeAllocatedValue=100;const a=val03V397.confirmationAmount(g,s,1);s.confirmedQty=1;s.confirmedValue=a;const b=val03V397.confirmationAmount(g,s,1);s.confirmedQty=2;s.confirmedValue=a+b;const c=val03V397.confirmationAmount(g,s,1);Object.assign(s,{originalQty:save.oq,confirmedQty:save.cq,confirmedValue:save.cv});if(save.av===undefined)delete s.scopeAllocatedValue;else s.scopeAllocatedValue=save.av;return [a,b,c,a+b+c];}''')
    ck('Cumulative partial allocation closes exactly to authoritative scope value',cumulative[3]==100 and all(x>0 for x in cumulative[:3]),cumulative)

    # Initial Official Cost bootstrap result with business/recorded time.
    p.goto('about:blank')
    p.set_content(inline_html(),wait_until='load',timeout=30000)
    p.evaluate("()=>{activeFlowId='UIF-03';val03SelectedReceiptId='VAL03-R3';activeScreenId='SCR-015';stateByScreen['SCR-015']='READY';render();}")
    p.locator('[data-val03-slice="VAL03-S6"]').click(); p.locator('[data-val03-action="open-review"]').click()
    r3review=p.locator('#app-screen').inner_text()
    ck('First-cost review states exact Official Cost bootstrap consequence','Đơn giá chính thức khởi tạo' in r3review and '100.245 đ/lọ' in r3review,r3review[:1500])
    p.locator('[data-val03-action="confirm-value"]').click()
    result=p.locator('#app-screen').inner_text()
    ck('Completed result uses original receipt business date','Ngày nghiệp vụ' in result and '01/09/2026' in result,result[:1700])
    ck('Completed result separately shows server recorded time','Ghi nhận lúc' in result and '16/09/2026 16:25' in result,result[:1700])
    ck('Completed result reports Official Cost bootstrap in base UOM','Đơn giá chính thức' in result and 'Đã khởi tạo' in result and '100.245 đ/lọ' in result,result[:1800])
    ck('Completed result shows command-authoritative committed value','Giá trị đã ghi' in result and '1.002.450 đ' in result,result[:1800])
    shot(p,'05-SCR019-AUTHORITATIVE-RESULT.png','BJ03 authoritative result — business date, recorded time and Official Cost bootstrap')

    # Active flow excludes SCR-016.
    route=p.evaluate("flowCatalog.find(x=>x.id==='UIF-03').screens")
    ck('Runtime active UIF03 route excludes historical SCR-016','SCR-016' not in route,route)
    ck('Focused BJ03 browser has no page errors',not errors,errors)
    ck('Focused BJ03 browser has no console errors',not console_errors,console_errors)
    b.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.9.7','scope':'Wave 3 / BJ03 deep-review direct valuation semantic hardening','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors,'consoleErrors':console_errors,'captures':shots}
(QA/'BJ03-DEEP-REVIEW-QA-v3.9.7.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=['# BJ03 Deep Review QA — v3.9.7','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','', 'Scope: approved D03-01..D03-07 / T7-DR-150..156, DirectCostBasis semantics, transaction/base-UOM normalization, deterministic cumulative allocation, basis/scope freshness, Official Cost bootstrap and accounting-time boundaries.','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': `{x["note"]}`' if (not x['pass'] and x['note']!='') else '') for x in checks]
md += ['', '## Visual captures'] + [f'- `{x["file"]}` — {x["label"]}' for x in shots]
(QA/'BJ03-DEEP-REVIEW-QA-v3.9.7.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,out['passed'],out['total'],'browserErrors',len(errors),'consoleErrors',len(console_errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
