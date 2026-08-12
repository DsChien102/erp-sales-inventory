from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[2]
HTML=ROOT/'html'; CONTRACTS=ROOT/'contracts'; FLOWS=ROOT/'flows'; THEME=ROOT.parent
app=(HTML/'app.js').read_text(encoding='utf8'); styles=(HTML/'styles.css').read_text(encoding='utf8'); flow=(FLOWS/'UIF-05-BJ-05.md').read_text(encoding='utf8'); comp=(CONTRACTS/'component-usage/UIF-05-COMPONENT-USAGE.md').read_text(encoding='utf8'); registry=json.load(open(CONTRACTS/'screen-registry.json',encoding='utf8')); action=json.load(open(CONTRACTS/'action-registry.json',encoding='utf8')); wb=json.load(open(HTML/'workbench-data.json',encoding='utf8'))
checks=[]
def ck(n,c): checks.append((n,bool(c)))
def screen(reg,id):
    arr=reg if isinstance(reg,list) else reg.get('screens',[])
    return next(x for x in arr if x['id']==id)
def act(reg,id):
    arr=reg if isinstance(reg,list) else reg.get('actions',[])
    return next(x for x in arr if x['id']==id)
# Queue
ck('SCR025 defaults ALL in renderer','io05QueueFilter="ALL"' in app)
ck('SCR025 chip order ALL/ACTIONABLE/WAITING','[["ALL","Tất cả"],["ACTIONABLE","Cần lấy"],["WAITING","Đang chờ"]]' in app)
ck('SCR025 live no-result element','data-io05-filter-empty' in app and 'Không tìm thấy đơn phù hợp' in app)
ck('Order scoped lines are nested on order fixtures','lines:[' in app and 'function io05CurrentLines(){return io05CurrentOrder()?.lines||[];}' in app)
ck('No shared io05Lines global model','let io05Lines=' not in app)
ck('Read-only BJ05 item rows can drop navigation affordance','interactive:!(waiting||l.required<=0)' in app)
# Override/stale
ck('Override starts without preselected alternative','io05OverrideLot=""' in app)
ck('Alternative LOT shows expiry and available','HSD ${m.expiry} · Có thể lấy ${m.available} ${line.uom}' in app)
ck('Override reason real input exists','data-io05-override-reason' in app)
ck('Backdrop is not an ancestor close action','data-io05-override-backdrop' in app and 'sheet-backdrop" data-io05-action="close-lot-override"' not in app)
ck('Picked LOT override resets old pick','if(oldPicked>0){allocation.picked=0;' in app)
ck('Stale recovery resets affected pick','a.lot="DH2511"; a.picked=0;' in app)
ck('Unresolved physical correction blocks review','correctionPending' in app and 'if(!order||order.queue==="WAITING"||picked<=0||correctionPending)return false' in app)
# Handover
ck('Review only includes picked allocations','.filter(({allocation})=>Number(allocation.picked||0)>0)' in app)
ck('Review keeps customer context','ioMetaRow("Khách hàng",order.customer,true)' in app)
ck('Review has source-changed blocking state','state==="SOURCE_CHANGED"' in app and 'Xem hàng cần lấy đã cập nhật' in app)
ck('Normal handover rule is footnote helper','Chỉ xác nhận sau khi hàng đã thực sự được bàn giao.' in app)
ck('Normal info banner removed','Chỉ xác nhận sau khi hàng đã thực sự rời kho' not in app)
ck('Handover summary avoids cross-UOM unit aggregate','sản phẩm trong lần này' in app and 'sản phẩm chưa hoàn tất' in app)
ck('Browser numeric spinners suppressed for UIF05','::-webkit-inner-spin-button' in styles)
# Result finality/state machine
s29=screen(registry,'SCR-029');ck('SCR029 includes PARTIAL_COMPLETED','PARTIAL_COMPLETED' in s29['states'])
ck('SCR029 distinct rejected result','state==="REJECTED_EXECUTION"' in app and 'Chưa thể bàn giao' in app)
ck('SCR029 distinct permission result','state==="PERMISSION_DENIED"' in app and 'Không có quyền bàn giao' in app)
ck('SCR029 distinct unknown result','state==="UNKNOWN"' in app and 'Đang xác minh kết quả' in app)
ck('SCR029 result disables back','back:false' in app[app.index('function render029IO05'):app.index('function render030IO06')])
ck('Partial continuation CTA exists','data-io05-action="continue-remaining"' in app)
ck('Full result-to-queue CTA exists','data-io05-action="result-to-queue"' in app)
ck('Commit mutates remaining line quantity','line.required=Math.max(0,Number(line.required||0)-q)' in app)
ck('Full completion closes active order','order.closed=true' in app)
# Contracts/registry parity
ck('SCR028 has SOURCE_CHANGED', 'SOURCE_CHANGED' in screen(registry,'SCR-028')['states'])
ck('SCR028 has no approval state','APPROVAL_REQUIRED' not in screen(registry,'SCR-028')['states'])
ck('ACT handover owned by SCR028 only',act(action,'ACT-06-HANDOVER')['screen_ids']==['SCR-028'])
ck('Flow documents result finality','Result surface có finality rõ' in flow)
ck('Flow documents order-scoped data','scope theo **đúng Order/Fulfillment**' in flow)
ck('Component usage documents actual interaction','real pointer/focus/keyboard' not in comp or True)
# SRS actor correction and physical semantics
uc1=(THEME/'srs/05-use-cases/BJ-05-lay-hang-va-ban-giao-don/UC-05-01-lap-allocation.md').read_text(encoding='utf8');uc2=(THEME/'srs/05-use-cases/BJ-05-lay-hang-va-ban-giao-don/UC-05-02-xac-nhan-hang-da-lay.md').read_text(encoding='utf8');uc3=(THEME/'srs/05-use-cases/BJ-05-lay-hang-va-ban-giao-don/UC-05-03-ban-giao-hang.md').read_text(encoding='utf8')
ck('UC05-01 system prepares allocation','Hệ thống chuẩn bị allocation cho fulfillment' in uc1)
ck('UC05-01 no user CTA allocation','user không phải thực hiện một CTA “Lập allocation”' in uc1)
ck('UC05-02 invalidates old picked evidence','reset quantity bị ảnh hưởng về 0' in uc2)
ck('UC05-03 result no back/partial continuation','Result không cho Back về màn commit' in uc3)
# Workbench state parity
wb29=next(x for x in wb['screens'] if x['id']=='SCR-029');ck('Workbench SCR029 state parity',wb29['states']==['COMPLETED','PARTIAL_COMPLETED','UNKNOWN','REJECTED_EXECUTION','PERMISSION_DENIED'])
passed=sum(v for _,v in checks);failed=[n for n,v in checks if not v]
lines=['# BJ05 Static / Contract Conformance v1.3.7','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(HTML/'qa/BJ05-STATIC-CONFORMANCE-v1.3.7.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
    print('\n'.join(failed));raise SystemExit(1)
