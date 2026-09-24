#!/usr/bin/env python3
import json
from pathlib import Path
BASE=Path(__file__).resolve().parents[6]
HTML=BASE/'specs/themes/theme-07/prototype/html'
QA=HTML/'qa'
checks=[]
def ck(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
def load(name): return json.loads((QA/name).read_text(encoding='utf-8'))

def text(rel): return (BASE/rel).read_text(encoding='utf-8')
root_readme=text('README.md')
root_index=text('index.html')
html_index=(HTML/'index.html').read_text(encoding='utf-8')
app=(HTML/'app.js').read_text(encoding='utf-8')
v392=(HTML/'v392-bj02-semantic-hardening.js').read_text(encoding='utf-8')
v393=(HTML/'v393-bj05-semantic-hardening.js').read_text(encoding='utf-8')
v360=(HTML/'v360-full-theme-completion.js').read_text(encoding='utf-8')
proto=json.loads((HTML/'prototype.manifest.json').read_text(encoding='utf-8'))
outer=json.loads((BASE/'specs/themes/theme-07/prototype/prototype.manifest.json').read_text(encoding='utf-8'))
manifest=json.loads((HTML/'manifest.json').read_text(encoding='utf-8'))
wb=json.loads((HTML/'workbench-data.json').read_text(encoding='utf-8'))
reg=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf-8'))
cat=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/screen-catalog.json').read_text(encoding='utf-8'))
rt=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/runtime-state-registry-v3.7.0.json').read_text(encoding='utf-8'))

deep=load('BJ05-DEEP-REVIEW-QA-v3.9.3.json')
bj02=load('BJ02-DEEP-REVIEW-QA-v3.9.2.json')
enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.9.3.json')
flow=load('FLOW-LOGIC-E2E-QA-v3.9.3.json')
smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.9.3.json')
runtime=load('RUNTIME-UI-QA-v3.9.3.json')
device=load('DEVICE-FRAME-QA-v3.9.3.json')
coh=load('REPRESENTATIVE-COHERENCE-QA-v3.9.3.json')

ck('root package identifies v3.9.3','v3.9.3' in root_readme and 'v3.9.3' in root_index)
ck('prototype metadata identifies v3.9.3 and parent v3.9.2',proto.get('version')=='3.9.3' and proto.get('parentVersion')=='3.9.2' and outer.get('version')=='3.9.3' and outer.get('parentVersion')=='3.9.2' and manifest.get('version')=='3.9.3' and manifest.get('parentVersion')=='3.9.2')
ck('current presentation registries identify v3.9.3',wb.get('version')=='3.9.3' and reg.get('version')=='3.9.3' and cat.get('version')=='3.9.3' and cat.get('package_version')=='3.9.3' and rt.get('version')=='3.7.0')
ck('v3.9.3 BJ05 CSS/JS load after BJ02 hardening','v393-bj05-semantic-hardening.css' in html_index and 'v393-bj05-semantic-hardening.js' in html_index and html_index.index('v393-bj05-semantic-hardening.css')>html_index.index('v392-bj02-semantic-hardening.css') and html_index.index('v393-bj05-semantic-hardening.js')>html_index.index('v392-bj02-semantic-hardening.js'))
ck('canonical Product viewport remains 402x874',proto.get('defaultViewport')=={'width':402,'height':874})
ck('Figma DS remains UI authority','figmaDesignSystem' in manifest.get('authority',{}) and 'UI authority' in manifest.get('authority',{}).get('figmaDesignSystem',''))
ck('BJ05 deep-review gate passes',deep.get('status')=='PASS' and deep.get('passed')==deep.get('total')==22,f"{deep.get('passed')}/{deep.get('total')}")
ck('BJ02 locked deep-review evidence remains present',bj02.get('status')=='PASS' and bj02.get('passed')==bj02.get('total')==51,f"{bj02.get('passed')}/{bj02.get('total')}")
ck('full-theme end-user regression passes',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19,f"{enduser.get('passed')}/{enduser.get('total')}")
ck('semantic flow/logic regression passes',flow.get('status')=='PASS' and flow.get('checks')==21 and flow.get('version')=='3.9.3')
ck('all-flow runtime smoke passes',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI regression passes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==518 and runtime.get('version')=='3.9.3')
ck('device-frame regression passes',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
ck('representative coherence regression passes',coh.get('passed')==coh.get('total')==8 and coh.get('version')=='3.9.3')

caps=QA/'v393-bj05-captures'
pngs=sorted(caps.glob('*.png'))
ck('BJ05 focused visual evidence contains five captures',len(pngs)==5,len(pngs))

# Semantic hardening guardrails.
ck('BJ05 runtime uses immutable requested quantity and separate allocated/picked/consumed facts',all(x in app for x in ['requestedQty','allocatedQty','pickedQty','consumedQty']) and 'line.required -=' not in app and 'allocation.qty -=' not in app)
ck('handover evidence preserves source and operation identity','sourceVersion:(order.sourceVersion??order.fulfillmentVersion)' in app and 'operationId:order.operationId' in app and 'HandoverEvidence' in text('specs/themes/theme-07/srs/04-data-entities.md'))
ck('UNKNOWN handoff uses exact BJ05 operation identity','data-operation=\\"${v393Attr(operation)}\\"' in v393 and "const operation=o.operationId||o.id" in v393 and 'Đang xác minh bàn giao' in v393)
ck('VERIFYING remains visible but non-actionable in BJ05 queue',"io05VisibleOrders=function(){return io05Orders.filter(o=>!o.closed);}" in v393 and 'v393-verifying-task' in v393)
ck('LOT candidates are pick-time snapshots, not LOT reservations','pickableQty' in app and 'snapshotVersion' in app and 'lot_pickable_quantity' in text('specs/themes/theme-07/know-how/decisions/decision-register.md'))
ck('physical correction requires explicit actor assertion','physicalCorrection' in app and 'Xác nhận đã điều chỉnh hàng' in app and 'confirmedAt' in app)
ck('legacy representative seeder still protects explicit BJ02 draft data','v360Bj02HasExplicitDraftData' in v360 and '!v360Bj02HasExplicitDraftData()' in v360 and 'ownershipAssertion' in v392)
ck('BJ05 active screens carry current deep-review trace',all(s.get('deep_review',{}).get('version')=='3.9.3' for s in reg.get('screens',[]) if s.get('id') in {'SCR-025','SCR-026','SCR-027','SCR-028','SCR-029'}))
ck('owned-entity catalog count is internally consistent','26 thực thể sở hữu' in text('specs/themes/theme-07/srs/04-data-entities.md'))

required=[HTML/'v393-bj05-semantic-hardening.css',HTML/'v393-bj05-semantic-hardening.js',QA/'BJ05-DEEP-REVIEW-QA-v3.9.3.md']
ck('v3.9.3 release assets exist',all(x.exists() for x in required))

passed=sum(1 for x in checks if x['pass'])
out={'version':'3.9.3','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.3.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Current Package Validation — v3.9.3','',f"**Status:** {out['status']} — {passed}/{len(checks)} checks PASS",'']
for x in checks: lines.append(f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}"+(f" — `{x['note']}`" if x['note']!='' else ''))
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.3.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(out['status'],passed,'/',len(checks))
if out['status']!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x)
    raise SystemExit(1)
