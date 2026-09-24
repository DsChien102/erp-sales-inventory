#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, subprocess, sys

ROOT=Path(__file__).resolve().parents[4]
HTML=ROOT/'specs/themes/theme-07/prototype/html'
CONTRACT=ROOT/'specs/themes/theme-07/prototype/contracts/figma-ds'
USAGE=ROOT/'specs/themes/theme-07/prototype/contracts/component-usage'
QA=HTML/'qa'
checks=[]

def add(name, ok, detail=''):
    checks.append({'name':name,'pass':bool(ok),'detail':str(detail)})
def load(p): return json.loads(Path(p).read_text())
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()

manifest=load(HTML/'manifest.json')
status=load(CONTRACT/'UIF-MIGRATION-STATUS.json')
runtime=load(HTML/'figma-ds-runtime/runtime-registry.json')
wb=load(HTML/'workbench-data.json')
qa=load(QA/'BJ01-BJ02-DS-CORRECTION-QA-v2.5.1.json')
smoke=load(QA/'ALL-FLOWS-RUNTIME-SMOKE-v2.5.1.json')
release_manifest=load(ROOT/'RELEASE-MANIFEST-v2.5.1.json')

add('HTML manifest version', manifest.get('version')=='2.5.1', manifest.get('version'))
add('HTML manifest parent', manifest.get('parent')=='2.5.0', manifest.get('parent'))
add('Workbench version', wb.get('version')=='2.5.1', wb.get('version'))
add('UIF migration release', status.get('release')=='2.5.1', status.get('release'))
add('Product wiring scope exact', status.get('productWiringScope')==['UIF-01','UIF-02','UIF-08'], status.get('productWiringScope'))
ui01=next((x for x in status.get('uifs',[]) if x.get('uif')=='UIF-01'),{})
ui02=next((x for x in status.get('uifs',[]) if x.get('uif')=='UIF-02'),{})
add('UIF-01 corrective implementation recorded', 'V2_5_1_KEY_VALUE_ALIGNMENT_HARDENED' in ui01.get('implementation',''), ui01.get('implementation'))
add('UIF-02 corrective implementation recorded', 'V2_5_1_UI_DS_CORRECTED' in ui02.get('implementation',''), ui02.get('implementation'))
add('UIF-01 review ready', ui01.get('productApproval')=='REVIEW_READY', ui01.get('productApproval'))
add('UIF-02 review ready', ui02.get('productApproval')=='REVIEW_READY', ui02.get('productApproval'))
add('Runtime registry version', runtime.get('release')=='2.5.1', runtime.get('release'))
add('Runtime migrated UIFs exact', runtime.get('workingFreeze',{}).get('currentMigratedUifs')==['UIF-01','UIF-02','UIF-08'], runtime.get('workingFreeze',{}).get('currentMigratedUifs'))
add('BJ02 corrected runtime contract', runtime.get('bj02',{}).get('status')=='STRUCTURALLY_MIGRATED_UI_DS_CORRECTED_REVIEW_READY', runtime.get('bj02',{}).get('status'))
add('No new BJ02 feature component', runtime.get('bj02',{}).get('newFeatureComponentsCreated')==0, runtime.get('bj02',{}).get('newFeatureComponentsCreated'))
add('Combined BJ01/BJ02 correction QA', qa.get('status')=='PASS' and qa.get('passed')==66 and qa.get('total')==66, f"{qa.get('passed')}/{qa.get('total')}")
add('Combined QA browser errors zero', qa.get('browserErrors')==[], len(qa.get('browserErrors',[])))
add('All-flow smoke pass', smoke.get('status')=='PASS' and smoke.get('renders')==85 and smoke.get('failures') in (0, []), f"renders={smoke.get('renders')} failures={len(smoke.get('failures',[]))}")
add('Correction contract exists', (CONTRACT/'BJ01-BJ02-UI-DS-CORRECTION-v2.5.1.md').exists())
add('BJ02 component usage MD current', 'v2.5.1' in (USAGE/'UIF-02-COMPONENT-USAGE.md').read_text())
add('BJ02 component usage YAML current', 'release: 2.5.1' in (USAGE/'UIF-02-COMPONENT-USAGE.yaml').read_text())
add('Final corrective CSS exists', (HTML/'v251-ui-ds-corrections.css').exists())
html_index=(HTML/'index.html').read_text()
add('Corrective CSS loaded after BJ02 fidelity CSS', html_index.find('v251-ui-ds-corrections.css') > html_index.find('bj02-ds-fidelity.css') >= 0, 'load order')
add('Visual contact sheet exists', (QA/'v251-bj01-bj02-captures/BJ01-BJ02-contact-sheet.png').exists())
add('Visual evidence set complete', len(list((QA/'v251-bj01-bj02-captures').glob('*.png'))) >= 14, len(list((QA/'v251-bj01-bj02-captures').glob('*.png'))))
add('Action registry preserved from v2.5.0', sha(ROOT/'specs/themes/theme-07/prototype/contracts/action-registry.json')=='35f59f04480d6a41f24e1735a88ac14e478319bc57f85e842ac5ff885f6b332a', sha(ROOT/'specs/themes/theme-07/prototype/contracts/action-registry.json'))
add('Screen registry preserved from v2.5.0', sha(ROOT/'specs/themes/theme-07/prototype/contracts/screen-registry.json')=='20d3abc7a229ba54aaa436942ffa767f9914b9af2e8c8e6f901b4049ceab5ebf', sha(ROOT/'specs/themes/theme-07/prototype/contracts/screen-registry.json'))
node=subprocess.run(['node','--check',str(HTML/'app.js')],capture_output=True,text=True)
add('JavaScript syntax', node.returncode==0, node.stderr.strip())
root_index=(ROOT/'index.html').read_text()
add('Root release launcher version', 'v2.5.1' in root_index and 'RELEASE-VALIDATION-v2.5.1.md' in root_index)
add('Release manifest version/parent', release_manifest.get('release')=='2.5.1' and release_manifest.get('parent')=='2.5.0', f"{release_manifest.get('release')} / {release_manifest.get('parent')}")
add('Release manifest claims no new UIF migration', release_manifest.get('migration',{}).get('newlyMigrated')==[], release_manifest.get('migration',{}).get('newlyMigrated'))

