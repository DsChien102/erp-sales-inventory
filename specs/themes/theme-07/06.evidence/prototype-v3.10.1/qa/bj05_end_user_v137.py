from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent; SHOTS=OUT/'screenshots-v1.3.7'; SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf8');css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8');data=(ROOT/'workbench-data.js').read_text(encoding='utf8');app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]
def check(name,cond): checks.append((name,bool(cond)))
def show(page,screen,state='READY'):
    page.evaluate('(x)=>{activeFlowId="UIF-05";activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'s':screen,'st':state})
def text(page): return page.locator('#app-screen').inner_text()
def shot(page,name): page.locator('#device-preview').screenshot(path=str(SHOTS/f'{name}.png'))
def fresh(page):
    page.goto('about:blank');page.set_content(html,wait_until='load');page.wait_for_timeout(80);page.evaluate('activeFlowId="UIF-05";activeScreenId="SCR-025";stateByScreen["SCR-025"]="READY";render();')
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);page=b.new_page(viewport={'width':1200,'height':1000});errors=[];page.on('pageerror',lambda e: errors.append(str(e)));fresh(page)
    # Queue: default all, correct order, filtering, live no-result.
    chips=page.locator('[data-io05-filter]');check('Queue default filter is Tất cả',chips.nth(0).get_attribute('data-io05-filter')=='ALL' and 'is-active' in (chips.nth(0).get_attribute('class') or ''));check('Queue chip order is Tất cả/Cần lấy/Đang chờ',[chips.nth(i).inner_text() for i in range(chips.count())]==['Tất cả','Cần lấy','Đang chờ']);check('Queue all shows actionable and waiting','Đại lý An Phú' in text(page) and 'Phòng khám Minh Tâm' in text(page));shot(page,'BJ05-SCR025-all')
    page.click('[data-io05-filter="ACTIONABLE"]');check('Cần lấy filters source-waiting out','Đại lý An Phú' in text(page) and 'Phòng khám Minh Tâm' not in text(page));page.click('[data-io05-filter="ALL"]');q=page.locator('[data-io05-search]');q.fill('khong-ton-tai');check('Live search has no-result state','Không tìm thấy đơn phù hợp' in text(page));q.fill('')
    # Order-scoped data: opening waiting order must never show other order lines.
    page.click('[data-io05-order="SO-260827-24"]');t=text(page);check('Waiting order shows its own customer/lines','Phòng khám Minh Tâm' in t and 'Amox 500' in t and 'Vitamin ADE' in t);check('Waiting order does not leak first order lines','Nobivac DHPPi' not in t and 'Găng tay khám Nitrile' not in t);check('Waiting order has no handover CTA',page.locator('[data-io05-action="review-handover"]').count()==0);check('Waiting item rows are read-only without navigation affordance',page.locator('#app-screen .io-product-row [data-ds-prop-icon="VIcons.chevronRight"]').count()==0);shot(page,'BJ05-SCR026-waiting-order')
    # Actionable order initial fixture is truly in progress, not falsely complete.
    page.evaluate('navigate("SCR-025")');page.click('[data-io05-filter="ALL"]');page.click('[data-io05-order="SO-260827-21"]');t=text(page);check('Actionable order is in-progress fixture','12/20 hộp' in t and '0/6 hộp' in t);check('Overview does not repeat success badge on untouched line','Chưa lấy' not in t);shot(page,'BJ05-SCR026-in-progress')
    # LOT override: real click/focus/type, no preselect, details, reset old picked evidence.
    page.click('[data-io05-line="PK-21-01"]');page.click('[data-io05-open-override="AL-21-01"]');ta=page.locator('[data-io05-override-reason]');ta.click();ta.type('Lô đang cầm không còn phù hợp');check('Override reason accepts real click/focus/type',ta.input_value()=='Lô đang cầm không còn phù hợp');check('Override does not preselect alternative',page.locator('.io-choice-row.is-selected').count()==0);option=page.locator('[data-io05-select-lot="DH2509"]');check('Alternative LOT shows expiry and availability','HSD 30/09/2027' in option.inner_text() and 'Có thể lấy 18 hộp' in option.inner_text());shot(page,'BJ05-SCR027-override-sheet')
    page.click('[data-io05-select-lot="DH2509"]');page.click('[data-io05-action="confirm-lot-override"]');t=text(page);check('Override resets picked evidence',page.locator('[data-io05-picked-allocation="AL-21-01"]').input_value()=='0');check('Override gives physical return/repick instruction','Trả lại 4 hộp lô DH2507' in t and 'lấy 4 hộp lô DH2509' in t);show(page,'SCR-026','READY');check('Unresolved physical correction blocks handover',page.locator('[data-io05-action="review-handover"]').is_disabled());
    # Complete correction then handover becomes available.
    page.click('[data-io05-line="PK-21-01"]');page.locator('[data-io05-picked-allocation="AL-21-01"]').fill('4');page.click('[data-io05-action="save-pick"]');check('Completed physical correction clears blocker',not page.locator('[data-io05-action="review-handover"]').is_disabled())
    # Stale recovery uses same physical model and resets affected pick.
    fresh(page);page.evaluate('io05SelectedOrderId="SO-260827-21";io05StaleAppliedForOrder={};activeScreenId="SCR-026";stateByScreen["SCR-026"]="STALE_RECOVERED";render();');t=text(page);check('Stale replaces LOT in actual row','DH2511: 0/4' in t);check('Stale tells user exactly what to return/take','Trả lại 4 hộp DH2507' in t and 'lấy 4 hộp DH2511' in t);check('Stale blocks handover until repick',page.locator('[data-io05-action="review-handover"]').is_disabled());shot(page,'BJ05-SCR026-stale-correction')
    # Partial handover: only picked allocations, totals/remaining, commit mutates state.
    fresh(page);page.evaluate('''let o=io05Orders[0];o.lines[0].allocations[0].picked=4;o.lines[0].allocations[1].picked=8;o.lines[1].allocations[0].picked=0;io05SelectedOrderId=o.id;io05ResetHandover(o);activeScreenId="SCR-028";stateByScreen["SCR-028"]="PARTIAL_ALLOWED";render();''');check('Review renders only picked allocations',page.locator('[data-io05-handover-allocation]').count()==2);check('Review keeps customer at irreversible commit','Đại lý An Phú' in text(page));page.locator('[data-io05-handover-allocation="AL-21-01"]').fill('2');page.locator('[data-io05-handover-allocation="AL-21-02"]').fill('0');t=text(page);check('Review updates handover summary','1 sản phẩm trong lần này' in t and 'Còn 2 sản phẩm chưa hoàn tất' in t);check('Normal physical rule is helper, not info banner','Chỉ xác nhận sau khi hàng đã thực sự được bàn giao.' in t and 'Chỉ xác nhận sau khi hàng đã thực sự rời kho' not in t);shot(page,'BJ05-SCR028-partial-review')
    page.click('[data-io05-action="confirm-handover"]');t=text(page);check('Partial result is explicit','Đã bàn giao một phần' in t and 'Nobivac DHPPi' in t and '2 hộp' in t and '2 sản phẩm cần tiếp tục' in t);check('Partial result has continuation CTA',page.locator('[data-io05-action="continue-remaining"]').count()==1);check('Result cannot Back to commit screen',page.locator('[data-back]').count()==0);remaining=page.evaluate('io05Orders[0].lines.reduce((s,l)=>s+l.required,0)');check('Partial commit consumes only actual handover quantity',remaining==24);shot(page,'BJ05-SCR029-partial-result')
    page.click('[data-io05-action="continue-remaining"]');check('Continuation goes to current order pick state',page.evaluate('activeScreenId')=='SCR-026' and 'Đại lý An Phú' in text(page))
    # Full completion removes task from active queue and result CTA is safe.
    fresh(page);page.evaluate('''let o=io05Orders[0];o.lines.forEach(l=>l.allocations.forEach(a=>a.picked=a.qty));io05SelectedOrderId=o.id;io05ResetHandover(o);activeScreenId="SCR-028";stateByScreen["SCR-028"]="PARTIAL_ALLOWED";render();''');page.click('[data-io05-action="confirm-handover"]');t=text(page);check('Full result is explicit','Đã bàn giao toàn bộ' in t and 'Còn lại\n0 sản phẩm' in t);check('Full result CTA returns queue',page.locator('[data-io05-action="result-to-queue"]').count()==1);check('Full result no Back',page.locator('[data-back]').count()==0);shot(page,'BJ05-SCR029-full-result');page.click('[data-io05-action="result-to-queue"]');check('Completed order removed from active queue','SO-260827-21' not in text(page))
    # Result state matrix must never collapse into success.
    fresh(page)
    for st,needle in [('REJECTED_EXECUTION','Chưa thể bàn giao'),('PERMISSION_DENIED','Không có quyền bàn giao'),('UNKNOWN','Đang xác minh kết quả')]:
        show(page,'SCR-029',st);check(f'{st} renders distinct result',needle in text(page));check(f'{st} has no back to commit',page.locator('[data-back]').count()==0)
        if st=='REJECTED_EXECUTION': shot(page,'BJ05-SCR029-rejected')
    show(page,'SCR-028','SOURCE_CHANGED');shot(page,'BJ05-SCR028-source-changed');check('SOURCE_CHANGED blocks commit',page.locator('[data-io05-action="confirm-handover"]').count()==0);check('SOURCE_CHANGED gives safe recovery CTA','Xem hàng cần lấy đã cập nhật' in text(page));
    # Mobile geometry and horizontal overflow.
    fresh(page)
    for scr,st in [('SCR-025','READY'),('SCR-026','READY'),('SCR-027','READY'),('SCR-028','PARTIAL_ALLOWED'),('SCR-029','COMPLETED')]:
        show(page,scr,st);g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})');check(f'{scr} no horizontal overflow',g['sw']<=g['cw']+1)
    check('No page JavaScript errors',not errors);b.close()
passed=sum(v for _,v in checks);failed=[n for n,v in checks if not v]
lines=['# BJ05 End-user / State QA v1.3.7','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Coverage: queue defaults/filter/search; per-order data scoping; real click/focus/type LOT override; alternative LOT information; physical pick invalidation for manual override/stale; partial/full handover; state mutation; result finality/state matrix; source-changed blocker; mobile overflow.','', '## Checks','']
lines += [f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines += ['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'BJ05-END-USER-QA-v1.3.7.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
    print('\n'.join(failed));raise SystemExit(1)
