from pathlib import Path
from playwright.sync_api import sync_playwright
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent
SHOTS = OUT / 'v251-bj01-bj02-captures'
SHOTS.mkdir(exist_ok=True)
checks = []
errors = []

def check(name, ok, detail=''):
    checks.append((name, bool(ok), detail))

def build():
    idx = (ROOT / 'index.html').read_text()
    for line in list(idx.splitlines()):
        if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
            idx = idx.replace(line + '\n', '').replace(line, '')
    cssfiles = [
        'figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css',
        'styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css'
    ]
    css = '\n'.join((ROOT / x).read_text() for x in cssfiles)
    for x in cssfiles:
        idx = idx.replace(f'<link rel="stylesheet" href="{x}" />', '')
    idx = idx.replace('</head>', f'<style>{css}</style></head>')
    idx = idx.replace('<script src="workbench-data.js"></script>', f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
    idx = idx.replace('<script src="figma-ds-runtime-map.js"></script>', f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
    idx = idx.replace('<script src="app.js"></script>', f'<script>{(ROOT/"app.js").read_text()}</script>')
    return idx

def set_screen(p, uif, sid, state='READY', mode='document'):
    p.evaluate(f'''()=>{{activeFlowId="{uif}"; flowMode="{mode}"; if(activeFlowId==="UIF-02") resetBj02Receipt("{mode}"); activeScreenId="{sid}"; stateByScreen["{sid}"]="{state}"; render();}}''')

def seed_document(p):
    p.evaluate('''()=>{
      flowMode='document'; resetBj02Receipt('document'); selectedDocumentId='PN-260816-04';
      bj02Lines=createDocumentReceiptLines(selectedDocumentId);
      bj02Lines[0].status='COMPLETED';
      bj02Lines[0].lots=[{id:'LOT-QA-1',code:'DH2507',expiry:'30/11/2026',manufactureDate:'',accepted:118,quarantine:2,damaged:0,rejected:0,totalReceived:120}];
      bj02Lines[1].status='COMPLETED';
      bj02Lines[1].lots=[{id:'LOT-QA-2',code:'AM2608',expiry:'',manufactureDate:'',accepted:24,quarantine:0,damaged:0,rejected:0,totalReceived:24}];
    }''')

def seed_quick(p):
    p.evaluate('''()=>{
      flowMode='quick'; resetBj02Receipt('quick');
      bj02Header={supplierId:'SUP-MINH-DUNG',supplier:'Minh Dũng',businessDate:localDateIso(),evidence:'PG-01.pdf',note:''};
      bj02Lines=[hydrateReceiptLine({id:'QUICK-QA-1',productId:'P-GLOVE-N',uomId:'UOM-BOX',uom:'hộp',trackingPolicy:'NONE',expiryRequired:false,sourceExpected:null,accepted:20,quarantine:1,damaged:0,rejected:2,status:'COMPLETED'})];
    }''')

def geom(p, sel):
    return p.locator(sel).first.evaluate('''e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {x:r.x,y:r.y,w:Math.round(r.width),h:Math.round(r.height),right:Math.round(r.right*10)/10,pad:s.padding,pt:s.paddingTop,pb:s.paddingBottom,pl:s.paddingLeft,pr:s.paddingRight,gap:s.gap,r:s.borderRadius,ff:s.fontFamily,fs:s.fontSize,lh:s.lineHeight,fw:s.fontWeight,disp:s.display,jc:s.justifyContent,wrap:s.whiteSpace,bd:s.borderStyle,bw:s.borderWidth,bg:s.backgroundColor,op:s.opacity}}''')

def no_over(p):
    return p.locator('.v-page-scaffold').evaluate('(e)=>e.scrollWidth<=e.clientWidth+1')

def shot(p, name):
    p.locator('#device-preview').screenshot(path=str(SHOTS / name))

with sync_playwright() as pw:
    browser = pw.chromium.launch(executable_path='/usr/bin/chromium', headless=True, args=['--no-sandbox','--disable-dev-shm-usage'])
    p = browser.new_page(viewport={'width':1440,'height':1100})
    p.set_default_timeout(6000)
    p.on('pageerror', lambda e: errors.append(str(e)))
    p.set_content(build(), wait_until='load')

    # BJ01: exact current master for Key-value Row 525:358, loaded last.
    set_screen(p,'UIF-01','SCR-003')
    rows = p.locator('.ds24-key-value-row')
    check('BJ01 detail has exactly 4 Key-value rows', rows.count()==4, str(rows.count()))
    eg = geom(p,'.ds24-key-value-row--emphasis')
    check('BJ01 Emphasis Key-value Row is 338x44', eg['w']==338 and eg['h']==44, str(eg))
    check('BJ01 Emphasis uses Figma Inter 16/22 value', 'Inter' in geom(p,'.ds24-key-value-row--emphasis > strong')['ff'] and geom(p,'.ds24-key-value-row--emphasis > strong')['fs']=='16px' and geom(p,'.ds24-key-value-row--emphasis > strong')['lh']=='22px', str(geom(p,'.ds24-key-value-row--emphasis > strong')))
    default_rows = p.locator('.ds24-key-value-row:not(.ds24-key-value-row--emphasis)')
    check('BJ01 has 3 Default Key-value rows', default_rows.count()==3, str(default_rows.count()))
    rights=[]
    for i in range(default_rows.count()):
        r=default_rows.nth(i)
        rg=r.evaluate('e=>{const b=e.getBoundingClientRect();return [Math.round(b.width),Math.round(b.height),getComputedStyle(e).justifyContent]}')
        vg=r.locator('strong').evaluate('e=>{const b=e.getBoundingClientRect(),s=getComputedStyle(e);return {right:Math.round(b.right*10)/10,ff:s.fontFamily,fs:s.fontSize,lh:s.lineHeight,wrap:s.whiteSpace}}')
        rights.append(vg['right'])
        check(f'BJ01 Default row {i+1} is 338x44/space-between', rg[0]==338 and rg[1]==44 and rg[2]=='space-between', str(rg))
        check(f'BJ01 Default row {i+1} value is Mono 14/22 nowrap', 'JetBrains Mono' in vg['ff'] and vg['fs']=='14px' and vg['lh']=='22px' and vg['wrap']=='nowrap', str(vg))
    check('BJ01 supporting values share one right edge', max(rights)-min(rights) <= .2, str(rights))
    check('BJ01 availability block does not use Info Row', p.locator('.ds24-key-value-stack [data-ds-component="DS v2 / Info Row"]').count()==0)
    check('BJ01 no horizontal overflow', no_over(p))
    shot(p,'BJ01-SCR-003.png')

    # BJ02 entry/records.
    set_screen(p,'UIF-02','SCR-006')
    g=geom(p,'.bj02-ds-list-row')
    check('BJ02 SCR006 List Row exact 370x76', g['w']==370 and g['h']==76, str(g))
    check('BJ02 SCR006 no horizontal overflow', no_over(p))
    shot(p,'BJ02-SCR-006.png')

    set_screen(p,'UIF-02','SCR-007')
    check('BJ02 SCR007 does not show meaningless READY badge', 'Sẵn sàng nhận' not in p.locator('#app-screen').inner_text())
    rg=geom(p,'.bj02-record-card')
    check('BJ02 SCR007 Record Card exact 370x116', rg['w']==370 and rg['h']==116, str(rg))
    shot(p,'BJ02-SCR-007.png')

    # SCR008: canonical Form fields and overlay.
    set_screen(p,'UIF-02','SCR-008',mode='quick')
    seed_quick(p); p.evaluate("activeScreenId='SCR-008'; stateByScreen['SCR-008']='READY'; render();")
    check('BJ02 SCR008 Supplier is VSelect', p.locator('.supplier-field[data-ds-component="VSelect"][data-figma-node="522:7291"]').count()==1)
    check('BJ02 SCR008 Warehouse is disabled VSelect', p.locator('.form-field.is-disabled[data-ds-component="VSelect"] .bj02-vselect-trigger:disabled').count()==1)
    check('BJ02 SCR008 has no fake inline Search Results Dropdown', p.locator('[data-ds-component*="Search Results Dropdown"]').count()==0)
    fg=geom(p,'.file-drop-zone')
    check('BJ02 SCR008 VFileDropZone exact 310x116', fg['w']==310 and fg['h']==116, str(fg))
    check('BJ02 SCR008 VFileDropZone keeps dashed Default after file selected', fg['bd']=='dashed', str(fg))
    check('BJ02 SCR008 upload uses approved cloud-upload slot', p.locator('.file-drop-icon [data-ds-icon="li:cloud-upload"]').count()==1)
    ft=geom(p,'.figma-sticky-footer'); fb=geom(p,'.figma-sticky-footer .button')
    check('BJ02 Sticky Footer exact 402x92/12/24', ft['w']==402 and ft['h']==92 and ft['pt']=='12px' and ft['pb']=='24px', str(ft))
    check('BJ02 Sticky Footer action exact 44px', fb['h']==44, str(fb))
    check('BJ02 SCR008 no horizontal overflow', no_over(p))
    shot(p,'BJ02-SCR-008.png')

    p.locator('[data-bj02-open-supplier-sheet]').click()
    sg=geom(p,'.bj02-select-sheet'); sr=geom(p,'.bj02-sheet-list-row')
    check('BJ02 Supplier Select Sheet exact 402x560', sg['w']==402 and sg['h']==560, str(sg))
    check('BJ02 Supplier Select Sheet uses 370x76 Selection rows', sr['w']==370 and sr['h']==76, str(sr))
    check('BJ02 Supplier Select Sheet uses VSearchBar', p.locator('.bj02-sheet-search[data-ds-component="VSearchBar"]').count()==1)
    shot(p,'BJ02-SCR-008-supplier-sheet.png')
    p.locator('[data-bj02-supplier-backdrop]').click(position={'x':4,'y':4})

    # SCR009: flat context, no Summary Card/card soup.
    seed_document(p); p.evaluate("activeScreenId='SCR-009'; stateByScreen['SCR-009']='READY'; render();")
    check('BJ02 SCR009 context uses Info Row', p.locator('.bj02-context-section [data-ds-component="DS v2 / Info Row"]').count()>=2)
    check('BJ02 SCR009 does not use Summary Card', p.locator('[data-ds-component="DS v2 / Summary Card"]').count()==0)
    check('BJ02 SCR009 products use Record Card', p.locator('.receipt-line-card[data-ds-component="DS v2 / Record Card"]').count()==2)
    check('BJ02 SCR009 no horizontal overflow', no_over(p))
    shot(p,'BJ02-SCR-009.png')

    # SCR084: Product identity flat; explicit numeric rows; Numeric keypad master.
    p.evaluate("beginLineEditor(bj02Lines[0].id); activeScreenId='SCR-084'; stateByScreen['SCR-084']='READY'; render();")
    identity=geom(p,'.line-product-identity')
    check('BJ02 SCR084 product identity is flat VSection not card', identity['bw']=='0px' and identity['bg'] in ('rgba(0, 0, 0, 0)','transparent'), str(identity))
    hits=p.locator('.bj02-quantity-hit')
    check('BJ02 SCR084 has exactly 4 authoritative quantity hit areas', hits.count()==4, str(hits.count()))
    check('BJ02 SCR084 does not use VTextField for classification quantities', p.locator('.classification-quantities [data-ds-component="VTextField"]').count()==0)
    qg=geom(p,'.bj02-quantity-hit')
    check('BJ02 SCR084 quantity hit area exact 338x44', qg['w']==338 and qg['h']==44, str(qg))
    check('BJ02 SCR084 has no editable total field', p.locator('[data-bj02-line-total],[data-bj02-lot-total]').count()==0)
    check('BJ02 SCR084 derived total uses Emphasis Key-value Row', p.locator('.bj02-derived-total[data-ds-component="DS v2 / Key-value Row"][data-ds-prop-state="Emphasis"]').count()>=1)
    shot(p,'BJ02-SCR-084.png')

    before=p.evaluate("lineEditorDraft.lots[0].accepted")
    p.locator('.bj02-quantity-hit').first.click()
    ng=geom(p,'.bj02-numeric-sheet'); kg=geom(p,'.bj02-keypad-key'); ag=geom(p,'.bj02-numeric-actions .button')
    check('BJ02 Numeric Keypad Sheet exact 402x512', ng['w']==402 and ng['h']==512, str(ng))
    check('BJ02 Numeric Keypad key exact 118x52', kg['w']==118 and kg['h']==52, str(kg))
    check('BJ02 Numeric Keypad actions exact 181x44', ag['w']==181 and ag['h']==44, str(ag))
    p.locator('[data-bj02-numeric-key="9"]').click()
    mid=p.evaluate("lineEditorDraft.lots[0].accepted")
    check('BJ02 Numeric Keypad preserves source value until Lưu', before==mid, f'{before} -> {mid}')
    shot(p,'BJ02-SCR-084-keypad.png')
    p.locator('[data-bj02-action="numeric-cancel"]').click()

    # Review — seed meaningful values so visual QA cannot pass on zero-line fixtures.
    seed_document(p); p.evaluate("activeScreenId='SCR-010'; stateByScreen['SCR-010']='READY'; render();")
    check('BJ02 SCR010 has no legacy review-card', p.locator('.review-card').count()==0)
    check('BJ02 SCR010 uses flat VSection review composition', p.locator('.bj02-review-section[data-ds-component="VSection"]').count()>=2)
    check('BJ02 SCR010 uses Key-value rows for receipt quantities', p.locator('.bj02-review-product [data-ds-component="DS v2 / Key-value Row"]').count()>=5)
    check('BJ02 SCR010 meaningful fixture shows 120 hộp', '120 hộp' in p.locator('#app-screen').inner_text())
    check('BJ02 SCR010 no horizontal overflow', no_over(p))
    shot(p,'BJ02-SCR-010-document.png')

    seed_quick(p); p.evaluate("activeScreenId='SCR-010'; stateByScreen['SCR-010']='READY'; render();")
    cb=geom(p,'.v-banner[data-ds-prop-density="Compact"]')
    check('BJ02 routine Quick approval banner is Compact 72px', cb['h']==72, str(cb))
    check('BJ02 Quick review uses actor handoff copy', 'Gửi hồ sơ duyệt' in p.locator('#app-screen').inner_text())
    check('BJ02 Quick review meaningful fixture shows 23 hộp', '23 hộp' in p.locator('#app-screen').inner_text())
    shot(p,'BJ02-SCR-010-quick.png')

    # Approver read-only decision surface.
    seed_quick(p); p.evaluate("activeScreenId='SCR-011'; stateByScreen['SCR-011']='APPROVAL_REQUIRED'; render();")
    check('BJ02 SCR011 has exactly approve + reject decision actions', p.locator('[data-action="approve"]').count()==1 and p.locator('[data-action="open-reject"]').count()==1)
    check('BJ02 SCR011 has no editable receipt inputs', p.locator('#app-screen input:not([type="hidden"]), #app-screen textarea, #app-screen select').count()==0)
    dft=geom(p,'.approval-actions.figma-sticky-footer'); db=geom(p,'.approval-actions .button')
    check('BJ02 SCR011 Dual Footer exact 402x92', dft['w']==402 and dft['h']==92, str(dft))
    check('BJ02 SCR011 decision buttons 181x44', db['w']==181 and db['h']==44, str(db))
    check('BJ02 SCR011 actor handoff visible', 'Việc dành cho người phê duyệt' in p.locator('#app-screen').inner_text())
    check('BJ02 SCR011 no horizontal overflow', no_over(p))
    shot(p,'BJ02-SCR-011.png')

    # Result and unknown recovery.
    seed_document(p); p.evaluate("activeScreenId='SCR-012'; stateByScreen['SCR-012']='COMPLETED'; render();")
    check('BJ02 SCR012 no receive mutation CTA', 'Ghi nhận hàng' not in p.locator('#app-screen').inner_text())
    check('BJ02 SCR012 no legacy review-card', p.locator('.review-card').count()==0)
    shot(p,'BJ02-SCR-012.png')

    seed_quick(p); p.evaluate("activeScreenId='SCR-013'; stateByScreen['SCR-013']='PROCESSING_OR_UNKNOWN'; render();")
    txt=p.locator('#app-screen').inner_text()
    check('BJ02 SCR013 UNKNOWN has no blind retry', 'Thử lại' not in txt)
    check('BJ02 SCR013 preserves same-operation guidance', 'Chưa cần thực hiện lại lần nhận' in txt or 'Không cần tạo lần nhận mới' in txt)
    shot(p,'BJ02-SCR-013.png')

    # Source governance gate: migrated BJ02 segment does not introduce Theme7 shared components.
    source=(ROOT/'app.js').read_text(); a=source.index('function bj02ListRow'); z=source.index('function esc(v)'); bj=source[a:z]
    check('BJ02 source has no VCombobox fake identity', 'data-ds-component="VCombobox"' not in bj)
    check('BJ02 source has no VTextFormField fake identity', 'data-ds-component="VTextFormField"' not in bj)
    check('BJ02 source creates no Theme7 shared component identity', 'data-theme-component=' not in bj)
    check('BJ02 V-first dependencies present', all(x in bj for x in ['VSelect','VDatePicker','VFileDropZone','VTextarea','VBanner','VButton','DS v2 / Select Sheet','DS v2 / Key-value Row','DS v2 / Info Row']))

    check('Browser runtime errors = 0', len(errors)==0, str(errors))
    browser.close()

passed=sum(1 for _,ok,_ in checks if ok)
failed=[x for x in checks if not x[1]]
status='PASS' if not failed and not errors else 'FAIL'
result={'status':status,'passed':passed,'total':len(checks),'failed':[{'name':n,'detail':d} for n,ok,d in failed],'browserErrors':errors}
(OUT/'BJ01-BJ02-DS-CORRECTION-QA-v2.5.1.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ01 + BJ02 Figma DS correction QA — v2.5.1','',f'**Result: {status} · {passed}/{len(checks)} checks**','',f'- Browser errors: **{len(errors)}**','- Product canvas: **402 × 874**','- Figma authority: live Components + Patterns/Templates; computed-style geometry is checked in browser.','- Gate explicitly re-checks BJ01 Key-value Row `525:358` and BJ02 form/list/overlay/numeric/review structures.','','## Checks','']
for n,ok,d in checks:
    lines.append(f'- [{"x" if ok else " "}] {n}' + (f' — `{d}`' if d else ''))
(OUT/'BJ01-BJ02-DS-CORRECTION-QA-v2.5.1.md').write_text('\n'.join(lines)+'\n')
print(status, passed, '/', len(checks))
for n,ok,d in failed:
    print('FAIL', n, d)
if status!='PASS':
    raise SystemExit(1)
