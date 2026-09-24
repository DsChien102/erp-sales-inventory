#!/usr/bin/env python3
import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[6]
HTML = BASE / 'specs/themes/theme-07/prototype/html'
QA = HTML / 'qa'
checks=[]
def ck(name, ok, note=''):
    checks.append({'name':name,'pass':bool(ok),'note':note})
def load(name):
    return json.loads((QA/name).read_text(encoding='utf-8'))

root_readme=(BASE/'README.md').read_text(encoding='utf-8')
root_index=(BASE/'index.html').read_text(encoding='utf-8')
html_index=(HTML/'index.html').read_text(encoding='utf-8')
proto=json.loads((HTML/'prototype.manifest.json').read_text(encoding='utf-8'))
wb=json.loads((HTML/'workbench-data.json').read_text(encoding='utf-8'))
reg=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf-8'))
rt=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/runtime-state-registry-v3.7.0.json').read_text(encoding='utf-8'))

ck('root package identifies v3.8.0','v3.8.0' in root_readme and 'v3.8.0' in root_index)
ck('prototype metadata identifies v3.8.0 while business registries remain v3.7.0',proto.get('version')=='3.8.0' and wb.get('version')=='3.7.0' and reg.get('version')=='3.7.0' and rt.get('version')=='3.7.0',{'prototype':proto.get('version'),'workbench':wb.get('version'),'screenRegistry':reg.get('version'),'runtime':rt.get('version')})
ck('v3.8.0 task-driven patch loads after v3.7.1',html_index.find('v380-task-driven-warehouse-home.css')>html_index.find('v371-flat-hub-navigation.css') and html_index.find('v380-task-driven-warehouse-home.js')>html_index.find('v371-flat-hub-navigation.js'))
ck('canonical device remains 402x874',proto.get('defaultViewport')=={'width':402,'height':874})
ck('prototype authority identifies Figma DS as UI authority','figmaDesignSystem' in proto.get('authority',{}) and 'UI authority' in proto.get('authority',{}).get('figmaDesignSystem','') and 'htmlPrototype' in proto.get('authority',{}),proto.get('authority',{}))

static=load('STATIC-CONSISTENCY-QA-v3.8.0.json')
nav=load('LIST-NAVIGATION-STATE-QA-v3.8.0.json')
rhythm=load('LIST-SURFACE-RHYTHM-QA-v3.8.0.json')
footer=load('FOOTER-ACTION-QA-v3.8.0.json')
flow=load('FLOW-LOGIC-E2E-QA-v3.8.0.json')
full=load('FULL-THEME-COMPLETION-QA-v3.8.0.json')
coh=load('REPRESENTATIVE-COHERENCE-QA-v3.8.0.json')
helper=load('RADIO-HELPER-DS-QA-v3.8.0.json')
runtime=load('RUNTIME-UI-QA-v3.8.0.json')
smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.8.0.json')
device=load('DEVICE-FRAME-QA-v3.8.0.json')
home=load('TASK-DRIVEN-WAREHOUSE-HOME-QA-v3.8.0.json')

ck('static consistency gate passes',static.get('passed')==static.get('total')==48,f"{static.get('passed')}/{static.get('total')}")
ck('task-driven Warehouse Home gate passes',home.get('status')=='PASS' and all(x.get('pass') for x in home.get('checks',[])),f"checks={sum(1 for x in home.get('checks',[]) if x.get('pass'))}/{len(home.get('checks',[]))}")
ck('radio/helper DS gate passes across all declared states',helper.get('status')=='PASS' and helper.get('routeStatesScanned')==518 and all(x.get('pass') for x in helper.get('checks',[])),{'checks':f"{sum(1 for x in helper.get('checks',[]) if x.get('pass'))}/{len(helper.get('checks',[]))}",'states':helper.get('routeStatesScanned')})
ck('list navigation-state gate passes across all declared states',nav.get('status')=='PASS' and nav.get('routeStatesScanned')==518 and all(x.get('pass') for x in nav.get('checks',[])),{'checks':f"{sum(1 for x in nav.get('checks',[]) if x.get('pass'))}/{len(nav.get('checks',[]))}",'states':nav.get('routeStatesScanned')})
ck('list/card rhythm regression passes',rhythm.get('status')=='PASS' and rhythm.get('postFixIndependentCollisionPairs')==0 and rhythm.get('routeStatesScanned')==518,{'states':rhythm.get('routeStatesScanned'),'collisions':rhythm.get('postFixIndependentCollisionPairs')})
ck('footer regression gate passes',footer.get('status')=='PASS' and all(x.get('status')=='PASS' for x in footer.get('checks',[])),f"{sum(1 for x in footer.get('checks',[]) if x.get('status')=='PASS')}/{len(footer.get('checks',[]))}")
ck('semantic flow/logic gate passes',flow.get('status')=='PASS' and flow.get('checks')==21,f"{flow.get('checks')}/21")
ck('full-theme completion gate passes',full.get('passed')==full.get('total')==14,f"{full.get('passed')}/{full.get('total')}")
ck('representative coherence gate passes',coh.get('passed')==coh.get('total')==8,f"{coh.get('passed')}/{coh.get('total')}")
ck('runtime UI gate passes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==518,f"{runtime.get('passed')}/{runtime.get('total')} states={runtime.get('declared_states')}")
ck('all-flow runtime smoke passes',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'),f"renders={smoke.get('renders')} failures={len(smoke.get('failures',[]))} errors={len(smoke.get('errors',[]))}")
ck('device frame gate passes',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7,f"{device.get('passed')}/{device.get('total')}")

passed=sum(1 for x in checks if x['pass'])
out={'version':'3.8.0','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.8.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding='utf-8')
lines=['# Current Package Validation — v3.8.0','',f"**Status:** {out['status']} — {passed}/{len(checks)} checks PASS",'']
for x in checks: lines.append(f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}" + (f" — `{x['note']}`" if x['note']!='' else ''))
(QA/'CURRENT-PACKAGE-VALIDATION-v3.8.0.md').write_text('\n'.join(lines)+"\n",encoding='utf-8')
print(f"{out['status']} {passed}/{len(checks)}")
if out['status']!='PASS': raise SystemExit(1)
