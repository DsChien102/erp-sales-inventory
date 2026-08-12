#!/usr/bin/env python3
import json
from pathlib import Path
BASE=Path(__file__).resolve().parents[6]
HTML=BASE/'specs/themes/theme-07/prototype/html'; QA=HTML/'qa'
checks=[]
def ck(n,v,note=''): checks.append({'name':n,'pass':bool(v),'note':note})
def load(name): return json.loads((QA/name).read_text(encoding='utf-8'))
def text(rel): return (BASE/rel).read_text(encoding='utf-8')
readme=text('README.md'); root_index=text('index.html'); html_index=(HTML/'index.html').read_text(encoding='utf-8')
proto=json.loads((HTML/'prototype.manifest.json').read_text(encoding='utf-8')); outer=json.loads((BASE/'specs/themes/theme-07/prototype/prototype.manifest.json').read_text(encoding='utf-8')); manifest=json.loads((HTML/'manifest.json').read_text(encoding='utf-8')); wb=json.loads((HTML/'workbench-data.json').read_text(encoding='utf-8')); reg=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf-8')); cat=json.loads((BASE/'specs/themes/theme-07/prototype/contracts/screen-catalog.json').read_text(encoding='utf-8'))
focused=load('BJ06-DEEP-REVIEW-QA-v3.9.4.json'); prior=load('PRIOR-LOCKED-BJ-REGRESSION-v3.9.4.json'); frozen=load('FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.4.json'); enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.9.4.json'); flow=load('FLOW-LOGIC-E2E-QA-v3.9.4.json'); smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.9.4.json'); runtime=load('RUNTIME-UI-QA-v3.9.4.json'); coh=load('REPRESENTATIVE-COHERENCE-QA-v3.9.4.json'); device=load('DEVICE-FRAME-QA-v3.9.4.json')
ck('root package identifies v3.9.4','v3.9.4' in readme and 'v3.9.4' in root_index)
ck('prototype metadata identifies v3.9.4 with parent v3.9.3',proto.get('version')=='3.9.4' and proto.get('parentVersion')=='3.9.3' and outer.get('version')=='3.9.4' and outer.get('parentVersion')=='3.9.3' and manifest.get('version')=='3.9.4' and manifest.get('parentVersion')=='3.9.3')
ck('current registries identify v3.9.4',wb.get('version')=='3.9.4' and reg.get('version')=='3.9.4' and cat.get('version')=='3.9.4' and cat.get('package_version')=='3.9.4')
ck('v3.9.4 BJ06 CSS/JS load after v3.9.3 BJ05 hardening','v394-bj06-semantic-hardening.css' in html_index and 'v394-bj06-semantic-hardening.js' in html_index and html_index.index('v394-bj06-semantic-hardening.css')>html_index.index('v393-bj05-semantic-hardening.css') and html_index.index('v394-bj06-semantic-hardening.js')>html_index.index('v393-bj05-semantic-hardening.js'))
ck('canonical viewport remains 402x874',proto.get('defaultViewport')=={'width':402,'height':874})
ck('Figma DS remains UI authority','UI authority' in manifest.get('authority',{}).get('figmaDesignSystem',''))
ck('BJ06 focused deep-review passes',focused.get('status')=='PASS' and focused.get('passed')==focused.get('total')==40,f"{focused.get('passed')}/{focused.get('total')}")
ck('prior locked BJ regression passes',prior.get('status')=='PASS' and prior.get('passed')==prior.get('total')==8,f"{prior.get('passed')}/{prior.get('total')}")
ck('frozen-source immutability passes',frozen.get('status')=='PASS' and not frozen.get('differences'))
ck('full-theme end-user regression passes',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19,f"{enduser.get('passed')}/{enduser.get('total')}")
ck('flow logic regression passes',flow.get('status')=='PASS' and flow.get('checks')==21 and flow.get('version')=='3.9.4')
ck('all-flow runtime smoke passes',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI regression passes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==518 and runtime.get('version')=='3.9.4')
ck('representative coherence passes',coh.get('passed')==coh.get('total')==8 and coh.get('version')=='3.9.4')
ck('device-frame regression passes',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
# Semantic trace checks.
dec=text('specs/themes/theme-07/know-how/decisions/decision-register.md'); data=text('specs/themes/theme-07/srs/04-data-entities.md'); bc=text('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md'); flowdoc=text('specs/themes/theme-07/prototype/flows/UIF-06-BJ-06.md'); patch=(HTML/'v394-bj06-semantic-hardening.js').read_text(encoding='utf-8')
ck('approved decision pack T7-DR-131..137 is present',all(f'T7-DR-{n}' in dec for n in range(131,138)))
ck('ApprovalCase supports line-exception subject cardinality',all(x in data for x in ['LINE_EXCEPTION','subject_line_id','subject_snapshot_hash','SUPERSEDED']))
ck('customer-return authorization/partial contract is explicit','authorized_return_quantity' in bc and 'remaining_authorized_quantity' in bc and 'partial' in bc.lower())
ck('classification owns system-derived expiry','EXPIRED = SYSTEM_DERIVED' in bc and 'không yêu cầu reason/evidence/approval' in bc)
ck('UNKNOWN recovery is same-operation and no blind retry','same operation identity' in flowdoc and 'không blind retry' in flowdoc and 'UIF-17' in flowdoc)
ck('evidence runtime binds content, version and identity','evidenceVersion' in patch and 'evidenceHash' in patch and "crypto.subtle.digest('SHA-256'" in patch)
ck('result UI does not invent RR receipt identity','RR-260817-03' not in json.dumps(wb,ensure_ascii=False) and 'Return receipt' not in json.dumps([s for s in reg['screens'] if s['id']=='SCR-035'],ensure_ascii=False))
ck('BJ06 active screens carry validated v3.9.4 deep-review trace',all(s.get('deep_review',{}).get('version')=='3.9.4' and s.get('deep_review',{}).get('status')=='APPROVED_AND_VALIDATED' for s in reg['screens'] if s.get('id') in {f'SCR-{i:03d}' for i in range(30,36)}))
ck('BJ01/BJ02/BJ05 deep-review traces remain locked',next(s for s in reg['screens'] if s['id']=='SCR-001').get('deep_review',{}).get('version')=='3.9.1' and next(s for s in reg['screens'] if s['id']=='SCR-006').get('deep_review',{}).get('version')=='3.9.2' and next(s for s in reg['screens'] if s['id']=='SCR-025').get('deep_review',{}).get('version')=='3.9.3')
ck('focused visual evidence contains six captures',len(list((QA/'v394-bj06-captures').glob('*.png')))==6, len(list((QA/'v394-bj06-captures').glob('*.png')))) # six user-visible UI captures
required=[HTML/'v394-bj06-semantic-hardening.css',HTML/'v394-bj06-semantic-hardening.js',QA/'BJ06-DEEP-REVIEW-QA-v3.9.4.md',QA/'PRIOR-LOCKED-BJ-REGRESSION-v3.9.4.md']
ck('v3.9.4 release assets exist',all(x.exists() for x in required))
passed=sum(x['pass'] for x in checks); out={'version':'3.9.4','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.4.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.4.md').write_text('\n'.join(['# Current Package Validation — v3.9.4','',f'**Status:** {out["status"]} — {passed}/{len(checks)} checks PASS','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — `{x["note"]}`' if x['note']!='' else '') for x in checks])+'\n',encoding='utf-8')
print(out['status'],passed,'/',len(checks))
if out['status']!='PASS':
 for x in checks:
  if not x['pass']: print('FAIL',x)
 raise SystemExit(1)
