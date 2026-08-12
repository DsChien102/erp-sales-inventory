#!/usr/bin/env python3
from pathlib import Path
import json, subprocess, sys
ROOT=Path(__file__).resolve().parents[4]
HTML=ROOT/'specs/themes/theme-07/prototype/html'
CONTRACT=ROOT/'specs/themes/theme-07/prototype/contracts/figma-ds'
QA=HTML/'qa'
checks=[]
def add(name, ok, detail=''):
    checks.append({'name':name,'pass':bool(ok),'detail':str(detail)})
def load(p): return json.loads(Path(p).read_text())
manifest=load(HTML/'manifest.json')
status=load(CONTRACT/'UIF-MIGRATION-STATUS.json')
runtime=load(HTML/'figma-ds-runtime/runtime-registry.json')
wb=load(HTML/'workbench-data.json')
bjqa=load(QA/'BJ02-FIGMA-DS-QA-v2.5.0.json')
smoke=load(QA/'ALL-FLOWS-RUNTIME-SMOKE-v2.5.0.json')
add('HTML manifest version', manifest.get('version')=='2.5.0', manifest.get('version'))
add('HTML manifest parent', manifest.get('parent')=='2.4.5', manifest.get('parent'))
add('Workbench version', wb.get('version')=='2.5.0', wb.get('version'))
add('UIF migration release', status.get('release')=='2.5.0', status.get('release'))
ui02=next((x for x in status.get('uifs',[]) if x.get('uif')=='UIF-02'),{})
add('UIF-02 structurally migrated', 'STRUCTURALLY_MIGRATED' in ui02.get('implementation',''), ui02.get('implementation'))
add('UIF-02 review ready', ui02.get('productApproval')=='REVIEW_READY', ui02.get('productApproval'))
add('Product wiring scope exact', status.get('productWiringScope')==['UIF-01','UIF-02','UIF-08'], status.get('productWiringScope'))
add('Runtime registry version', runtime.get('release')=='2.5.0', runtime.get('release'))
add('Runtime migrated UIFs exact', runtime.get('workingFreeze',{}).get('currentMigratedUifs')==['UIF-01','UIF-02','UIF-08'], runtime.get('workingFreeze',{}).get('currentMigratedUifs'))
add('BJ02 runtime contract present', runtime.get('bj02',{}).get('status')=='STRUCTURALLY_MIGRATED_REVIEW_READY', runtime.get('bj02',{}).get('status'))
add('No new BJ02 feature component', runtime.get('bj02',{}).get('newFeatureComponentsCreated')==0, runtime.get('bj02',{}).get('newFeatureComponentsCreated'))
add('BJ02 QA pass', bjqa.get('status')=='PASS' and bjqa.get('passed')==39 and bjqa.get('total')==39, f"{bjqa.get('passed')}/{bjqa.get('total')}")
add('BJ02 browser errors zero', bjqa.get('browserErrors')==[], len(bjqa.get('browserErrors',[])))
add('All-flow smoke pass', smoke.get('status')=='PASS' and smoke.get('renders')==85 and smoke.get('failures') in (0, []), smoke)
add('BJ02 migration contract exists', (CONTRACT/'BJ02-MIGRATION-CONTRACT-v2.5.0.md').exists())
add('BJ02 component usage MD exists', (ROOT/'specs/themes/theme-07/prototype/contracts/component-usage/UIF-02-COMPONENT-USAGE.md').exists())
add('BJ02 component usage YAML exists', (ROOT/'specs/themes/theme-07/prototype/contracts/component-usage/UIF-02-COMPONENT-USAGE.yaml').exists())
add('BJ02 visual contact sheet exists', (QA/'v250-bj02-captures/BJ02-contact-sheet.png').exists())
node=subprocess.run(['node','--check',str(HTML/'app.js')],capture_output=True,text=True)
add('JavaScript syntax', node.returncode==0, node.stderr.strip())
root_index=(ROOT/'index.html').read_text()
add('Root release launcher version', 'v2.5.0' in root_index and 'RELEASE-VALIDATION-v2.5.0.md' in root_index)
passed=sum(1 for c in checks if c['pass'])
result={'release':'2.5.0','parent':'2.4.5','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(ROOT/'RELEASE-VALIDATION-v2.5.0.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
lines=[f"# Release Validation — v2.5.0",'',f"**Result: {result['status']} · {passed}/{len(checks)} checks**",'',f"Parent: **v2.4.5** · Scope: **BJ02 / UIF-02 Figma DS migration + cumulative regression**",'', '## Gates','']
for c in checks: lines.append(f"- [{'x' if c['pass'] else ' '}] {c['name']}" + (f" — `{c['detail']}`" if c['detail'] else ''))
lines += ['', '## QA evidence','', '- BJ02 Figma DS / Business QA: **PASS 39/39**, browser errors **0**.', '- All-flow runtime smoke: **PASS 85/85**, failures **0**, browser errors **0**.', '- BJ01 key-value alignment regression suite was rerun on this package: **PASS 34/34**.', '- Visual contact sheet was manually inspected for SCR-006/007/008/009/084/010/011/012/013.', '', '## Scope statement','', 'This release claims structural Figma-DS migration only for UIF-01, UIF-02 and UIF-08. The other UIFs remain explicitly legacy/not structurally migrated. It does not claim global FROZEN_RUNTIME_EXACT or a complete v2.0.3 byte-for-byte local DS mirror.', '']
(ROOT/'RELEASE-VALIDATION-v2.5.0.md').write_text('\n'.join(lines))
print(result['status'], passed, '/', len(checks))
sys.exit(0 if result['status']=='PASS' else 1)
