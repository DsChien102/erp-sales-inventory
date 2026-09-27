from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent; SHOTS=OUT/'screenshots-v1.3.6'; SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf8'); css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8'); data=(ROOT/'workbench-data.js').read_text(encoding='utf8'); app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]
def check(name,cond): checks.append((name,bool(cond)))
def show(page,flow,screen,state=None):
    page.evaluate('(x)=>{activeFlowId=x.f; activeScreenId=x.s; if(x.st) stateByScreen[x.s]=x.st; render();}',{'f':flow,'s':screen,'st':state})
def txt(page): return page.locator('#app-screen').inner_text()
def shot(page,name): page.locator('#device-preview').screenshot(path=str(SHOTS/f'{name}.png'))
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':1200,'height':1000}); errors=[];page.on('pageerror',lambda e: errors.append(str(e)));page.set_content(html,wait_until='load');page.wait_for_timeout(100)
    # BJ02 tiny correction
    show(page,'UIF-02','SCR-008','READY'); t=txt(page); check('BJ02 removed date helper copy','Không chọn ngày trước hôm nay.' not in t); check('BJ02 date still constrained',page.locator('[data-bj02-header="businessDate"]').get_attribute('min') is not None)
    # BJ05 queue + multi-lot
    show(page,'UIF-05','SCR-025','READY');t=txt(page);check('BJ05 queue filters actionable/waiting','Cần lấy' in t and 'Đang chờ' in t);shot(page,'BJ05-queue')
    page.click('[data-io05-filter="WAITING"]'); t=txt(page);check('BJ05 waiting exposes source wait','Chờ đơn bán xử lý' in t)
    show(page,'UIF-05','SCR-027','READY');t=txt(page);check('BJ05 multi-lot allocations visible','DH2507' in t and 'DH2509' in t and page.locator('.io-allocation-block').count()==2);shot(page,'BJ05-multilot-pick')
    show(page,'UIF-05','SCR-026','STALE_RECOVERED');t=txt(page);check('BJ05 stale gives physical correction','Trả lại 4 hộp DH2507' in t and 'DH2511' in t);shot(page,'BJ05-stale-physical')
    show(page,'UIF-05','SCR-028','PARTIAL_ALLOWED');t=txt(page);check('BJ05 handover keeps customer context','Đại lý An Phú' in t);check('BJ05 partial handover fields per allocation',page.locator('[data-io05-handover-allocation]').count()==3);page.locator('[data-io05-handover-allocation="AL-01"]').fill('2');check('BJ05 partial quantity accepted',not page.locator('[data-io05-action="confirm-handover"]').is_disabled());shot(page,'BJ05-partial-handover')
    # BJ06 queue and multi-line
    show(page,'UIF-06','SCR-030','READY');t=txt(page);check('BJ06 queue filters actionable/waiting','Cần xử lý' in t and 'Đang chờ' in t);page.click('[data-io06-request="RET-260827-05"]');check('BJ06 classification reentry direct',page.evaluate('activeScreenId')=='SCR-033');shot(page,'BJ06-classification-overview')
    show(page,'UIF-06','SCR-031','READY');page.evaluate('io06SelectedRequestId="RET-260827-03";io06ActiveLineId="RET-L1";renderAppScreen();');check('BJ06 receipt overview multi-line',page.locator('[data-io06-line]').count()==3);shot(page,'BJ06-multiline-receipt')
    # wrong lot evidence
    page.evaluate('io06SelectedRequestId="RET-260827-03";io06ActiveLineId="RET-L1";let l=io06ActiveLine();l.actualLot="DH2509";l.exception="NONE";l.reasonCode="";l.evidenceFile="";activeScreenId="SCR-032";render();');t=txt(page);check('BJ06 wrong lot needs reason and image','Lô thực nhận không khớp' in t and 'Ảnh nhãn lô thực nhận' in t);shot(page,'BJ06-wrong-lot')
    # classification bottom sheet and hard guard
    page.evaluate('io06SelectedRequestId="RET-260827-05";io06ActiveLineId="RET-L4";io06ClassificationOpen=true;activeScreenId="SCR-033";stateByScreen["SCR-033"]="EXPIRED_GUARD";render();');check('BJ06 classification item editor has four fields',page.locator('[data-io06-class]').count()==4);page.locator('[data-io06-class="sellable"]').fill('4');page.locator('[data-io06-class="expired"]').fill('0');t=txt(page);check('BJ06 expired hard guard','không thể bán lại' in t);shot(page,'BJ06-classification-sheet')
    # BJ07 lifecycle, delta, verification
    show(page,'UIF-07','SCR-036','READY');t=txt(page);check('BJ07 lifecycle not replaced by update event','Chờ bàn giao' in t and 'Đã cập nhật' not in t and 'Yêu cầu vừa thay đổi' in t);shot(page,'BJ07-queue')
    page.click('[data-io07-request="RTV-260827-04"]');t=txt(page);check('BJ07 source delta explicit','giảm từ 8 xuống 5' in t and 'Bỏ 3 hộp' in t);check('BJ07 review disabled before physical verify',page.locator('[data-io07-action="review-handover"]').is_disabled());page.click('[data-io07-verify-item="RTV-I3"]');check('BJ07 review enabled after physical verify',not page.locator('[data-io07-action="review-handover"]').is_disabled());shot(page,'BJ07-physical-verify')
    page.click('[data-io07-action="review-handover"]');t=txt(page);check('BJ07 final review distinct from preparation','Hàng đã kiểm và sẵn sàng bàn giao' in t and 'Xác nhận đã bàn giao' in t);shot(page,'BJ07-handover-review')
    # geometry key screens
    for f,s,st in [('UIF-05','SCR-027','READY'),('UIF-05','SCR-028','PARTIAL_ALLOWED'),('UIF-06','SCR-031','READY'),('UIF-06','SCR-033','READY'),('UIF-07','SCR-037','SOURCE_UPDATED'),('UIF-07','SCR-039','READY')]:
        show(page,f,s,st);g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})');check(f'{f}/{s} no horizontal overflow',g['sw']<=g['cw']+1)
    check('No page JavaScript errors',not errors)
    b.close()
passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Inventory Operations QA v1.3.6','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Coverage: BJ02 requested copy correction; BJ05 multi-LOT/partial/stale/task-queue; BJ06 multi-line/re-entry/wrong-LOT/classification; BJ07 lifecycle/source-delta/physical verification; mobile horizontal-overflow guard.','', '## Checks','']
lines += [f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines += ['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'INVENTORY-OPERATIONS-QA-v1.3.6.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
 print('\n'.join(failed));raise SystemExit(1)
