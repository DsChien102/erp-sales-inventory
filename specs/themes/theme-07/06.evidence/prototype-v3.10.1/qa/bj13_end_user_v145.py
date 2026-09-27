from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text()
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def text(page): return page.locator('#app-screen').inner_text()
def fresh(page):
 page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(20); page.evaluate('activeFlowId="UIF-13";activeScreenId="SCR-085";stateByScreen["SCR-085"]="READY";render();')
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':1400,'height':1100}); page.on('pageerror',lambda e:errors.append(str(e))); fresh(page)
 # Queue
 t=text(page); ck('Queue explains late-cost context','Chi phí đến sau lần xác nhận giá nhập' in t); ck('Queue distinguishes waiting','Chờ tỷ giá Kế toán' in t); ck('Waiting row has no task navigation',page.locator('[data-val13-task="LC13-003"]').count()==0)
 page.fill('[data-val13-search]','không tồn tại'); ck('Search no-result', 'Không tìm thấy công việc phù hợp' in text(page)); page.fill('[data-val13-search]',''); page.click('[data-val13-filter="WAITING"]'); ck('Waiting filter only waiting', 'VC-8890' in text(page) and 'VC-8842' not in text(page)); page.click('[data-val13-filter="ALL"]')
 # Scope
 page.click('[data-val13-task="LC13-001"]'); ck('Actionable task opens source/scope',page.evaluate('activeScreenId')=='SCR-086' and 'Phạm vi liên quan' in text(page)); ck('Exact receipt/LOT context visible','PN-260816-04' in text(page) and 'Lô DH2507' in text(page))
 # deselect all -> disabled
 for sid in ['LC13-T1','LC13-T2','LC13-T3']: page.click(f'[data-val13-target="{sid}"]')
 ck('No target disables preview',page.locator('[data-val13-action="scope-to-allocation"]').is_disabled())
 for sid in ['LC13-T1','LC13-T2','LC13-T3']: page.click(f'[data-val13-target="{sid}"]')
 page.click('[data-val13-action="scope-to-allocation"]'); ck('Scope goes to allocation choice',page.evaluate('activeScreenId')=='SCR-087')
 ck('Multiple allowed methods are not preselected',page.locator('[data-val13-method]').input_value()=='' and 'Chọn căn cứ phân bổ' in text(page))
 ck('Review disabled until method chosen',page.locator('[data-val13-action="open-review"]').is_disabled())
 page.select_option('[data-val13-method]','FIXTURE_VALUE')
 normalized=page.evaluate('val13Current().normalizedAmount'); total=page.evaluate('val13Preview().reduce((s,x)=>s+x.allocatedAmount,0)'); ck('Preview total reconciles',total==normalized)
 before=page.evaluate('val13Preview().map(x=>x.allocatedAmount).join(",")'); page.select_option('[data-val13-method]','FIXTURE_QTY'); after=page.evaluate('val13Preview().map(x=>x.allocatedAmount).join(",")'); ck('Allowed method changes allocation',before!=after); ck('Changed preview still reconciles',page.evaluate('val13Preview().reduce((s,x)=>s+x.allocatedAmount,0)')==normalized)
 ck('Period open/closed consequence visible','Kỳ gốc' in text(page) and 'Kỳ ghi nhận' in text(page))
 # Review
 page.click('[data-val13-action="open-review"]'); rt=text(page); ck('Final review is dedicated late-cost review','Rà soát ghi chi phí' in rt and 'Ghi chi phí mua bổ sung' in rt); ck('Final review says quantity unchanged','Số lượng tồn kho' in rt and 'Không thay đổi' in rt); ck('Final review says official cost not auto-published','Giá vốn chính thức' in rt and 'Chưa tự công bố lại' in rt); ck('No wrong direct-valuation CTA/copy','Xác nhận giá trị' not in rt and 'Khả dụng tăng' not in rt)
 # stale source blocks commit
 page.evaluate('val13ApplySourceUpdate()'); st=text(page); ck('Source update blocks stale review','Nguồn hoặc preview đã thay đổi' in st); ck('Stale review hides obsolete allocation preview','Phân bổ sẽ ghi' not in st and 'Giá trị preview trước' in st and 'Giá trị nguồn hiện hành' in st); ck('No commit CTA on stale review',page.locator('[data-val13-action="confirm-late-cost"]').count()==0)
 page.click('[data-val13-action="back-allocation"]'); page.click('[data-val13-action="open-review"]'); ck('Fresh preview can review again',page.locator('[data-val13-action="confirm-late-cost"]').count()==1)
 page.click('[data-val13-action="confirm-late-cost"]'); res=text(page); ck('Commit ends on dedicated result',page.evaluate('activeScreenId')=='SCR-089' and 'Đã ghi chi phí mua bổ sung' in res); ck('Result hands dirty scope to BJ14','Giá vốn chưa được công bố lại' in res and 'BJ14' in res); ck('Result has no quantity increase','Số lượng tồn kho không thay đổi' in res and 'Khả dụng' not in res)
 # Negative component fixture
 page.click('[data-val13-action="result-to-queue"]'); page.click('[data-val13-task="LC13-004"]'); page.click('[data-val13-action="scope-to-allocation"]'); ck('Negative discount preview preserves sign',page.evaluate('val13Preview().reduce((s,x)=>s+x.allocatedAmount,0)')==-350000 and '-350.000 đ' in text(page))
 # FX fixture
 fresh(page); page.click('[data-val13-task="LC13-002"]'); page.click('[data-val13-action="scope-to-allocation"]'); fx=text(page); ck('FX provenance visible','Tỷ giá Kế toán' in fx and '6.125.000 đ' in fx)
 # result states
 page.evaluate('val13SelectedTaskId="LC13-002";val13LastResult=null;activeScreenId="SCR-089";stateByScreen["SCR-089"]="UNKNOWN";render();'); ck('UNKNOWN forbids blind retry','Không gửi lại chi phí' in text(page) and 'Ghi chi phí mua bổ sung' not in text(page))
 page.evaluate('stateByScreen["SCR-089"]="REJECTED_EXECUTION";render();'); ck('Rejected effect zero','Không thay đổi' in text(page) and 'Xem lại phân bổ' in text(page))
 # layout / JS
 for sid in ['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089']:
  page.evaluate('(s)=>{activeScreenId=s;if(s==="SCR-088"){val13SelectedTaskId="LC13-002";val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();stateByScreen[s]="READY";}if(s==="SCR-089")stateByScreen[s]="COMPLETED";render();}',sid)
  g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); ck(f'{sid} no horizontal overflow',g['sw']<=g['cw']+1)
 ck('No page JS errors',not errors); b.close()
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# BJ13 End-user / Interaction QA v1.4.5','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', '- Real pointer/form interactions on the dedicated UIF13 flow.', '- Covers actionable/waiting queue, exact scope, preview reconciliation, allocation-method change, period context, stale-source invalidation, commit/result, negative component, FX and UNKNOWN/REJECTED finality.','', '## Checks','']+[f'- [{"x" if ok else " "}] {n}' for n,ok in checks]
(OUT/'BJ13-END-USER-QA-v1.4.5.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed: print('\n'.join(failed)); raise SystemExit(1)
