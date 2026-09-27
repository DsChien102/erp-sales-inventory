from pathlib import Path
import json,yaml,re
ROOT=Path(__file__).resolve().parents[3]
HTML=Path(__file__).resolve().parents[1]
checks=[]
def ck(name,cond): checks.append((name,bool(cond)))
def txt(rel): return (ROOT/rel).read_text(encoding='utf8')
# SRS / contract
ent=txt('srs/04-data-entities.md'); bc=txt('srs/06-shared-behavioral-contracts.md'); tech=txt('srs/07-technical-contracts.md'); bj=txt('srs/02-business-journeys/13-BJ-13-ghi-nhan-chi-phi-mua-den-muon.md')
ck('ENT-IV-07 LateLandedCost', 'ENT-IV-07' in ent and 'LateLandedCost' in ent)
ck('ENT-IV-08 allocation lines', 'ENT-IV-08' in ent and 'LateLandedCostAllocation' in ent)
ck('Late cost has source amount', 'source_amount' in ent and 'normalized_amount_vnd' in ent)
ck('Late cost links adjustment batch', 'adjustment_batch_id' in ent)
ck('BC-IV-06 preview exists', 'BC-IV-06' in bc and 'API-Q-12' in bc)
ck('BC-IV-06 non-mutating', 'Không tạo valuation adjustment' in bc or 'không mutation' in bc.lower())
ck('BC-IV-04 owned by BJ13', re.search(r'BC-IV-04[\s\S]{0,220}BJ-13',bc) is not None)
ck('API-Q-12 preview path', '/v1/late-landed-costs/preview' in tech)
ck('API-C-23 no longer receipt-valuation anchored', 'POST /v1/late-landed-costs' in tech and '/receipt-valuations/{id}/late-costs' not in tech)
ck('BJ13 1..N allocation scope', '1..N' in bj)
ck('No invented allocation enum in BJ', 'allowed_allocation_methods' in bj or 'tập phương pháp' in bj or 'policy' in bj.lower())
for uc in ['UC-13-01-xac-dinh-nguon-va-pham-vi.md','UC-13-02-tinh-va-phan-bo-chi-phi.md']:
    u=txt('srs/05-use-cases/BJ-13-ghi-nhan-chi-phi-mua-den-muon/'+uc); ck(f'{uc} uses preview', 'BC-IV-06' in u and 'API-Q-12' in u and 'API-C-23' not in u)
u=txt('srs/05-use-cases/BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-03-xac-nhan-ghi-nhan-chi-phi.md'); ck('UC13-03 owns commit', 'BC-IV-04' in u and 'API-C-23' in u)
# flow / product contracts
flow=txt('prototype/flows/UIF-13-BJ-13.md');
ck('Dedicated UIF13 flow', all(s in flow for s in ['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089']))
mermaid=flow.split('## 2. Flow',1)[1].split('## 3. Transition contract',1)[0]; ck('Old shared screens excluded from active flow', all(s not in mermaid for s in ['SCR-014','SCR-015','SCR-017','SCR-018','SCR-019']))
entry=txt('prototype/contracts/entry-architecture.md'); ck('BJ13 module entry defined', 'UIF13 / BJ13' in entry and 'SCR-085' in entry and 'Chi phí mua bổ sung' in entry)
comp=yaml.safe_load(txt('prototype/contracts/component-usage/UIF-13-COMPONENT-USAGE.yaml')); ck('UIF13 component contract corrected', comp.get('status')=='PRODUCT_CORRECTED_v1.4.5' and comp.get('screens')==['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089'])
ck('Allocation method fixture policy explicit', 'allocationMethodLabels' in comp.get('fixturePolicy',{}))
actions=json.loads(txt('prototype/contracts/action-registry.json')); a=next(x for x in actions['actions'] if x['id']=='ACT-03-RECORD-LATE-COST'); ck('Late cost commit lives on SCR-088', a.get('screen_ids')==['SCR-088'] and 'quantity' in a.get('effect','').lower())
reg=json.loads(txt('prototype/contracts/screen-registry.json')); by={x['id']:x for x in reg['screens']}
ck('SCR018 retired', by['SCR-018']['prototype_status']=='RETIRED_FROM_ACTIVE_UIF13_v1.4.5')
ck('Old BJ03 screens no longer own BJ13', all('BJ-13' not in by[s].get('related_business_journeys',[]) for s in ['SCR-014','SCR-015','SCR-017','SCR-019']))
ck('Dedicated screens registered', all(s in by and by[s]['prototype_status']=='PRODUCT_CORRECTED_v1.4.5' for s in ['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089']))
wf=json.loads((HTML/'workbench-data.json').read_text()); f=next(x for x in wf['flows'] if x['id']=='UIF-13'); ck('Workbench UIF13 topology', f['screens']==['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089'])
sc={x['id']:x for x in wf['screens']}; ck('Workbench SCR017 direct valuation only', 'UIF-13' not in sc['SCR-017'].get('uifs',[]) and all(a.get('id')!='ACT-03-RECORD-LATE-COST' for a in sc['SCR-017'].get('actions',[])))
app=(HTML/'app.js').read_text(); v13=app[app.index('// UIF-13 / BJ-13 v1.4.5'):app.index('function cloneBj02')]
ck('Dedicated custom renderers', all(f'function render{s[4:]}IV13' in v13 for s in ['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089']))
ck('BJ13 source-task direct entry wired', 'activeFlowId === "UIF-13" && entryMode === "source-task"' in app and 'activeScreenId = "SCR-086"' in app)
ck('No direct-valuation event in UIF13 renderer', 'ReceiptValuationConfirmed' not in v13 and 'Khả dụng tăng' not in v13)
ck('Result says official cost not auto published', 'Giá vốn chưa được công bố lại' in v13)
ck('Result says quantity unchanged', 'Số lượng tồn kho' in v13 and 'Không thay đổi' in v13)

ck('Multiple allocation methods are not preselected', 'selectedMethod:""' in v13 and 'length===1?t.allowedMethods[0].id:""' in v13)
ck('Allocation screen has explicit method placeholder', 'Chọn căn cứ phân bổ' in v13 and 'Không có lựa chọn mặc định' in v13)
ck('Stale review hides obsolete allocation preview', 'Giá trị preview trước' in v13 and 'Giá trị nguồn hiện hành' in v13)
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
out=Path(__file__).resolve().parent/'BJ13-STATIC-QA-v1.4.5.md'
lines=['# BJ13 Static / Contract QA v1.4.5','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', '- Scope: BJ13 domain/data/BC/API trace, dedicated UIF13 topology, entry/component/action/screen registries.', '- Source gaps are not silently converted into business enums; allocation-method labels remain preview/policy-owned.','', '## Checks','']+[f'- [{"x" if ok else " "}] {name}' for name,ok in checks]
out.write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed: print('\n'.join(failed)); raise SystemExit(1)
