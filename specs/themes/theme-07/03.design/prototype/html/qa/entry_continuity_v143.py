from pathlib import Path
import json
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf8'); css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8'); data=(ROOT/'workbench-data.js').read_text(encoding='utf8'); app0=(ROOT/'app.js').read_text(encoding='utf8')
checks=[]
def ck(n,v): checks.append((n,bool(v)))
def html_for(q):
    app=app0.replace('window.location.search',json.dumps(q))
    return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
def load(page,q): page.goto('about:blank'); page.set_content(html_for(q),wait_until='load'); page.wait_for_timeout(35)
def txt(page): return page.locator('#app-screen').inner_text()
def no_overflow(page):
    g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); return g['sw']<=g['cw']+1
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':1200,'height':1000}); errors=[]; page.on('pageerror',lambda e:errors.append(str(e)))
    cases=[
      ('BJ01 Product deep link','?uif=UIF-01&entry=product-context','SCR-003',['Chi tiết tồn kho','Từ ngữ cảnh sản phẩm']),
      ('BJ02 module','?uif=UIF-02','SCR-006',['Chọn cách nhận hàng','Nhận theo chứng từ hoặc nhập hàng nhanh']),
      ('BJ02 Purchase deep link','?uif=UIF-02&entry=document-context','SCR-009',['Hàng thực nhận','Từ chứng từ']),
      ('BJ02 approver task','?uif=UIF-02&entry=approver','SCR-011',['Phê duyệt yêu cầu nhận hàng','Việc dành cho người phê duyệt']),
      ('BJ03 module','?uif=UIF-03','SCR-014',['Hàng chờ xác nhận giá nhập','Từ các phiếu nhận hàng đã ghi nhận']),
      ('BJ03 receipt task','?uif=UIF-03&entry=receipt-task','SCR-015',['Chọn phạm vi xác nhận','Việc xác nhận giá nhập từ phiếu nhận']),
      ('BJ04 contextual only','?uif=UIF-04&entry=order-context','SCR-021',['Giữ hàng theo đơn','Từ đơn','Chỉ xem']),
      ('BJ05 module','?uif=UIF-05','SCR-025',['Đơn cần lấy hàng','Từ đơn bán đã sẵn sàng xuất kho']),
      ('BJ05 order task','?uif=UIF-05&entry=order-task','SCR-026',['Hàng cần lấy','Việc lấy hàng từ đơn bán đã được giao cho Kho']),
      ('BJ06 maker module','?uif=UIF-06','SCR-030',['Hàng khách trả','Yêu cầu trả đã đủ điều kiện tiếp nhận']),
      ('BJ06 maker request','?uif=UIF-06&entry=return-task','SCR-031',['Hàng khách trả','Việc tiếp nhận hàng trả đã được giao cho Kho']),
      ('BJ06 approver task','?uif=UIF-06&entry=approver','SCR-034',['Việc dành cho người phê duyệt']),
      ('BJ07 module','?uif=UIF-07','SCR-036',['Hàng chờ trả nhà cung cấp','Yêu cầu do Mua hàng chuyển sang Kho']),
      ('BJ07 supplier task','?uif=UIF-07&entry=return-task','SCR-037',['Chuẩn bị hàng trả','Việc trả hàng đã được Mua hàng chuyển sang Kho']),
    ]
    for name,q,sid,need in cases:
        load(page,q); t=txt(page); st=page.evaluate('({f:activeFlowId,s:activeScreenId,e:entryMode})')
        ck(name+' opens canonical screen',st['s']==sid)
        ck(name+' explains why here',all(x in t for x in need))
        ck(name+' no horizontal overflow',no_overflow(page))
    # Back / exit continuity for non-generic entry contexts.
    load(page,'?uif=UIF-01&entry=product-context'); page.locator('[data-action="exit-inventory-product-context"]').click(); page.wait_for_timeout(20); ck('BJ01 Product deep-link Back returns source context','Quay về sản phẩm' in txt(page))
    load(page,'?uif=UIF-02&entry=document-context'); page.locator('[data-action="exit-receipt-document-context"]').click(); page.wait_for_timeout(20); ck('BJ02 document deep-link Back returns source context','Quay về chứng từ' in txt(page))
    load(page,'?uif=UIF-02&entry=approver'); page.locator('[data-action="exit-approval"]').click(); page.wait_for_timeout(20); ck('BJ02 approver exit returns approver worklist context','danh sách việc cần duyệt' in txt(page))
    load(page,'?uif=UIF-03&entry=receipt-task'); page.locator('[data-back]').click(); page.wait_for_timeout(20); ck('BJ03 receipt task Back returns valuation queue',page.evaluate('activeScreenId')=='SCR-014')
    load(page,'?uif=UIF-04&entry=order-context'); page.locator('[data-action="exit-reservation-context"]').click(); page.wait_for_timeout(20); ck('BJ04 contextual-only Back returns order context','Quay về đơn bán' in txt(page))
    load(page,'?uif=UIF-05&entry=order-task'); page.locator('[data-back]').click(); page.wait_for_timeout(20); ck('BJ05 assigned task Back returns picking queue',page.evaluate('activeScreenId')=='SCR-025')
    load(page,'?uif=UIF-06&entry=return-task'); page.locator('[data-back]').click(); page.wait_for_timeout(20); ck('BJ06 assigned maker task Back returns return queue',page.evaluate('activeScreenId')=='SCR-030')
    load(page,'?uif=UIF-07&entry=return-task'); page.locator('[data-back]').click(); page.wait_for_timeout(20); ck('BJ07 assigned task Back returns supplier-return queue',page.evaluate('activeScreenId')=='SCR-036')

    # Recovery surface is explicitly system-owned.
    load(page,'?uif=UIF-02&screen=SCR-013&state=EMPTY'); t=txt(page)
    ck('SCR013 recovery explains automatic entry','Tự mở khi kết quả lần nhận chưa xác định' in t)
    ck('SCR013 no blind retry copy','Thử lại' not in t)
    # BJ06 intermediate vs terminal result mental roles.
    load(page,'?uif=UIF-06&screen=SCR-035'); page.evaluate('io06SelectedRequestId="RET-260827-03"; stateByScreen["SCR-035"]="RECEIVED_PENDING_CLASSIFICATION"; render();'); t1=txt(page)
    ck('BJ06 receipt milestone is not labeled terminal result','Đã nhận hàng khách trả' in t1 and 'Còn bước phân loại trước khi hoàn tất' in t1)
    page.evaluate('stateByScreen["SCR-035"]="COMPLETED"; io06CurrentRequest().classified=true; render();'); t2=txt(page)
    ck('BJ06 final classification has distinct terminal title','Kết quả phân loại hàng trả' in t2 and 'Bước cuối của yêu cầu khách trả' in t2)
    # BJ07 mismatch clearly hands ownership back to Purchase.
    load(page,'?uif=UIF-07&entry=return-task'); page.evaluate('var x=io07Allocations(io07Current())[0].allocation; x.physicalMismatch=true; render();'); t=txt(page)
    ck('BJ07 mismatch names waiting owner','Đang chờ Mua hàng cập nhật yêu cầu' in t)
    ck('BJ07 mismatch says warehouse cannot edit source','Kho không sửa số lượng hoặc lô tại đây' in t)
    ck('No page JavaScript errors',not errors)
    b.close()
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Entry & Journey Continuity Runtime QA v1.4.3','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', '- Covers module entry, contextual deep-link, actor-handoff task, recovery-only meaning, source ownership and re-entry comprehension.', '- Canonical Product viewport horizontal safety is checked on each direct-entry specimen.', '- QA PASS supports Product review; it is not Product approval.','','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines+=['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'ENTRY-JOURNEY-CONTINUITY-QA-v1.4.3.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
