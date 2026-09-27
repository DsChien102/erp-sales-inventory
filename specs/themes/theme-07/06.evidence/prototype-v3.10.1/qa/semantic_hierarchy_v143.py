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
def check(name,cond): checks.append((name,bool(cond)))
def tx(page): return page.locator('#app-screen').inner_text()
def fresh(page):
    page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(30)
def show(page,flow,screen,state='READY',setup=''):
    page.evaluate('''(x)=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;if(x.f==="UIF-02"&&x.s==="SCR-009"){flowMode="document";resetBj02Receipt("document");}if(x.setup){eval(x.setup);}render();}''',{'f':flow,'s':screen,'st':state,'setup':setup}); page.wait_for_timeout(25)
def no_overflow(page):
    g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); return g['sw']<=g['cw']+1

with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=b.new_page(viewport={'width':1400,'height':1050}); errors=[]; page.on('pageerror',lambda e:errors.append(str(e))); page.set_content(html,wait_until='load'); page.wait_for_timeout(50)

    # BJ01 benchmark: existing hierarchy intentionally unchanged.
    show(page,'UIF-01','SCR-003'); t=tx(page)
    check('BJ01 benchmark keeps Product identity separate from LOT section','Lô và hạn dùng' in t and page.locator('.bj01-lot-row').count()>0)
    check('BJ01 benchmark remains horizontally safe',no_overflow(page))

    # BJ02 selection affordance + LOT role label.
    fresh(page); show(page,'UIF-02','SCR-009',setup='flowMode="quick"; resetBj02Receipt("quick"); quickOverviewProductMenuOpen=true;')
    t=tx(page)
    check('BJ02 Product search row exposes action hint','Chọn' in t and page.locator('.product-search-select-hint').count()>0)
    check('BJ02 Product search rows remain full-row buttons',page.locator('[data-bj02-overview-product-option]').count()>0)
    check('BJ02 Product search keeps identity and UOM','NOB-DHPP' in t and 'hộp, lọ' in t)
    check('BJ02 Product search horizontal safety',no_overflow(page))
    check('Inventory Operations renderer no longer exposes ambiguous mục hàng vocabulary','mục hàng' not in app.lower())
    # Render a completed LOT line in SCR010 so the role label is proven in the Product viewport.
    fresh(page); show(page,'UIF-02','SCR-010',setup='flowMode="document"; resetBj02Receipt("document"); var l=bj02Lines[0]; l.status="COMPLETED"; l.lots=[{id:1,code:"ND2408",expiry:"30/11/2026",accepted:120,quarantine:0,damaged:0,rejected:0}]; render();'); t=tx(page)
    check('BJ02 LOT review visibly labels the raw code role','LÔ' in t and 'ND2408' in t and page.locator('.receipt-lot-review .io-object-kicker').count()==1)

    # BJ03 / SCR015: input owns its meaning.
    fresh(page); show(page,'UIF-03','SCR-015',setup='val03SelectedReceiptId="VAL03-R1";')
    check('BJ03 scope Product parent uses explicit role',page.locator('.val03-product-head .io-object-kicker').count()>=2)
    page.locator('[data-val03-slice="VAL03-S1"]').click(); page.wait_for_timeout(20); t=tx(page)
    check('BJ03 quantity control self-describes valuation task','Số lượng xác nhận giá' in t)
    check('BJ03 selected quantity no longer relies on old generic label','Xác nhận lần này' not in t)
    check('BJ03 scope footnote is concise','Không thay đổi số lượng đã nhận.' in t and 'Số lượng ở đây là phạm vi xác nhận giá trị' not in t)
    check('BJ03 scope remains horizontally safe',no_overflow(page))

    # BJ03 / SCR016: structured scope, quiet normal guidance.
    fresh(page); show(page,'UIF-03','SCR-016',setup='val03SelectedReceiptId="VAL03-R1"; var r=val03Current(); r.groups.forEach(g=>g.slices.forEach(s=>s.selected=false)); r.groups[0].slices[0].selected=true; r.groups[0].slices[0].selectedQty=50;')
    t=tx(page)
    check('BJ03 calculation has explicit Product role','SẢN PHẨM' in t)
    check('BJ03 calculation scope is structured, not one packed meta value',page.locator('.val03-scope-summary-row').count()==1 and 'PHẠM VI XÁC NHẬN GIÁ' in t)
    check('BJ03 calculation vocabulary uses dòng hàng','1 dòng hàng' in t)
    check('BJ03 normal late-cost guidance is quiet footnote','Chi phí mua phát sinh sau lần này' in t and 'Chi phí mua đến sau không sửa lần xác nhận này' not in t)
    check('BJ03 calculation normal state has no persistent banner',page.locator('.banner').count()==0)
    check('BJ03 calculation remains horizontally safe',no_overflow(page))

    # BJ03 / SCR017: amount label and grouped effects.
    fresh(page); show(page,'UIF-03','SCR-017',setup='val03SelectedReceiptId="VAL03-R1"; var r=val03Current(); r.groups.forEach(g=>g.slices.forEach(s=>s.selected=false)); r.groups[0].slices[0].selected=true; r.groups[0].slices[0].selectedQty=50; val03ReviewSourceVersion=r.sourceVersion;')
    t=tx(page)
    check('BJ03 review group amount has semantic label','Giá trị sẽ ghi' in t and page.locator('.val03-group-value').count()==1)
    check('BJ03 availability effect grouped under Product',page.locator('.val03-effect-group').count()==1 and 'Khả dụng +50 hộp' in t)
    check('BJ03 normal physical-state rule is quiet text','Xác nhận giá không thay đổi trạng thái vật lý' in t and page.locator('.banner').count()==0)
    check('BJ03 review remains horizontally safe',no_overflow(page))

    # BJ03 result: Product parent + slice child.
    fresh(page); show(page,'UIF-03','SCR-019','COMPLETED',setup='val03LastResult={receipt:"PN-TEST",supplier:"Minh Dũng",totalValue:4085000,groups:[{name:"Nobivac DHPPi",code:"SP-00142",uom:"hộp",value:4085000,slices:[{state:"Đủ điều kiện bán",qty:50},{state:"Cách ly",qty:4}]}],available:[],blocked:[]};')
    t=tx(page)
    check('BJ03 result groups by Product+UOM',page.locator('.val03-result-group').count()==1 and 'SẢN PHẨM' in t)
    check('BJ03 result labels group financial value','Giá trị đã ghi' in t)
    check('BJ03 result makes sellability effect explicit','Khả dụng +50 hộp' in t and '4 hộp · Cách ly giữ nguyên' in t)
    check('BJ03 result does not flatten Product into repeated meta row labels',page.locator('.val03-result-slice').count()==2)
    check('BJ03 result remains horizontally safe',no_overflow(page))

    # BJ04 benchmark unchanged.
    fresh(page); show(page,'UIF-04','SCR-021','FULL'); t=tx(page)
    check('BJ04 benchmark keeps explicit Cần/Đã giữ roles','Cần' in t and 'Đã giữ' in t)
    check('BJ04 benchmark remains horizontally safe',no_overflow(page))

    # BJ05: queue budget, stable vocabulary, partial action explanation.
    fresh(page); show(page,'UIF-05','SCR-025'); t=tx(page)
    check('BJ05 queue helper no longer carries item count','mặt hàng · Kho' not in t)
    check('BJ05 queue helper preserves customer and warehouse','Đại lý An Phú · Kho chính' in t)
    fresh(page); show(page,'UIF-05','SCR-026',setup='io05SelectedOrderId="SO-260827-21";'); t=tx(page)
    check('BJ05 progress vocabulary is dòng, not mục','dòng đã lấy đủ' in t and 'mục đã lấy đủ' not in t)
    check('BJ05 partial handover allowance is visible near enabled CTA','Có thể bàn giao phần đã lấy.' in t and not page.locator('[data-io05-action="review-handover"]').is_disabled())
    check('BJ05 partial allowance uses quiet note, not banner',page.locator('.io-footnote--decision').count()==1)
    fresh(page); show(page,'UIF-05','SCR-028','PARTIAL_ALLOWED',setup='io05SelectedOrderId="SO-260827-21"; io05ResetHandover();'); t=tx(page)
    check('BJ05 review summary vocabulary uses dòng hàng','dòng hàng trong lần này' in t and 'mục hàng trong lần này' not in t)
    check('BJ05 screens remain horizontally safe',no_overflow(page))

    # BJ06: LOT facts labeled separately, evidence role, grouped result.
    fresh(page); show(page,'UIF-06','SCR-031',setup='io06SelectedRequestId="RET-260827-03"; io06RefreshRequestState(io06CurrentRequest());'); t=tx(page)
    check('BJ06 return lines separate source LOT role','Lô giao' in t and page.locator('.io06-lot-facts').count()>=1)
    check('BJ06 source LOT is not packed into Product helper','SP-000184 · Lô giao' not in t)
    check('BJ06 progress vocabulary uses dòng','dòng đã kiểm' in t)
    # Force one verified wrong lot to show actual LOT as a separate labeled fact.
    page.evaluate('var l=io06CurrentLines()[0]; l.qty=2; l.actualLot="DH2509"; l.actualLotMode="OTHER"; l.verified=true; l.reasonCode="ACTUAL_DIFF"; l.evidenceFile="lot.jpg"; l.evidenceData=io06EvidenceSvg("DH2509"); render();'); page.wait_for_timeout(20); t=tx(page)
    check('BJ06 actual LOT is a separate labeled fact','Lô thực nhận' in t and 'DH2509' in t)
    fresh(page); show(page,'UIF-06','SCR-034','READY',setup='io06ApproverListMode=false; io06SelectedApprovalCaseId="EX-06-001";'); t=tx(page)
    check('BJ06 approval evidence has explicit role label','Ảnh nhãn lô thực nhận' in t)
    fresh(page); show(page,'UIF-06','SCR-035','COMPLETED',setup='io06SelectedRequestId="RET-260827-05"; var ls=io06CurrentLines(); ls[0].classification={sellable:3,quarantine:1,damaged:0,expired:0}; ls[1].classification={sellable:0,quarantine:0,damaged:5,expired:0}; io06CurrentRequest().classified=true;'); t=tx(page)
    check('BJ06 result groups Product parent and allocation child',page.locator('.io06-result-group').count()==2 and page.locator('.io06-result-allocation').count()==2)
    check('BJ06 result hides zero classification states','Hết hạn\n0' not in t and 'Cách ly\n0' not in t)
    check('BJ06 result shows only meaningful classification outcomes','Bán được' in t and 'Cách ly' in t and 'Hỏng' in t)
    check('BJ06 result uses dòng hàng vocabulary','Dòng hàng đã phân loại' in t and 'Mục hàng đã phân loại' not in t)
    check('BJ06 result remains horizontally safe',no_overflow(page))

    # BJ07: central Product-reported defect and downstream consistency.
    fresh(page); show(page,'UIF-07','SCR-037',setup='io07Selected="RTV-260827-02"; io07VerifySheetOpen=false;'); t=tx(page)
    check('BJ07 preparation has Product parent headers',page.locator('.io07-product-head .io-object-kicker').count()==3)
    check('BJ07 preparation has distinct child allocation rows',page.locator('.io07-allocation-row').count()==4)
    check('BJ07 LOT children explicitly say Lô cần kiểm',t.count('LÔ CẦN KIỂM')==3)
    check('BJ07 non-LOT child explicitly says Phần hàng cần kiểm','PHẦN HÀNG CẦN KIỂM' in t)
    check('BJ07 unverified rows expose light action hint, not badge spam',page.locator('.io-action-hint').count()==4 and 'Cần kiểm' not in t)
    check('BJ07 progress copy removes ambiguous mục','0/4 đã kiểm' in t and 'mục đã kiểm' not in t)
    check('BJ07 preparation remains horizontally safe',no_overflow(page))
    page.locator('[data-io07-allocation="RTV-A1"]').click(); page.wait_for_timeout(20); t=tx(page)
    check('BJ07 verification sheet action title is task-oriented','Kiểm hàng thực tế' in t)
    check('BJ07 verification sheet separates Product and target LOT','SẢN PHẨM' in t and 'LÔ CẦN KHỚP' in t)
    check('BJ07 LOT input states verification meaning','Quét hoặc nhập LOT để đối chiếu' in t)
    check('BJ07 LOT input explicitly denies source edit','không thay đổi LOT của yêu cầu' in t)
    check('BJ07 old edit-like label is gone','Mã LOT (không bắt buộc)' not in t)
    check('BJ07 sheet retains mismatch and confirm actions','Không khớp thực tế' in t and 'Xác nhận đúng hàng' in t)
    lot_input=page.locator('[data-io07-scan-lot]')
    lot_input.fill('WRONG-LOT'); page.wait_for_timeout(20); t=tx(page)
    check('BJ07 typed wrong LOT gives inline mismatch feedback','LOT không thuộc yêu cầu hiện tại' in t)
    check('BJ07 wrong typed LOT disables confirmation',page.locator('[data-io07-action="confirm-allocation"]').is_disabled())
    lot_input.fill('DH2507'); page.wait_for_timeout(20)
    check('BJ07 matching typed LOT re-enables confirmation',not page.locator('[data-io07-action="confirm-allocation"]').is_disabled())
    page.click('[data-io07-action="confirm-allocation"]'); page.wait_for_timeout(20)
    check('BJ07 confirm updates physical evidence and closes sheet',page.evaluate('io07FindAllocation("RTV-A1").allocation.verified') and page.locator('[data-io07-verify-backdrop]').count()==0)
    check('BJ07 verification does not mutate authoritative LOT',page.evaluate('io07FindAllocation("RTV-A1").allocation.lot')=='DH2507')
    fresh(page); show(page,'UIF-07','SCR-039',setup='io07Selected="RTV-260827-02"; io07Allocations().forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;}); io07Current().reviewSourceVersion=io07Current().sourceVersion;'); t=tx(page)
    check('BJ07 final review groups Product parent and allocations',page.locator('.io07-review-group').count()==3 and page.locator('.io07-review-line').count()==4)
    check('BJ07 final review removes ambiguous count meta','mặt hàng ·' not in t and ' phần' not in page.locator('.io-section-title').first.inner_text())
    check('BJ07 final review still preserves mixed UOM','4 hộp' in t and '6 lọ' in t)
    fresh(page); show(page,'UIF-07','SCR-041','COMPLETED',setup='io07LastResult={requestId:"RTV-260827-02",supplier:"Minh Dũng",lines:[{name:"Nobivac DHPPi",code:"SP-00142",uom:"hộp",lot:"DH2507",expiry:"30/11/2026",qty:4},{name:"Nobivac DHPPi",code:"SP-00142",uom:"hộp",lot:"DH2511",expiry:"31/03/2027",qty:2},{name:"Nobivac DHPPi",code:"SP-00142",uom:"lọ",lot:"DH2507",expiry:"30/11/2026",qty:6}]};'); t=tx(page)
    check('BJ07 result groups same Product+UOM instead of flattening',page.locator('.io07-result-group').count()==2 and page.locator('.io07-result-line').count()==3)
    check('BJ07 result explicitly labels LOT children',t.count('LÔ')>=3)
    check('BJ07 result does not aggregate mixed UOM','4 hộp' in t and '2 hộp' in t and '6 lọ' in t)
    check('BJ07 result remains horizontally safe',no_overflow(page))

    check('No page JavaScript errors',not errors)
    b.close()

passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Semantic Hierarchy QA v1.4.3','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',
'Lens: 2-second semantic scan — user should identify object role, parent/child hierarchy, state and expected action without decoding helper prose.','',
'## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines += ['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'SEMANTIC-HIERARCHY-QA-v1.4.3.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
