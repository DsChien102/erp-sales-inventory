from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'screenshots-v0.3.3'
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
    page.wait_for_timeout(260)
    page.locator('#device-preview').screenshot(path=str(SHOTS/f'{name}.png'))

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1680,'height':1000})
    page.set_content(build_html(),wait_until='load')
    page.wait_for_timeout(60)
    frame=page.locator('#device-preview').evaluate('(e)=>[Math.round(e.getBoundingClientRect().width),Math.round(e.getBoundingClientRect().height)]')
    check('mobile frame 402x874', frame==[402,874], str(frame))
    page.evaluate('activeFlowId="UIF-01"; activeScreenId="SCR-001"; stateByScreen["SCR-001"]="READY"; bj01Filter="ALL"; bj01Query=""; bj01LotOpen=false; bj01ProvenanceOpen=false; render()')

    # SCR001 DS composition
    check('SCR001 uses VPageScaffold', page.locator('[data-ds-component="VPageScaffold"]').count()==1)
    check('SCR001 uses VAppBar', page.locator('[data-ds-component="VAppBar"]').count()==1)
    check('SCR001 uses shared VSearchBar profile', page.locator('.search-box[data-ds-component="VSearchBar"][data-ds-profile="search.standard"]').count()==1)
    check('SCR001 uses 5 VChip filters', page.locator('[data-bj01-filter][data-ds-component="VChip"]').count()==5)
    check('SCR001 has one list VCard container', page.locator('.bj01-list-card[data-ds-component="VCard"]').count()==1)
    check('SCR001 not card-per-product', page.locator('[data-bj01-product][data-ds-component="VCard"]').count()==0)
    check('SCR001 product rows compose DS primitives', page.locator('[data-bj01-product][data-theme-component="Theme7InventoryProductRow"]').count()==5)
    check('SCR001 whole row tap only, no open CTA', 'Mở' not in page.locator('#app-screen').inner_text())
    check('SCR001 no tracking text', all(x not in page.locator('#app-screen').inner_text() for x in ['Theo lô','Không theo lô']))
    check('SCR001 no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    shot(page,'SCR-001-all')

    # status badge only when useful; suppressed when filtered
    check('SCR001 all may show VBadge statuses', page.locator('[data-bj01-product] [data-ds-component="VBadge"]').count()>=1)
    page.locator('[data-bj01-filter="LOW"]').click()
    check('LOW filter keeps VChip selected state', page.locator('[data-bj01-filter="LOW"][data-ds-prop-selected="true"]').count()==1)
    check('LOW filter does not repeat row status badge', page.locator('[data-bj01-product] [data-ds-component="VBadge"]').count()==0)
    shot(page,'SCR-001-low')

    # no result recovery is VButton
    page.locator('[data-bj01-filter="ALL"]').click()
    inp=page.locator('[data-bj01-search]'); inp.fill('NO-MATCH-XYZ')
    check('filter empty retains VSearchBar/VChip', page.locator('[data-bj01-empty]:visible').count()==1 and page.locator('[data-bj01-filter]').count()==5)
    check('empty recovery uses VButton secondary', page.locator('[data-bj01-clear][data-ds-component="VButton"][data-ds-prop-variant="VButtonVariant.secondary"]').count()==1)
    page.locator('[data-bj01-clear]').click()

    # Detail normal
    page.locator('[data-bj01-product="INV-NOB"]').click()
    check('opens SCR003', 'SCR-003' in page.locator('#current-screen-id').inner_text())
    check('detail summary is one VCard', page.locator('.bj01-summary-card[data-ds-component="VCard"]').count()==1)
    check('detail summary has one available hero', page.locator('.bj01-detail-availability').count()==1)
    labels=page.locator('.bj01-summary-card .bj01-breakdown-row span').all_inner_texts()
    check('detail breakdown exactly physical/sellable/reserved', labels==['Tồn vật lý','Đủ điều kiện bán','Đã giữ'], str(labels))
    check('normal detail has no VBanner', page.locator('.v-banner').count()==0)
    check('LOT list in one VCard', page.locator('.bj01-lot-card[data-ds-component="VCard"]').count()==1)
    check('LOT rows use VBadge for expiry only when needed', page.locator('[data-bj01-lot="DH2509"] [data-ds-component="VBadge"]').count()==1)
    check('provenance entry is interactive VCard', page.locator('.bj01-provenance-card[data-ds-component="VCard"][data-ds-profile="card.interactive"]').count()==1)
    check('detail no horizontal overflow', no_h_overflow(page), str(overflow(page)))
    shot(page,'SCR-003-normal')

    # LOT BottomSheet exact public shell: no custom close
    page.locator('[data-bj01-lot="DH2509"]').click()
    check('LOT uses VBottomSheet', page.locator('.bottom-sheet[data-ds-component="VBottomSheet"][aria-label="Chi tiết lô"]').count()==1)
    check('LOT sheet uses standard handle/title/divider/content', all(page.locator(sel).count()==1 for sel in ['.bottom-sheet .sheet-handle','.bottom-sheet .sheet-title','.bottom-sheet .sheet-divider','.bottom-sheet .sheet-content']))
    check('LOT sheet has no custom close icon/button', page.locator('.bottom-sheet button[aria-label="Đóng"],.bottom-sheet .app-icon-button').count()==0)
    check('near expiry uses VBanner warning in sheet', page.locator('.bottom-sheet .v-banner--warning[data-ds-component="VBanner"]').count()==1)
    shot(page,'LOT-detail-sheet')
    # dismiss by backdrop
    page.locator('.sheet-backdrop').click(position={'x':5,'y':5})
    check('LOT backdrop dismiss returns SCR003', page.locator('.bottom-sheet').count()==0 and 'SCR-003' in page.locator('#current-screen-id').inner_text())

    # Provenance BottomSheet + DS button
    page.locator('[data-bj01-provenance]').click()
    check('provenance uses VBottomSheet', page.locator('.bottom-sheet[data-ds-component="VBottomSheet"][aria-label="Nguồn và thời điểm cập nhật"]').count()==1)
    check('provenance has no custom close', page.locator('.bottom-sheet button[aria-label="Đóng"],.bottom-sheet .app-icon-button').count()==0)
    check('provenance handoff uses VButton secondary', page.locator('[data-bj01-handoff][data-ds-component="VButton"][data-ds-prop-variant="VButtonVariant.secondary"]').count()==1)
    ptxt=page.locator('.bottom-sheet').inner_text().lower()
    check('provenance has no technical English', all(x not in ptxt for x in ['snapshot','projection','movement','cut-off','retry','version']))
    shot(page,'provenance-sheet')
    page.locator('.sheet-backdrop').click(position={'x':5,'y':5})

    # LOW uses DS VBanner, no custom attention component
    page.evaluate('bj01SelectedProductId="INV-AMX"; stateByScreen["SCR-003"]="READY"; renderAppScreen()')
    check('LOW uses VBanner.warning', page.locator('.v-banner--warning[data-ds-component="VBanner"]').count()==1)
    check('LOW banner carries threshold/suggestion', 'Ngưỡng 50 hộp' in page.locator('.v-banner').inner_text() and 'Gợi ý bổ sung 38 hộp' in page.locator('.v-banner').inner_text())
    check('no custom attention-row visual remains', page.locator('.bj01-attention-row,.bj01-attention-list').count()==0)
    shot(page,'SCR-003-low')

    # OUT error semantic
    page.evaluate('bj01SelectedProductId="INV-ENRO"; renderAppScreen()')
    check('OUT uses VBanner.error', page.locator('.v-banner--error[data-ds-component="VBanner"]').count()==1)

    # STALE query action
    page.evaluate('bj01SelectedProductId="INV-OXY"; stateByScreen["SCR-003"]="STALE"; renderAppScreen()')
    check('STALE uses warning banner and secondary VButton', page.locator('.v-banner--warning').count()==1 and page.locator('[data-bj01-refresh][data-ds-component="VButton"]').count()==1)
    page.locator('[data-bj01-refresh]').click()
    check('refresh returns READY', page.evaluate('stateByScreen["SCR-003"]')=='READY')

    # Permission masking
    page.evaluate('stateByScreen["SCR-003"]="PERMISSION_DENIED"; renderAppScreen()')
    check('permission uses VEmptyState', page.locator('[data-ds-component="VEmptyState"]').count()==1)
    check('permission omits inventory summary/lot data', page.locator('.bj01-summary-card,.bj01-lot-card').count()==0)

    browser.close()

passed=sum(ok for _,ok,_ in checks)
failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# BJ-01 Runtime / Flutter DS Smoke v0.3.3','',f'**Result: {passed}/{len(checks)} PASS**' if not failed else f'**Result: {passed}/{len(checks)} PASS · {len(failed)} FAIL**','', 'Runs the cumulative renderer in headless Chromium at 402 × 874.','', '## Checks','']
for n,ok,d in checks:
    lines.append(f'- [{"x" if ok else " "}] {n}' + (f' — {d}' if d else ''))
lines += ['', '## Boundary','', '- Validates BJ01 public Flutter-DS mapping, layout/interaction, content hygiene and 402×874 overflow.', '- Does not assert external Vercel pixel parity because the external site is not available in this runtime.']
(OUT/'BJ01-RUNTIME-QA-v0.3.3.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
raise SystemExit(1 if failed else 0)
