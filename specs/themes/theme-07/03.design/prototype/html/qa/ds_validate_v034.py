from pathlib import Path
import json, yaml, re

HTML=Path(__file__).resolve().parents[1]
PROTO=HTML.parent
CON=PROTO/'contracts'
checks=[]
def check(name, cond, detail=''): checks.append((name,bool(cond),detail))
app=(HTML/'app.js').read_text(encoding='utf8')
css=(HTML/'styles.css').read_text(encoding='utf8')
manifest=json.loads((HTML/'manifest.json').read_text(encoding='utf8'))
lock=json.loads((CON/'FLUTTER-DS-LOCK.json').read_text(encoding='utf8'))
u1=yaml.safe_load((CON/'component-usage/UIF-01-COMPONENT-USAGE.yaml').read_text(encoding='utf8'))
u2=yaml.safe_load((CON/'component-usage/UIF-02-COMPONENT-USAGE.yaml').read_text(encoding='utf8'))
reg=json.loads((CON/'screen-registry.json').read_text(encoding='utf8'))

check('manifest version 0.3.4',str(manifest.get('version'))=='0.3.4',str(manifest.get('version')))
check('Flutter DS remains authority',lock.get('authority')=='Flutter Design System source ZIP',str(lock.get('authority')))
check('HTML policy remains renderer-only',lock.get('htmlPolicy')=='renderer_only_not_design_system',str(lock.get('htmlPolicy')))
check('UIF01 component contract is v0.3.4','0.3.4' in str(u1.get('version','')) or 'v0.3.4' in str(u1.get('version','')),str(u1.get('version')))
check('UIF02 component contract is v0.3.4','0.3.4' in str(u2.get('version','')) or 'v0.3.4' in str(u2.get('version','')),str(u2.get('version')))

# BJ01 end-user corrections / DS primitives.
check('BJ01 search includes barcode in actual search data','${p.name} ${p.code} ${p.barcode || ""}' in app)
check('BJ01 list search uses VSearchBar','data-bj01-search' in app and 'data-ds-component="VSearchBar"' in app)
check('BJ01 filters use VChip','data-bj01-filter' in app and 'data-ds-component="VChip"' in app)
check('BJ01 detail uses VCard summary','bj01-summary-card' in app and 'data-ds-component="VCard"' in app)
check('BJ01 uses VBanner for stock exceptions','function bj01AttentionBanner' in app and 'vBanner(' in app)
check('BJ01 LOT/provenance use VBottomSheet','aria-label="Chi tiết lô"' in app and 'aria-label="Nguồn và thời điểm cập nhật"' in app and 'data-ds-component="VBottomSheet"' in app)
check('BJ01 no technical provenance words in active render',all(x not in re.search(r'function bj01ProvenanceSheet\(p\).*?function render003BJ01',app,re.S).group(0).lower() for x in ['snapshot','projection','movement','cut-off','sequence']))

# BJ02 requested changes using Flutter DS components.
render009=re.search(r'function render009\(state\).*?function beginLineEditor',app,re.S).group(0)
quant=re.search(r'function exceptionQuantitiesEditor\(target, totals, locked = false\).*?function documentSourceContextHtml',app,re.S).group(0)
check('Quick Product discovery is on SCR009','quickOverviewProductSearch()' in render009)
check('Quick discovery uses VSearchBar','data-bj02-overview-product-search' in app and 'data-ds-component="VSearchBar"' in app)
check('Quick UOM uses VSelect','data-bj02-overview-uom' in app and 'data-ds-component="VSelect"' in app)
check('SCR009 has no Add Product action','data-bj02-action="add-line"' not in render009)
check('Four classifications defined together',all(f'label: "{x}"' in quant for x in ['Đạt','Cách ly','Hỏng','Từ chối']))
check('Accepted is derived/read-only','derived: true' in quant and 'readonly aria-readonly="true"' in quant)
check('No progressive classification CTA in active renderer','Có hàng cần phân loại khác?' not in app)
check('Duplicate Quick line uses VBanner + VButton','Sản phẩm và đơn vị này đã có' in app and 'open-existing-overview-line' in app)

# v0.3.4 CSS is additive/scoped for UIF02.
marker='/* ==========================================================================\n   BJ-02 v0.3.4'
check('BJ02 v0.3.4 CSS marker exists',marker in css)
if marker in css:
    block=css[css.index(marker):]
    selectors=[line.strip() for line in block.splitlines() if line.strip().startswith(('body[','.quick','.quantity','.classification','[data'))]
    unscoped=[s for s in selectors if s.startswith(('body[',)) is False and not s.startswith(('/*','*','}'))]
    check('v0.3.4 CSS selectors scoped under UIF02',len(unscoped)==0,str(unscoped[:5]))
else: check('v0.3.4 CSS selectors scoped under UIF02',False,'missing block')
check('hidden search results are truly hidden','quick-overview-product-option[hidden]' in css and 'display:none !important' in css)

# Metadata sanity.
screens={x.get('id'):x for x in reg.get('screens',[])} if isinstance(reg,dict) else {}
check('SCR009 exists in screen registry','SCR-009' in screens)
check('SCR084 exists in screen registry','SCR-084' in screens)

passed=sum(ok for _,ok,_ in checks); failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# Flutter DS / Static Conformance v0.3.4','',f'**Result: {passed}/{len(checks)} PASS**' if not failed else f'**Result: {passed}/{len(checks)} PASS · {len(failed)} FAIL**','', '## Checks','']
for n,ok,d in checks: lines.append(f'- [{"x" if ok else " "}] {n}' + (f' — {d}' if d else ''))
lines += ['', '## Authority','', '- Flutter Design System remains the visual/component authority.', '- HTML remains a renderer/workbench; this report checks component mapping and scope, not Figma parity.']
(HTML/'qa/BJ01-BJ02-DS-CONFORMANCE-v0.3.4.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
raise SystemExit(1 if failed else 0)
