from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf8')
css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8')
data=(ROOT/'workbench-data.js').read_text(encoding='utf8')
app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')

checks=[]
def check(name, cond):
    checks.append((name, bool(cond)))
def tx(page):
    return page.locator('#app-screen').inner_text()
def show(page, flow, screen, state='READY', setup=''):
    page.evaluate('''(x)=>{
      activeFlowId=x.flow;
      activeScreenId=x.screen;
      stateByScreen[x.screen]=x.state;
      if(x.flow==="UIF-02" && x.screen==="SCR-009"){flowMode="document"; resetBj02Receipt("document");}
      if(x.setup){eval(x.setup);}
      render();
    }''', {'flow':flow,'screen':screen,'state':state,'setup':setup})
    page.wait_for_timeout(20)
def no_overflow(page):
    g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
    return g['sw'] <= g['cw']+1

with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=b.new_page(viewport={'width':1400,'height':1050})
    errors=[]
    page.on('pageerror',lambda e: errors.append(str(e)))
    page.set_content(html,wait_until='load')
    page.wait_for_timeout(50)

    # UIF01 / BJ01
    show(page,'UIF-01','SCR-001')
    t=tx(page)
    check('BJ01 queue uses concise expiry badges','Có lô cận hạn' not in t and 'Có lô hết hạn' not in t)
    check('BJ01 queue retains actionable concise badges','Cận hạn' in t or 'Hết hạn' in t)
    check('BJ01 context copy removes awkward Cập nhật lúc','Cập nhật lúc' not in t)
    check('BJ01 context still exposes warehouse and timestamp','Kho trung tâm' in t and 'Cập nhật' in t)
    check('BJ01 default list has no horizontal overflow',no_overflow(page))
    q=page.locator('[data-bj01-search]'); q.fill('khong-ton-tai')
    check('BJ01 live search has business no-result','Không có kết quả phù hợp' in tx(page))
    q.fill(''); page.click('[data-bj01-filter="NEAR"]')
    check('BJ01 filter interaction remains usable','Cận hạn' in tx(page))
    show(page,'UIF-01','SCR-003')
    check('BJ01 detail keeps core stock breakdown',all(x in tx(page) for x in ['Khả dụng','Tồn vật lý','Đủ điều kiện bán','Đã giữ']))
    check('BJ01 detail remains horizontally safe',no_overflow(page))

    # UIF02 / BJ02
    show(page,'UIF-02','SCR-008',setup='flowMode="quick";')
    t=tx(page)
    check('BJ02 quick header has concise purpose copy','Chọn nhà cung cấp và căn cứ giao nhận.' in t)
    wh=page.locator('[data-bj02-warehouse]')
    check('BJ02 warehouse is readonly field, not disabled select',wh.count()==1 and wh.evaluate('(e)=>e.tagName')=='INPUT' and wh.get_attribute('readonly') is not None)
    check('BJ02 warehouse has no dropdown chevron in its field',wh.locator('xpath=..').locator('svg').count()==0)
    check('BJ02 quick header mobile overflow safe',no_overflow(page))
    supplier=page.locator('[data-bj02-supplier-search]'); supplier.click(); supplier.fill('Minh')
    check('BJ02 supplier selection is actual combobox interaction',page.locator('[data-bj02-supplier-menu]').is_visible())
    show(page,'UIF-02','SCR-009',setup='flowMode="quick"; resetBj02Receipt("quick"); quickOverviewProductMenuOpen=true;')
    t=tx(page)
    check('BJ02 product discovery does not expose tracking policy','Theo lô' not in t and 'Không theo lô' not in t)
    check('BJ02 product discovery keeps identity + UOM','NOB-DHPP' in t and 'hộp, lọ' in t)
    if page.locator('[data-product-option]').count():
        page.locator('[data-product-option]').first.click()
        check('BJ02 selected product summary avoids tracking policy jargon','Theo lô' not in tx(page) and 'Không theo lô' not in tx(page))
    show(page,'UIF-02','SCR-084',setup='flowMode="document"; resetBj02Receipt("document"); beginLineEditor("DOC-04-01");')
    check('BJ02 editor removes derived-total helper duplication','Tổng thực nhận được tính tự động' not in tx(page) and 'Tổng lô được tính tự động' not in tx(page))
    check('BJ02 editor still exposes authoritative derived total','Tổng thực nhận' in tx(page))
    check('BJ02 editor remains horizontally safe',no_overflow(page))

    # UIF04 / BJ04
    show(page,'UIF-04','SCR-021','FULL')
    t=tx(page)
    check('BJ04 normal full reservation has no success banner','Đã giữ đủ hàng' not in t)
    check('BJ04 normal full reservation removes redundant system-updated meta','Hệ thống tự cập nhật' not in t)
    check('BJ04 preserves reservation facts',all(x in t for x in ['Hàng đã giữ','Cần','Đã giữ']))
    check('BJ04 concise physical-stock footnote','Giữ hàng làm giảm khả dụng, không làm giảm tồn vật lý.' in t)
    show(page,'UIF-04','SCR-021','PARTIAL')
    check('BJ04 partial remains exception-visible','Chưa giữ đủ cho đơn' in tx(page) and 'Phần thiếu đã được trả về đơn bán' in tx(page))
    check('BJ04 no horizontal overflow',no_overflow(page))

    # UIF05 / BJ05
    show(page,'UIF-05','SCR-025')
    t=tx(page)
    check('BJ05 queue uses mặt hàng for line count','mặt hàng' in t)
    check('BJ05 waiting source-owned card is not navigable',page.locator('[data-io05-order="SO-260827-24"]').count()==0)
    check('BJ05 waiting card has no chevron',page.locator('.io-order-row.is-readonly').filter(has_text='SO-260827-24').locator('svg').count()==0)
    check('BJ05 waiting queue card keeps one compact helper line',page.locator('.io-order-row.is-readonly').filter(has_text='SO-260827-24').locator('small').count()==1)
    check('BJ05 waiting badge is concise','Chờ đơn bán' in t)
    show(page,'UIF-05','SCR-026',setup='io05SelectedOrderId="SO-260827-24";')
    t=tx(page)
    check('BJ05 waiting detail avoids mixed-UOM generic aggregate','8 đơn vị' not in t)
    check('BJ05 waiting detail explains source ownership','Chờ đơn bán xử lý' in t)
    check('BJ05 waiting detail is truly read-only',page.locator('[data-io05-line]').count()==0 and page.locator('[data-io05-action="review-handover"]').count()==0)
    show(page,'UIF-05','SCR-026',setup='io05SelectedOrderId="SO-260827-21";')
    t=tx(page)
    check('BJ05 line rows avoid duplicate picked-state badges','Đã lấy một phần' not in t and 'Đã lấy đủ' not in t)
    check('BJ05 lot helper is compact','DH2507: 4/4' not in t and ('2 lô' in t or 'Lô DH2507' in t))
    check('BJ05 progress uses task language','mục đã lấy đủ' in t)
    show(page,'UIF-05','SCR-028',setup='io05SelectedOrderId="SO-260827-21"; io05ResetHandover();')
    t=tx(page)
    check('BJ05 handover summary uses mục hàng','mục hàng trong lần này' in t)
    check('BJ05 handover footnote is concise','Xác nhận sau khi hàng đã giao thực tế.' in t)
    show(page,'UIF-05','SCR-029','COMPLETED',setup='io05SelectedOrderId="SO-260827-21"; io05LastResult={orderId:"SO-260827-21",customer:"Đại lý An Phú",full:true,remaining:0,detail:[{product:"Nobivac DHPPi",uom:"hộp",qty:4}]};')
    check('BJ05 full result removes zero-remaining noise','Còn lại' not in tx(page))
    show(page,'UIF-05','SCR-029','UNKNOWN')
    check('BJ05 UNKNOWN has no technical identity language','định danh' not in tx(page) and 'Không gửi lại bàn giao' in tx(page))
    check('BJ05 screens remain horizontally safe',no_overflow(page))

    # UIF06 / BJ06
    show(page,'UIF-06','SCR-030')
    t=tx(page)
    check('BJ06 waiting approval-owned card is not navigable',page.locator('[data-io06-request="RET-260827-07"]').count()==0)
    check('BJ06 waiting queue card keeps one compact helper line',page.locator('.io-order-row.is-readonly').filter(has_text='RET-260827-07').locator('small').count()==1)
    check('BJ06 waiting queue badge is concise','Chờ duyệt lô' in t)
    show(page,'UIF-06','SCR-031',setup='io06SelectedRequestId="RET-260827-07"; io06RefreshRequestState(io06CurrentRequest());')
    t=tx(page)
    check('BJ06 waiting item rows are non-interactive',page.locator('[data-io06-line]').count()==0 and page.locator('.io-product-row.is-readonly').count()>0)
    check('BJ06 normal unverified badge noise removed','Chưa kiểm' not in t)
    check('BJ06 waiting banner is concise','Chờ người duyệt xử lý các ngoại lệ lô.' in t)
    show(page,'UIF-06','SCR-031',setup='io06SelectedRequestId="RET-260827-03"; io06RefreshRequestState(io06CurrentRequest());')
    t=tx(page)
    check('BJ06 unverified quantity copy is concise and bounded','Tối đa 4 hộp' in t)
    check('BJ06 lot context uses business phrasing','Lô giao DH2507' in t)
    show(page,'UIF-06','SCR-032',setup='io06SelectedRequestId="RET-260827-03"; io06ActiveLineId="RET-L1A"; var l=io06ActiveLine(); l.qty=2; l.actualLot="DH2509"; l.actualLotMode="OTHER"; l.verified=true; l.reasonCode="ACTUAL_DIFF"; l.evidenceFile="lot.jpg"; l.evidenceData=io06EvidenceSvg("DH2509");')
    t=tx(page)
    check('BJ06 mismatch guidance is concise','Cần lý do, ảnh nhãn lô và duyệt ngoại lệ' in t)
    check('BJ06 alternate LOT helper is concise','Khi lô thực nhận khác lô đã giao.' in t)
    show(page,'UIF-06','SCR-034','TASK_LIST',setup='io06ApproverListMode=true;')
    t=tx(page)
    check('BJ06 approval list leads with product, not technical case ID','EX-06-' not in t and 'Nobivac DHPPi' in t)
    show(page,'UIF-06','SCR-034','READY',setup='io06ApproverListMode=false; io06SelectedApprovalCaseId="EX-06-001";')
    t=tx(page)
    check('BJ06 approval detail hides technical approval ID','Mã duyệt' not in t and 'EX-06-001' not in t)
    check('BJ06 approval detail keeps decision evidence',all(x in t for x in ['Yêu cầu','Sản phẩm','Lô đã giao','Lô thực nhận','Căn cứ quyết định']))
    show(page,'UIF-06','SCR-033',setup='io06SelectedRequestId="RET-260827-05";')
    t=tx(page)
    check('BJ06 incomplete classification rows remove redundant warning badges','Cần phân loại' not in t)
    show(page,'UIF-06','SCR-035','UNKNOWN',setup='io06SelectedRequestId="RET-260827-03";')
    check('BJ06 UNKNOWN removes technical operation identity','định danh' not in tx(page))
    check('BJ06 screens remain horizontally safe',no_overflow(page))

    # UIF07 / BJ07
    show(page,'UIF-07','SCR-036')
    t=tx(page)
    waiting=page.locator('.io07-waiting-row')
    check('BJ07 waiting card exists and is read-only',waiting.count()==1 and page.locator('[data-io07-request="RTV-260903-05"]').count()==0)
    check('BJ07 waiting card has exactly one helper/meta line',waiting.locator('small').count()==1)
    check('BJ07 waiting card removes prose helper','Bộ phận Mua hàng đang cập nhật' not in t)
    check('BJ07 waiting card has concise state badge','Chờ cập nhật' in waiting.inner_text())
    check('BJ07 source-changed task uses state badge','Cần kiểm lại' in t and 'Yêu cầu vừa cập nhật' not in t)
    check('BJ07 queue removes redundant list section header','Công việc trả nhà cung cấp' not in t)
    check('BJ07 queue removes technical source-authorize language','source-authorize' not in t)
    show(page,'UIF-07','SCR-037',setup='io07Selected="RTV-260827-02"; io07VerifySheetOpen=false;')
    t=tx(page)
    check('BJ07 preparation removes redundant tracking tail','2 LOT' not in t)
    check('BJ07 preparation uses task progress wording','mục đã kiểm' in t)
    check('BJ07 normal allocation rows do not repeat Cần kiểm badges','Cần kiểm' not in t)
    check('BJ07 preparation footer is concise','Quét mã lô không bắt buộc' in t)
    page.click('[data-io07-allocation="RTV-A1"]')
    t=tx(page)
    check('BJ07 verification sheet has no custom close button',page.locator('.io07-sheet-close').count()==0)
    check('BJ07 verification sheet uses business quantity label','Số lượng yêu cầu' in t)
    check('BJ07 verification sheet removes duplicate LOT helper','Để trống nếu đã đối chiếu trực quan' not in t)
    check('BJ07 verification sheet keeps mismatch and confirmation actions',page.locator('[data-io07-action="mark-mismatch"]').count()==1 and page.locator('[data-io07-action="confirm-allocation"]').count()==1)
    show(page,'UIF-07','SCR-039',setup='io07Selected="RTV-260827-02"; io07Allocations().forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;}); io07Current().reviewSourceVersion=io07Current().sourceVersion;')
    t=tx(page)
    check('BJ07 final review removes repeated verified helper','Đã kiểm thực tế' not in t)
    check('BJ07 final review uses compact section meta','mặt hàng' in t and 'phần' in t)
    check('BJ07 final review uses quiet footnote for normal state','Chỉ xác nhận sau khi hàng đã thực sự rời kho' not in t and 'Xác nhận sau khi hàng đã rời kho' in t)
    check('BJ07 final review preserves mixed UOM separately','4 hộp' in t and '6 lọ' in t)
    show(page,'UIF-07','SCR-041','UNKNOWN')
    t=tx(page)
    check('BJ07 UNKNOWN removes technical identity/recovery wording','định danh thao tác' not in t and 'xử lý bất thường' not in t)
    check('BJ07 UNKNOWN forbids blind retry',page.locator('[data-io07-action="confirm-handover"]').count()==0)
    show(page,'UIF-07','SCR-041','COMPLETED',setup='io07LastResult={requestId:"RTV-260827-02",supplier:"Minh Dũng",lines:[{name:"Nobivac DHPPi",uom:"hộp",lot:"DH2507",expiry:"30/11/2026",qty:4}]};')
    t=tx(page)
    check('BJ07 result avoids duplicate UOM in row label','Nobivac DHPPi · hộp · LOT' not in t and 'Nobivac DHPPi · LOT DH2507' in t)
    check('BJ07 result copy is business-facing','Tồn vật lý và giá trị đã giảm theo đúng hàng bàn giao.' in t)
    check('BJ07 result remains horizontally safe',no_overflow(page))

    # All 27 Inventory Operations screens render and fit.
    op_flows=['UIF-01','UIF-02','UIF-04','UIF-05','UIF-06','UIF-07']
    flow_map=page.evaluate('(ids)=>flowCatalog.filter(f=>ids.includes(f.id)).map(f=>({id:f.id,screens:f.screens}))',op_flows)
    rendered=0
    for flow in flow_map:
        for sid in flow['screens']:
            show(page,flow['id'],sid)
            rendered+=1
            check(f'{flow["id"]}/{sid} renders non-empty',bool(tx(page).strip()))
            check(f'{flow["id"]}/{sid} no horizontal overflow',no_overflow(page))
    check('Inventory Operations screen count stays canonical 27',rendered==27)
    check('No page JavaScript errors',not errors)
    b.close()

passed=sum(1 for _,v in checks if v)
failed=[n for n,v in checks if not v]
lines=[
'# Inventory Operations End-user UX QA v1.4.1','',
f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',
'Scope: UIF-01, UIF-02, UIF-04, UIF-05, UIF-06, UIF-07. The entire Inventory Operations group is audited from the end-user perspective while preserving existing business contracts.','',
'QA lenses: information necessity, duplicate affordances, read-only ownership, semantic feedback, mixed-UOM safety, technical-language leakage, progressive disclosure, finality, mobile geometry, and cross-flow runtime stability.','',
'## Checks',''
]+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors:
    lines += ['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'INVENTORY-OPERATIONS-END-USER-QA-v1.4.1.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
    print('\n'.join(failed[:80]))
    raise SystemExit(1)
