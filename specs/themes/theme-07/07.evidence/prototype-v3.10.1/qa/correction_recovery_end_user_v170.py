from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text()
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def text(p): return p.locator('#app-screen').inner_text()
def fresh(p,u='UIF-11',s=None,state=None,entry=None):
 q=f'?uif={u}'+(f'&entry={entry}' if entry else '')
 p.goto('about:blank'+q); p.set_content(html,wait_until='load'); p.wait_for_timeout(20)
 if s:
  p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;if(x.st)stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':state})
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':402,'height':874}); p.on('pageerror',lambda e:errors.append(str(e)))
 # Entry contract
 fresh(p,'UIF-11',entry='approver'); ck('UIF11 approver URL enters SCR051 directly',p.evaluate('activeScreenId')=='SCR-051')
 fresh(p,'UIF-11',entry='operation-context'); ck('UIF11 operation-context enters SCR049',p.evaluate('activeScreenId')=='SCR-049')
 fresh(p,'UIF-16',entry='case-context'); ck('UIF16 case-context enters SCR079',p.evaluate('activeScreenId')=='SCR-079')
 fresh(p,'UIF-17',entry='unknown-context'); ck('UIF17 UNKNOWN-context enters SCR079',p.evaluate('activeScreenId')=='SCR-079')
 # BJ11 cancel path
 fresh(p,'UIF-11','SCR-048','READY'); p.click('[data-cr11-operation="IO-260906-022"]'); ck('BJ11 cancelable row opens detail',p.evaluate('activeScreenId')=='SCR-049' and 'Có thể hủy' in text(p))
 p.click('[data-cr11-action="open-cancel"]'); ck('BJ11 cancel route is a dedicated task',p.evaluate('activeScreenId')=='SCR-052' and 'Hủy trước khi thực thi' in text(p))
 ck('BJ11 cancel confirms zero stock effect','tồn kho và giá trị không thay đổi' in text(p).lower())
 ck('BJ11 cancel disabled without reason',p.locator('[data-cr11-action="confirm-cancel"]').is_disabled())
 p.fill('[data-cr11-cancel-reason]','Yêu cầu tạo nhầm'); ck('BJ11 cancel enables after reason',not p.locator('[data-cr11-action="confirm-cancel"]').is_disabled())
 p.click('[data-cr11-action="confirm-cancel"]'); ck('BJ11 cancel terminates without movement','Đã hủy yêu cầu' in text(p) and 'Không thay đổi' in text(p))
 # BJ11 correction maker
 fresh(p,'UIF-11','SCR-048','READY'); p.click('[data-cr11-operation="IO-260901-014"]'); ck('BJ11 completed operation offers correction',p.locator('[data-cr11-action="open-correction"]').count()==1)
 p.click('[data-cr11-action="open-correction"]'); ck('BJ11 strategy uses user language','Sửa phần sai' in text(p) and 'Hoàn nguyên và ghi lại đúng' in text(p))
 p.click('[data-cr11-action="edit-correction"]'); t=text(p); ck('BJ11 editor has one authoritative correct quantity',p.locator('[data-cr11-correct-qty]').count()==1 and 'Số đúng' in t)
 ck('BJ11 editor derives delta','Điều chỉnh' in t and '-2 hộp' in t.replace('−','-'))
 ck('BJ11 editor has no visible Save Draft','Lưu nháp' not in t and p.locator('button:has-text("Lưu nháp")').count()==0)
 p.click('[data-cr11-action="submit-correction"]'); t=text(p); ck('BJ11 maker submit ends at pending result',p.evaluate('activeScreenId')=='SCR-053' and 'Đã gửi chờ duyệt' in t)
 ck('BJ11 maker pending has no approve CTA',p.locator('[data-cr11-action="approve"]').count()==0)
 ck('BJ11 pending says stock not changed','Chưa thay đổi' in t)
 # BJ11 approver independent task reject reason
 fresh(p,'UIF-11',entry='approver'); ck('BJ11 approver sees before/after evidence','Trước / sau' in text(p) and 'Người lập' in text(p))
 ck('BJ11 approver has approve/reject',p.locator('[data-cr11-action="approve"]').count()==1 and p.locator('[data-cr11-action="reject-open"]').count()==1)
 p.click('[data-cr11-action="reject-open"]'); ck('BJ11 reject opens required reason sheet',p.locator('.bottom-sheet').count()==1 and p.locator('[data-cr11-action="reject-confirm"]').is_disabled())
 p.fill('[data-cr11-approval-reason]','Cần kiểm tra lại căn cứ'); ck('BJ11 reject enables only with reason',not p.locator('[data-cr11-action="reject-confirm"]').is_disabled())
 # approve automatic path separately
 fresh(p,'UIF-11',entry='approver'); p.click('[data-cr11-action="approve"]'); ck('BJ11 approve enters processing result',p.evaluate('activeScreenId')=='SCR-053' and 'Đang ghi nhận sửa sai' in text(p)); p.wait_for_timeout(800); t=text(p)
 ck('BJ11 approved correction auto-completes','Đã hoàn tất sửa sai' in t)
 ck('BJ11 no second correction commit CTA',p.locator('[data-cr11-action="approve"],[data-cr11-action="submit-correction"]').count()==0)
 # BJ11 unknown and physical return boundary
 fresh(p,'UIF-11','SCR-048','READY'); p.click('[data-cr11-operation="IO-260906-031"]'); ck('BJ11 UNKNOWN blocks cancel/correction',p.locator('[data-cr11-action="open-cancel"],[data-cr11-action="open-correction"]').count()==0 and 'Kết quả chưa xác định' in text(p)); p.click('[data-cr11-action="handoff-unknown"]'); ck('BJ11 UNKNOWN hands off to UIF17 same operation',p.evaluate('activeFlowId')=='UIF-17' and p.evaluate('activeScreenId')=='SCR-079' and 'IO-260906-031' in text(p))
 fresh(p,'UIF-11','SCR-048','READY'); p.click('[data-cr11-operation="IO-260902-005"]'); t=text(p); ck('BJ11 physical handover does not fake stock return','Hàng khách trả' in t and p.locator('[data-cr11-action="open-correction"]').count()==0)
 # BJ16 projection recovery
 fresh(p,'UIF-16','SCR-078','READY'); p.click('[data-cr-case="REC-260907-03"]'); t=text(p); ck('BJ16 projection case compares source/ledger/display',all(x in t for x in ['Nguồn nghiệp vụ','Sổ kho','Số liệu hiển thị']))
 ck('BJ16 offers recovery only after ledger proven correct','Sổ kho đúng, số liệu hiển thị sai' in t and p.locator('[data-cr16-action="open-plan"]').count()==1)
 p.click('[data-cr16-action="open-plan"]'); t=text(p); ck('BJ16 plan states what will not change','Sổ kho' in t and 'Không thay đổi' in t and 'Nghiệp vụ nguồn' in t)
 ck('BJ16 plan has no raw technical selector',p.locator('#app-screen select,#app-screen [data-cr16-replay],#app-screen [data-cr16-rebuild]').count()==0 and all(x not in t for x in ['Replay','Outbox','Hash']))
 p.click('[data-cr16-action="start-recovery"]'); ck('BJ16 recovery progress has no user mutation CTA',p.evaluate('activeScreenId')=='SCR-081' and p.locator('[data-cr16-action="start-recovery"]').count()==0)
 p.wait_for_timeout(900); ck('BJ16 recovery auto-reaches review-ready','Đã khôi phục số liệu hiển thị' in text(p) and p.locator('[data-cr16-action="review-result"]').count()==1)
 p.click('[data-cr16-action="review-result"]'); ck('BJ16 review compares final facts','Chênh lệch' in text(p) and '0 hộp' in text(p))
 p.click('[data-cr16-action="close-case"]'); ck('BJ16 closes/unlocks only after review','Đã xử lý sai lệch' in text(p) and 'Đã mở khóa' in text(p))
 # BJ16 other routes
 fresh(p,'UIF-16','SCR-078','READY'); p.click('[data-cr-case="REC-260907-04"]'); p.click('[data-cr16-action="handoff-correction"]'); ck('BJ16 correction route hands off to UIF11 detail',p.evaluate('activeFlowId')=='UIF-11' and p.evaluate('activeScreenId')=='SCR-049')
 fresh(p,'UIF-16','SCR-078','READY'); p.click('[data-cr-case="REC-260907-06"]'); t=text(p); ck('BJ16 ledger integrity blocks auto recovery','Cần kiểm tra toàn vẹn sổ kho' in t and p.locator('[data-cr16-action="open-plan"]').count()==0); p.click('[data-cr16-action="show-escalated"]'); ck('BJ16 ledger integrity escalates','Đã chuyển xử lý chuyên sâu' in text(p))
 fresh(p,'UIF-16','SCR-078','READY'); p.click('[data-cr-case="REC-260907-07"]'); ck('BJ16 source mismatch remains waiting with no inventory mutation CTA','Đang chờ nghiệp vụ nguồn xác minh' in text(p) and p.locator('[data-cr16-action]').count()==0)
 # BJ17 committed evidence
 fresh(p,'UIF-17','SCR-078','READY'); p.click('[data-cr-case="REC-UNKNOWN-01"]'); t=text(p); ck('BJ17 commit evidence says no duplicate effect','không ghi lại tác động lần hai' in t.lower()); p.click('[data-cr17-action="open-plan"]'); t=text(p); ck('BJ17 committed plan is finalize-existing-effect','Xác lập đã hoàn tất' in t and 'Tạo nghiệp vụ mới' in t and 'Không' in t); p.click('[data-cr17-action="execute-plan"]'); ck('BJ17 finality review preserves identity','Định danh' in text(p) and 'Không thay đổi' in text(p)); p.click('[data-cr17-action="finish-review"]'); ck('BJ17 committed result completed without new operation','Đã xác lập kết quả nghiệp vụ' in text(p) and 'không tạo operation mới' in text(p).lower())
 # BJ17 no-commit same identity
 fresh(p,'UIF-17','SCR-078','READY'); p.click('[data-cr-case="REC-UNKNOWN-02"]'); t=text(p); ck('BJ17 no-commit evidence confirms no partial effect','Tác động dở dang' in t and 'Không phát hiện' in t); p.click('[data-cr17-action="open-plan"]'); t=text(p); ck('BJ17 no-commit uses same processing identity','Tiếp tục lần xử lý này' in t and 'IO-260906-044' in t and 'Định danh' in t and 'Giữ nguyên' in t); p.click('[data-cr17-action="execute-plan"]'); ck('BJ17 continued review creates no new operation','Nghiệp vụ mới' in text(p) and 'Không tạo' in text(p))
 # BJ17 insufficient evidence
 fresh(p,'UIF-17','SCR-078','READY'); p.click('[data-cr-case="REC-UNKNOWN-03"]'); t=text(p); ck('BJ17 insufficient evidence remains unresolved','Chưa đủ bằng chứng để kết luận' in t and 'phạm vi tiếp tục được bảo vệ' in t.lower()); ck('BJ17 insufficient evidence has no retry/new-op CTA',all(x not in t for x in ['Thử lại','Tạo nghiệp vụ mới','Retry'])); p.click('[data-cr17-action="show-escalated"]'); t=text(p); ck('BJ17 escalated result keeps owner and protection','Chưa xác định — đã chuyển xử lý' in t and 'Vận hành nền tảng' in t and 'Tiếp tục được bảo vệ' in t)
 # overflow gate target defaults
 for u,sids in [('UIF-11',['SCR-048','SCR-049','SCR-052','SCR-050','SCR-053','SCR-051']),('UIF-16',['SCR-078','SCR-079','SCR-080','SCR-081','SCR-082','SCR-083']),('UIF-17',['SCR-078','SCR-079','SCR-080','SCR-082','SCR-083'])]:
  for s in sids:
   p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=screens.find(q=>q.id===x.s).defaultState;render();}',{'u':u,'s':s}); g=p.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); ck(f'{u}/{s} no horizontal overflow',g['sw']<=g['cw']+1)
 ck('No page JS errors',not errors); b.close()
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Correction & Recovery End-user QA v1.7.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','','Covers actor boundaries, immutable correction, evidence-first routing, same-identity UNKNOWN recovery, and mobile overflow.','','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines+=['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'CORRECTION-RECOVERY-END-USER-QA-v1.7.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
 print('\n'.join(failed)); print('\n'.join(errors[:20])); raise SystemExit(1)
