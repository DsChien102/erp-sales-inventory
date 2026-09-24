from pathlib import Path
from PIL import Image, ImageDraw
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'screenshots-v1.4.0'; SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf8')
css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8')
data=(ROOT/'workbench-data.js').read_text(encoding='utf8')
app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]
def check(name,cond): checks.append((name,bool(cond)))
def text(page): return page.locator('#app-screen').inner_text()
def shot(page,name): page.locator('#device-preview').screenshot(path=str(SHOTS/f'{name}.png'))
def fresh(page):
    page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(70)
    page.evaluate('activeFlowId="UIF-03";activeScreenId="SCR-014";stateByScreen["SCR-014"]="READY";render();')
def show(page,scr,state='READY'):
    page.evaluate('(x)=>{activeFlowId="UIF-03";activeScreenId=x.scr;stateByScreen[x.scr]=x.state;render();}',{'scr':scr,'state':state})
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=b.new_page(viewport={'width':1400,'height':1100}); errors=[]; page.on('pageerror',lambda e: errors.append(str(e))); fresh(page)
    # SCR014 worklist/search/filter
    t=text(page)
    check('Queue title is business-facing','Chờ xác nhận giá trị' in t)
    check('Queue uses receipt task summaries','2 mặt hàng · 3 phần chờ giá' in t)
    check('Queue does not use old 118 hộp aggregate','118 hộp' not in t)
    chips=page.locator('[data-val03-filter]')
    check('Queue has 3 filters',[chips.nth(i).inner_text() for i in range(chips.count())]==['Tất cả','Có thể xử lý','Thiếu căn cứ'])
    page.click('[data-val03-filter="MISSING"]'); check('Missing filter isolates missing evidence receipt','PN-260816-02' in text(page) and 'PN-260816-04' not in text(page))
    page.click('[data-val03-filter="ALL"]'); q=page.locator('[data-val03-search]'); q.fill('khong-co'); check('Search no-result is explicit','Không tìm thấy phiếu phù hợp' in text(page)); q.fill('')
    shot(page,'BJ03-SCR014-worklist')
    # Missing evidence receipt cannot select slice.
    page.click('[data-val03-receipt="VAL03-R2"]');
    check('Missing evidence banner is shown','Có phần chưa đủ căn cứ' in text(page))
    check('Missing evidence slice is disabled',page.locator('[data-val03-slice="VAL03-S4"]').is_disabled())
    check('No price input on scope screen',page.locator('#app-screen input[type="text"]').count()==0)
    # Return queue and select main receipt.
    fresh(page); page.click('[data-val03-receipt="VAL03-R1"]');
    check('Scope groups same receipt by Product+UOM','SP-00142 · hộp' in text(page) and 'SP-00088 · chai' in text(page))
    check('Scope distinguishes sellable and quarantine','Đủ điều kiện bán' in text(page) and 'Cách ly' in text(page))
    check('Calculation CTA disabled with no scope',page.locator('[data-val03-action="open-calculation"]').is_disabled())
    page.click('[data-val03-slice="VAL03-S1"]'); page.locator('[data-val03-qty="VAL03-S1"]').fill('50')
    page.click('[data-val03-slice="VAL03-S2"]'); page.click('[data-val03-slice="VAL03-S3"]')
    check('Partial selected quantity retained in model',page.evaluate('val03Receipts[0].groups[0].slices[0].selectedQty')==50)
    check('Scope CTA enables after selection',not page.locator('[data-val03-action="open-calculation"]').is_disabled())
    shot(page,'BJ03-SCR015-scope')
    page.locator('.app-content').evaluate('(e)=>e.scrollTop=e.scrollHeight')
    reach=page.evaluate('()=>{const f=document.querySelector(".io-footnote").getBoundingClientRect();const a=document.querySelector(".app-actions").getBoundingClientRect();return f.bottom<=a.top+1;}')
    check('Scope content remains reachable above sticky footer',reach)
    page.click('[data-val03-action="open-calculation"]'); ct=text(page)
    check('Authoritative price is not rendered as editable money input',page.locator('#app-screen input[type="number"]').count()==0 and page.locator('#app-screen input[type="text"]').count()==0)
    check('Ready source shows provenance read-only','Đơn mua PO-2608-041 · v3' in ct)
    check('Calculation shows discount line','Chiết khấu dòng' in ct and 'Phân bổ chiết khấu phiếu' in ct and 'Chi phí mua đã có' in ct)
    check('Conflict warning is explicit','Nguồn giá đang mâu thuẫn' in ct)
    src=page.locator('[data-val03-source="VAL03-G2"]'); check('Conflict source has two candidates',src.count()==2)
    check('Conflict has no preselection',page.locator('[data-val03-source="VAL03-G2"][aria-pressed="true"]').count()==0)
    check('Review CTA disabled before conflict resolution',page.locator('[data-val03-action="open-review"]').is_disabled())
    shot(page,'BJ03-SCR016-conflict')
    page.click('[data-val03-source="VAL03-G2"][data-val03-source-id="SUP"]')
    check('Reason is required after explicit source selection',page.locator('[data-val03-reason="VAL03-G2"]').count()==1 and page.locator('[data-val03-action="open-review"]').is_disabled())
    page.locator('[data-val03-reason="VAL03-G2"]').fill('Xác nhận NCC ngày 02/09 là căn cứ mới nhất')
    check('Review CTA enables after source+reason',not page.locator('[data-val03-action="open-review"]').is_disabled())
    # review
    page.click('[data-val03-action="open-review"]'); rt=text(page)
    check('Review has one direct valuation commit CTA',page.locator('[data-val03-action="confirm-value"]').count()==1)
    check('Late cost action is not visible in UIF03','Ghi chi phí mua bổ sung' not in rt)
    check('No second approval copy in UIF03','phê duyệt' not in rt.lower())
    check('Mixed UOM quantities stay separate','50 hộp' in rt and '24 chai' in rt)
    check('Quarantine availability is explicitly not released','4 hộp vẫn cách ly' in rt.lower())
    check('Review separates availability semantics','Tác động sau xác nhận' in rt and 'Xác nhận giá trị không đổi trạng thái vật lý' in rt)
    shot(page,'BJ03-SCR017-review')
    # source stale after review; only affected source resolution resets.
    before_reason=page.evaluate('val03Receipts[0].groups[1].reason')
    page.evaluate('val03ApplySourceUpdate("VAL03-G1",84000)')
    check('Source update increments source version',page.evaluate('val03Receipts[0].sourceVersion')==4)
    check('Affected group source selection reset',page.evaluate('val03Receipts[0].groups[0].selectedSource')=='')
    check('Unaffected conflict group reason preserved',page.evaluate('val03Receipts[0].groups[1].reason')==before_reason)
    page.click('[data-val03-action="confirm-value"]'); st=text(page)
    check('Stale commit is blocked','Căn cứ giá đã thay đổi' in st)
    check('Stale review shows business delta before reconciliation','Nobivac DHPPi' in st and '83.000 đ/hộp' in st and '84.000 đ/hộp' in st)
    check('Stale review removes commit CTA',page.locator('[data-val03-action="confirm-value"]').count()==0)
    check('Stale review offers safe reconciliation',page.locator('[data-val03-action="back-to-calculation"]').count()==1)
    shot(page,'BJ03-SCR017-source-changed')
    # Fresh flow for successful partial commit.
    fresh(page); page.click('[data-val03-receipt="VAL03-R1"]'); page.click('[data-val03-slice="VAL03-S1"]'); page.locator('[data-val03-qty="VAL03-S1"]').fill('50'); page.click('[data-val03-slice="VAL03-S2"]'); page.click('[data-val03-action="open-calculation"]'); page.click('[data-val03-action="open-review"]')
    pending_before=page.evaluate('val03Receipts[0].groups[0].slices[0].pendingQty')
    page.click('[data-val03-action="confirm-value"]'); done=text(page)
    check('Completed result is explicit','Đã xác nhận giá trị' in done)
    check('Commit decrements exact selected slice only',page.evaluate('val03Receipts[0].groups[0].slices[0].pendingQty')==pending_before-50)
    check('Unselected product slice remains pending',page.evaluate('val03Receipts[0].groups[1].slices[0].pendingQty')==24)
    check('Result distinguishes sellable and quarantine effects','Khả dụng +50 hộp' in done and '4 hộp vẫn cách ly' in done.lower())
    check('Completed partial result offers continue remaining',page.locator('[data-val03-action="continue-remaining"]').count()==1)
    check('Completed result has no Back to consumed commit',page.locator('[data-back]').count()==0)
    shot(page,'BJ03-SCR019-completed')
    page.click('[data-val03-action="continue-remaining"]'); check('Remaining scope screen shows only pending values','46 hộp đang chờ giá' in text(page))
    # FX source fixture
    fresh(page); page.click('[data-val03-receipt="VAL03-R3"]'); page.click('[data-val03-slice="VAL03-S5"]'); page.click('[data-val03-action="open-calculation"]'); fx=text(page)
    check('FX fixture shows foreign unit price',('4,1 USD/lọ' in fx or '4.1 USD/lọ' in fx))
    check('FX fixture shows accounting provenance','Tỷ giá Kế toán 24.450 VND/USD · v7' in fx)
    shot(page,'BJ03-SCR016-fx')
    page.locator('.app-content').evaluate('(e)=>e.scrollTop=e.scrollHeight')
    fxreach=page.evaluate('()=>{const b=[...document.querySelectorAll(".callout")].at(-1)?.getBoundingClientRect();const a=document.querySelector(".app-actions").getBoundingClientRect();return !!b&&b.bottom<=a.top+1;}')
    check('FX guidance remains reachable above sticky footer',fxreach)
    # Finality matrix
    fresh(page)
    for state,needle in [('UNKNOWN','Đang xác minh kết quả'),('REJECTED_EXECUTION','Chưa ghi nhận giá trị'),('PERMISSION_DENIED','Không có quyền thực hiện')]:
        show(page,'SCR-019',state); tx=text(page); check(f'{state} distinct result',needle in tx); check(f'{state} has no Back',page.locator('[data-back]').count()==0); check(f'{state} has no commit retry CTA',page.locator('[data-val03-action="confirm-value"]').count()==0)
    show(page,'SCR-019','UNKNOWN'); check('UNKNOWN explicitly forbids resubmission','Không gửi lại xác nhận' in text(page)); check('UNKNOWN hides technical operation id','VAL-260903-' not in text(page)); shot(page,'BJ03-SCR019-unknown')
    show(page,'SCR-019','REJECTED_EXECUTION'); check('Rejected result offers provenance reconciliation',page.locator('[data-val03-action="back-to-calculation"]').count()==1); page.click('[data-val03-action="back-to-calculation"]'); check('Rejected result returns to calculation, matching flow contract',page.evaluate('activeScreenId')=='SCR-016')
    # Permission masking on direct finance screen/review.
    show(page,'SCR-016','PERMISSION_DENIED'); check('Permission denied omits source prices','83.000' not in text(page) and '120.000' not in text(page))
    show(page,'SCR-017','PERMISSION_DENIED'); check('Review permission denied omits financial total','Tổng giá trị sẽ ghi' not in text(page))
    # UIF13 shared renderer regression: custom renderer must fall back.
    page.evaluate('activeFlowId="UIF-13";activeScreenId="SCR-017";stateByScreen["SCR-017"]="READY";render();')
    u13=text(page); check('UIF13 shared review remains on baseline generic renderer','Giá trị dự kiến' in u13 and 'Phạm vi xác nhận' in u13 and 'xác nhận giá trị hoặc chi phí mua bổ sung' in u13); check('UIF13 does not render UIF03 custom source-slice review','Tác động sau xác nhận' not in u13)
    # 402x874 geometry and errors.
    fresh(page); g=page.locator('#device-preview').evaluate('(e)=>({w:e.getBoundingClientRect().width,h:e.getBoundingClientRect().height})'); check('Product viewport is 402x874',round(g['w'])==402 and round(g['h'])==874)
    for scr,state in [('SCR-014','READY'),('SCR-015','READY'),('SCR-016','READY'),('SCR-017','READY'),('SCR-019','UNKNOWN')]:
        show(page,scr,state); ov=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); check(f'{scr} no horizontal overflow',ov['sw']<=ov['cw']+1)
    check('No page JavaScript errors',not errors)
    b.close()
