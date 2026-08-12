from pathlib import Path
import json
HTML=Path(__file__).resolve().parents[1]; THEME=HTML.parents[1]
app=(HTML/'app.js').read_text(encoding='utf8'); styles=(HTML/'styles.css').read_text(encoding='utf8'); wb=json.loads((HTML/'workbench-data.json').read_text(encoding='utf8')); manifest=json.loads((HTML/'manifest.json').read_text(encoding='utf8'))
registry=json.loads((THEME/'prototype/contracts/screen-registry.json').read_text(encoding='utf8')); action=json.loads((THEME/'prototype/contracts/action-registry.json').read_text(encoding='utf8')); uif=json.loads((THEME/'prototype/flows/ui-flow-registry.json').read_text(encoding='utf8'))
dec=(THEME/'know-how/decisions/decision-register.md').read_text(encoding='utf8'); bj=(THEME/'srs/02-business-journeys/07-BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md').read_text(encoding='utf8'); flow=(THEME/'prototype/flows/UIF-07-BJ-07.md').read_text(encoding='utf8'); comp=(THEME/'prototype/contracts/component-usage/UIF-07-COMPONENT-USAGE.md').read_text(encoding='utf8'); mapdoc=(THEME/'prototype/contracts/bj-ui-flow-map.md').read_text(encoding='utf8')
ucdir=THEME/'srs/05-use-cases/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap'; uc1=(ucdir/'UC-07-01-xac-minh-pham-vi-tra.md').read_text(encoding='utf8'); uc2=(ucdir/'UC-07-02-dua-hang-vao-cho-tra.md').read_text(encoding='utf8'); uc3=(ucdir/'UC-07-03-dieu-chinh-hoac-huy-truoc-ban-giao.md').read_text(encoding='utf8'); uc4=(ucdir/'UC-07-04-ghi-nhan-ban-giao-tra-nha-cung-cap.md').read_text(encoding='utf8')
checks=[]
def ck(n,c): checks.append((n,bool(c)))
def scr(i): return next(x for x in registry['screens'] if x['id']==i)
def act(i): return next(x for x in action['actions'] if x['id']==i)
# Business decisions/SRS
ck('Decision register locks exact-source supplier handover','T7-DR-114' in dec and 'exact current source-authorized scope' in dec)
ck('Decision register locks granular source invalidation','T7-DR-115' in dec and 'affected allocations' in dec)
ck('BJ07 references v1.3.9 exact source amendment','Design amendment v1.3.9' in bj and 'T7-DR-114' in bj and 'T7-DR-115' in bj)
ck('UC07-01 distinguishes source fact from physical verification','authoritative expectation' in uc1 and 'physical confirmation' in uc1)
ck('UC07-02 removes manual state-change task','SCR-038 không thuộc active UIF07' in uc2)
ck('UC07-03 defines affected-only invalidation and system release','affected allocations' in uc3 and 'system-owned release' in uc3)
ck('UC07-04 forbids arbitrary warehouse partial/LOT substitution','arbitrary partial handover' in uc4 and 'LOT substitution' in uc4)
ck('UC07-04 locks result finality and UNKNOWN','UNKNOWN không blind retry' in uc4 and 'BJ17' in uc4)
# Renderer semantics
ck('Queue default is ALL','io07QueueFilter="ALL"' in app)
ck('Queue filters all/prepare/ready/waiting','[["ALL","Tất cả"],["ACTIONABLE","Cần chuẩn bị"],["READY","Sẵn sàng"],["WAITING","Đang chờ"]]' in app)
ck('Waiting source-owned row is read-only','io07-waiting-row' in app and 'req.queue==="WAITING"' in app)
ck('Search has no-result state','data-io07-filter-empty' in app and 'Không tìm thấy yêu cầu phù hợp' in app)
ck('Data model groups Product+UOM to allocations','groups:[' in app and 'allocations:[' in app and 'RTV-G1' in app and 'RTV-A2' in app)
ck('Mixed UOM fixture exists for same Product','name:"Nobivac DHPPi",code:"SP-00142",uom:"hộp"' in app and 'name:"Nobivac DHPPi",code:"SP-00142",uom:"lọ"' in app)
ck('Source quantity is read-only in verification UI','Lượng nguồn' in app and 'data-io07-qty' not in app)
ck('LOT scan is optional and mismatch blocker exists','Mã LOT quét/nhập' in app and 'không bắt buộc' in app and 'LOT không thuộc yêu cầu hiện tại' in app)
ck('Physical mismatch does not offer quantity/LOT override','Không khớp thực tế' in app and 'Kho không tự giảm lượng trả hoặc đổi lô' in app)
ck('Granular source update resets only affected allocation','function io07ApplySourceUpdate' in app and 'f.allocation.verified=false' in app and 'affectedByChange=true' in app)
ck('Source remove releases pending scope copy','lượng chờ trả được hệ thống giải phóng' in app)
ck('Source cancel closes task system-side','function io07CancelSource' in app and 'req.closed=true' in app and 'req.queue="CLOSED"' in app)
ck('Final review rechecks source version','reviewSourceVersion' in app and 'stateByScreen["SCR-039"]="SOURCE_CHANGED"' in app)
ck('Final review has no second confirmation modal','Xác nhận đã bàn giao' in app and 'confirm-handover' in app and 'confirmation modal' not in app.lower())
ck('Final review explicitly avoids mixed-UOM aggregation','Số lượng ở các đơn vị khác nhau không được cộng gộp thành một tổng' in app)
ck('Result creates immutable-like operation snapshot fields','function io07CreateResult' in app and 'operationId' in app and 'sourceVersion' in app and 'lines' in app)
result_block=app[app.index('function render041IO07'):app.index('const renderers =')]
ck('Result distinguishes completed/rejected/unknown/permission','REJECTED_EXECUTION' in result_block and 'UNKNOWN' in result_block and 'PERMISSION_DENIED' in result_block and 'Đã bàn giao cho nhà cung cấp' in result_block)
ck('All result terminal states disable Back',result_block.count('back:false')>=5)
ck('UNKNOWN has no blind retry and references BJ17','Không gửi lại bàn giao' in result_block and 'định danh thao tác hiện tại' in result_block and 'BJ17' not in result_block)
# Registry parity
ck('Manifest version is 1.3.9',manifest.get('version')=='1.3.9' and manifest.get('calibration',{}).get('bj')=='BJ-07')
ck('Screen registry version is 1.3.9',registry.get('version')=='1.3.9')
ck('Action registry version is 1.3.9',action.get('version')=='1.3.9')
f=next(x for x in uif['flows'] if x['id']=='UIF-07')
ck('UIF07 active screen order is exactly 036/037/039/041',f['screen_ids']==['SCR-036','SCR-037','SCR-039','SCR-041'])
ck('UIF07 registry excludes state-change action',f['action_ids']==['ACT-08-RTV'])
ck('UIF07 transition count is 8',f['transition_count']==8)
ck('SCR039 states exclude approval and include source/mismatch',scr('SCR-039')['states']==['READY','SOURCE_CHANGED','PHYSICAL_MISMATCH','VALIDATION_ERROR','PERMISSION_DENIED'])
ck('ACT08RTV is one explicit review without repeat modal','Explicit final review' in act('ACT-08-RTV')['confirmation'] and act('ACT-08-RTV')['screen_ids']==['SCR-039'])
ck('Workbench UIF07 has corrected patterns',all(x in next(y for y in wb['flows'] if y['id']=='UIF-07')['patterns'] for x in ['ACTIONABLE_VS_SOURCE_WAITING','PRODUCT_UOM_MULTI_LOT','SOURCE_DELTA_GRANULAR_INVALIDATION','RESULT_FINALITY']))
ck('BJ/UI map has four active BJ07 screens','| `BJ-07` | Thực hiện trả hàng cho nhà cung cấp | 4 | 4 |' in mapdoc and 'SCR-037`](screens/SCR-037.md) → [`SCR-039`' in mapdoc)
ck('Component usage version is v1.3.9','v1.3.9' in comp and 'waiting row read-only' in comp and 'Product+UOM' in comp and 'allocation row' in comp)
# CSS scope
v139css=styles[styles.index('v1.3.9 — BJ07/UIF07 deep product correction'):]
ck('All v1.3.9 CSS selectors are scoped to UIF07',all(('body[data-active-uif="UIF-07"]' in line or not line.strip().startswith(('body','.io07'))) for line in v139css.splitlines() if '{' in line))
passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# BJ07 Static / Contract Conformance v1.3.9','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Coverage: decisions/SRS/UC source, exact-source physical semantics, queue ownership, Product+UOM multi-LOT model, mismatch/source-delta behavior, final review/result finality, registry/action/workbench parity and UIF07 CSS scoping.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(HTML/'qa/BJ07-STATIC-CONFORMANCE-v1.3.9.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
 print('\n'.join(failed)); raise SystemExit(1)
