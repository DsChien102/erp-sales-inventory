from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'screenshots-v0.3.4'
SHOTS.mkdir(exist_ok=True)
checks=[]

def check(name, cond, detail=''): checks.append((name,bool(cond),detail))
def build_html():
    idx=(ROOT/'index.html').read_text(encoding='utf8')
    css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8')
    data=(ROOT/'workbench-data.js').read_text(encoding='utf8'); app=(ROOT/'app.js').read_text(encoding='utf8')
    return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
def no_h_overflow(page):
    g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); return g['sw']<=g['cw']+1
def shot(page,name): page.wait_for_timeout(320); page.locator('#device-preview').screenshot(path=str(SHOTS/f'{name}.png'))
def labels(page): return [x.strip() for x in page.locator('.classification-quantities .quantity-label strong').all_inner_texts()]

def reset(page,mode='quick',screen='SCR-009'):
    setup = f'activeFlowId="UIF-02"; flowMode="{mode}"; resetBj02Receipt("{mode}");'
    if mode == "quick":
        setup += 'bj02Header.supplierId="SUP-MINH-DUNG"; bj02Header.supplier="Minh Dũng"; bj02Header.businessDate="27/08/2026"; bj02Header.evidence="PG-2708-01";'
    setup += f'activeScreenId="{screen}"; stateByScreen["{screen}"]="READY"; render()'
    page.evaluate(setup)

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1680,'height':1000}); page.set_content(build_html(),wait_until='load'); page.wait_for_timeout(80)
    frame=page.locator('#device-preview').evaluate('(e)=>[Math.round(e.getBoundingClientRect().width),Math.round(e.getBoundingClientRect().height)]')
    check('mobile frame 402x874',frame==[402,874],str(frame))

    # Existing flow boundary is preserved: Quick header still continues to Hàng thực nhận.
    reset(page,'quick','SCR-008')
    cont=page.locator('[data-next="SCR-009"]')
    check('Quick header still owns supplier/date/evidence before item overview', cont.count()==1 and not cont.is_disabled())
    cont.click()
    check('Quick header continues to SCR009', 'SCR-009' in page.locator('#current-screen-id').inner_text())

    # Quick overview: search is directly on Hàng thực nhận, no Add Product indirection.
    reset(page,'quick','SCR-009')
    check('Quick SCR009 has VSearchBar directly',page.locator('[data-bj02-overview-product-search]').count()==1)
    check('Quick SCR009 has no Add Product CTA',page.locator('[data-bj02-action="add-line"]').count()==0 and 'Thêm sản phẩm' not in page.locator('#app-screen').inner_text())
    check('empty Quick overview explains search above','Tìm sản phẩm ở trên để thêm' in page.locator('#app-screen').inner_text())
    check('Quick overview no horizontal overflow',no_h_overflow(page))
    shot(page,'BJ02-quick-overview-empty')

    # Multi-UOM product: search -> product -> choose UOM, all on SCR009.
    q=page.locator('[data-bj02-overview-product-search]'); q.fill('Nobivac');
    check('Quick search filters product results',page.locator('[data-bj02-overview-product-option]:visible').count()==1)
    shot(page,'BJ02-quick-overview-search')
    page.locator('[data-bj02-overview-product-option="P-NOB-DHPP"]').click()
    check('multi-UOM choice stays on SCR009','SCR-009' in page.locator('#current-screen-id').inner_text() and page.locator('[data-bj02-overview-uom]').count()==1)
    shot(page,'BJ02-quick-overview-uom')
    page.locator('[data-bj02-overview-uom]').select_option('UOM-BOX'); page.wait_for_timeout(30)
    check('selected product becomes list item on SCR009','SCR-009' in page.locator('#current-screen-id').inner_text() and page.locator('button.receipt-line-card[data-bj02-line-id]').count()==1)
    check('no automatic jump to detail after adding',page.locator('[data-bj02-overview-product-search]').count()==1)
    shot(page,'BJ02-quick-overview-list')

    # Tap item -> detail. 4 classifications always visible; accepted is derived/read-only.
    page.locator('[data-bj02-line-id]').first.click()
    check('tap item opens SCR084','SCR-084' in page.locator('#current-screen-id').inner_text())
    check('Product/UOM already selected in normal Quick editor',page.locator('.line-product-identity').count()==1 and page.locator('[data-bj02-product-search],[data-bj02-uom]').count()==0)
    check('LOT editor shows four classification fields immediately',labels(page)==['Đạt','Cách ly','Hỏng','Từ chối'],str(labels(page)))
    check('Đạt is read-only derived field',page.locator('[data-bj02-accepted-preview][readonly]').count()==1)
    check('no classification reveal button','Có hàng cần phân loại' not in page.locator('#app-screen').inner_text())
    page.locator('[data-bj02-lot-field="code"]').fill('LOT-2608-A'); page.locator('[data-bj02-lot-field="expiry"]').fill('30/09/2027'); page.locator('[data-bj02-lot-total]').fill('10')
    check('Đạt derives from total immediately',page.locator('[data-bj02-accepted-preview]').input_value()=='10')
    page.locator('[data-bj02-lot-qty="quarantine"]').fill('2')
    check('Đạt updates when classification changes',page.locator('[data-bj02-accepted-preview]').input_value()=='8')
    check('detail no horizontal overflow',no_h_overflow(page))
    shot(page,'BJ02-detail-four-classifications-lot')
    page.locator('[data-bj02-action="save-line"]').click(); check('save returns SCR009','SCR-009' in page.locator('#current-screen-id').inner_text())

    # Duplicate Product+UOM stays in overview and offers open existing.
    q=page.locator('[data-bj02-overview-product-search]'); q.fill('Nobivac'); page.locator('[data-bj02-overview-product-option="P-NOB-DHPP"]').click(); page.locator('[data-bj02-overview-uom]').select_option('UOM-BOX')
    check('duplicate blocked on SCR009', 'Sản phẩm và đơn vị này đã có' in page.locator('#app-screen').inner_text())
    check('duplicate did not add second item',page.locator('button.receipt-line-card[data-bj02-line-id]').count()==1)
    check('duplicate offers open existing CTA',page.locator('[data-bj02-action="open-existing-overview-line"]').count()==1)
    page.locator('[data-bj02-action="open-existing-overview-line"]').click(); check('open existing goes to SCR084','SCR-084' in page.locator('#current-screen-id').inner_text())

    # Single UOM product is added directly and stays on overview.
    reset(page,'quick','SCR-009'); q=page.locator('[data-bj02-overview-product-search]'); q.fill('Găng tay'); page.locator('[data-bj02-overview-product-option="P-GLOVE-N"]').click()
    check('single-UOM product adds immediately on overview','SCR-009' in page.locator('#current-screen-id').inner_text() and page.locator('[data-bj02-line-id]').count()==1 and page.locator('[data-bj02-overview-uom]').count()==0)
    page.locator('[data-bj02-line-id]').click()
    check('non-LOT editor shows four classification fields immediately',labels(page)==['Đạt','Cách ly','Hỏng','Từ chối'],str(labels(page)))
    page.locator('[data-bj02-line-total]').fill('12'); check('non-LOT Đạt derives live',page.locator('[data-bj02-accepted-preview]').input_value()=='12')
    page.locator('[data-bj02-line-qty="damaged"]').fill('1'); check('non-LOT Đạt updates live',page.locator('[data-bj02-accepted-preview]').input_value()=='11')
    shot(page,'BJ02-detail-four-classifications-nonlot')
    page.locator('[data-bj02-action="save-line"]').click()
    check('completed Quick item returns to overview', 'SCR-009' in page.locator('#current-screen-id').inner_text())
    review_btn=page.locator('[data-next="SCR-010"]')
    check('Quick review becomes available after item is handled', review_btn.count()==1 and not review_btn.is_disabled())
    review_btn.click()
    check('Quick review still requires approval', 'Cần phê duyệt trước khi ghi nhận' in page.locator('#app-screen').inner_text() and page.locator('[data-action="submit"]').inner_text()=='Gửi phê duyệt')
    page.locator('[data-action="submit"]').click()
    check('maker submit stays in pending approval without stock execution', page.evaluate('stateByScreen["SCR-010"]')=='PENDING_APPROVAL' and 'Đã gửi phê duyệt' in page.locator('#app-screen').inner_text())
    page.evaluate('stateByScreen["SCR-011"]="READY"; navigate("SCR-011")')
    check('approver still has only Duyệt/Từ chối decisions', page.locator('[data-action="approve"]').count()==1 and page.locator('[data-action="open-reject"]').count()==1)
    page.locator('[data-action="approve"]').click()
    check('approval starts system-owned execution', 'SCR-012' in page.locator('#current-screen-id').inner_text() and page.evaluate('stateByScreen["SCR-012"]')=='PROCESSING')
    page.wait_for_timeout(1550)
    check('system execution reaches authoritative result state', page.evaluate('stateByScreen["SCR-012"]')=='VALUATION_PENDING_RESULT')
    page.evaluate('stateByScreen["SCR-013"]="PROCESSING_OR_UNKNOWN"; navigate("SCR-013")')
    check('UNKNOWN recovery keeps same operation and no blind retry CTA', 'Không cần tạo lần nhận mới' in page.locator('#app-screen').inner_text() and 'Thử lại' not in page.locator('#app-screen').inner_text())

    # Document flow uses same four-field rule without changing source line semantics.
    reset(page,'document','SCR-009'); page.locator('[data-bj02-line-id]').first.click()
    check('Document detail keeps source context','Còn chờ nhận' in page.locator('#app-screen').inner_text())
    check('Document LOT detail shows four classification fields',labels(page)==['Đạt','Cách ly','Hỏng','Từ chối'],str(labels(page)))
    check('Document has no reveal button','Có hàng cần phân loại' not in page.locator('#app-screen').inner_text())

    # Read-only Quick overview hides discovery but keeps data view.
    reset(page,'quick','SCR-009'); page.evaluate('addQuickOverviewLine("P-GLOVE-N","UOM-BOX"); stateByScreen["SCR-009"]="READ_ONLY"; renderAppScreen()')
    check('read-only overview hides Quick search',page.locator('[data-bj02-overview-product-search]').count()==0)
    check('read-only overview still shows existing item',page.locator('button.receipt-line-card[data-bj02-line-id]').count()==1)
    check('read-only has no mutation footer',page.locator('.app-actions button:not([disabled])').count()==0)

    browser.close()

passed=sum(ok for _,ok,_ in checks); failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# BJ-02 Runtime QA v0.3.4','',f'**Result: {passed}/{len(checks)} PASS**' if not failed else f'**Result: {passed}/{len(checks)} PASS · {len(failed)} FAIL**','', 'Chromium interaction QA at 402 × 874 for the two requested BJ02 refinements.','', '## Checks','']
for n,ok,d in checks: lines.append(f'- [{"x" if ok else " "}] {n}' + (f' — {d}' if d else ''))
lines += ['', '## Regression intent','', '- Keeps the existing BJ02 flow boundaries: Quick header → Hàng thực nhận → item detail → review.', '- Product/UOM discovery moved to Hàng thực nhận; item detail still owns actual quantity/LOT editing.', '- Four classifications are always visible while `Đạt` remains derived, preserving one authoritative input for total actual quantity.']
(OUT/'BJ02-RUNTIME-QA-v0.3.4.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
raise SystemExit(1 if failed else 0)
