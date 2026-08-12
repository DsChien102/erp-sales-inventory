from pathlib import Path
from playwright.sync_api import sync_playwright
import base64

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'screenshots-v1.3.5'
SHOTS.mkdir(exist_ok=True)
TMP=OUT/'tmp-v1.3.5'
TMP.mkdir(exist_ok=True)
(TMP/'delivery.pdf').write_bytes(b'%PDF-1.4\n% VET45 QA fixture\n')
(TMP/'lot-label.png').write_bytes(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9Z6KAAAAAASUVORK5CYII='))
checks=[]

def check(name, cond, detail=''):
    checks.append((name,bool(cond),str(detail) if detail else ''))

def build_html():
    idx=(ROOT/'index.html').read_text(encoding='utf8')
    css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8')
    data=(ROOT/'workbench-data.js').read_text(encoding='utf8')
    app=(ROOT/'app.js').read_text(encoding='utf8')
    return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')

def no_h_overflow(page):
    g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
    return g['sw']<=g['cw']+1

def shot(page,name):
    page.wait_for_timeout(360)
    page.locator('#device-preview').screenshot(path=str(SHOTS/f'{name}.png'))

def setup_bj02(page, screen='SCR-008'):
    page.evaluate(f'''activeFlowId="UIF-02"; flowMode="quick"; resetBj02Receipt("quick"); activeScreenId="{screen}"; stateByScreen["{screen}"]="READY"; render();''')

def setup_bj06(page, screen='SCR-032', state='LOT_MISMATCH'):
    page.evaluate(f'''activeFlowId="UIF-06"; activeScreenId="{screen}"; stateByScreen["{screen}"]="{state}"; io06Line.actualLot="LOT-KHAC"; io06Line.reasonCode=""; io06Line.reasonDetail=""; io06Line.evidenceFile=""; io06Line.exception="NONE"; io06RejectOpen=false; render();''')

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1680,'height':1000})
    errors=[]
    page.on('pageerror',lambda e: errors.append(str(e)))
    page.set_content(build_html(), wait_until='load')
    page.wait_for_timeout(80)

    frame=page.locator('#device-preview').evaluate('(e)=>[Math.round(e.getBoundingClientRect().width),Math.round(e.getBoundingClientRect().height)]')
    check('Canonical mobile frame is 402 x 874', frame==[402,874], frame)

    # BJ02 SCR-008 — fixed selector semantics, temporal guard, file evidence.
    setup_bj02(page,'SCR-008')
    warehouse=page.locator('[data-bj02-warehouse]')
    check('SCR008 warehouse is a select control', warehouse.count()==1 and warehouse.evaluate('(e)=>e.tagName')=='SELECT')
    check('SCR008 warehouse selector is disabled', warehouse.is_disabled())
    check('SCR008 warehouse resolves default warehouse', warehouse.input_value()=='Kho mặc định', warehouse.input_value())
    date=page.locator('[data-bj02-header="businessDate"]')
    today=page.evaluate('localDateIso()')
    check('SCR008 date uses native date input', date.get_attribute('type')=='date')
    check('SCR008 date minimum equals tenant/client current day fixture', date.get_attribute('min')==today, f"min={date.get_attribute('min')} today={today}")
    check('SCR008 evidence is file input', page.locator('[data-bj02-evidence-file][type="file"]').count()==1)
    check('SCR008 has no text evidence field', page.locator('input[data-bj02-header="evidence"],textarea[data-bj02-header="evidence"]').count()==0)
    # Resolve supplier via real UI.
    supplier=page.locator('[data-bj02-supplier-search]'); supplier.click(); supplier.fill('Minh')
    page.locator('[data-bj02-supplier-option="SUP-MINH-DUNG"]').click()
    # Past date must block continue.
    page.evaluate('bj02Header.businessDate="2020-01-01"; renderAppScreen()')
    check('Past receiving date exposes validation error', 'Ngày nhận không được trước hôm nay' in page.locator('#app-screen').inner_text())
    check('Past receiving date blocks Continue', page.locator('[data-next="SCR-009"]').is_disabled())
    # Restore today; evidence still missing => blocked.
    page.evaluate('bj02Header.businessDate=localDateIso(); renderAppScreen()')
    check('Missing delivery file blocks Continue', page.locator('[data-next="SCR-009"]').is_disabled())
    page.locator('[data-bj02-evidence-file]').set_input_files(str(TMP/'delivery.pdf'))
    page.wait_for_timeout(30)
    check('Uploaded delivery file name is shown', 'delivery.pdf' in page.locator('#app-screen').inner_text())
    check('Valid supplier/date/file enables Continue', not page.locator('[data-next="SCR-009"]').is_disabled())
    check('SCR008 product copy has no technical evidence wording', 'evidence' not in page.locator('#app-screen').inner_text().lower())
    check('SCR008 no horizontal overflow', no_h_overflow(page))
    shot(page,'BJ02-SCR008-quick-header')
    page.locator('[data-next="SCR-009"]').click()
    check('Quick header advances to SCR009', 'SCR-009' in page.locator('#current-screen-id').inner_text())

    # BJ02 SCR-009 — visible mandatory UOM, decisive selection advances.
    q=page.locator('[data-bj02-overview-product-search]'); q.fill('Nobivac')
    page.locator('[data-bj02-overview-product-option="P-NOB-DHPP"]').click()
    choices=page.locator('[data-bj02-overview-uom-choice]')
    check('Multi-UOM product shows all UOM choices directly', choices.count()>=2, choices.count())
    check('Multi-UOM chooser has no select/dropdown', page.locator('select[data-bj02-overview-uom],select[data-bj02-uom]').count()==0)
    check('UOM choices remain on SCR009 before selection', 'SCR-009' in page.locator('#current-screen-id').inner_text())
    check('SCR009 UOM chooser no horizontal overflow', no_h_overflow(page))
    shot(page,'BJ02-SCR009-uom-choices')
    choices.first.click()
    check('Choosing UOM advances directly to SCR084', 'SCR-084' in page.locator('#current-screen-id').inner_text())
    check('Selected Product/UOM already resolved in detail', page.locator('.line-product-identity').count()==1)
    check('Detail does not ask UOM again', page.locator('select[data-bj02-uom],[data-bj02-line-uom-choice]').count()==0)

    # LOT append semantics.
    check('LOT collection action says Thêm lô khác', page.locator('[data-bj02-action="add-editor-lot"]').inner_text().strip()=='Thêm lô khác')
    check('Detail completion CTA remains Xong', page.locator('[data-bj02-action="save-line"]').inner_text().strip()=='Xong')
    check('No exact ambiguous Thêm lô button remains', page.locator('button').filter(has_text='Thêm lô').count()==page.locator('button').filter(has_text='Thêm lô khác').count())
    check('SCR084 no horizontal overflow', no_h_overflow(page))
    shot(page,'BJ02-SCR084-lot')

    # Single UOM should also advance immediately.
    setup_bj02(page,'SCR-009')
    q=page.locator('[data-bj02-overview-product-search]'); q.fill('Găng tay')
    page.locator('[data-bj02-overview-product-option="P-GLOVE-N"]').click()
    check('Single-UOM Product advances directly to SCR084', 'SCR-084' in page.locator('#current-screen-id').inner_text())

    # BJ06 wrong-LOT evidence — direct choices + actual image artifact.
    setup_bj06(page)
    reason_choices=page.locator('[data-io06-reason]')
    check('Wrong-LOT shows reason choices directly', reason_choices.count()==4, reason_choices.count())
    check('Wrong-LOT evidence uses image file input', page.locator('[data-io06-evidence-file][type="file"][accept="image/*"]').count()==1)
    submit=page.locator('[data-io06-action="submit-lot-exception"]')
    check('Wrong-LOT submit blocked before reason/evidence', submit.is_disabled())
    page.locator('[data-io06-reason="ACTUAL_DIFF"]').click()
    submit=page.locator('[data-io06-action="submit-lot-exception"]')
    check('Reason alone is insufficient', submit.is_disabled())
    page.locator('[data-io06-evidence-file]').set_input_files(str(TMP/'lot-label.png'))
    page.wait_for_timeout(30)
    submit=page.locator('[data-io06-action="submit-lot-exception"]')
    check('Reason plus LOT image enables maker submit', not submit.is_disabled())
    check('Uploaded LOT image filename shown', 'lot-label.png' in page.locator('#app-screen').inner_text())
    check('SCR032 copy uses Vietnamese reason wording', 'reason' not in page.locator('#app-screen').inner_text().lower())
    check('SCR032 no horizontal overflow', no_h_overflow(page))
    shot(page,'BJ06-SCR032-wrong-lot')
    submit.click()
    check('Submitting exception returns to return overview', 'SCR-031' in page.locator('#current-screen-id').inner_text())
    # Open approver independently; evidence retained.
    page.evaluate('activeScreenId="SCR-034"; stateByScreen["SCR-034"]="READY"; render()')
    text=page.locator('#app-screen').inner_text()
    check('Approver sees original and actual LOT', io := ('Lô đã giao' in text and 'Lô thực nhận' in text), text[:200] if not io else '')
    check('Approver sees structured reason', 'Hàng thực tế khác thông tin giao trước đó' in text)
    check('Approver sees evidence image reference', 'lot-label.png' in text)
    check('Approver sees maker identity', 'Nguyễn Minh' in text)
    check('SCR034 no horizontal overflow', no_h_overflow(page))
    shot(page,'BJ06-SCR034-approver')

    # OTHER requires description.
    setup_bj06(page)
    page.locator('[data-io06-reason="OTHER"]').click()
    page.locator('[data-io06-evidence-file]').set_input_files(str(TMP/'lot-label.png'))
    check('Reason Other plus image still blocked without description', page.locator('[data-io06-action="submit-lot-exception"]').is_disabled())
    page.locator('[data-io06-reason-detail]').fill('Nhãn trên hàng thực nhận khác dữ liệu giao trước đó')
    check('Reason Other becomes valid with description and image', not page.locator('[data-io06-action="submit-lot-exception"]').is_disabled())

    # BJ05/BJ07 handover: no invented evidence inputs, physical assertion remains.
    page.evaluate('activeFlowId="UIF-05"; activeScreenId="SCR-028"; stateByScreen["SCR-028"]="READY"; render()')
    t5=page.locator('#app-screen').inner_text()
    check('BJ05 handover explicitly refers to physical handover confirmation', 'bàn giao' in t5.lower())
    check('BJ05 handover does not invent photo/signature/recipient/carrier inputs', page.locator('input[type="file"],input[placeholder*="người nhận" i],input[placeholder*="carrier" i]').count()==0)
    check('BJ05 handover no horizontal overflow', no_h_overflow(page))
    shot(page,'BJ05-SCR028-handover')

    page.evaluate('activeFlowId="UIF-07"; activeScreenId="SCR-039"; stateByScreen["SCR-039"]="READY"; render()')
    t7=page.locator('#app-screen').inner_text()
    check('BJ07 handover explicitly refers to physical handover confirmation', 'bàn giao' in t7.lower())
    check('BJ07 handover does not invent photo/signature/recipient/carrier inputs', page.locator('input[type="file"],input[placeholder*="người nhận" i],input[placeholder*="carrier" i]').count()==0)
    check('BJ07 handover hides technical commit/actor wording', all(x not in t7.lower() for x in ['commit','actor','source/lot']))
    check('BJ07 handover no horizontal overflow', no_h_overflow(page))
    shot(page,'BJ07-SCR039-handover')

    check('No page-level JavaScript errors', not errors, '; '.join(errors[:3]))
    browser.close()

passed=sum(ok for _,ok,_ in checks)
failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# BJ02 + BJ06 interaction/evidence runtime QA — v1.3.5','',f'**Result: {passed}/{len(checks)} PASS**' if not failed else f'**Result: {passed}/{len(checks)} PASS · {len(failed)} FAIL**','', 'Chromium interaction QA against the cumulative v1.3.5 workbench at the canonical 402 × 874 product viewport.','', '## Checks','']
for n,ok,d in checks:
    lines.append(f'- [{"x" if ok else " "}] {n}' + (f' — {d}' if d else ''))
lines += ['', '## Scope', '', '- BJ02: locked warehouse selector, temporal guard, file evidence, visible UOM choice, direct Product+UOM → detail, unambiguous LOT append.', '- BJ06: structured wrong-LOT reason + required image evidence + approver evidence visibility.', '- BJ05/BJ07: normal handover keeps system evidence + actor physical confirmation without inventing mandatory photo/signature/recipient fields.']
(OUT/'RUNTIME-INTERACTION-QA-v1.3.5.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
raise SystemExit(1 if failed else 0)
