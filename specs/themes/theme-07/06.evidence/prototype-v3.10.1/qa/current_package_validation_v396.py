#!/usr/bin/env python3
from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[6]
HTML=ROOT/'specs/themes/theme-07/prototype/html'
QA=HTML/'qa'

def load(name): return json.loads((QA/name).read_text(encoding='utf-8'))
def j(rel): return json.loads((ROOT/rel).read_text(encoding='utf-8'))
def r(rel): return (ROOT/rel).read_text(encoding='utf-8')
checks=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':note})

focused=load('BJ04-DEEP-REVIEW-QA-v3.9.6.json')
prior=load('PRIOR-LOCKED-BJ-REGRESSION-v3.9.6.json')
frozen=load('FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.6.json')
wave=load('WAVE-2-CROSS-BJ-AUDIT-v3.9.6.json')
enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.9.6.json')
flowqa=load('FLOW-LOGIC-E2E-QA-v3.9.6.json')
smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.9.6.json')
runtime=load('RUNTIME-UI-QA-v3.9.6.json')
coh=load('REPRESENTATIVE-COHERENCE-QA-v3.9.6.json')
device=load('DEVICE-FRAME-QA-v3.9.6.json')
proto=j('specs/themes/theme-07/prototype/prototype.manifest.json')
outer=j('specs/themes/theme-07/prototype/html/prototype.manifest.json')
manifest=j('specs/themes/theme-07/prototype/html/manifest.json')
wb=j('specs/themes/theme-07/prototype/html/workbench-data.json')
reg=j('specs/themes/theme-07/prototype/contracts/screen-registry.json')
cat=j('specs/themes/theme-07/prototype/contracts/screen-catalog.json')
creg=j('specs/themes/theme-07/harness/contract-registry.json')
readme=r('README.md'); root_index=r('index.html'); html_index=r('specs/themes/theme-07/prototype/html/index.html')
bj04=r('specs/themes/theme-07/srs/02-business-journeys/04-BJ-04-quan-ly-vong-doi-giu-hang.md')
bc=r('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md')
data=r('specs/themes/theme-07/srs/04-data-entities.md')
tech=r('specs/themes/theme-07/srs/07-technical-contracts.md')
scr=r('specs/themes/theme-07/prototype/contracts/screens/SCR-021.md')
uc05=r('specs/themes/theme-07/srs/05-use-cases/BJ-05-lay-hang-va-ban-giao-don/UC-05-04-phuc-hoi-allocation-stale.md')

def find_id(o,target):
 if isinstance(o,dict):
  if o.get('id')==target:return o
  for v in o.values():
   x=find_id(v,target)
   if x:return x
 elif isinstance(o,list):
  for v in o:
   x=find_id(v,target)
   if x:return x
 return None

ck('root package identifies v3.9.6','v3.9.6' in readme and 'v3.9.6' in root_index)
ck('prototype metadata identifies v3.9.6 with parent v3.9.5',proto.get('version')=='3.9.6' and proto.get('parentVersion')=='3.9.5' and outer.get('version')=='3.9.6' and outer.get('parentVersion')=='3.9.5' and manifest.get('version')=='3.9.6' and manifest.get('parentVersion')=='3.9.5')
ck('current registries identify v3.9.6',wb.get('version')=='3.9.6' and reg.get('version')=='3.9.6' and cat.get('version')=='3.9.6' and cat.get('package_version')=='3.9.6')
ck('v3.9.6 BJ04 CSS/JS load after v3.9.5 BJ07 hardening','v396-bj04-semantic-hardening.css' in html_index and 'v396-bj04-semantic-hardening.js' in html_index and html_index.index('v396-bj04-semantic-hardening.css')>html_index.index('v395-bj07-semantic-hardening.css') and html_index.index('v396-bj04-semantic-hardening.js')>html_index.index('v395-bj07-semantic-hardening.js'))
ck('BJ04 focused deep-review passes',focused.get('status')=='PASS' and focused.get('passed')==focused.get('total')==52,f"{focused.get('passed')}/{focused.get('total')}")
ck('prior locked BJ regression passes',prior.get('status')=='PASS' and prior.get('passed')==prior.get('total')==15,f"{prior.get('passed')}/{prior.get('total')}")
ck('frozen-source immutability passes',frozen.get('status')=='PASS' and frozen.get('filesCompared')==108 and not frozen.get('added') and not frozen.get('removed') and not frozen.get('changed'))
ck('Wave 2 cross-BJ audit passes',wave.get('status')=='PASS' and wave.get('passed')==wave.get('total')==30,f"{wave.get('passed')}/{wave.get('total')}")
ck('full-theme end-user regression passes',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19,f"{enduser.get('passed')}/{enduser.get('total')}")
ck('flow logic regression passes',flowqa.get('status')=='PASS' and flowqa.get('checks')==21 and flowqa.get('version')=='3.9.6')
ck('all-flow runtime smoke passes',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI regression passes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==514 and runtime.get('version')=='3.9.6')
ck('representative coherence passes',coh.get('passed')==coh.get('total')==8 and coh.get('version')=='3.9.6')
ck('device-frame regression passes',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)

