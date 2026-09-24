from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf8'); css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8'); data=(ROOT/'workbench-data.js').read_text(encoding='utf8'); app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def t(page): return page.locator('#app-screen').inner_text()
def fresh(page,uif,sid):
 page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(25); page.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]="READY";render();}',{'u':uif,'s':sid})
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':402,'height':874}); page.on('pageerror',lambda e:errors.append(str(e)))
 # BJ03
 fresh(page,'UIF-03','SCR-014'); tx=t(page)
 ck('BJ03 queue no Nguồn việc card','Nguồn việc' not in tx)
 ck('BJ03 queue no architecture lesson','BJ02' not in tx and 'flow' not in tx.lower())
 ck('BJ03 waiting task read-only',page.locator('.val03-work-row.is-waiting [data-val03-receipt]').count()==0)
 page.click('[data-val03-receipt="VAL03-R1"]'); ck('BJ03 enters working scope',page.evaluate('activeScreenId')=='SCR-015')
 page.click('[data-val03-slice="VAL03-S1"]'); ck('BJ03 partial hidden by default',page.locator('[data-val03-qty]').count()==0)
 page.click('[data-val03-action="open-evidence-sheet"]'); ck('BJ03 evidence stays on same screen',page.evaluate('activeScreenId')=='SCR-015' and page.locator('.val03-evidence-sheet').count()==1)
 page.click('.button--primary[data-val03-action="close-evidence-sheet"]'); ck('BJ03 close evidence stays scope',page.evaluate('activeScreenId')=='SCR-015')
 page.click('[data-val03-action="open-review"]'); ck('BJ03 happy path direct to final review',page.evaluate('activeScreenId')=='SCR-017')
 ck('BJ03 final review has unit cost','Giá nhập thực tế' in t(page))
 page.click('[data-val03-action="open-evidence-sheet"]'); ck('BJ03 review provenance is overlay',page.evaluate('activeScreenId')=='SCR-017' and page.locator('.val03-evidence-sheet').count()==1)
 # conflict resolution stays contextual
 fresh(page,'UIF-03','SCR-015'); page.evaluate('val03SelectedReceiptId="VAL03-R1";render();'); page.click('[data-val03-slice="VAL03-S4"]'); page.click('[data-val03-action="open-evidence-sheet"]')
 ck('BJ03 conflict source not preselected',page.locator('.val03-source-option.is-selected').count()==0)
 page.click('[data-val03-source="VAL03-G2"][data-val03-source-id="SUP"]'); page.locator('[data-val03-reason="VAL03-G2"]').fill('Theo chứng từ NCC hiện hành')
 done=page.locator('.button--primary[data-val03-action="close-evidence-sheet"]'); ck('BJ03 reason enables contextual done',not done.is_disabled()); done.click(); ck('BJ03 conflict did not navigate loop',page.evaluate('activeScreenId')=='SCR-015')
 # BJ13
 fresh(page,'UIF-13','SCR-085'); tx=t(page)
 ck('BJ13 queue no architecture banner','Chi phí đến sau lần xác nhận giá nhập' not in tx and 'BJ14' not in tx)
 ck('BJ13 waiting source task read-only',page.locator('[data-val13-task="LC13-003"]').count()==0)
 page.click('[data-val13-task="LC13-001"]'); ck('BJ13 queue to scope',page.evaluate('activeScreenId')=='SCR-086')
 page.click('[data-val13-action="scope-to-allocation"]'); ck('BJ13 scope to allocation',page.evaluate('activeScreenId')=='SCR-087')
 if page.locator('[data-val13-method]').count() and page.locator('[data-val13-method]').input_value()=='' : page.locator('[data-val13-method]').select_option(index=1)
 page.click('[data-val13-action="open-review"]'); ck('BJ13 allocation to one final review',page.evaluate('activeScreenId')=='SCR-088')
 tx=t(page); ck('BJ13 review value-only','Số lượng tồn kho' in tx and 'Không thay đổi' in tx); ck('BJ13 review no internal BJ text','BJ14' not in tx)
 ck('BJ13 review one edit path',page.locator('[data-val13-action="back-allocation"]').count()==1 and page.locator('[data-val13-action="back-scope"]').count()==0)
 # BJ14
 fresh(page,'UIF-14','SCR-072'); tx=t(page)
 ck('BJ14 module entry business-facing','Giá vốn' in tx)
 ck('BJ14 list shows run states','Sẵn sàng công bố' in tx and 'Bị chặn' in tx and 'Cần tính lại' in tx)
 page.click('[data-val14-run="COST-0826"]'); ck('BJ14 run opens result surface',page.evaluate('activeScreenId')=='SCR-074')
 tx=t(page); ck('BJ14 shows both methods','Bình quân liên hoàn' in tx and 'Bình quân cuối kỳ' in tx)
 ck('BJ14 method is policy-led','Dùng để công bố theo chính sách' in tx)
 ck('BJ14 no method selector',page.locator('[data-val14-method]').count()==0)
 page.click('[data-val14-action="review-publish"]'); ck('BJ14 ready run to final review',page.evaluate('activeScreenId')=='SCR-076')
 tx=t(page); ck('BJ14 final review says sale price unchanged','Giá bán' in tx and 'Không thay đổi' in tx)
 ck('BJ14 one final publish CTA',page.locator('[data-val14-action="publish"]').count()==1)
 # stale input blocks commit and forces successor
 page.evaluate('val14ApplyInputChange()'); page.click('[data-val14-action="publish"]'); ck('BJ14 stale blocks publish',page.evaluate('activeScreenId')=='SCR-076' and 'Tạo lần tính kế tiếp' in t(page))
 # blocker is state of same result screen
 fresh(page,'UIF-14','SCR-072'); page.click('[data-val14-run="COST-0901-B"]'); ck('BJ14 blocker remains SCR074',page.evaluate('activeScreenId')=='SCR-074'); tx=t(page); ck('BJ14 blocker identifies owner','Đang chờ:' in tx); ck('BJ14 blocked has no publish action',page.locator('[data-val14-action="review-publish"]').count()==0)
 # new run no method user decision; calculate -> same run result
 fresh(page,'UIF-14','SCR-072'); page.click('[data-val14-action="new-run"]'); ck('BJ14 setup screen',page.evaluate('activeScreenId')=='SCR-073'); ck('BJ14 setup no policy method input',page.locator('[data-val14-method]').count()==0); page.click('[data-val14-action="calculate"]'); ck('BJ14 calculate opens result state',page.evaluate('activeScreenId')=='SCR-074'); page.wait_for_timeout(180); ck('BJ14 calculation becomes reviewable in same surface','Rà soát công bố' in t(page))
 # permission masking: denied screen must not expose known financial fixture amounts
 page.evaluate('stateByScreen["SCR-074"]="PERMISSION_DENIED";activeScreenId="SCR-074";render();'); tx=t(page); ck('BJ14 permission masks financial amounts','1.245.920.000' not in tx and '486.300.000' not in tx)
 # Active screens no overflow
 for uif,sids in [('UIF-03',['SCR-014','SCR-015','SCR-017','SCR-019']),('UIF-13',['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089']),('UIF-14',['SCR-072','SCR-073','SCR-074','SCR-076','SCR-077'])]:
  for sid in sids:
   page.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]="READY";render();}',{'u':uif,'s':sid}); g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); ck(f'{uif}/{sid} no horizontal overflow',g['sw']<=g['cw']+1)
 ck('No page JS errors',not errors); b.close()
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Inventory Valuation End-user QA v1.5.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Covers the three Product journeys as a user: no architecture explanation UI, linear task flow, contextual provenance, value-only late cost, immutable cost-run states, locked policy method, stale-input recovery, permission masking and 402×874 overflow.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines+=['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'INVENTORY-VALUATION-END-USER-QA-v1.5.0.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
 print('\n'.join(failed)); raise SystemExit(1)