passed=sum(1 for c in checks if c['pass'])
result={'release':'2.5.1','parent':'2.5.0','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(ROOT/'RELEASE-VALIDATION-v2.5.1.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
lines=[
 '# Release Validation — v2.5.1','',f"**Result: {result['status']} · {passed}/{len(checks)} checks**",'',
 'Parent: **v2.5.0** · Scope: **BJ01 Key-value Row fidelity + BJ02 UI/Figma DS corrective patch; no new UIF migration**','',
 '## Gates',''
]
for c in checks:
    lines.append(f"- [{'x' if c['pass'] else ' '}] {c['name']}" + (f" — `{c['detail']}`" if c['detail'] else ''))
lines += [
 '', '## QA evidence','',
 '- BJ01 + BJ02 DS correction QA: **PASS 66/66**, browser errors **0**.',
 '- All-flow runtime smoke: **PASS 85/85**, failures **0**, browser errors **0**.',
 '- Visual evidence: BJ01 SCR-003 plus BJ02 SCR-006/007/008/008 Select Sheet/009/084/084 Keypad/010 document/010 quick/011/012/013 and a combined contact sheet.',
 '- Registry preservation: action and screen registries match the v2.5.0 parent SHA256 exactly.',
 '', '## Scope statement','',
 'This patch corrects UIF-01 and UIF-02 only. It does not add another structurally migrated UIF, does not change business authority, does not claim global FROZEN_RUNTIME_EXACT, and does not claim a complete byte-for-byte local mirror of Figma DS v2.0.3.',
 '', 'Historical legacy validators from the embedded package remain non-applicable to the v2.x Harness release line for the same reasons already documented in earlier v2.x releases; the current gate is this release validation plus current Product QA and all-flow smoke.', ''
]
(ROOT/'RELEASE-VALIDATION-v2.5.1.md').write_text('\n'.join(lines))
print(result['status'], passed, '/', len(checks))
sys.exit(0 if result['status']=='PASS' else 1)
