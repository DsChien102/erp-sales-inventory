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
proto=json.loads((HTML/'prototype.manifest.json').read_text(encoding='utf-8'))
outer=json.loads((BASE/'specs/themes/theme-07/prototype/prototype.manifest.json').read_text(encoding='utf-8'))
manifest=json.loads((HTML/'manifest.json').read_text(encoding='utf-8'))
wb=json.loads((HTML/'workbench-data.json').read_text(encoding='utf-8'))
reg=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf-8'))
rt=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/runtime-state-registry-v3.7.0.json').read_text(encoding='utf-8'))
ck('root package identifies v3.9.0','v3.9.0' in root_readme and 'v3.9.0' in root_index)
ck('prototype metadata identifies v3.9.0 and parent v3.8.3',proto.get('version')=='3.9.0' and outer.get('version')=='3.9.0' and manifest.get('version')=='3.9.0' and manifest.get('parentVersion')=='3.8.3')
ck('business registries remain unchanged at v3.7.0',wb.get('version')=='3.7.0' and reg.get('version')=='3.7.0' and rt.get('version')=='3.7.0')
ck('v3.9.0 patch loads after v3.8.3',html_index.find('v390-full-theme-end-user-hardening.css')>html_index.find('v383-warehouse-home-clarity-polish.css') and html_index.find('v390-full-theme-end-user-hardening.js')>html_index.find('v383-warehouse-home-clarity-polish.js'))
ck('canonical Product viewport remains 402x874',proto.get('defaultViewport')=={'width':402,'height':874})
ck('Figma DS remains UI authority','figmaDesignSystem' in manifest.get('authority',{}) and 'UI authority' in manifest.get('authority',{}).get('figmaDesignSystem',''))
new=load('FULL-THEME-END-USER-HARDENING-QA-v3.9.0.json')
flow=load('FLOW-LOGIC-E2E-QA-v3.9.0.json')
smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.9.0.json')
runtime=load('RUNTIME-UI-QA-v3.9.0.json')
device=load('DEVICE-FRAME-QA-v3.9.0.json')
coh=load('REPRESENTATIVE-COHERENCE-QA-v3.9.0.json')
ck('full-theme end-user hardening gate passes',new.get('status')=='PASS' and new.get('passed')==new.get('total')==19,f"{new.get('passed')}/{new.get('total')}")
ck('semantic flow/logic regression passes',flow.get('status')=='PASS' and flow.get('checks')==21)
ck('all-flow runtime smoke passes',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI regression passes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==518)
ck('device-frame regression passes',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
ck('representative coherence regression passes',coh.get('passed')==coh.get('total')==8)
caps=QA/'v390-end-user-captures'
cap_manifest=json.loads((caps/'manifest.json').read_text(encoding='utf-8')) if (caps/'manifest.json').exists() else []
ck('focused visual evidence contains five captures',len(cap_manifest)==5 and all((caps/x['file']).exists() for x in cap_manifest),len(cap_manifest))
ck('integrated runtime contract declares persona/context hardening',proto.get('integratedRuntime',{}).get('exactTaskDeepLink') is True and proto.get('integratedRuntime',{}).get('contextAwareExit') is True and proto.get('integratedRuntime',{}).get('manualObjectSelection') is True)
required=[HTML/'v390-full-theme-end-user-hardening.js',HTML/'v390-full-theme-end-user-hardening.css',QA/'FULL-THEME-END-USER-HARDENING-QA-v3.9.0.md']
ck('v3.9.0 release assets exist',all(x.exists() for x in required))
passed=sum(1 for x in checks if x['pass'])
out={'version':'3.9.0','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Current Package Validation — v3.9.0','',f"**Status:** {out['status']} — {passed}/{len(checks)} checks PASS",'']
for x in checks: lines.append(f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}"+(f" — `{x['note']}`" if x['note']!='' else ''))
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(out['status'],passed,'/',len(checks))
if out['status']!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x)
    raise SystemExit(1)
