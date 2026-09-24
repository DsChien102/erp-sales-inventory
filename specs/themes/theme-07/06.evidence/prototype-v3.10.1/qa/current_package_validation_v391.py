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
proto=json.loads((HTML/'prototype.manifest.json').read_text(encoding='utf-8'))
outer=json.loads((BASE/'specs/themes/theme-07/prototype/prototype.manifest.json').read_text(encoding='utf-8'))
manifest=json.loads((HTML/'manifest.json').read_text(encoding='utf-8'))
wb=json.loads((HTML/'workbench-data.json').read_text(encoding='utf-8'))
reg=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf-8'))
rt=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/runtime-state-registry-v3.7.0.json').read_text(encoding='utf-8'))

deep=load('BJ01-DEEP-REVIEW-QA-v3.9.1.json')
enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.9.1.json')
flow=load('FLOW-LOGIC-E2E-QA-v3.9.1.json')
smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.9.1.json')
runtime=load('RUNTIME-UI-QA-v3.9.1.json')
device=load('DEVICE-FRAME-QA-v3.9.1.json')
coh=load('REPRESENTATIVE-COHERENCE-QA-v3.9.1.json')

ck('root package identifies v3.9.1','v3.9.1' in root_readme and 'v3.9.1' in root_index)
ck('prototype metadata identifies v3.9.1 and parent v3.9.0',proto.get('version')=='3.9.1' and outer.get('version')=='3.9.1' and manifest.get('version')=='3.9.1' and manifest.get('parentVersion')=='3.9.0')
ck('business registries retain cumulative registry version',wb.get('version')=='3.7.0' and reg.get('version')=='3.7.0' and rt.get('version')=='3.7.0')
ck('v3.9.1 scoped stylesheet loads in Product harness','v391-bj01-semantic-hardening.css' in html_index)
ck('canonical Product viewport remains 402x874',proto.get('defaultViewport')=={'width':402,'height':874})
ck('Figma DS remains UI authority','figmaDesignSystem' in manifest.get('authority',{}) and 'UI authority' in manifest.get('authority',{}).get('figmaDesignSystem',''))
ck('BJ01 deep-review gate passes',deep.get('status')=='PASS' and deep.get('passed')==deep.get('total')==31,f"{deep.get('passed')}/{deep.get('total')}")
ck('full-theme end-user regression passes',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19,f"{enduser.get('passed')}/{enduser.get('total')}")
ck('semantic flow/logic regression passes',flow.get('status')=='PASS' and flow.get('checks')==21)
ck('all-flow runtime smoke passes',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI regression passes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==518)
ck('device-frame regression passes',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
ck('representative coherence regression passes',coh.get('passed')==coh.get('total')==8)

caps=QA/'v391-bj01-captures'
cap_manifest=json.loads((caps/'manifest.json').read_text(encoding='utf-8')) if (caps/'manifest.json').exists() else []
ck('BJ01 focused visual evidence contains five captures',len(cap_manifest)==5 and all((caps/x['file']).exists() for x in cap_manifest),len(cap_manifest))

# Semantic scope guardrails.
start=app.index('const bj01Products = ['); end=app.index('let bj01Filter =',start)
fixture=app[start:end]
lot_objects=re.findall(r'\{\s*code:"[^"]+",\s*expiryDisplay:[^}]+\}',fixture)
ck('LOT fixtures do not carry reserved/available fields',bool(lot_objects) and all(not re.search(r'\b(reserved|available)\s*:',x) for x in lot_objects),len(lot_objects))
ck('BJ01 refresh no longer uses client clock','[data-bj01-refresh]' in app and not re.search(r'data-bj01-refresh[^\n]{0,260}new Date',app))
ck('BJ01 screen registry marks current deep-review status',all(s.get('deep_review',{}).get('version')=='3.9.1' for s in reg.get('screens',[]) if s.get('id') in {'SCR-001','SCR-003','SCR-004','SCR-005'}))
ck('buyer actor trace is present on monitoring surfaces',all('Người mua hàng' in s.get('actors',[]) for s in reg.get('screens',[]) if s.get('id') in {'SCR-001','SCR-003','SCR-004','SCR-005'}))

required=[HTML/'v391-bj01-semantic-hardening.css',QA/'BJ01-DEEP-REVIEW-QA-v3.9.1.md']
ck('v3.9.1 release assets exist',all(x.exists() for x in required))

passed=sum(1 for x in checks if x['pass'])
out={'version':'3.9.1','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.1.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Current Package Validation — v3.9.1','',f"**Status:** {out['status']} — {passed}/{len(checks)} checks PASS",'']
for x in checks: lines.append(f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}"+(f" — `{x['note']}`" if x['note']!='' else ''))
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.1.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(out['status'],passed,'/',len(checks))
if out['status']!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x)
    raise SystemExit(1)
