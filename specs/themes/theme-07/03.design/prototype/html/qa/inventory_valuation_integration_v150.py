from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text()
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':900,'height':900}); page.on('pageerror',lambda e: errors.append(str(e))); page.set_content(html,wait_until='load'); page.wait_for_timeout(25)
 # BJ03 bootstrap official cost remains a valuation side effect, not BJ14 publish.
 page.evaluate('activeFlowId="UIF-03";activeScreenId="SCR-015";val03SelectedReceiptId="VAL03-R1";render();')
 page.click('[data-val03-slice="VAL03-S4"]'); page.click('[data-val03-action="open-evidence-sheet"]'); page.click('[data-val03-source="VAL03-G2"][data-val03-source-id="SUP"]'); page.locator('[data-val03-reason="VAL03-G2"]').fill('Nguồn hợp lệ'); page.locator('.button--primary[data-val03-action="close-evidence-sheet"]').click(); page.click('[data-val03-action="open-review"]')
 ck('BJ03 can disclose initial official-cost bootstrap','Sẽ khởi tạo' in page.locator('#app-screen').inner_text())
 # BJ13 commit stays value-only and outputs dirty scope without pretending publish is done.
 page.evaluate('activeFlowId="UIF-13";activeScreenId="SCR-085";stateByScreen["SCR-085"]="READY";render();'); page.click('[data-val13-task="LC13-001"]'); page.click('[data-val13-action="scope-to-allocation"]');
 if page.locator('[data-val13-method]').input_value()=='': page.locator('[data-val13-method]').select_option(index=1)
 page.click('[data-val13-action="open-review"]'); tx=page.locator('#app-screen').inner_text(); ck('BJ13 does not change quantity','Số lượng tồn kho' in tx and 'Không thay đổi' in tx); ck('BJ13 does not auto-publish official cost','Chưa tự công bố lại' in tx)
 page.click('[data-val13-action="confirm-late-cost"]'); tx=page.locator('#app-screen').inner_text(); ck('BJ13 result says cost needs recalculation','Giá vốn' in tx and 'Cần tính lại' in tx); ck('BJ13 Product UI does not name BJ14','BJ14' not in tx)
 # BJ14 dirty scope is a run task, not an automatic mutation; method fixed by policy.
 page.evaluate('activeFlowId="UIF-14";activeScreenId="SCR-072";stateByScreen["SCR-072"]="READY";render();'); ck('BJ14 has dirty-scope work item','Cần tính lại' in page.locator('#app-screen').inner_text()); page.click('[data-val14-run="COST-0903"]'); ck('Dirty scope opens setup, not auto publish',page.evaluate('activeScreenId')=='SCR-073')
 tx=page.locator('#app-screen').inner_text(); ck('BJ14 setup exposes policy as read-only fact','Phương pháp công bố' in tx and 'Chính sách giá vốn' in tx); ck('BJ14 setup does not let user choose costing method',page.locator('[data-val14-method]').count()==0)
 # Publish success and UNKNOWN semantics.
 page.evaluate('val14SelectedRunId="COST-0826";activeScreenId="SCR-074";stateByScreen["SCR-074"]="READY";render();'); page.click('[data-val14-action="review-publish"]'); page.click('[data-val14-action="publish"]'); ck('BJ14 successful publish reaches terminal result',page.evaluate('activeScreenId')=='SCR-077'); tx=page.locator('#app-screen').inner_text(); ck('BJ14 publish leaves sale price unchanged','Giá bán' in tx and 'Không thay đổi' in tx)
 page.evaluate('stateByScreen["SCR-077"]="UNKNOWN";activeScreenId="SCR-077";render();'); tx=page.locator('#app-screen').inner_text(); ck('BJ14 UNKNOWN no blind retry','Không gửi lại lệnh công bố' in tx and page.locator('[data-val14-action="publish"]').count()==0)
 ck('No page JS errors',not errors); b.close()
# Documentation cross-chain facts.
t7=ROOT.parents[2]
# ROOT is html; find theme root via parents[2]? Verify using direct.
PRO=ROOT.parent
entry=(PRO/'contracts/entry-architecture.md').read_text(encoding='utf8')
ck('Cross-BJ chain kept outside Product UI','BJ03' in entry and 'BJ13' in entry and 'BJ14' in entry)
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Inventory Valuation Integration QA v1.5.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Validates the valuation chain without collapsing separate mutations: BJ03 initial valuation, BJ13 value-only late cost/dirty scope, BJ14 immutable calculation/publication; internal handoff remains architecture metadata.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'INVENTORY-VALUATION-INTEGRATION-QA-v1.5.0.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
 print('\n'.join(failed)); raise SystemExit(1)
