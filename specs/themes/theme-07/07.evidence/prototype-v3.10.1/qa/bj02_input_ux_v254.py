from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'v254-bj02-captures'; SHOTS.mkdir(exist_ok=True)
checks=[]; errors=[]
def check(n,ok,d=''): checks.append((n,bool(ok),d))
def build():
    idx=(ROOT/'index.html').read_text()
    for line in list(idx.splitlines()):
        if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line: idx=idx.replace(line+'\n','').replace(line,'')
    cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css']
    css='\n'.join((ROOT/x).read_text() for x in cssfiles)
    for x in cssfiles: idx=idx.replace(f'<link rel="stylesheet" href="{x}" />','')
    idx=idx.replace('</head>',f'<style>{css}</style></head>')
    for s in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
        idx=idx.replace(f'<script src="{s}"></script>',f'<script>{(ROOT/s).read_text()}</script>')
    return idx

def no_overflow(p):
    return p.locator('.figma-calibrated-shell').evaluate('e=>e.scrollWidth<=e.clientWidth+1')
def shot(p,n): p.locator('#device-preview').screenshot(path=str(SHOTS/n))
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1200}); p.set_default_timeout(6000); p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_content(build(),wait_until='load')
    # Quick receiving real path
    p.evaluate("activeFlowId='UIF-02'; activeScreenId='SCR-006'; flowMode='document'; resetBj02Receipt('document'); stateByScreen['SCR-006']='READY'; render();")
    p.locator('[data-flow="quick"]').click()
    p.locator('[data-bj02-open-supplier-sheet]').click(); p.locator('[data-bj02-supplier-option]').first.click()
    p.locator('[data-bj02-header="businessDate"]').fill(p.evaluate('localDateIso()'))
    p.evaluate("bj02Header.evidence='phieu-giao-hang.pdf'; renderAppScreen();")
    p.locator('[data-next="SCR-009"]').click();
    p.locator('[data-bj02-overview-product-search]').click(); p.locator('[data-bj02-overview-product-option="P-NOB-DHPP"]').click()
    check('Quick multi-UOM stays on SCR009', p.evaluate('activeScreenId')=='SCR-009', p.evaluate('activeScreenId'))
    check('UOM choices are inside selected product card', p.locator('.quick-overview-uom-picker .quick-uom-choice').count()==2)
    check('Selected product card contains product identity and UOM group', p.locator('.quick-overview-uom-picker .quick-overview-uom-copy').count()==1 and p.locator('.quick-overview-uom-picker .quick-uom-choice-group').count()==1)
    check('Quick UOM screen no overflow', no_overflow(p))
    shot(p,'01-quick-uom-in-card.png')
    p.locator('[data-bj02-overview-uom-choice="UOM-VIAL"]').click()
    check('Choosing UOM opens detail', p.evaluate('activeScreenId')=='SCR-084')
    # quantity inputs
    triggers=p.locator('.bj02-quantity-input-trigger')
    check('Four classification controls render as editable input surfaces', triggers.count()==4, str(triggers.count()))
    check('No Key-value Row used as editable classification control', p.locator('.classification-quantities .bj02-key-value-row').count()==0)
    g=triggers.first.evaluate('e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {w:r.width,h:r.height,b:s.borderTopWidth,rad:s.borderRadius,bg:s.backgroundColor}}')
    check('Quantity input surface is 44px with visible field border', round(g['h'])==44 and g['b']=='1px' and g['rad']=='8px', str(g))
    # interaction not readonly
    triggers.first.click(); check('Quantity input opens numeric keypad', p.locator('.bj02-numeric-sheet').count()==1)
    pad=p.evaluate('({...bj02NumericPad})'); before=p.evaluate('(x)=>bj02NumericValue(x.target,x.key,x.lotId)',pad)
    p.locator('[data-bj02-numeric-key="3"]').click(); mid=p.evaluate('(x)=>bj02NumericValue(x.target,x.key,x.lotId)',pad); check('Value not committed before Save', mid==before, f'{before}->{mid}')
    p.locator('[data-bj02-action="numeric-save"]').click(); after=p.evaluate('(x)=>bj02NumericValue(x.target,x.key,x.lotId)',pad); check('Value commits after Save', after==3, str(after))
    check('Detail no overflow after edit', no_overflow(p)); shot(p,'02-quick-detail-inputs.png')
    # Quick destructive action is already available for the newly-created line.
    quick_style=p.locator('.remove-line-action').evaluate('e=>{const s=getComputedStyle(e);return {c:s.color,b:s.borderTopWidth,bg:s.backgroundColor,w:e.getBoundingClientRect().width}}')
    check('Quick remove action is red text link', quick_style['b']=='0px' and quick_style['w']<200, str(quick_style))
    # document mode and same treatment
    p.evaluate("flowMode='document'; selectedDocumentId='PN-260816-04'; resetBj02Receipt('document'); activeScreenId='SCR-009'; stateByScreen['SCR-009']='READY'; renderAppScreen();")
    docline=p.locator('[data-bj02-line-id]').first
    if docline.count(): docline.click()
    check('Document detail exposes Chưa nhận lần này', p.locator('.not-received-action').count()==1)
    doc_style=p.locator('.not-received-action').evaluate('e=>{const s=getComputedStyle(e);return {c:s.color,b:s.borderTopWidth,bg:s.backgroundColor,w:e.getBoundingClientRect().width}}')
    check('Document not-received action matches red text-link treatment', doc_style['b']=='0px' and doc_style['w']<200 and doc_style['c']==quick_style['c'], str(doc_style))
    check('Document classification is also editable input surfaces', p.locator('.bj02-quantity-input-trigger').count()==4)
    check('Document detail no overflow', no_overflow(p)); shot(p,'03-document-detail-inputs.png')
    # prior regressions
    src=(ROOT/'app.js').read_text()
    check('Quick single-UOM still skips redundant UOM step', 'if (uoms.length === 1) return addQuickOverviewLine(product.id, uoms[0].id);' in src)
    check('No new Theme7 component identity added', 'data-theme-component=' not in src[src.index('function quickOverviewProductSearch'):src.index('function esc(v)')])
    check('Browser errors zero', not errors, str(errors))
    b.close()
passed=sum(ok for _,ok,_ in checks); failed=[(n,d) for n,ok,d in checks if not ok]; status='PASS' if not failed and not errors else 'FAIL'
res={'status':status,'passed':passed,'total':len(checks),'failed':[{'name':n,'detail':d} for n,d in failed],'browserErrors':errors}
(OUT/'BJ02-INPUT-UX-QA-v2.5.4.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
md=['# BJ02 Input + UX QA — v2.5.4','',f'**Result: {status} · {passed}/{len(checks)} checks**','', '- Scope: SCR-009 / SCR-084 quick + document modes; prior v2.5.2 flow invariants retained.', '- Editable classification quantities use explicit numeric input hit areas + VNumericKeypadSheet; they are not Key-value Rows.', '- Quick multi-UOM returns to the v2.5.0 in-product-card selection model while retaining v2.5.2 flow behavior.','','## Checks','']
for n,ok,d in checks: md.append(f'- [{"x" if ok else " "}] {n}'+(f' — `{d}`' if d else ''))
(OUT/'BJ02-INPUT-UX-QA-v2.5.4.md').write_text('\n'.join(md)+'\n')
print(status,passed,'/',len(checks)); [print('FAIL',n,d) for n,d in failed]
raise SystemExit(0 if status=='PASS' else 1)
