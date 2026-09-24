#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]
QA=Path(__file__).resolve().parent
PKG=Path(__file__).resolve().parents[6]
CAP=QA/'v396-bj04-captures'; CAP.mkdir(exist_ok=True)

def read(rel): return (PKG/rel).read_text(encoding='utf-8')
def jread(rel): return json.loads((PKG/rel).read_text(encoding='utf-8'))

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

# ---------- Static semantic/contract checks ----------
bj=read('specs/themes/theme-07/srs/02-business-journeys/04-BJ-04-quan-ly-vong-doi-giu-hang.md')
bc=read('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md')
data=read('specs/themes/theme-07/srs/04-data-entities.md')
tech=read('specs/themes/theme-07/srs/07-technical-contracts.md')
dec=read('specs/themes/theme-07/know-how/decisions/decision-register.md')
flow=read('specs/themes/theme-07/prototype/flows/UIF-04-BJ-04.md')
scr=read('specs/themes/theme-07/prototype/contracts/screens/SCR-021.md')
uc05=read('specs/themes/theme-07/srs/05-use-cases/BJ-05-lay-hang-va-ban-giao-don/UC-05-04-phuc-hoi-allocation-stale.md')
reg=jread('specs/themes/theme-07/prototype/contracts/screen-registry.json')
wb=jread('specs/themes/theme-07/prototype/html/workbench-data.json')
contracts=jread('specs/themes/theme-07/harness/contract-registry.json')

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

ck('Approved BJ04 decisions T7-DR-144..149 are registered',all(f'T7-DR-{i}' in dec for i in range(144,150)))
ck('Reservation capability is explicit NONE/ALL_OR_NOTHING/PARTIAL_ALLOWED',all(x in bj for x in ['NONE','ALL_OR_NOTHING','PARTIAL_ALLOWED']))
ck('BJ04 capability is limited to Advanced Stock and Basic Stock does not create Theme7 reservation','ADVANCED' in bj and 'Basic Stock' in bj)
ck('Transaction UOM identity and conversion snapshot are preserved',all(x in data for x in ['transaction_uom_id','transaction_uom_snapshot','conversion_to_base','conversion_version']))
ck('Reservation requested quantity is stored in transaction and base semantics',all(x in data for x in ['requested_quantity','requested_base_quantity']))
ck('reserved_base_quantity is defined as current hold','reserved_base_quantity' in data and ('current held' in data.lower() or 'lượng hiện đang được giữ' in data.lower()))
ck('consumed_base_quantity preserves cumulative committed handover history','consumed_base_quantity' in data and ('cumulative' in data.lower() or 'cộng dồn' in data.lower()))
ck('Remaining-required and shortage formulas are explicit','remaining_required_base = max(0, requested_base_quantity - consumed_base_quantity)' in bj and 'shortage_base = max(0, remaining_required_base - reserved_base_quantity)' in bj)
ck('ReservationBucket counts current held amount only','ReservationBucket' in bj and ('current held' in bj.lower() or 'current hold' in bj.lower()))
ck('ALL_OR_NOTHING insufficient capacity leaves bucket unchanged','ALL_OR_NOTHING' in bj and ('bucket không đổi' in bj.lower() or 'ReservationBucket không đổi' in bj))
ck('Deterministic reservation priority is priority then source_confirmed_at then stable source_line_id',all(x in bj for x in ['reservation_priority','source_confirmed_at','source_line_id']))
ck('No automatic top-up after capacity returns','không auto top-up' in bj.lower() or 'không tự top-up' in bj.lower())
ck('Source expiry is source-owned with no implicit TTL','expires_at' in data and 'no implicit TTL' in data)
ck('ReservationGroup entity exists for combo atomicity','ENT-IO-13 — ReservationGroup' in data)
ck('Combo child reservations carry group identity','reservation_group_id' in data and 'source_component_id' in data)
ck('Combo partial reservation is rounded to complete combo quantity','combo' in bj.lower() and ('số nguyên' in bj.lower() or 'complete combo' in bj.lower()))
ck('BC-IO-06 is Adjust reservation capacity, not pick-allocation ownership','BC-IO-06' in bc and 'Adjust reservation capacity' in bc)
ck('BC-IO-06 does not own active PickAllocation mutation','allocation_review_required' in bc and ('không' in bc.lower() and 'pickallocation' in bc.lower()))
ck('UC05 stale-allocation recovery is owned by BC-IO-15','BC-IO-15' in uc05 and 'không trao ownership PickAllocation cho BC-IO-06' in uc05)
ck('Technical API-C-06 uses reservation adjustments endpoint','POST /v1/reservations/{id}/adjustments' in tech)
ck('Technical reservation event carries current held/consumed/shortage facts',all(x in tech for x in ['current_reserved','consumed','shortage']))
ck('SCR-021 contract rejects global FULL/PARTIAL/RELEASED/STALE lifecycle states',all(x in scr for x in ['READY','LOADING','PERMISSION_DENIED']) and 'Không dùng global state `FULL`, `PARTIAL`, `SHORT`, `RELEASED`, `STALE`' in scr)
ck('SCR-021 is contextual-only and read-only','contextual' in scr.lower() and 'read-only' in scr.lower())
ck('SCR-021 does not expose the static physical-vs-availability helper','Giữ hàng làm giảm khả dụng' not in scr)
ck('UIF-04 flow keeps current facts and per-line lifecycle semantics','current' in flow.lower() and 'source line' in flow.lower())
ck('Canonical registry has exactly three active BJ04 states',find_id(reg,'SCR-021')['states']==['READY','LOADING','PERMISSION_DENIED'],find_id(reg,'SCR-021')['states'])
ck('Workbench defaults BJ04 screen to READY',find_id(wb,'SCR-021')['defaultState']=='READY')
ck('Workbench includes UC-04-03 lifecycle release context','UC-04-03' in find_id(wb,'SCR-021')['uc'])
ck('Harness BC-IO-06 excludes UC-05-04',find_id(contracts,'BC-IO-06')['stories']==['UC-04-02','UC-04-03','UC-04-04'],find_id(contracts,'BC-IO-06')['stories'])
ck('Harness API-C-06 excludes UC-05-04 and uses adjustments endpoint',find_id(contracts,'API-C-06')['stories']==['UC-04-02','UC-04-03','UC-04-04'] and 'adjustments' in find_id(contracts,'API-C-06')['name'])

