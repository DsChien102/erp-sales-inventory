from pathlib import Path
import json, re, yaml
HTML=Path(__file__).resolve().parents[1]
THEME=HTML.parents[1]
app=(HTML/'app.js').read_text(encoding='utf8')
styles=(HTML/'styles.css').read_text(encoding='utf8')
manifest=json.loads((HTML/'manifest.json').read_text(encoding='utf8'))
wb=json.loads((HTML/'workbench-data.json').read_text(encoding='utf8'))
registry=json.loads((THEME/'prototype/contracts/screen-registry.json').read_text(encoding='utf8'))
actions=json.loads((THEME/'prototype/contracts/action-registry.json').read_text(encoding='utf8'))
flows=json.loads((THEME/'prototype/flows/ui-flow-registry.json').read_text(encoding='utf8'))
flowdoc=(THEME/'prototype/flows/UIF-03-BJ-03.md').read_text(encoding='utf8')
compmd=(THEME/'prototype/contracts/component-usage/UIF-03-COMPONENT-USAGE.md').read_text(encoding='utf8')
compyaml=yaml.safe_load((THEME/'prototype/contracts/component-usage/UIF-03-COMPONENT-USAGE.yaml').read_text(encoding='utf8'))
compreg=yaml.safe_load((THEME/'prototype/contracts/COMPONENT-USAGE-REGISTRY.yaml').read_text(encoding='utf8'))
cross=(THEME/'prototype/contracts/CROSS-UIF-DECISIONS.md').read_text(encoding='utf8')
bj=(THEME/'srs/02-business-journeys/03-BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan.md').read_text(encoding='utf8')
ucdir=THEME/'srs/05-use-cases/BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan'
uc2=(ucdir/'UC-03-02-xac-dinh-gia-nhap-thuc-te.md').read_text(encoding='utf8')
uc3=(ucdir/'UC-03-03-xac-nhan-gia-tri.md').read_text(encoding='utf8')
bc=(THEME/'srs/06-shared-behavioral-contracts.md').read_text(encoding='utf8')
checks=[]
def ck(name, cond): checks.append((name,bool(cond)))
def scr(sid): return next(x for x in registry['screens'] if x['id']==sid)
def act(aid): return next(x for x in actions['actions'] if x['id']==aid)
def flow(fid): return next(x for x in flows['flows'] if x['id']==fid)
def wbflow(fid): return next(x for x in wb['flows'] if x['id']==fid)
# Source-rule grounding: no new business semantics invented by the renderer.
ck('BJ03 says valuation is independent of sellability','độc lập với việc hàng có đủ điều kiện bán hay không' in bj)
ck('BJ03 supports identified quantity partial valuation','lát số lượng định danh' in bj and 'phần còn lại tiếp tục chờ giá' in bj)
ck('BJ03 forbids silent source choice','không âm thầm chọn' in bj and 'chọn nguồn và ghi lý do' in bj)
ck('BJ03 defines direct-cost components and deductible VAT exclusion','discount dòng' in bj and 'thuế không được khấu trừ' in bj and 'VAT được khấu trừ' in bj)
ck('BJ03 requires approved FX provenance','tỷ giá được nguồn kế toán phê duyệt' in bj and 'provenance' in bj)
ck('BJ03 routes late cost to BJ13','chi phí mua đến sau' in bj and 'BJ-13' in bj)
ck('UC03-02 preserves UNKNOWN identity','UNKNOWN' in uc2 and 'operation/idempotency identity' in uc2)
ck('UC03-03 commits value movement for exact scope','Value movement được commit và scope hết chờ giá' in uc3)
ck('BC-IV-01 is the direct valuation command','BC-IV-01 — Confirm direct receipt cost and release' in bc and 'ReceiptValuation' in bc and 'outbox atomically' in bc)
# Release/registry parity.
ck('Manifest is v1.4.0 BJ03/UIF03',manifest.get('version')=='1.4.0' and manifest.get('calibration',{}).get('bj')=='BJ-03' and manifest.get('calibration',{}).get('uif')=='UIF-03')
ck('Screen registry is v1.4.0',registry.get('version')=='1.4.0')
ck('Action registry is v1.4.0',actions.get('version')=='1.4.0')
ck('UI-flow registry patch is v1.4.0',flows.get('patch_version')=='1.4.0')
ck('Workbench data is v1.4.0',wb.get('version')=='1.4.0')
f=flow('UIF-03')
ck('UIF03 keeps exact five-screen path',f['screen_ids']==['SCR-014','SCR-015','SCR-016','SCR-017','SCR-019'])
ck('UIF03 keeps one business mutation action',f['action_ids']==['ACT-03-CONFIRM-COST'])
ck('UIF03 transition count remains 9',f['transition_count']==9)
ck('UIF03 promoted patterns are registered',all(x in f['patterns_promoted'] for x in ['VALUATION_SCOPE_SLICE','SOURCE_PROVENANCE_FIRST','SOURCE_CONFLICT_EXPLICIT_RESOLUTION','SELLABILITY_SEPARATED_FROM_VALUATION','SOURCE_VERSION_RECHECK','RESULT_FINALITY','UNKNOWN_RECOVERY','FINANCIAL_MASKING']))
ck('Workbench promotes same valuation mental model',all(x in wbflow('UIF-03')['patterns'] for x in ['VALUATION_SCOPE_SLICE','SOURCE_PROVENANCE_FIRST','SOURCE_CONFLICT_EXPLICIT_RESOLUTION','SELLABILITY_SEPARATED_FROM_VALUATION','RESULT_FINALITY']))
# Screen contracts/modes.
ck('SCR014 is valuation worklist, not mixed-UOM total','lát số lượng' in scr('SCR-014')['purpose'] and 'không cộng gộp quantity khác UOM' in scr('SCR-014')['purpose'])
ck('SCR015 selected qty does not edit receipt qty','không sửa số lượng đã nhận' in scr('SCR-015')['purpose'])
ck('SCR016 source/provenance is authoritative','source/provenance authoritative' in scr('SCR-016')['purpose'] and 'SYSTEM_DERIVED_READ_ONLY' in str(scr('SCR-016')['design_readiness']))
ck('SCR017 supports stale source state','SOURCE_CHANGED' in scr('SCR-017')['states'])
ck('SCR017 mode scopes direct vs late-cost review',scr('SCR-017')['mode']['modes']=={'UIF-03':'DIRECT_VALUATION_REVIEW','UIF-13':'LATE_COST_REVIEW'})
ck('SCR019 has explicit finality states',all(x in scr('SCR-019')['states'] for x in ['PROCESSING','COMPLETED','UNKNOWN','REJECTED_EXECUTION','PERMISSION_DENIED']))
ck('SCR019 mode scopes direct vs late-cost result',scr('SCR-019')['mode']['modes']=={'UIF-03':'DIRECT_VALUATION_RESULT','UIF-13':'LATE_COST_RESULT'})
ck('Direct cost action has single-review confirmation semantics','no second approval or repeat confirmation modal' in act('ACT-03-CONFIRM-COST')['confirmation'] and act('ACT-03-CONFIRM-COST')['screen_ids']==['SCR-017'])
ck('Embedded SCR017 action contract matches direct-review semantics',any(a.get('id')=='ACT-03-CONFIRM-COST' and 'no second approval or repeat confirmation modal' in a.get('confirmation','') for a in scr('SCR-017')['action_contracts']))
# Renderer semantics.
ck('Custom renderers cover all five UIF03 screens',all(f'"{sid}":{fn}' in app for sid,fn in [('SCR-014','render014IV03'),('SCR-015','render015IV03'),('SCR-016','render016IV03'),('SCR-017','render017IV03'),('SCR-019','render019IV03')]))
ck('Every shared custom renderer falls back outside UIF03',all(f'function {fn}(state){{if(activeFlowId!=="UIF-03")return renderGeneric' in app for fn in ['render014IV03','render015IV03','render017IV03','render019IV03']))
ck('Queue has search and three business filters','data-val03-search' in app and '["ALL","Tất cả"]' in app and '["READY","Có thể xử lý"]' in app and '["MISSING","Thiếu căn cứ"]' in app)
ck('Queue no-result is explicit','Không tìm thấy phiếu phù hợp' in app)
ck('Scope uses Product+UOM slices and bounded quantity','data-val03-slice' in app and 'data-val03-qty' in app and 'Số lượng ở đây là phạm vi xác nhận giá trị, không phải sửa số lượng đã nhận' in app)
ck('Missing evidence is non-selectable','val03EvidenceState(g)==="MISSING"?"disabled"' in app)
ck('Source conflict has no silent preselection','Nguồn giá đang mâu thuẫn' in app and 'Hệ thống không tự chọn' in app and 'Lý do chọn nguồn' in app)
ck('Foreign source amount and FX provenance are both rendered','Đơn giá nguồn' in app and 'Quy đổi' in app and 'fxLabel' in app)
ck('No authoritative money-entry field exists in UIF03 code','VMoneyField' not in app[app.index('const val03Receipts ='):app.index('function cloneBj02')])
ck('Direct valuation separates late landed cost','Chi phí mua đến sau không sửa lần xác nhận này' in app)
ck('Review separates value from availability','Tổng giá trị sẽ ghi' in app and 'Tác động sau xác nhận' in app and 'Xác nhận giá trị không đổi trạng thái vật lý' in app)
ck('Source stale blocks commit and returns to provenance','Căn cứ giá đã thay đổi' in app and 'back-to-calculation' in app and 'val03ReviewSourceVersion' in app)
ck('Partial commit decrements exact selected slice','slice.pendingQty-=q' in app and 'slice.selected=false' in app)
result=app[app.index('function render019IV03'):app.index('function cloneBj02')]
ck('Result distinguishes completed/rejected/unknown/permission',all(x in result for x in ['Đã xác nhận giá trị','REJECTED_EXECUTION','UNKNOWN','PERMISSION_DENIED']))
ck('Result has no blind retry','Không gửi lại xác nhận' in result and 'back:false' in result)
ck('Completed partial result can continue remaining','continue-remaining' in result)
# Component/DS/scoping.
ck('UIF03 component contract is v1.4.0 corrected',compyaml.get('status')=='PRODUCT_CORRECTED_v1.4.0')
ck('UIF03 component allowlist has no money field','VMoneyField' not in compyaml.get('componentAllowlist',[]))
ck('UIF03 source conflict uses text reason only','VTextFormField' in compyaml.get('componentAllowlist',[]) and 'VNumberField' in compyaml.get('componentAllowlist',[]))
ck('Component registry records cumulative v1.4.0',compreg.get('status')=='CUMULATIVE_v1.4.0')
ck('Cross-UIF contract protects UIF13 mode scope','Mode-scoped shared valuation screens' in cross and 'UIF-13' in cross)
css_marker='/* UIF-03 / BJ-03 v1.4.0 — scoped Inventory Valuation product correction */'
css=styles[styles.index(css_marker):] if css_marker in styles else ''
selectors=[ln.strip() for ln in css.splitlines() if '{' in ln and ln.strip() and not ln.strip().startswith('/*')]
ck('v1.4.0 CSS block exists',bool(css))
ck('UIF03 interactive controls meet 44px target','min-height:var(--v-control-medium)' in css and 'min-height:56px' in css and 'min-height:60px' in css)
ck('v1.4.0 CSS selectors are UIF03-scoped',bool(selectors) and 'body[data-active-uif="UIF-03"]' in css and not any(re.match(r'^\s*\.val03',ln) for ln in css.splitlines()))
ck('UIF03 docs prohibit second approval/modal','một commit duy nhất' in compmd and 'không second approval/modal' in flowdoc)
# Report.
passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# BJ03 Static / Contract Conformance v1.4.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Coverage: existing BJ03/UC03/BC-IV-01 source rules, five-screen architecture, identified valuation scope, provenance/source conflict, FX, value-vs-sellability, single commit, stale-source guard, result finality, UIF13 mode isolation, registry parity, Flutter DS component contract and scoped CSS.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(HTML/'qa/BJ03-STATIC-CONFORMANCE-v1.4.0.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
