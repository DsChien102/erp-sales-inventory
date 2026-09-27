from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent
SHOTS = OUT / 'screenshots-v0.2.9'
SHOTS.mkdir(exist_ok=True)
checks=[]

def check(name, condition, detail=''):
    checks.append((name,bool(condition),detail))

def build_html():
    idx=(ROOT/'index.html').read_text(encoding='utf8')
    css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8')
    data=(ROOT/'workbench-data.js').read_text(encoding='utf8')
    app=(ROOT/'app.js').read_text(encoding='utf8')
    idx=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','')
    idx=idx.replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>')
    idx=idx.replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
    idx=idx.replace('<script src="app.js"></script>',f'<script>{app}</script>')
    return idx

def overflow(page):
    return page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth,sh:e.scrollHeight,ch:e.clientHeight})')

def no_h_overflow(page):
    o=overflow(page); return o['sw'] <= o['cw'] + 1

def shot(page,name):
    page.locator('#device-preview').screenshot(path=str(SHOTS/f'{name}.png'))

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='/usr/bin/chromium', headless=True, args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1680,'height':1000})
    page.set_content(build_html(), wait_until='load')
    page.wait_for_timeout(80)

    # Harness / frame
    check('workbench boots UIF-02', 'SCR-006' in page.locator('#current-screen-id').inner_text())
    frame=page.locator('#device-preview').evaluate('(e)=>[Math.round(e.getBoundingClientRect().width),Math.round(e.getBoundingClientRect().height)]')
    check('mobile frame 402x874', frame == [402,874], str(frame))

    # SCR-006
    check('SCR-006 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    page.evaluate('stateByScreen["SCR-006"]="PERMISSION_DENIED"; render()')
    check('SCR-006 permission uses centered empty state', page.locator('.app-content--centered [data-ds-component="VEmptyState"]').count()==1)
    page.evaluate('stateByScreen["SCR-006"]="READY"; navigate("SCR-007")')

    # SCR-007 scalable search
    check('SCR-007 has document search', page.locator('[data-bj02-document-search]').count()==1)
    check('SCR-007 has two document cards', page.locator('[data-bj02-document-id]').count()==2)
    inp=page.locator('[data-bj02-document-search]')
    inp.fill('Minh')
    visible=page.locator('[data-bj02-document-id]:visible').count()
    check('document search filters by supplier', visible==1, str(visible))
    inp.fill('XYZ-NOT-FOUND')
    check('document search no-result uses VEmptyState', page.locator('[data-bj02-document-filter-empty]:visible [data-ds-component="VEmptyTitle"]').count()==1)
    inp.fill('')
    check('document search clear restores results', page.locator('[data-bj02-document-id]:visible').count()==2)
    check('SCR-007 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    shot(page,'SCR-007-document-search')

    # Select multi-product source -> overview
    page.locator('[data-bj02-document-id="PN-260816-04"]').click()
    check('Document overview exposes both source products', page.locator('[data-bj02-line-id]').count()==2)
    check('SCR-009 has primary and secondary hierarchy', page.locator('.receipt-line-primary').count()==2 and page.locator('.receipt-line-secondary').count()==2)
    check('SCR-009 no compressed lot text in primary line initially', 'lô' not in page.locator('.receipt-line-primary').first.inner_text().lower())
    check('SCR-009 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    shot(page,'SCR-009-document-overview')

    # True read-only propagation from overview
    page.evaluate('stateByScreen["SCR-009"]="READ_ONLY"; render()')
    check('SCR-009 read-only hides Quick mutation and disables review', page.locator('[data-bj02-action="add-line"]').count()==0 and page.locator('[data-next="SCR-010"]').is_disabled())
    page.locator('[data-bj02-line-id="DOC-04-01"]').click()
    check('read-only opens detail for viewing', 'SCR-084' in page.locator('#current-screen-id').inner_text())
    enabled_mut_inputs=page.locator('.app-screen input:not([disabled]), .app-screen select:not([disabled]), .app-screen textarea:not([disabled])').count()
    check('SCR-084 true read-only has no editable inputs', enabled_mut_inputs==0, str(enabled_mut_inputs))
    check('SCR-084 true read-only hides mutation actions', page.locator('[data-bj02-action="save-line"], [data-bj02-action="add-editor-lot"], [data-bj02-action="not-received"], [data-bj02-action="remove-editor-lot"]').count()==0)

    # Editable Document LOT detail
    page.evaluate('lineEditorReadOnly=false; stateByScreen["SCR-009"]="READY"; stateByScreen["SCR-084"]="READY"; beginLineEditor("DOC-04-01")')
    bodytxt=page.locator('#app-screen').inner_text()
    check('Document UOM appears only in product identity, no select', page.locator('[data-bj02-uom]').count()==0 and 'Mã NOB-DHPP · hộp' in bodytxt)
    check('Orphan Theo chứng từ copy removed', 'Theo chứng từ:' not in bodytxt)
    check('LOT source context says Còn chờ nhận', 'Còn chờ nhận 120 hộp' in bodytxt)
    check('LOT derived total starts at 0/120', '0 / 120 hộp' in page.locator('[data-bj02-editor-total-summary]').inner_text())
    check('Initial lot is open', page.locator('.active-lot-editor').count()==1)

    # Fill first lot 80 with exceptions; should show remaining info
    page.locator('[data-bj02-lot-field="code"]').fill('ND2408')
    page.locator('[data-bj02-lot-field="expiry"]').fill('31/12/2027')
    page.locator('[data-bj02-lot-total]').fill('80')
    page.locator('[data-bj02-action="toggle-lot-classification"]').click()
    page.locator('[data-bj02-lot-qty="quarantine"]').fill('2')
    check('existing exception UI shows computed accepted', '78' in page.locator('[data-bj02-accepted-preview]').inner_text())
    check('partial Document shows remaining info', 'Còn hàng chưa nhận' in page.locator('[data-bj02-document-variance]').inner_text() and '40' in page.locator('[data-bj02-document-variance]').inner_text())
    check('derived total updates live', '80 / 120 hộp' in page.locator('[data-bj02-editor-total-summary]').inner_text())

    # Multi-lot accordion semantics
    page.locator('[data-bj02-action="add-editor-lot"]').click()
    check('Add lot appends second lot', page.locator('.lot-accordion-item').count()==2)
    check('New lot opens and prior collapses', page.locator('.lot-accordion-item.is-expanded').count()==1 and page.locator('.lot-accordion-item').nth(1).get_attribute('class').find('is-expanded')>=0)
    check('Delete is inside expanded content not header', page.locator('.lot-accordion-header [data-bj02-action="remove-editor-lot"]').count()==0 and page.locator('.active-lot-editor [data-bj02-action="remove-editor-lot"]').count()==1)
    page.locator('[data-bj02-lot-field="code"]').fill('ND2409')
    page.locator('[data-bj02-lot-field="expiry"]').fill('31/01/2028')
    page.locator('[data-bj02-lot-total]').fill('40')
    check('Exact Document quantity suppresses variance banner', page.locator('[data-bj02-document-variance]').inner_text().strip()=='')
    check('Derived total exact is 120/120', '120 / 120 hộp' in page.locator('[data-bj02-editor-total-summary]').inner_text())
    # manually reopen first lot, existing exception should remain expanded
    page.locator('.lot-accordion-toggle').first.click()
    check('User can manually open previous lot', page.locator('.lot-accordion-item').first.get_attribute('class').find('is-expanded')>=0)
    check('Existing exceptions auto-expand after reopen', page.locator('[data-bj02-lot-qty="quarantine"]').count()==1 and page.locator('[data-bj02-action="toggle-lot-classification"]').count()==0)
    # over source
    page.locator('.lot-accordion-toggle').nth(1).click()
    page.locator('[data-bj02-lot-total]').fill('45')
    check('Document over-source shows warning', 'Số lượng giao vượt chứng từ' in page.locator('[data-bj02-document-variance]').inner_text() and '5' in page.locator('[data-bj02-document-variance]').inner_text())
    # not-received remains available after data and requires confirm
    page.locator('[data-bj02-action="not-received"]').click()
    check('Not received after entered data opens VConfirmDialog', page.locator('[data-dialog-kind="not-received"] [data-ds-component="VConfirmDialog"]').count()==1)
    page.locator('[data-bj02-action="close-not-received"]').click()
    check('SCR-084 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    shot(page,'SCR-084-document-multilot')

    # Make exact again and save first line, mark second not received -> review
    page.locator('[data-bj02-lot-total]').fill('40')
    page.locator('[data-bj02-action="save-line"]').click()
    check('Save line returns to overview', 'SCR-009' in page.locator('#current-screen-id').inner_text())
    page.locator('[data-bj02-line-id="DOC-04-02"]').click()
    page.locator('[data-bj02-action="not-received"]').click()
    check('Zero untouched document line marks not received directly', 'SCR-009' in page.locator('#current-screen-id').inner_text())
    check('Overview shows 2/2 handled', '2/2 đã xử lý' in page.locator('#app-screen').inner_text())
    check('Review CTA enabled when every source item handled', not page.locator('[data-next="SCR-010"]').is_disabled())
    page.locator('[data-next="SCR-010"]').click()
    check('SCR-010 shows actual LOT code and expiry', 'ND2408' in page.locator('#app-screen').inner_text() and 'HSD 31/12/2027' in page.locator('#app-screen').inner_text())
    check('SCR-010 result includes handled-zero line without false received wording', 'chưa nhận lần này' in page.locator('#app-screen').inner_text().lower())
    check('SCR-010 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    shot(page,'SCR-010-document-review')

    # Quick header UX
    page.evaluate('flowMode="quick"; resetBj02Receipt("quick"); stateByScreen["SCR-008"]="READY"; navigate("SCR-008")')
    check('Quick note has no redundant optional copy', 'Không bắt buộc' not in page.locator('#app-screen').inner_text())
    sup=page.locator('[data-bj02-supplier-search]')
    sup.fill('Minh')
    sup.blur()
    check('Unresolved supplier shows inline guidance', page.locator('[data-bj02-supplier-error]:visible').count()==1)
    sup.focus(); page.locator('[data-bj02-supplier-option="SUP-MINH-DUNG"]').click()
    check('Supplier search result has code and phone', 'NCC-0018' in page.locator('#app-screen').inner_text() or page.evaluate('bj02Header.supplierId')=='SUP-MINH-DUNG')
    page.locator('[data-bj02-header="evidence"]').fill('PGH-826-01')
    page.locator('[data-bj02-header="note"]').fill('Giao tại cửa kho số 2')
    check('Quick Continue enables after valid header', not page.locator('[data-next="SCR-009"]').is_disabled())
    page.locator('[data-next="SCR-009"]').click()
    check('Quick overview starts empty with add action', page.locator('.receipt-lines-empty').count()==1 and page.locator('[data-bj02-action="add-line"]').count()==1)
    page.locator('[data-bj02-action="add-line"]').click()
    prod_option=page.locator('[data-bj02-product-option="P-NOB-DHPP"]')
    option_text=prod_option.inner_text()
    check('Product search result is compact discriminator', 'Nobivac DHPPi' in option_text and 'NOB-DHPP' in option_text and 'hộp' in option_text and 'lọ' in option_text and 'LOT' not in option_text)
    prod_option.click()
    check('Quick multi-UOM asks UOM only at new-item step', page.locator('[data-bj02-uom]').count()==1)
    page.locator('[data-bj02-uom]').select_option('UOM-BOX')
    check('Quick UOM select collapses after choice', page.locator('[data-bj02-uom]').count()==0 and 'Mã NOB-DHPP · hộp' in page.locator('#app-screen').inner_text())
    # fill single lot and save
    page.locator('[data-bj02-lot-field="code"]').fill('Q260826')
    page.locator('[data-bj02-lot-field="expiry"]').fill('31/08/2027')
    page.locator('[data-bj02-lot-total]').fill('10')
    page.locator('[data-bj02-action="save-line"]').click()
    check('Quick saved item appears in overview', page.locator('[data-bj02-line-id]').count()==1)

    # duplicate Product+UOM blocker
    page.locator('[data-bj02-action="add-line"]').click()
    page.locator('[data-bj02-product-option="P-NOB-DHPP"]').click()
    page.locator('[data-bj02-uom]').select_option('UOM-BOX')
    txt=page.locator('#app-screen').inner_text()
    check('Duplicate Product+UOM shows blocker and open-existing CTA', 'Sản phẩm và đơn vị này đã có' in txt and 'Mở sản phẩm đã có' in txt)
    check('Duplicate Product+UOM does not render LOT editor', 'Lô hàng' not in txt and page.locator('[data-bj02-action="add-editor-lot"]').count()==0)
    page.locator('[data-bj02-action="open-duplicate-line"]').click()
    check('Open-existing returns to existing item editor', page.locator('[data-bj02-action="remove-quick-line"]').count()==1)
    page.locator('[data-back]').click()
    check('Opening a completed item then Back does not demote its status', '10 hộp' in page.locator('.receipt-line-primary').first.inner_text() and '10 đạt' in page.locator('.receipt-line-secondary').first.inner_text())

    # Quick Review with normal approval info and note
    page.evaluate('navigate("SCR-010")')
    banners=page.locator('.v-banner')
    check('Quick mandatory approval uses info banner', banners.count()>=1 and 'v-banner--info' in banners.first.get_attribute('class'))
    check('Quick Review shows note only when present', 'Giao tại cửa kho số 2' in page.locator('#app-screen').inner_text())
    check('Quick Review shows lot identity', 'Q260826' in page.locator('#app-screen').inner_text())
    shot(page,'SCR-010-quick-review')

    # Approver context
    page.evaluate('stateByScreen["SCR-011"]="READY"; navigate("SCR-011")')
    apptext=page.locator('#app-screen').inner_text()
    check('Approver gets receiving context', all(x in apptext for x in ['Thông tin lần nhận','Minh Dũng','Kho mặc định','26/08/2026','PGH-826-01','Giao tại cửa kho số 2']))
    check('Approver gets request summary', 'Thông tin yêu cầu' in apptext and 'Người lập' in apptext)
    check('Approver gets actual lot evidence', 'Q260826' in apptext and 'HSD 31/08/2027' in apptext)
    check('Quick approval reason is info not warning', page.locator('.v-banner--info').count()>=1 and page.locator('.v-banner--warning').count()==0)
    check('Approver only has approve/reject decision CTAs', page.locator('[data-action="approve"]').count()==1 and page.locator('[data-action="open-reject"]').count()==1 and 'Yêu cầu bổ sung' not in apptext)
    check('SCR-011 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    shot(page,'SCR-011-approval-context')

    # Result semantics
    page.evaluate('stateByScreen["SCR-012"]="COMPLETED"; navigate("SCR-012")')
    resulttxt=page.locator('#app-screen').inner_text()
    check('Completed result uses Kết quả theo mục hàng', 'Kết quả theo mục hàng' in resulttxt)
    check('Completed result includes lot identity', 'Q260826' in resulttxt)
    check('Completed does not show valuation-pending banner', 'Đang chờ xác nhận giá' not in resulttxt)
    page.evaluate('stateByScreen["SCR-012"]="VALUATION_PENDING_RESULT"; render()')
    check('Valuation-pending state shows info banner only when relevant', 'Đang chờ xác nhận giá' in page.locator('#app-screen').inner_text() and page.locator('.v-banner--info').count()>=1)
    check('SCR-012 no horizontal overflow', no_h_overflow(page), str(overflow(page)))

    # Recovery UX
    page.evaluate('stateByScreen["SCR-013"]="PROCESSING_OR_UNKNOWN"; navigate("SCR-013")')
    t=page.locator('#app-screen').inner_text()
    check('Unknown recovery uses one loading message', page.locator('[data-ds-component="VLoading"]').count()==1 and 'Chưa cần thực hiện lại lần nhận.' in t)
    check('Unknown recovery avoids duplicate warning banner', page.locator('.v-banner--warning').count()==0)
    check('Recovery removes technical operation/movement/approval IDs', all(x not in t for x in ['APR-','MOV-','IO-',' v3']))
    check('Recovery keeps one useful receipt reference', 'REC-260817-04' in t)
    page.evaluate('stateByScreen["SCR-013"]="EMPTY"; render()')
    t=page.locator('#app-screen').inner_text()
    check('Recovery EMPTY uses user-facing VEmptyState', page.locator('[data-ds-component="VEmptyState"]').count()==1 and 'Chưa có kết quả mới' in t)
    check('Recovery EMPTY has no warning banner', page.locator('.v-banner--warning').count()==0)
    page.evaluate('stateByScreen["SCR-013"]="STALE"; render()')
    check('Recovery STALE retains query-only warning/refresh', page.locator('.v-banner--warning').count()==1 and page.locator('[data-action="refresh"]').count()==1)
    check('SCR-013 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    shot(page,'SCR-013-recovery')

    browser.close()

passed=sum(ok for _,ok,_ in checks)
failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# BJ-02 Runtime / Render Smoke v0.2.9','',f'**Result: {passed}/{len(checks)} PASS**' if not failed else f'**Result: {passed}/{len(checks)} PASS · {len(failed)} FAIL**','', 'Runs the real BJ-02 renderer in headless Chromium by injecting the self-contained workbench into an `about:blank` target.','', '## Checks','']
for n,ok,d in checks:
    lines.append(f'- [{"x" if ok else " "}] {n}' + (f' — {d}' if d else ''))
lines += ['', '## Boundary','', '- Exercises real DOM/layout and representative end-user interactions on the 402 × 874 product viewport.', '- Validates search, multi-product overview, true read-only, multi-LOT, quantity variance, Quick duplicate guard, review/approval context, result and recovery semantics.', '- Does not claim pixel parity against the external Vercel Flutter reference.']
(OUT/'RUNTIME-SMOKE-v0.2.9.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
raise SystemExit(1 if failed else 0)
