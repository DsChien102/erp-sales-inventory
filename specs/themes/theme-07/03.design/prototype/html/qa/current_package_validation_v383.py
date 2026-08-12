#!/usr/bin/env python3
import json
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
manifest=json.loads((HTML/'manifest.json').read_text(encoding='utf-8'))
wb=json.loads((HTML/'workbench-data.json').read_text(encoding='utf-8'))
reg=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf-8'))
rt=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/runtime-state-registry-v3.7.0.json').read_text(encoding='utf-8'))
ck('root package identifies v3.8.3','v3.8.3' in root_readme and 'v3.8.3' in root_index)
ck('prototype metadata identifies v3.8.3 while business registries remain v3.7.0',proto.get('version')=='3.8.3' and manifest.get('version')=='3.8.3' and manifest.get('parentVersion')=='3.8.2' and wb.get('version')=='3.7.0' and reg.get('version')=='3.7.0' and rt.get('version')=='3.7.0')
ck('v3.8.3 patch loads after v3.8.2',html_index.find('v383-warehouse-home-clarity-polish.css')>html_index.find('v382-warehouse-home-action-placement.css') and html_index.find('v383-warehouse-home-clarity-polish.js')>html_index.find('v382-warehouse-home-action-placement.js'))
ck('canonical device remains 402x874',proto.get('defaultViewport')=={'width':402,'height':874})
ck('Figma DS remains UI authority','figmaDesignSystem' in manifest.get('authority',{}) and 'UI authority' in manifest.get('authority',{}).get('figmaDesignSystem',''))

files={
 'static':'STATIC-CONSISTENCY-QA-v3.8.3.json',
 'clarity':'WAREHOUSE-HOME-CLARITY-QA-v3.8.3.json',
 'nav':'LIST-NAVIGATION-STATE-QA-v3.8.3.json',
 'rhythm':'LIST-SURFACE-RHYTHM-QA-v3.8.3.json',
 'footer':'FOOTER-ACTION-QA-v3.8.3.json',
 'flow':'FLOW-LOGIC-E2E-QA-v3.8.3.json',
 'full':'FULL-THEME-COMPLETION-QA-v3.8.3.json',
 'coh':'REPRESENTATIVE-COHERENCE-QA-v3.8.3.json',
 'helper':'RADIO-HELPER-DS-QA-v3.8.3.json',
 'runtime':'RUNTIME-UI-QA-v3.8.3.json',
 'smoke':'ALL-FLOWS-RUNTIME-SMOKE-v3.8.3.json',
 'device':'DEVICE-FRAME-QA-v3.8.3.json'
}
data={k:load(v) for k,v in files.items()}
ck('static consistency gate passes',data['static'].get('passed')==data['static'].get('total')==56,f"{data['static'].get('passed')}/{data['static'].get('total')}")
ck('Warehouse Home clarity gate passes',data['clarity'].get('status')=='PASS' and data['clarity'].get('passed')==data['clarity'].get('total')==28,f"{data['clarity'].get('passed')}/{data['clarity'].get('total')}")
ck('list navigation-state gate passes',data['nav'].get('status')=='PASS' and data['nav'].get('routeStatesScanned')==518)
ck('list/card rhythm gate passes',data['rhythm'].get('status')=='PASS' and data['rhythm'].get('routeStatesScanned')==518 and data['rhythm'].get('postFixIndependentCollisionPairs')==0)
ck('footer gate passes',data['footer'].get('status')=='PASS' and all(x.get('status')=='PASS' for x in data['footer'].get('checks',[])))
ck('semantic flow/logic gate passes',data['flow'].get('status')=='PASS' and data['flow'].get('checks')==21)
ck('full-theme completion gate passes',data['full'].get('passed')==data['full'].get('total')==14)
ck('representative coherence gate passes',data['coh'].get('passed')==data['coh'].get('total')==8)
ck('radio/helper DS gate passes',data['helper'].get('status')=='PASS' and data['helper'].get('routeStatesScanned')==518)
ck('runtime UI gate passes',data['runtime'].get('passed')==data['runtime'].get('total')==14 and data['runtime'].get('declared_states')==518)
ck('all-flow runtime smoke passes',data['smoke'].get('status')=='PASS' and data['smoke'].get('renders')==89 and not data['smoke'].get('failures') and not data['smoke'].get('errors'))
ck('device frame gate passes',data['device'].get('status')=='PASS' and data['device'].get('passed')==data['device'].get('total')==7 and data['device'].get('screensChecked')==89)
passed=sum(1 for x in checks if x['pass'])
out={'version':'3.8.3','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.8.3.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Current Package Validation — v3.8.3','',f"**Status:** {out['status']} — {passed}/{len(checks)} checks PASS",'']
for x in checks: lines.append(f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}" + (f" — `{x['note']}`" if x['note']!='' else ''))
(QA/'CURRENT-PACKAGE-VALIDATION-v3.8.3.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(out['status'],passed,'/',len(checks))
if out['status']!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x)
    raise SystemExit(1)
