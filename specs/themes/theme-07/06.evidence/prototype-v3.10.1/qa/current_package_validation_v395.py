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
focused=load('BJ07-DEEP-REVIEW-QA-v3.9.5.json'); prior=load('PRIOR-LOCKED-BJ-REGRESSION-v3.9.5.json'); frozen=load('FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.5.json'); enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.9.5.json'); flow=load('FLOW-LOGIC-E2E-QA-v3.9.5.json'); smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.9.5.json'); runtime=load('RUNTIME-UI-QA-v3.9.5.json'); coh=load('REPRESENTATIVE-COHERENCE-QA-v3.9.5.json'); device=load('DEVICE-FRAME-QA-v3.9.5.json')
ck('root package identifies v3.9.5','v3.9.5' in readme and 'v3.9.5' in root_index)
ck('prototype metadata identifies v3.9.5 with parent v3.9.4',proto.get('version')=='3.9.5' and proto.get('parentVersion')=='3.9.4' and outer.get('version')=='3.9.5' and outer.get('parentVersion')=='3.9.4' and manifest.get('version')=='3.9.5' and manifest.get('parentVersion')=='3.9.4')
ck('current registries identify v3.9.5',wb.get('version')=='3.9.5' and reg.get('version')=='3.9.5' and cat.get('version')=='3.9.5' and cat.get('package_version')=='3.9.5')
ck('v3.9.5 BJ07 CSS/JS load after v3.9.4 BJ06 hardening','v395-bj07-semantic-hardening.css' in html_index and 'v395-bj07-semantic-hardening.js' in html_index and html_index.index('v395-bj07-semantic-hardening.css')>html_index.index('v394-bj06-semantic-hardening.css') and html_index.index('v395-bj07-semantic-hardening.js')>html_index.index('v394-bj06-semantic-hardening.js'))
ck('canonical viewport remains 402x874',proto.get('defaultViewport')=={'width':402,'height':874})
ck('Figma DS remains UI authority','UI authority' in manifest.get('authority',{}).get('figmaDesignSystem',''))
ck('release manifest status is QA PASS',manifest.get('status')=='WAVE_2_BJ07_DEEP_REVIEW_SEMANTIC_HARDENING_QA_PASS')
ck('BJ07 focused deep-review passes',focused.get('status')=='PASS' and focused.get('passed')==focused.get('total')==52,f"{focused.get('passed')}/{focused.get('total')}")
ck('prior locked BJ regression passes',prior.get('status')=='PASS' and prior.get('passed')==prior.get('total')==12,f"{prior.get('passed')}/{prior.get('total')}")
ck('frozen-source immutability passes',frozen.get('status')=='PASS' and frozen.get('fileCount')==108 and not frozen.get('differences'))
ck('full-theme end-user regression passes',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19,f"{enduser.get('passed')}/{enduser.get('total')}")
ck('flow logic regression passes',flow.get('status')=='PASS' and flow.get('checks')==21 and flow.get('version')=='3.9.5')
ck('all-flow runtime smoke passes',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI regression passes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==518 and runtime.get('version')=='3.9.5')
ck('representative coherence passes',coh.get('passed')==coh.get('total')==8 and coh.get('version')=='3.9.5')
ck('device-frame regression passes',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
dec=text('specs/themes/theme-07/know-how/decisions/decision-register.md'); data=text('specs/themes/theme-07/srs/04-data-entities.md'); bc=text('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md'); tech=text('specs/themes/theme-07/srs/07-technical-contracts.md'); flowdoc=text('specs/themes/theme-07/prototype/flows/UIF-07-BJ-07.md'); ucdir=BASE/'specs/themes/theme-07/srs/05-use-cases/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap'; uctext='\n'.join(p.read_text(encoding='utf-8') for p in sorted(ucdir.glob('*.md'))); patch=(HTML/'v395-bj07-semantic-hardening.js').read_text(encoding='utf-8')
ck('approved decision pack T7-DR-138..143 is present',all(f'T7-DR-{n}' in dec for n in range(138,144)))
ck('BC-IO-17 owns system supplier-return synchronization','BC-IO-17 — Synchronize supplier-return authorization' in bc and 'RTV_PENDING' in bc and 'Không yêu cầu commercial supplier price' in bc)
ck('supplier-return source slice identity is explicit',all(x in data for x in ['source_allocation_id','source_balance_id','origin_stock_state']))
ck('structured supplier-return physical observation is modeled','ENT-IO-12 — SupplierReturnPhysicalObservation' in data and all(x in data for x in ['QUANTITY','LOT','ITEM_NOT_FOUND','OTHER']))
ck('HandoverEvidence is source-agnostic', 'ENT-IO-11 — HandoverEvidence' in data and 'source_type' in data and 'source_document_id' in data and 'evidence_hash' in data and 'source-agnostic' in data)
ck('technical contracts expose supplier-return synchronization','BC-IO-17' in tech and 'SynchronizeSupplierReturnAuthorization' in tech and 'EVT-IO-11' in tech)
ck('BJ07 no longer maps warehouse mutation to BC-IO-10','BC-IO-17' in uctext and 'BC-IO-10' not in uctext)
ck('SCR-038 is explicitly excluded from active UIF07','SCR-038 **không thuộc UIF-07**' in flowdoc or 'SCR-038` **không thuộc UIF-07**' in flowdoc)
ck('runtime carries stable source identities and exact source slices',all(x in patch for x in ['sourceRequestId','sourceLineId','sourceAllocationId','sourceSlices','sourceBalanceId']))
ck('runtime mismatch observation uses approved taxonomy',all(x in patch for x in ["['QUANTITY','Sai số lượng']","['LOT','Sai lô']","['ITEM_NOT_FOUND','Không thấy hàng']","['OTHER','Khác']"]) and 'stockEffect:\'NONE\'' in patch)
ck('runtime handover evidence is source-agnostic supplier return','sourceType:\'SUPPLIER_RETURN\'' in patch and 'handoverEvidenceId' in patch and 'lineEvidence' in patch and 'evidenceHash' in patch)
ck('runtime contains no commercial supplier-price blocker',not any(x.lower() in patch.lower() for x in ['approved supplier price','supplier approved price','commercial price','giá nhà cung cấp']))
ck('BJ07 UNKNOWN uses same operation identity and BJ17 handoff','data-v350-action="handoff-unknown"' in patch and 'req.operationId' in patch and 'BJ-17' in flowdoc)
ids={'SCR-036','SCR-037','SCR-039','SCR-041'}
ck('BJ07 active screens carry validated v3.9.5 deep-review trace',all(s.get('deep_review',{}).get('version')=='3.9.5' and s.get('deep_review',{}).get('status')=='PASS' for s in reg['screens'] if s.get('id') in ids))
ck('focused visual evidence contains five captures',len(list((QA/'v395-bj07-captures').glob('*.png')))==5,len(list((QA/'v395-bj07-captures').glob('*.png'))))
required=[HTML/'v395-bj07-semantic-hardening.css',HTML/'v395-bj07-semantic-hardening.js',QA/'BJ07-DEEP-REVIEW-QA-v3.9.5.md',QA/'PRIOR-LOCKED-BJ-REGRESSION-v3.9.5.md',QA/'FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.5.md']
ck('v3.9.5 release assets exist',all(x.exists() for x in required))
passed=sum(x['pass'] for x in checks); out={'version':'3.9.5','status':'PASS' if passed==len(checks) else 'FAIL','passed':passed,'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.5.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.5.md').write_text('\n'.join(['# Current Package Validation — v3.9.5','',f'**Status:** {out["status"]} — {passed}/{len(checks)} checks PASS','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — `{x["note"]}`' if x['note']!='' else '') for x in checks])+'\n',encoding='utf-8')
print(out['status'],passed,'/',len(checks))
if out['status']!='PASS':
 for x in checks:
  if not x['pass']: print('FAIL',x)
 raise SystemExit(1)