# ---------- Runtime/UI checks ----------
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1080})
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.on('console',lambda m: console_errors.append(m.text) if m.type=='error' else None)
    p.set_default_timeout(7000); p.set_content(inline_html(),wait_until='load',timeout=30000)
    ck('Runtime prototype identifies v3.9.6',p.evaluate('window.__VET45_PROTOTYPE__.version')=='3.9.6')
    p.evaluate("()=>{activeFlowId='UIF-04';activeScreenId='SCR-021';stateByScreen['SCR-021']='READY';render();}")
    txt=p.locator('#app-screen').inner_text()
    ck('BJ04 current projection shows order and warehouse context','SO-260827-18' in txt and 'Kho chính' in txt,txt[:700])
    ck('Consumed line reduces remaining requirement without rewriting consumed history','Cần giữ còn lại 16 hộp' in txt and 'Đang giữ 16 hộp' in txt,txt[:1400])
    ck('Short line shows current held and shortage facts','Cần giữ còn lại 50 hộp' in txt and 'Đang giữ 42 hộp' in txt and 'Thiếu 8 hộp' in txt,txt[:1400])
    ck('Combo line projects complete combo quantity instead of component internals','Bộ chăm sóc cơ bản' in txt and '3 bộ theo combo' in txt and 'Thiếu 1 bộ' in txt,txt[:1500])
    ck('Fully consumed line shows handover history and zero current hold','Đã bàn giao 6 chai' in txt and 'Không còn giữ' in txt,txt[:1500])
    ck('Current UI does not show historical global RELEASED copy','Cần trước đó' not in txt and 'Sản phẩm đã nhả' not in txt)
    ck('Current UI omits static domain helper','Giữ hàng làm giảm khả dụng' not in txt)
    ck('Current UI has no reservation mutation CTA',p.locator('#app-screen [data-io04-action],#app-screen [data-bj04-action]').count()==0)
    ck('Reservation rows are non-interactive status rows',p.locator('[data-v396-reservation-line]').count()==4 and p.locator('[data-v396-reservation-line][role="button"], [data-v396-reservation-line] button').count()==0)
    model=p.evaluate('''()=>io04V396.lines.map(x=>({id:x.id,uom:x.uomSnapshot,conversionVersion:x.conversionVersion,requested:x.requested,reserved:x.reserved,consumed:x.consumed,policy:x.policy,priority:x.priority,confirmedAt:x.confirmedAt,group:x.reservationGroupId||null,components:x.components||[]}))''')
    ck('Runtime fixtures preserve UOM snapshots and conversion versions',all(x['uom'] and x['conversionVersion'] for x in model),model)
    ck('Runtime fixtures separate current reserved from consumed quantity',model[0]['reserved']==16 and model[0]['consumed']==4 and model[3]['reserved']==0 and model[3]['consumed']==6,model)
    ck('Runtime fixtures carry deterministic priority inputs',all(x['priority'] is not None and x['confirmedAt'] for x in model),model)
    ck('Runtime combo fixture carries ReservationGroup and component definition',model[2]['group']=='RG-CB0007-01' and len(model[2]['components'])==2,model[2])
    shot(p,'01-SCR021-READY-CURRENT-PROJECTION.png','BJ04 READY — current reservation facts by source line, including combo and consumed history')

    # Legacy global business state should collapse to current READY presentation, because it is no longer part of the public state model.
    p.evaluate("()=>{stateByScreen['SCR-021']='RELEASED';render();}")
    txt_legacy=p.locator('#app-screen').inner_text()
    ck('Legacy global RELEASED state safely renders current facts rather than legacy released screen','Tình trạng giữ hàng' in txt_legacy and 'Sản phẩm đã nhả' not in txt_legacy,txt_legacy[:1000])

    # Source/current data can legitimately have no remaining hold at all.
    p.evaluate('''()=>{for(const l of io04V396.lines){l.consumed=l.requested;l.reserved=0;l.lifecycle='CONSUMED';}stateByScreen['SCR-021']='READY';render();}''')
    txt_zero=p.locator('#app-screen').inner_text()
    ck('All-terminal reservation projection shows concise no-current-hold information','Không còn hàng đang giữ cho đơn này.' in txt_zero,txt_zero[:1000])
    ck('All-terminal projection does not resurrect historical requested quantities as active needs','Cần giữ còn lại' not in txt_zero,txt_zero[:1200])
    shot(p,'02-SCR021-NO-CURRENT-HOLD.png','BJ04 all terminal — concise information instead of global RELEASED history dump')

    p.evaluate("()=>{stateByScreen['SCR-021']='LOADING';render();}")
    ck('BJ04 LOADING state uses canonical loading surface',p.locator('#app-screen [data-ds-component="VSkeleton"],#app-screen .skeleton').count()>0)
    p.evaluate("()=>{stateByScreen['SCR-021']='PERMISSION_DENIED';render();}")
    denied=p.locator('#app-screen').inner_text()
    ck('BJ04 permission state is non-mutating blocked surface','quyền' in denied.lower() and p.locator('#app-screen [data-io04-action],#app-screen [data-bj04-action]').count()==0,denied[:800])
    shot(p,'03-SCR021-PERMISSION-DENIED.png','BJ04 permission boundary')

    # Catalog remains contextual-only; no manual entry from warehouse function catalog.
    p.click('[data-workbench-mode="theme"]')
    p.wait_for_timeout(30)
    if p.locator('[data-theme-app-route="inventory"]').count(): p.locator('[data-theme-app-route="inventory"]').click()
    elif p.locator('[data-theme-sidebar-route="inventory"]').count(): p.locator('[data-theme-sidebar-route="inventory"]').click()
    p.wait_for_timeout(30)
    if p.locator('[data-t381-catalog-open]').count():
        p.locator('[data-t381-catalog-open]').click()
        row=p.locator('[data-t381-catalog-flow="UIF-04"]')
        ck('Warehouse function catalog marks BJ04 as contextual-only',row.count()==1 and row.get_attribute('aria-disabled')=='true' and ('Chỉ mở từ đơn có giữ hàng' in row.inner_text() or 'Thực hiện từ chi tiết đơn bán' in row.inner_text()),row.inner_text() if row.count() else 'missing')
        shot(p,'04-FUNCTION-CATALOG-BJ04-CONTEXTUAL.png','Warehouse catalog — reservation lifecycle is contextual, not a manual module')
    else:
        ck('Warehouse function catalog marks BJ04 as contextual-only',False,'catalog open control missing')

    ck('Focused BJ04 browser has no page errors',not errors,errors)
    ck('Focused BJ04 browser has no console errors',not console_errors,console_errors)
    b.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.9.6','scope':'Wave 2 / BJ04 deep-review semantic hardening','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors,'consoleErrors':console_errors,'captures':shots}
(QA/'BJ04-DEEP-REVIEW-QA-v3.9.6.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=['# BJ04 Deep Review QA — v3.9.6','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','', 'Scope: approved D04-01..D04-06 / T7-DR-144..149, current reservation semantics, BJ04/BJ05 ownership boundary and contextual read-only UI.','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': `{x["note"]}`' if (not x['pass'] and x['note']!='') else '') for x in checks]
md += ['', '## Visual captures'] + [f'- `{x["file"]}` — {x["label"]}' for x in shots]
(QA/'BJ04-DEEP-REVIEW-QA-v3.9.6.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,out['passed'],out['total'],'browserErrors',len(errors),'consoleErrors',len(console_errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
