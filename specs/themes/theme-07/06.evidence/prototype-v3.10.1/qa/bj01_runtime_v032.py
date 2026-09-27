from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'screenshots-v0.3.2'
SHOTS.mkdir(exist_ok=True)
checks=[]

def check(name, cond, detail=''):
    checks.append((name,bool(cond),detail))

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

def set_screen(page, sid, state='READY'):
    page.evaluate(f'activeFlowId="UIF-01"; activeScreenId="{sid}"; stateByScreen["{sid}"]="{state}"; bj01LotOpen=false; bj01ProvenanceOpen=false; render()')
    page.wait_for_timeout(20)

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1680,'height':1000})
    page.set_content(build_html(),wait_until='load')
    page.wait_for_timeout(80)

    # Harness baseline / activate BJ01
    frame=page.locator('#device-preview').evaluate('(e)=>[Math.round(e.getBoundingClientRect().width),Math.round(e.getBoundingClientRect().height)]')
    check('mobile frame remains 402x874', frame==[402,874], str(frame))
    page.evaluate('activeFlowId="UIF-01"; activeScreenId="SCR-001"; stateByScreen["SCR-001"]="READY"; bj01Filter="ALL"; bj01Query=""; bj01LotOpen=false; bj01ProvenanceOpen=false; render()')

    # SCR-001 single list
    txt=page.locator('#app-screen').inner_text()
    check('SCR-001 has no Tra cứu/Cần chú ý tabs', 'Tra cứu' not in txt and 'Cần chú ý' not in txt)
    check('SCR-001 has 5 filter chips', page.locator('[data-bj01-filter]').count()==5, str(page.locator('[data-bj01-filter]').count()))
    check('SCR-001 shows five fixture rows', page.locator('[data-bj01-product]').count()==5)
    check('SCR-001 search copy uses mã vạch', 'mã vạch' in page.locator('[data-bj01-search]').get_attribute('placeholder').lower())
    check('SCR-001 has no tracking metadata', 'Theo lô' not in txt and 'Không theo lô' not in txt)
    check('SCR-001 first row uses one compact quantity+UOM', '106 hộp' in page.locator('[data-bj01-product="INV-NOB"]').inner_text())
    left=page.locator('[data-bj01-product="INV-NOB"] .bj01-product-copy').inner_text()
    check('SCR-001 left metadata does not repeat UOM', 'hộp' not in left.lower(), left)
    row_h=page.locator('[data-bj01-product="INV-NOB"]').evaluate('(e)=>Math.round(e.getBoundingClientRect().height)')
    check('SCR-001 product row remains compact', row_h<=72, str(row_h))
    check('SCR-001 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    shot(page,'SCR-001-all')

    # Filters + no repeated status per row
    expected={'OUT':('INV-ENRO',1),'LOW':('INV-AMX',2),'NEAR':('INV-NOB',1),'EXPIRED':('INV-TYLO',1)}
    for key,(must_id,count) in expected.items():
        page.locator(f'[data-bj01-filter="{key}"]').click()
        rows=page.locator('[data-bj01-product]')
        ids=rows.evaluate_all('(els)=>els.map(e=>e.dataset.bj01Product)')
        check(f'{key} filter returns expected count', len(ids)==count, str(ids))
        check(f'{key} filter includes expected product', must_id in ids, str(ids))
        check(f'{key} filtered rows do not repeat filter status', page.locator('.bj01-inline-status').count()==0, str(page.locator('.bj01-inline-status').count()))
    # LOW screenshot
    page.locator('[data-bj01-filter="LOW"]').click(); shot(page,'SCR-001-low')

    # Search / no result / clear / FILTER_EMPTY recovery
    page.locator('[data-bj01-filter="ALL"]').click()
    inp=page.locator('[data-bj01-search]')
    inp.fill('Amox')
    check('search filters current list', page.locator('[data-bj01-product]:visible').count()==1)
    inp.fill('ZZZ-NOT-FOUND')
    check('search no-result retains search and chips', page.locator('[data-bj01-empty]:visible').count()==1 and page.locator('[data-bj01-filter]').count()==5)
    page.locator('[data-bj01-clear]').click()
    check('clear search/filter restores full list', page.locator('[data-bj01-product]').count()==5 and page.evaluate('bj01Filter')=='ALL' and page.evaluate('bj01Query')=='')
    page.evaluate('stateByScreen["SCR-001"]="FILTER_EMPTY"; render()')
    check('FILTER_EMPTY renders empty state with filters retained', page.locator('[data-bj01-empty]:visible').count()==1 and page.locator('[data-bj01-filter]').count()==5)
    page.locator('[data-bj01-clear]').click()
    check('FILTER_EMPTY clear recovers READY state', page.evaluate('stateByScreen["SCR-001"]')=='READY' and page.locator('[data-bj01-product]').count()==5)

    # Product detail: normal LOT product
    page.locator('[data-bj01-product="INV-NOB"]').click()
    check('product row opens SCR-003', 'SCR-003' in page.locator('#current-screen-id').inner_text())
    txt=page.locator('#app-screen').inner_text()
    check('SCR-003 hero shows available once at product level', page.locator('.bj01-detail-availability').count()==1 and '106 hộp' in page.locator('.bj01-detail-availability').inner_text())
    labels=page.locator('.bj01-section .bj01-breakdown-row span').all_inner_texts()
    check('SCR-003 supporting breakdown is exactly 3 rows', labels[:3]==['Tồn vật lý','Đủ điều kiện bán','Đã giữ'], str(labels[:3]))
    check('SCR-003 breakdown does not repeat Khả dụng', 'Khả dụng' not in labels[:3], str(labels[:3]))
    check('SCR-003 normal product has no product-level attention block', page.locator('.bj01-attention-list').count()==0)
    check('SCR-003 LOT list has two compact rows', page.locator('[data-bj01-lot]').count()==2)
    check('LOT-level near-expiry wording stays on LOT row', 'Cận hạn' in page.locator('[data-bj01-lot="DH2509"]').inner_text())
    forbidden=['barcode','snapshot','inventory projection','cut-off','Theo lô','Không theo lô']
    check('SCR-003 has no technical/English leakage', all(x.lower() not in txt.lower() for x in forbidden), txt[:250])
    check('SCR-003 no legacy card-heavy BJ01 blocks', page.locator('.bj01-metrics,.bj01-info-card,.bj01-hero,.bj01-segment').count()==0)
    check('SCR-003 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    shot(page,'SCR-003-normal')
    # Long product identity must wrap rather than collide with availability.
    page.evaluate('bj01Products[0].name="Nobivac DHPPi vaccine phối hợp cho chó giống và chó trưởng thành"; renderAppScreen()')
    h2=page.locator('.bj01-detail-identity h2').evaluate('(e)=>({h:Math.round(e.getBoundingClientRect().height), sw:e.scrollWidth, cw:e.clientWidth})')
    check('long product name wraps without horizontal overflow', h2['h']>24 and h2['sw']<=h2['cw']+1 and no_h_overflow(page), str(h2))
    page.evaluate('bj01Products[0].name="Nobivac DHPPi"; renderAppScreen()')

    # LOT bottom sheet stays in SCR003
    page.locator('[data-bj01-lot="DH2509"]').click()
    check('LOT opens contextual bottom sheet', page.locator('.bj01-sheet[aria-label="Chi tiết lô"]').count()==1)
    check('LOT sheet does not navigate away from SCR-003', 'SCR-003' in page.locator('#current-screen-id').inner_text())
    ltxt=page.locator('.bj01-sheet[aria-label="Chi tiết lô"]').inner_text()
    check('LOT sheet shows identity expiry and availability', all(x in ltxt for x in ['Lô DH2509','15/09/2026','44 hộp']))
    sheet_labels=page.locator('.bj01-sheet[aria-label="Chi tiết lô"] .bj01-breakdown-row span').all_inner_texts()
    check('LOT sheet has 3 supporting rows without duplicate available', sheet_labels==['Tồn vật lý','Đủ điều kiện bán','Đã giữ'], str(sheet_labels))
    check('LOT sheet carries update time without extra context cards', 'Cập nhật lúc' in ltxt and 'Kho trung tâm' in ltxt)
    shot(page,'LOT-detail-sheet')
    page.locator('button[data-bj01-close-lot]').click()
    check('closing LOT sheet returns same detail screen', page.locator('.bj01-sheet[aria-label="Chi tiết lô"]').count()==0 and 'SCR-003' in page.locator('#current-screen-id').inner_text())

    # Provenance bottom sheet
    page.locator('[data-bj01-provenance]').click()
    check('provenance opens contextual bottom sheet', page.locator('.bj01-sheet[aria-label="Nguồn và thời điểm cập nhật"]').count()==1)
    ptxt=page.locator('.bj01-sheet[aria-label="Nguồn và thời điểm cập nhật"]').inner_text()
    check('provenance uses Vietnamese business copy', all(x in ptxt for x in ['Dữ liệu cập nhật lúc','Nguồn dữ liệu tồn kho','Tình trạng cập nhật','Xem lịch sử tồn kho']))
    check('provenance hides technical terminology', all(x not in ptxt.lower() for x in ['snapshot','projection','movement','cut-off','retry','version']))
    check('provenance stays on SCR-003 until explicit handoff', 'SCR-003' in page.locator('#current-screen-id').inner_text())
    shot(page,'provenance-sheet')
    page.locator('button[data-bj01-close-provenance]').click()

    # LOW detail: only meaningful operational context
    page.evaluate('bj01SelectedProductId="INV-AMX"; stateByScreen["SCR-003"]="READY"; renderAppScreen()')
    txt=page.locator('#app-screen').inner_text()
    check('LOW detail shows one compact attention row', page.locator('.bj01-attention-list .bj01-attention-row').count()==1 and 'Tồn thấp' in txt)
    check('LOW detail shows threshold and suggested quantity', 'Ngưỡng 50 hộp' in txt and 'Gợi ý bổ sung 38 hộp' in txt)
    check('LOW non-LOT product has no LOT list', page.locator('[data-bj01-lot]').count()==0)
    shot(page,'SCR-003-low')

    # OUT detail
    page.evaluate('bj01SelectedProductId="INV-ENRO"; renderAppScreen()')
    txt=page.locator('#app-screen').inner_text()
    check('OUT detail shows Hết hàng', 'Hết hàng' in txt)
    check('OUT detail shows configured threshold/suggestion only when useful', 'Ngưỡng 10 chai' in txt and 'Gợi ý bổ sung 30 chai' in txt)

    # Product with both LOW + expired LOT: no duplicated product-level lot warning
    page.evaluate('bj01SelectedProductId="INV-TYLO"; renderAppScreen()')
    txt=page.locator('#app-screen').inner_text()
    attention=page.locator('.bj01-attention-list').inner_text() if page.locator('.bj01-attention-list').count() else ''
    check('mixed indicator product prioritizes product LOW in detail attention', 'Tồn thấp' in attention and 'hết hạn' not in attention.lower(), attention)
    check('expired status remains on affected LOT row', 'Hết hạn' in page.locator('[data-bj01-lot="TY2408"]').inner_text())

    # No threshold configuration: no fake warning/suggestion
    page.evaluate('bj01SelectedProductId="INV-OXY"; renderAppScreen()')
    txt=page.locator('#app-screen').inner_text()
    check('no-threshold product stays quiet', page.locator('.bj01-attention-list').count()==0 and 'Chưa có ngưỡng' not in txt and 'Gợi ý bổ sung' not in txt)

    # Stale + permission states
    page.evaluate('stateByScreen["SCR-003"]="STALE"; renderAppScreen()')
    check('STALE retains data with refresh affordance', page.locator('.v-banner--warning').count()==1 and page.locator('[data-bj01-refresh]').count()==1 and '26 chai' in page.locator('#app-screen').inner_text())
    page.locator('[data-bj01-refresh]').click()
    check('refresh returns current screen to READY', page.evaluate('stateByScreen["SCR-003"]')=='READY')
    page.evaluate('stateByScreen["SCR-003"]="PERMISSION_DENIED"; renderAppScreen()')
    ptxt=page.locator('#app-screen').inner_text()
    check('permission denied does not render inventory quantities', page.locator('.bj01-detail-availability,.bj01-breakdown,[data-bj01-lot]').count()==0)
    check('permission denied uses centered empty surface', page.locator('.app-content--centered [data-ds-component="VEmptyState"]').count()==1)

    # Return to list and geometry
    set_screen(page,'SCR-001','READY')
    check('final SCR-001 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    browser.close()

passed=sum(ok for _,ok,_ in checks)
failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# BJ-01 Runtime / Visual Smoke v0.3.2','',f'**Result: {passed}/{len(checks)} PASS**' if not failed else f'**Result: {passed}/{len(checks)} PASS · {len(failed)} FAIL**','', 'Runs the real cumulative workbench renderer in headless Chromium with a 402 × 874 product viewport. Screenshots are written only to `screenshots-v0.3.2`; historical BJ-02 screenshots are not touched.','', '## Checks','']
for n,ok,d in checks:
    lines.append(f'- [{"x" if ok else " "}] {n}' + (f' — {d}' if d else ''))
lines += ['', '## Boundary','', '- Covers BJ-01 single-list architecture, filters/search, compact information hierarchy, LOT/provenance overlays, LOW/OUT/no-threshold/stale/permission scenarios and overflow.', '- Browser smoke plus screenshot review is required; this report does not assert pixel identity with BJ-02 or any external design source.']
(OUT/'BJ01-RUNTIME-QA-v0.3.2.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
raise SystemExit(1 if failed else 0)