# Approved semantic package
ck('reservation capability uses explicit source policy and Advanced Stock',all(x in bj04 for x in ['NONE','ALL_OR_NOTHING','PARTIAL_ALLOWED','ADVANCED']))
ck('reservation quantity model distinguishes current held and consumed history',all(x in data for x in ['reserved_base_quantity','consumed_base_quantity','requested_base_quantity']))
ck('reservation stores transaction UOM/conversion snapshot',all(x in data for x in ['transaction_uom_snapshot','conversion_to_base','conversion_version']))
ck('deterministic priority is captured',all(x in bj04 for x in ['reservation_priority','source_confirmed_at','source_line_id']))
ck('ReservationGroup combo aggregate exists','ENT-IO-13 — ReservationGroup' in data and 'reservation_group_id' in data)
ck('BJ04/BJ05 boundary is explicit','allocation_review_required' in bc and 'BC-IO-15' in uc05 and 'không trao ownership PickAllocation cho BC-IO-06' in uc05)
ck('API-C-06 is adjustments, not release-or-reallocate','POST /v1/reservations/{id}/adjustments' in tech and 'POST /v1/reservations/{id}/release-or-reallocate' not in tech)
ck('SCR-021 current contract is read-only per-line projection','read-only' in scr.lower() and 'Không dùng global state `FULL`, `PARTIAL`, `SHORT`, `RELEASED`, `STALE`' in scr)

screen=find_id(reg,'SCR-021')
ck('SCR-021 canonical active states are READY/LOADING/PERMISSION_DENIED',screen and screen.get('states')==['READY','LOADING','PERMISSION_DENIED'],screen.get('states') if screen else None)
ck('SCR-021 has validated v3.9.6 deep-review trace',screen and screen.get('deep_review',{}).get('version')=='3.9.6' and screen.get('deep_review',{}).get('status')=='PASS')
bc06=find_id(creg,'BC-IO-06'); api06=find_id(creg,'API-C-06')
ck('Harness BC-IO-06 excludes BJ05 ownership',bc06 and bc06.get('stories')==['UC-04-02','UC-04-03','UC-04-04'] and 'PickAllocation' in bc06.get('finality_semantics',''))
ck('Harness API-C-06 is the new adjustments operation',api06 and 'adjustments' in api06.get('name','') and api06.get('stories')==['UC-04-02','UC-04-03','UC-04-04'])

required=[HTML/'v396-bj04-semantic-hardening.css',HTML/'v396-bj04-semantic-hardening.js',QA/'BJ04-DEEP-REVIEW-QA-v3.9.6.md',QA/'PRIOR-LOCKED-BJ-REGRESSION-v3.9.6.md',QA/'FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.6.md',QA/'WAVE-2-CROSS-BJ-AUDIT-v3.9.6.md']
ck('v3.9.6 release assets exist',all(x.exists() for x in required),[str(x) for x in required if not x.exists()])

passed=sum(x['pass'] for x in checks)
out={'version':'3.9.6','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.6.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.6.md').write_text('\n'.join(['# Current Package Validation — v3.9.6','',f'**Status:** {out["status"]} — {passed}/{len(checks)} checks PASS','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — `{x["note"]}`' if x['note']!='' else '') for x in checks])+'\n')
print(out['status'],passed,len(checks))
if out['status']!='PASS':
 for x in checks:
  if not x['pass']: print('FAIL',x['name'],x['note'])
 sys.exit(1)