# contact sheet from selected screenshots
names=['BJ03-SCR014-worklist','BJ03-SCR015-scope','BJ03-SCR016-conflict','BJ03-SCR017-review','BJ03-SCR017-source-changed','BJ03-SCR019-completed','BJ03-SCR016-fx','BJ03-SCR019-unknown']
imgs=[Image.open(SHOTS/f'{n}.png').convert('RGB') for n in names]
thumb_w=402; label_h=34; cell_h=874+label_h; sheet=Image.new('RGB',(thumb_w*4,cell_h*2),'white'); draw=ImageDraw.Draw(sheet)
for i,(n,img) in enumerate(zip(names,imgs)):
    x=(i%4)*thumb_w; y=(i//4)*cell_h; sheet.paste(img.resize((thumb_w,874)),(x,y)); draw.text((x+8,y+878),n,fill='black')
sheet.save(SHOTS/'BJ03-CONTACT-SHEET-v1.4.0.png')
passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# BJ03 End-user / State QA v1.4.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Coverage: valuation worklist/search/filter; identified quantity slice and partial confirmation; evidence missing; provenance-first calculation; source conflict selection/reason; FX provenance; value vs sellability; source-version stale guard; exact partial commit; result finality; permission masking; UIF13 shared-screen fallback; 402×874 geometry.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines += ['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'BJ03-END-USER-QA-v1.4.0.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
