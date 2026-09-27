#!/usr/bin/env python3
import json,re
from pathlib import Path
BASE=Path(__file__).resolve().parents[6]
HTML=BASE/'specs/themes/theme-07/prototype/html'
QA=HTML/'qa'
checks=[]
def ck(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
def load(name): return json.loads((QA/name).read_text(encoding='utf-8'))

root_readme=(BASE/'README.md').read_text(encoding='utf-8')
root_index=(BASE/'index.html').read_text(encoding='utf-8')
html_index=(HTML/'index.html').read_text(encoding='utf-8')
app=(HTML/'app.js').read_text(encoding='utf-8')
v392=(HTML/'v392-bj02-semantic-hardening.js').read_text(encoding='utf-8')
v360=(HTML/'v360-full-theme-completion.js').read_text(encoding='utf-8')
proto=json.loads((HTML/'prototype.manifest.json').read_text(encoding='utf-8'))
outer=json.loads((BASE/'specs/themes/theme-07/prototype/prototype.manifest.json').read_text(encoding='utf-8'))
manifest=json.loads((HTML/'manifest.json').read_text(encoding='utf-8'))
wb=json.loads((HTML/'workbench-data.json').read_text(encoding='utf-8'))
reg=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf-8'))
rt=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/runtime-state-registry-v3.7.0.json').read_text(encoding='utf-8'))

deep=load('BJ02-DEEP-REVIEW-QA-v3.9.2.json')
enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.9.2.json')
flow=load('FLOW-LOGIC-E2E-QA-v3.9.2.json')
smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.9.2.json')
runtime=load('RUNTIME-UI-QA-v3.9.2.json')
device=load('DEVICE-FRAME-QA-v3.9.2.json')
coh=load('REPRESENTATIVE-COHERENCE-QA-v3.9.2.json')

ck('root package identifies v3.9.2','v3.9.2' in root_readme and 'v3.9.2' in root_index)
ck('prototype metadata identifies v3.9.2 and parent v3.9.1',proto.get('version')=='3.9.2' and outer.get('version')=='3.9.2' and manifest.get('version')=='3.9.2' and manifest.get('parentVersion')=='3.9.1')
ck('current BJ02 presentation registries identify v3.9.2',wb.get('version')=='3.9.2' and reg.get('version')=='3.9.2' and rt.get('version')=='3.7.0')
ck('v3.9.2 stylesheet and JS load after v3.9.1','v392-bj02-semantic-hardening.css' in html_index and 'v392-bj02-semantic-hardening.js' in html_index and html_index.index('v392-bj02-semantic-hardening.css')>html_index.index('v391-bj01-semantic-hardening.css'))
ck('canonical Product viewport remains 402x874',proto.get('defaultViewport')=={'width':402,'height':874})
ck('Figma DS remains UI authority','figmaDesignSystem' in manifest.get('authority',{}) and 'UI authority' in manifest.get('authority',{}).get('figmaDesignSystem',''))
ck('BJ02 deep-review gate passes',deep.get('status')=='PASS' and deep.get('passed')==deep.get('total')==51,f"{deep.get('passed')}/{deep.get('total')}")
ck('full-theme end-user regression passes',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19,f"{enduser.get('passed')}/{enduser.get('total')}")
ck('semantic flow/logic regression passes',flow.get('status')=='PASS' and flow.get('checks')==21 and flow.get('version')=='3.9.2')
ck('all-flow runtime smoke passes',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI regression passes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==518 and runtime.get('version')=='3.9.2')
ck('device-frame regression passes',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
ck('representative coherence regression passes',coh.get('passed')==coh.get('total')==8 and coh.get('version')=='3.9.2')

caps=QA/'v392-bj02-captures'
cap_manifest=json.loads((caps/'manifest.json').read_text(encoding='utf-8')) if (caps/'manifest.json').exists() else []
ck('BJ02 focused visual evidence contains six captures',len(cap_manifest)==6 and all((caps/x['file']).exists() for x in cap_manifest),len(cap_manifest))

# Semantic hardening guardrails.
ck('runtime no longer carries ambiguous sourceExpected or hard-coded priceBasisVnd','sourceExpected' not in app and 'priceBasisVnd' not in app)
ck('BJ02 overlay uses accepted physical base quantity for risk and approval','lineAcceptedBase' in v392 and 'documentLineAllowanceBase' in v392 and 'receiptRiskValue' in v392)
ck('Quick receipt has no hard-coded DOCX/10MB policy','DOCX' not in v392 and '10 MB' not in v392)
ck('UNKNOWN recovery keeps explicit handoff to BJ17','data-v350-action="bj02-handoff-unknown"' in v392)
ck('legacy representative seeder does not overwrite explicit BJ02 draft data','v360Bj02HasExplicitDraftData' in v360 and '!v360Bj02HasExplicitDraftData()' in v360)
ck('BJ02 active screens carry current deep-review trace',all(s.get('deep_review',{}).get('version')=='3.9.2' for s in reg.get('screens',[]) if s.get('id') in {'SCR-006','SCR-007','SCR-008','SCR-009','SCR-084','SCR-010','SCR-011','SCR-012','SCR-013'}))

required=[HTML/'v392-bj02-semantic-hardening.css',HTML/'v392-bj02-semantic-hardening.js',QA/'BJ02-DEEP-REVIEW-QA-v3.9.2.md']
ck('v3.9.2 release assets exist',all(x.exists() for x in required))

passed=sum(1 for x in checks if x['pass'])
out={'version':'3.9.2','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.2.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Current Package Validation — v3.9.2','',f"**Status:** {out['status']} — {passed}/{len(checks)} checks PASS",'']
for x in checks: lines.append(f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}"+(f" — `{x['note']}`" if x['note']!='' else ''))
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.2.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(out['status'],passed,'/',len(checks))
if out['status']!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x)
    raise SystemExit(1)
