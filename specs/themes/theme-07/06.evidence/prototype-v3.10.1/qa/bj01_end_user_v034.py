from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'screenshots-v0.3.4'
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

def geom(page):
    return page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth,sh:e.scrollHeight,ch:e.clientHeight})')

def no_h_overflow(page):
    g=geom(page); return g['sw'] <= g['cw']+1

def shot(page,name):
    page.wait_for_timeout(320)
    page.locator('#device-preview').screenshot(path=str(SHOTS/f'{name}.png'))

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='/usr/bin/chromium', headless=True, args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1680,'height':1000})
    page.set_content(build_html(),wait_until='load')
    page.wait_for_timeout(80)
    page.evaluate('activeFlowId="UIF-01"; activeScreenId="SCR-001"; stateByScreen["SCR-001"]="READY"; bj01Filter="ALL"; bj01Query=""; bj01RefreshedAt=null; bj01LotOpen=false; bj01ProvenanceOpen=false; render()')
    frame=page.locator('#device-preview').evaluate('(e)=>[Math.round(e.getBoundingClientRect().width),Math.round(e.getBoundingClientRect().height)]')
    check('mobile frame 402x874',frame==[402,874],str(frame))
    check('one inventory list, no Tra cứu/Cần chú ý tabs',page.locator('[data-bj01-filter]').count()==5 and 'Cần chú ý' not in page.locator('#app-screen').inner_text())
    check('search placeholder says name/code/barcode', 'mã vạch' in page.locator('[data-bj01-search]').get_attribute('placeholder').lower())
    check('compact rows do not show tracking policy', all(x not in page.locator('#app-screen').inner_text() for x in ['Theo lô','Không theo lô']))
    check('list has no horizontal overflow',no_h_overflow(page),str(geom(page)))
    shot(page,'BJ01-SCR-001-all')

    # Barcode is not just copy: it works.
    s=page.locator('[data-bj01-search]'); s.fill('8938500001012'); page.wait_for_timeout(40)
    visible=page.locator('[data-bj01-product]:visible')
    check('barcode search actually finds product',visible.count()==1 and visible.first.get_attribute('data-bj01-product')=='INV-NOB',str(visible.count()))
    s.fill('');
    page.locator('[data-bj01-filter="LOW"]').click()
    check('LOW filter selected',page.locator('[data-bj01-filter="LOW"][data-ds-prop-selected="true"]').count()==1)
    check('LOW rows do not repeat LOW badge',page.locator('[data-bj01-product] [data-ds-component="VBadge"]').count()==0)
    shot(page,'BJ01-SCR-001-low')

    # Detail normal.
    page.locator('[data-bj01-filter="ALL"]').click(); page.locator('[data-bj01-product="INV-NOB"]').click()
    check('opens stock detail', 'SCR-003' in page.locator('#current-screen-id').inner_text())
    labels=page.locator('.bj01-summary-card .bj01-breakdown-row span').all_inner_texts()
    check('detail has one available hero + three supporting quantities',page.locator('.bj01-detail-availability').count()==1 and labels==['Tồn vật lý','Đủ điều kiện bán','Đã giữ'],str(labels))
    check('normal product does not get warning noise',page.locator('.v-banner').count()==0)
    check('detail has no horizontal overflow',no_h_overflow(page),str(geom(page)))
    check('provenance entry does not duplicate timestamp', 'Cập nhật lúc' not in page.locator('.bj01-provenance-card').inner_text())
    shot(page,'BJ01-SCR-003-normal')

    # Long content remains readable.
    page.evaluate('bj01Products.find(p=>p.id==="INV-NOB").name="Vắc xin phòng bệnh đường hô hấp và tiêu hóa cho chó Nobivac DHPPi quy cách đặc biệt"; renderAppScreen()')
    title=page.locator('.bj01-detail-identity h2')
    check('long product name wraps instead of clipping', title.evaluate('(e)=>e.scrollHeight<=e.clientHeight+1 && getComputedStyle(e).whiteSpace!=="nowrap"'))
    check('long content still has no horizontal overflow',no_h_overflow(page),str(geom(page)))
    page.evaluate('bj01Products.find(p=>p.id==="INV-NOB").name="Nobivac DHPPi"; renderAppScreen()')

    # LOT sheet.
    page.locator('[data-bj01-lot="DH2509"]').click()
    check('lot detail is contextual bottom sheet',page.locator('.bottom-sheet[aria-label="Chi tiết lô"]').count()==1)
    check('lot sheet keeps only useful business language', all(x not in page.locator('.bottom-sheet').inner_text().lower() for x in ['snapshot','projection','movement','cut-off','version']))
    check('lot sheet no horizontal overflow',no_h_overflow(page),str(geom(page)))
    shot(page,'BJ01-LOT-sheet')
    page.locator('.sheet-backdrop').click(position={'x':5,'y':5})

    # Provenance language.
    page.locator('[data-bj01-provenance]').click(); ptxt=page.locator('.bottom-sheet').inner_text()
    check('provenance explains source in end-user language','Nguồn dữ liệu tồn kho' in ptxt and 'Phạm vi số liệu' in ptxt)
    check('provenance has no technical English',all(x not in ptxt.lower() for x in ['snapshot','projection','movement','cut-off','retry','sequence','version']))
    shot(page,'BJ01-provenance-sheet')
    page.locator('.sheet-backdrop').click(position={'x':5,'y':5})

    # Low detail copy explains suggestion, not just numbers.
    page.evaluate('bj01SelectedProductId="INV-AMX"; stateByScreen["SCR-003"]="READY"; renderAppScreen()')
    low=page.locator('.v-banner').inner_text()
    check('LOW message explains threshold', 'dưới ngưỡng' in low.lower())
    check('LOW message explains suggestion reaches target','để đạt mức' in low.lower())
    shot(page,'BJ01-SCR-003-low')

    # Stale refresh visibly changes as-of.
    page.evaluate('bj01SelectedProductId="INV-OXY"; bj01RefreshedAt=null; stateByScreen["SCR-003"]="STALE"; renderAppScreen()')
    before=page.locator('.bj01-context-line').inner_text()
    page.locator('[data-bj01-refresh]').click(); after=page.locator('.bj01-context-line').inner_text()
    check('refresh returns to READY',page.evaluate('stateByScreen["SCR-003"]')=='READY')
    check('refresh visibly updates as-of',before!=after,(before+' -> '+after))

    # Permission does not render sensitive inventory facts.
    page.evaluate('stateByScreen["SCR-003"]="PERMISSION_DENIED"; renderAppScreen()')
    check('permission uses full empty state',page.locator('[data-ds-component="VEmptyState"]').count()==1)
    check('permission masks inventory facts',page.locator('.bj01-summary-card,.bj01-lot-card,.bj01-provenance-card').count()==0)
    browser.close()

passed=sum(ok for _,ok,_ in checks)
failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# BJ-01 End-user QA v0.3.4','',f'**Result: {passed}/{len(checks)} PASS**' if not failed else f'**Result: {passed}/{len(checks)} PASS · {len(failed)} FAIL**','', 'End-user review in Chromium at the canonical 402 × 874 viewport.','', '## Checks','']
for n,ok,d in checks: lines.append(f'- [{"x" if ok else " "}] {n}' + (f' — {d}' if d else ''))
lines += ['', '## Scope','', '- Search/filter behavior, information hierarchy, content hygiene, stale refresh, LOT/provenance overlays, permission masking and mobile overflow.', '- This is a product-facing QA gate, not a declaration that future Product review cannot request further refinement.']
(OUT/'BJ01-END-USER-QA-v0.3.4.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
raise SystemExit(1 if failed else 0)
