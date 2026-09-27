from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf8'); css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8'); data=(ROOT/'workbench-data.js').read_text(encoding='utf8'); app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def fresh(page): page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(30); page.evaluate('activeFlowId="UIF-03";activeScreenId="SCR-014";render();')
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':1400,'height':1000}); page.on('pageerror',lambda e: errors.append(str(e)))
    fresh(page)
    # Queue semantics
    txt=page.locator('#app-screen').inner_text()
    ck('queue title business-facing', 'Hàng chờ xác nhận giá nhập' in txt)
    ck('queue shows actionable filter','Có thể xử lý' in txt)
    ck('queue shows waiting filter','Đang chờ' in txt)
    waiting=page.locator('.val03-work-row.is-waiting')
    ck('waiting receipt exists',waiting.count()>=1)
    ck('waiting receipt has no navigation attribute',waiting.locator('[data-val03-receipt]').count()==0)
    ck('aging visible','Chờ 19 ngày' in txt)
    # Enter R1, scope hierarchy
    page.click('[data-val03-receipt="VAL03-R1"]'); txt=page.locator('#app-screen').inner_text()
    ck('scope title self-explains price','Chọn hàng cần xác nhận giá' in txt)
    ck('lot identity visible','LÔ DH2507' in txt.upper() and 'LÔ DH2509' in txt.upper())
    ck('physical state visible','Đủ điều kiện bán' in txt and 'Cách ly' in txt)
    # select ready G1 slice, no immediate number field; progressive partial
    page.click('[data-val03-slice="VAL03-S1"]')
    ck('partial input hidden on default full selection',page.locator('[data-val03-qty="VAL03-S1"]').count()==0)
    ck('partial action visible',page.locator('[data-val03-partial="VAL03-S1"]').count()==1)
    page.click('[data-val03-partial="VAL03-S1"]'); ck('partial input appears on request',page.locator('[data-val03-qty="VAL03-S1"]').count()==1)
    page.locator('[data-val03-qty="VAL03-S1"]').fill('20')
    # ready-only happy path goes directly review
    page.click('[data-val03-action="open-review"]'); ck('happy path bypasses SCR016',page.evaluate('activeScreenId')=='SCR-017')
    txt=page.locator('#app-screen').inner_text(); ck('final review includes actual unit cost','Giá nhập thực tế' in txt and '/hộp' in txt)
    ck('final review includes exact LOT scope','LÔ DH2507' in txt.upper() and '20 HỘP' in txt.upper())
    ck('availability effect authoritative blocker example available in fixture','Khả dụng sau xác nhận' in txt)
    ck('provenance on demand action exists',page.locator('[data-val03-action="review-calculation"]').count()==1)
    # go back scope and select conflict G2, must route SCR016
    page.evaluate('activeScreenId="SCR-015";render();'); page.click('[data-val03-slice="VAL03-S4"]');
    ck('conflict changes primary CTA',page.locator('[data-val03-action="open-calculation"]').count()==1)
    page.click('[data-val03-action="open-calculation"]'); ck('conflict routes SCR016',page.evaluate('activeScreenId')=='SCR-016')
    ck('conflict source not preselected',page.locator('.val03-source-option.is-selected').count()==0)
    page.click('[data-val03-source="VAL03-G2"][data-val03-source-id="SUP"]'); page.locator('[data-val03-reason="VAL03-G2"]').fill('Xác nhận NCC mới nhất')
    ck('resolved conflict enables review',not page.locator('[data-val03-action="open-review"]').is_disabled())
    page.click('[data-val03-action="open-review"]'); txt=page.locator('#app-screen').inner_text()
    ck('new product official cost side effect visible','Sẽ khởi tạo' in txt)
    # test sellable blocker slice S2 effect not inferred +qty
    page.evaluate('activeScreenId="SCR-015";render();'); page.click('[data-val03-slice="VAL03-S2"]');
    # G2 stays selected/resolved, navigate review direct
    if page.locator('[data-val03-action="open-review"]').count(): page.click('[data-val03-action="open-review"]')
    txt=page.locator('#app-screen').inner_text(); ck('sellable blocker can yield zero availability','còn blocker chất lượng' in txt)
    # commit and partial same scope remains with version increment
    before=page.evaluate('val03Current().groups[0].slices[0].scopeVersion')
    page.click('[data-val03-action="confirm-value"]'); ck('commit reaches result',page.evaluate('activeScreenId')=='SCR-019')
    after=page.evaluate('val03Current().groups[0].slices[0].scopeVersion'); ck('scope version increments after partial commit',after==before+1)
    rem=page.evaluate('val03Current().groups[0].slices[0].pendingQty'); ck('partial remainder stays pending',rem==30)
    ck('same technical scope can continue after partial',page.locator('[data-val03-action="continue-remaining"]').count()==1)
    # mixed ready + missing: after committing ready, result must not dead-end into disabled scope
    fresh(page); page.click('[data-val03-receipt="VAL03-R4"]'); page.click('[data-val03-slice="VAL03-S7"]'); page.click('[data-val03-action="open-review"]'); page.click('[data-val03-action="confirm-value"]'); txt=page.locator('#app-screen').inner_text()
    ck('waiting-only remainder result explains waiting','Phần còn lại đang chờ căn cứ' in txt)
    ck('waiting-only remainder goes list, not continue',page.locator('[data-val03-action="continue-remaining"]').count()==0 and page.locator('[data-val03-action="result-to-queue"]').count()==1)
    # source stale blocks commit
    fresh(page); page.click('[data-val03-receipt="VAL03-R3"]'); page.click('[data-val03-slice="VAL03-S6"]'); page.click('[data-val03-action="open-review"]'); page.evaluate('val03ApplySourceUpdate("VAL03-G4",4.2)'); page.click('[data-val03-action="confirm-value"]'); ck('source stale blocks commit',page.evaluate('activeScreenId')=='SCR-017' and page.evaluate('stateByScreen["SCR-017"]')=='SOURCE_CHANGED')
    # UNKNOWN non blind retry wording
    page.evaluate('stateByScreen["SCR-019"]="UNKNOWN";activeScreenId="SCR-019";render();'); txt=page.locator('#app-screen').inner_text(); ck('UNKNOWN says no resubmit','Không gửi lại xác nhận' in txt); ck('UNKNOWN non-actionable status','Đang xác minh' in txt)
    # no errors / overflow on five screens
    for sid in ['SCR-014','SCR-015','SCR-016','SCR-017','SCR-019']:
        page.evaluate('(s)=>{activeScreenId=s;stateByScreen[s]="READY";render();}',sid); g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); ck(f'{sid} no horizontal overflow',g['sw']<=g['cw']+1)
    ck('No page JS errors',not errors); b.close()
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# BJ03 Inventory Valuation Foundation QA v1.4.4','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Covers actionable/waiting entry, identified LOT/state scope, progressive partial, happy-path bypass of SCR016, conflict resolution, unit-cost/effect review, partial second-confirmation readiness, waiting-only result, stale source and UNKNOWN finality.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines+=['','## Page errors']+[f'- {x}' for x in errors]
(OUT/'BJ03-FOUNDATION-QA-v1.4.4.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed: print('\n'.join(failed)); raise SystemExit(1)
