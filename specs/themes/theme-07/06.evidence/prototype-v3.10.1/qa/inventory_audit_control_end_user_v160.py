from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text()
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def txt(p): return p.locator('#app-screen').inner_text()
def fresh(p,u,s,state=None):
 p.goto('about:blank'); p.set_content(html,wait_until='load'); p.wait_for_timeout(20); p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;if(x.st)stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':state})
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':402,'height':874}); p.on('pageerror',lambda e:errors.append(str(e)))
 # BJ08
 fresh(p,'UIF-08','SCR-044','BLIND_COUNT'); t=txt(p)
 ck('BJ08 blind UI has actual-count only','Số đếm thực tế' in t)
 ck('BJ08 blind UI hides system quantity/discrepancy',all(x not in t for x in ['Số hệ thống','Chênh lệch','Số sổ']))
 p.click('[data-ic08-action="submit-first"]'); ck('BJ08 first submit opens recount',p.evaluate('activeScreenId')=='SCR-045')
 t=txt(p); ck('BJ08 recount reveals comparison','Số hệ thống' in t and 'Chênh lệch' in t)
 p.click('[data-ic08-action="submit-recount"]'); ck('BJ08 maker ends at pending not approver',p.evaluate('activeScreenId')=='SCR-042' and p.evaluate('stateByScreen["SCR-042"]')=='PENDING_APPROVAL')
 ck('BJ08 pending has no approval button',p.locator('[data-ic08-action="approve"]').count()==0)
 fresh(p,'UIF-08','SCR-046','APPROVAL_REQUIRED'); ck('BJ08 approver direct entry has approve/reject',p.locator('[data-ic08-action="approve"]').count()==1 and p.locator('[data-ic08-action="reject"]').count()==1)
 ck('BJ08 approver has no cancel',p.locator('[data-ic08-action="cancel-open"]').count()==0)
 p.click('[data-ic08-action="approve"]'); ck('BJ08 approval reaches result',p.evaluate('activeScreenId')=='SCR-047' and 'Đã hoàn tất kiểm kê' in txt(p))
 fresh(p,'UIF-08','SCR-042','READY'); p.click('[data-ic08-action="cancel-open"]'); ck('BJ08 cancellation is separate sheet',p.locator('.bottom-sheet').count()==1); p.click('[data-ic08-action="cancel-confirm"]'); ck('BJ08 cancel terminal no stock adjustment','Không có điều chỉnh tồn kho' in txt(p))
 fresh(p,'UIF-08','SCR-047','UNKNOWN'); ck('BJ08 unknown no new adjustment CTA','Kiểm tra kết quả' in txt(p) and 'Tạo phiên' not in txt(p))
 # BJ09
 fresh(p,'UIF-09','SCR-036','READY'); t=txt(p); ck('BJ09 list uses Product language','Tình trạng hàng' in t and 'Bán được' in t and 'Cách ly' in t and 'Hết hạn' in t)
 p.click('[data-ic09-item="vitc"]'); t=txt(p); ck('BJ09 expiry derived copy','tự loại' in t and 'không cần thao tác đánh dấu' in t.lower()); ck('BJ09 expired detail no change CTA',p.locator('[data-ic09-action="change"]').count()==0)
 fresh(p,'UIF-09','SCR-037','LOCKED'); ck('BJ09 locked true read-only',p.locator('[data-ic09-action="change"]').count()==0)
 fresh(p,'UIF-09','SCR-038','READY'); t=txt(p); ck('BJ09 state choices omit technical process states',all(x not in t for x in ['VALUATION_PENDING','RETURN_PENDING','RTV_PENDING']))
 ck('BJ09 no Save Draft','Lưu nháp' not in t)
 p.click('[data-ic09-action="submit"]'); ck('BJ09 maker stays pending','Đã gửi chờ duyệt' in txt(p) and p.locator('[data-ic09-action="approve"]').count()==0)
 fresh(p,'UIF-09','SCR-038','APPROVAL_REVIEW'); ck('BJ09 approver independent review',p.locator('[data-ic09-action="approve"]').count()==1)
 p.click('[data-ic09-action="approve"]'); t=txt(p); ck('BJ09 result preserves physical total','không thay đổi' in t.lower() and 'Tồn vật lý' in t)
 fresh(p,'UIF-09','SCR-056','READY'); ck('BJ09 history read-only',p.locator('input, textarea, [data-ic09-action="change"]').count()==0)
 # BJ10
 fresh(p,'UIF-10','SCR-036','READY'); t=txt(p); ck('BJ10 entry excludes sellable source','Chỉ hiển thị hàng đủ điều kiện' in t and 'Bán được' not in t)
 p.click('[data-ic10-item="amox-l2407"]'); p.click('[data-ic10-action="request"]'); ck('BJ10 prepare has no Save Draft','Lưu nháp' not in txt(p))
 p.click('[data-ic10-action="submit"]'); t=txt(p); ck('BJ10 submit ends maker task','Đã gửi chờ duyệt' in t and 'Tồn kho chưa thay đổi' in t)
 fresh(p,'UIF-10','SCR-040','APPROVAL_REVIEW'); t=txt(p); ck('BJ10 approval explicitly not disposal','Phê duyệt chưa phải tiêu hủy' in t and 'Tồn vật lý chưa giảm' in t)
 p.click('[data-ic10-action="approve"]'); t=txt(p); ck('BJ10 approved waits separate physical task','chờ xử lý thực tế' in t.lower() and p.locator('[data-ic10-action="complete"]').count()==0)
 fresh(p,'UIF-10','SCR-040','COMPLETION'); ck('BJ10 completion direct task has destructive CTA',p.locator('[data-ic10-action="complete"]').count()==1)
 p.click('[data-ic10-action="complete"]'); ck('BJ10 completed result decrements only now','Đã ghi nhận tiêu hủy' in txt(p) and 'Tồn vật lý còn lại' in txt(p))
 fresh(p,'UIF-10','SCR-040','COMPLETION_QTY_BLOCKED'); ck('BJ10 excess actual quantity blocks commit',p.locator('[data-ic10-action="complete"]').is_disabled())
 fresh(p,'UIF-10','SCR-040','PRICE_BASIS_REQUIRED'); t=txt(p); ck('BJ10 price basis missing blocks submit',p.locator('[data-ic10-action="submit"]').is_disabled() and 'nhập giá thủ công' in t.lower())
 fresh(p,'UIF-10','SCR-041','UNKNOWN'); ck('BJ10 unknown has verify-only recovery','Kiểm tra kết quả' in txt(p) and 'tiêu hủy mới' in txt(p).lower())
 # target default screens 402 width no overflow
 for u,sids in [('UIF-08',['SCR-042','SCR-043','SCR-044','SCR-045','SCR-046','SCR-047']),('UIF-09',['SCR-036','SCR-037','SCR-038','SCR-041','SCR-056']),('UIF-10',['SCR-036','SCR-037','SCR-040','SCR-041'])]:
  for s in sids:
   st={'SCR-044':'BLIND_COUNT','SCR-045':'RECOUNT_REQUIRED','SCR-046':'APPROVAL_REQUIRED','SCR-047':'COMPLETED','SCR-041':'COMPLETED'}.get(s,'READY')
   p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':st}); g=p.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); ck(f'{u}/{s} no horizontal overflow',g['sw']<=g['cw']+1)
 ck('No page JS errors',not errors); b.close()
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Inventory Audit & Control End-user QA v1.6.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','','Covers end-user decisions, actor boundaries, true read-only, finality/recovery, and canonical 402×874 overflow.','','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines+=['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'INVENTORY-AUDIT-CONTROL-END-USER-QA-v1.6.0.md').write_text('\n'.join(lines)+'\n')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed: print('\n'.join(failed)); raise SystemExit(1)
