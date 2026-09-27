#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[4]
HTML=ROOT/'specs/themes/theme-07/prototype/html'; CON=ROOT/'specs/themes/theme-07/prototype/contracts/figma-ds'; QA=HTML/'qa'
checks=[]
def add(n,ok,d=''): checks.append({'name':n,'pass':bool(ok),'detail':str(d)})
def load(p): return json.loads(Path(p).read_text())
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
manifest=load(HTML/'manifest.json'); wb=load(HTML/'workbench-data.json'); status=load(CON/'UIF-MIGRATION-STATUS.json'); runtime=load(HTML/'figma-ds-runtime/runtime-registry.json'); rel=load(ROOT/'RELEASE-MANIFEST-v2.5.4.json')
ux=load(QA/'BJ02-INPUT-UX-QA-v2.5.4.json'); layout=load(QA/'BJ02-STATE-LAYOUT-QA-v2.5.4.json'); smoke=load(QA/'ALL-FLOWS-RUNTIME-SMOKE-v2.5.4.json')
add('HTML manifest version/parent',manifest.get('version')=='2.5.4' and manifest.get('parent')=='2.5.3',f"{manifest.get('version')} / {manifest.get('parent')}")
add('Workbench version',wb.get('version')=='2.5.4',wb.get('version'))
add('Migration status release',status.get('release')=='2.5.4',status.get('release'))
add('Migrated UIF scope unchanged',status.get('productWiringScope')==['UIF-01','UIF-02','UIF-08'],status.get('productWiringScope'))
add('Runtime release',runtime.get('release')=='2.5.4',runtime.get('release'))
add('BJ02 focused interaction QA',ux.get('status')=='PASS' and ux.get('passed')==ux.get('total')==20, f"{ux.get('passed')}/{ux.get('total')}")
add('BJ02 all-state layout QA',layout.get('status')=='PASS' and layout.get('renders')==61 and not layout.get('failures') and not layout.get('browserErrors'), f"{layout.get('renders')}/61")
add('All-flow runtime smoke',smoke.get('status')=='PASS' and smoke.get('renders')==85 and not smoke.get('failures') and not smoke.get('errors'),f"{smoke.get('renders')}/85")
app=(HTML/'app.js').read_text(); css=(HTML/'v254-bj02-input-ux-correction.css').read_text(); idx=(HTML/'index.html').read_text()
add('v2.5.4 correction stylesheet loaded last',idx.rfind('v254-bj02-input-ux-correction.css')>idx.rfind('v253-info-row-live-sync.css')>0,'load order')
add('Editable quantity no longer uses Key-value Row','data-ds-role="quantity-input-composition"' in app and 'data-composed-from="VTextField input anatomy,VNumericKeypadSheet"' in app,'explicit numeric input composition')
add('Four classification keys retained',all(f'key: "{x}"' in app for x in ['accepted','quarantine','damaged','rejected']),'4 authoritative inputs')
add('Quantity input visible field anatomy','height:44px' in css and 'border:1px solid var(--vet45-v2-border-default' in css and 'border-radius:var(--vet45-v2-radius-3,8px)' in css,'44px / border / radius8')
add('Document not-received uses danger link','bj02-danger-link-action not-received-action' in app and 'VButtonVariant.link' in app[app.find('const notReceived'):app.find('const removeQuickLine')],'link danger')
add('Quick remove uses same danger link','bj02-danger-link-action remove-line-action' in app,'shared treatment')
add('Quick UOM selection inside selected-product card','quick-overview-uom-picker' in app and 'quick-uom-choice-group' in app,'v2.5.0 interaction presentation')
add('Single-UOM direct flow retained','if (uoms.length === 1) return addQuickOverviewLine(product.id, uoms[0].id);' in app,'direct to detail')
add('No new Theme7 component identity','data-theme-component=' not in app[app.index('function quickOverviewProductSearch'):app.index('function esc(v)')],'0 new feature components')
add('Release manifest version/parent',rel.get('release')=='2.5.4' and rel.get('parent')=='2.5.3',f"{rel.get('release')} / {rel.get('parent')}")
add('No business-rule change',rel.get('businessBehaviorChanged') is False,rel.get('businessBehaviorChanged'))
add('Action registry preserved',sha(ROOT/'specs/themes/theme-07/prototype/contracts/action-registry.json')==rel['registryPreservation']['actionRegistrySha256'],sha(ROOT/'specs/themes/theme-07/prototype/contracts/action-registry.json'))
add('Screen registry preserved',sha(ROOT/'specs/themes/theme-07/prototype/contracts/screen-registry.json')==rel['registryPreservation']['screenRegistrySha256'],sha(ROOT/'specs/themes/theme-07/prototype/contracts/screen-registry.json'))
node=subprocess.run(['node','--check',str(HTML/'app.js')],capture_output=True,text=True); add('JavaScript syntax',node.returncode==0,node.stderr.strip())
readme=(ROOT/'README.md').read_text(); rootidx=(ROOT/'index.html').read_text(); add('Root README current','v2.5.4' in readme and 'v2.5.3' in readme,'current+parent'); add('Root launcher current','v2.5.4' in rootidx and 'RELEASE-VALIDATION-v2.5.4.md' in rootidx,'v2.5.4')
passed=sum(c['pass'] for c in checks); state='PASS' if passed==len(checks) else 'FAIL'
result={'release':'2.5.4','parent':'2.5.3','status':state,'passed':passed,'total':len(checks),'checks':checks}
(ROOT/'RELEASE-VALIDATION-v2.5.4.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
lines=['# Release Validation — v2.5.4','',f'**Result: {state} · {passed}/{len(checks)} checks**','','Parent: **v2.5.3** · Scope: **BJ02 input semantics + CTA consistency + Quick UOM UX + layout hardening**','','## Gates','']
for c in checks: lines.append(f"- [{'x' if c['pass'] else ' '}] {c['name']}"+(f" — `{c['detail']}`" if c['detail'] else ''))
lines += ['','## QA evidence','','- BJ02 focused interaction/UX: **PASS 20/20**.','- BJ02 state-layout scan: **PASS 61/61** states; no horizontal overflow, text clipping, or browser errors.','- All-flow runtime smoke: **PASS 85/85**.','- Classification quantities are editable numeric input surfaces; derived totals remain read-only data rows.','- Quick multi-UOM selection is again contained in the selected Product block as requested, while single-UOM continues directly to detail.','- No new Theme7 component was created.','']
(ROOT/'RELEASE-VALIDATION-v2.5.4.md').write_text('\n'.join(lines))
print(state,passed,'/',len(checks))
for c in checks:
    if not c['pass']: print('FAIL',c)
sys.exit(0 if state=='PASS' else 1)
