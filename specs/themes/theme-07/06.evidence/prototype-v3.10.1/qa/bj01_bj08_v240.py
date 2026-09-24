from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
data=(ROOT/'workbench-data.js').read_text(); fmap=(ROOT/'figma-ds-runtime-map.js').read_text(); app=(ROOT/'app.js').read_text()
html=(idx.replace('<link rel="stylesheet" href="figma-ds.exact.css" />','').replace('<link rel="stylesheet" href="figma-ds.styles.exact.css" />','').replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>'))
checks=[]
def chk(name,ok,note=''):
    checks.append({'name':name,'pass':bool(ok),'note':note})

# Static DS/token gate for the v2.4 block.
styles=(ROOT/'styles.css').read_text(); start=styles.find('.ds24-context'); block=styles[start:]
chk('No raw hex colors in v2.4 DS/Product block', not re.search(r'#[0-9a-fA-F]{3,8}', block))
chk('No raw rgb/rgba colors in v2.4 DS/Product block', not re.search(r'rgba?\(', block))
chk('Canonical semantic sheet radius consumed', '--vet45-v2-radius-sheet' in block)
chk('Canonical border width token consumed', '--vet45-v2-border-width-thin' in block)
chk('Disabled uses opacity token', '--vet45-v2-opacity-disabled' in block)
chk('BJ01 Search/Filter Header uses live Figma node', 'data-figma-node="547:2306"' in app)
chk('BJ01/BJ08 List Row uses live Figma node', 'data-figma-node="525:519"' in app)
chk('BJ08 Numeric keypad uses live Figma node', 'data-figma-node="1829:6657"' in app)
chk('BJ08 Confirmation Sheet uses live Figma node', 'data-figma-node="550:1058"' in app)
chk('Legacy Theme7TimeField removed from active BJ08 renderer', 'Theme7TimeField' not in app[app.find('function render042IC08'):app.find('function ic09StatusTone')])

errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e: errors.append(str(e))); p.set_content(html,wait_until='load')
    def set_screen(flow,screen,state):
        p.evaluate('([f,s,st])=>{activeFlowId=f;activeScreenId=s;stateByScreen[s]=st;render();}',[flow,screen,state])
    # BJ01 list semantics/search/filter.
    set_screen('UIF-01','SCR-001','READY')
    chk('BJ01 list has one search field', p.locator('[data-bj01-search]').count()==1)
    chk('BJ01 list has five canonical filter chips', p.locator('[data-bj01-filter][data-ds-component="VChip"]').count()==5)
    chk('BJ01 product results are direct List Rows', p.locator('[data-theme-component="Theme7InventoryProductRow"][data-ds-component="DS v2 / List Row"]').count()>=1)
    chk('BJ01 has no legacy Tra cứu/Cần chú ý tabs', 'Tra cứu' not in p.locator('#app-screen').inner_text() and 'Cần chú ý' not in p.locator('#app-screen').inner_text())
    # query and row navigation
    p.locator('[data-bj01-search]').fill('amox'); p.wait_for_timeout(50)
    chk('BJ01 search filters runtime results', p.locator('[data-bj01-product]:not([hidden])').count()==1 and 'Amox 500' in p.locator('#app-screen').inner_text())
    p.locator('[data-bj01-product="INV-AMX"]').click();
    chk('BJ01 whole-row navigation goes to SCR-003', p.evaluate('activeScreenId')=='SCR-003')
    txt=p.locator('#app-screen').inner_text()
    chk('BJ01 detail has single primary Khả dụng metric', p.locator('.ds24-metric > span').filter(has_text='Khả dụng').count()==1)
    chk('BJ01 detail has no mutation footer', p.locator('#app-screen .app-actions').count()==0)
    # Lot overlay on a lot-tracked product.
    p.evaluate("()=>{bj01SelectedProductId='P-001';activeScreenId='SCR-003';stateByScreen['SCR-003']='READY';render();}")
    if p.locator('[data-bj01-lot]').count():
        p.locator('[data-bj01-lot]').first.click();
        chk('BJ01 LOT detail is contextual overlay', p.locator('[data-theme-component="Theme7ContextSheet"][role="dialog"]').count()==1)
    else: chk('BJ01 LOT detail is contextual overlay',False,'No LOT row fixture rendered')
    # BJ08 blind count invariant.
    set_screen('UIF-08','SCR-044','BLIND_COUNT')
    dom=p.locator('#app-screen').inner_text().lower(); htmlfrag=p.locator('#app-screen').inner_html().lower()
    forbidden=['số sổ','book_quantity','chênh lệch']
    chk('BJ08 blind count does not render book quantity data', 'book_quantity' not in htmlfrag and p.locator('.ds24-info-row').filter(has_text='Sổ').count()==0)
    chk('BJ08 quantity entry opens Numeric Keypad Sheet', p.locator('[data-ic08-keypad-open]').count()>=1)
    p.locator('[data-ic08-keypad-open]').first.click();
    chk('BJ08 Numeric Keypad is canonical DS overlay', p.locator('[data-ds-component="VNumericKeypadSheet"][data-figma-node="1829:6657"]').count()==1)
    p.locator('[data-ic08-action="keypad-cancel"]').first.click()
    # Submit first -> recount.
    p.locator('[data-ic08-action="submit-first"]').click();
    chk('BJ08 first-submit uses canonical confirmation', p.locator('[data-ds-component="DS v2 / Confirmation Sheet"]').count()==1)
    p.locator('[data-ic08-action="confirm-submit-first"]').click();
    chk('BJ08 first submit goes to recount', p.evaluate('activeScreenId')=='SCR-045')
    # Evidence is status, not invented input.
    chk('BJ08 recount has no invented evidence textarea', p.locator('#app-screen textarea').count()==0)
    chk('BJ08 recount has editable recount quantities', p.locator('[data-ic08-keypad-open^="recount:"]').count()>=1)
    # Maker submit ends in read-only pending approval.
    p.locator('[data-ic08-action="submit-recount"]').click(); p.locator('[data-ic08-action="confirm-submit-recount"]').click();
    chk('BJ08 maker submit returns to maker read-only pending state', p.evaluate('activeScreenId')=='SCR-042' and p.evaluate("stateByScreen['SCR-042']")=='PENDING_APPROVAL')
    chk('BJ08 maker pending state has no approve control', p.locator('[data-ic08-action="approve"]').count()==0)
    # Independent approver surface.
    set_screen('UIF-08','SCR-046','APPROVAL_REQUIRED')
    chk('BJ08 approver cannot edit count', p.locator('[data-ic08-keypad-open]').count()==0 and p.locator('input').count()==0)
    chk('BJ08 approval has approve and request-review only', p.locator('[data-ic08-action="approve"]').count()==1 and p.locator('[data-ic08-action="request-review"]').count()==1 and p.locator('[data-ic08-action="cancel-open"]').count()==0)
    p.locator('[data-ic08-action="request-review"]').click();
    chk('BJ08 request-review requires reason', p.locator('[data-ic08-review-reason]').count()==1 and p.locator('[data-ic08-action="confirm-request-review"]').is_disabled())
    p.locator('[data-ic08-review-reason]').fill('Kiểm lại lô thực tế'); p.locator('[data-ic08-action="confirm-request-review"]').click();
    chk('BJ08 request-review returns to recount and keeps non-terminal session', p.evaluate('activeScreenId')=='SCR-045')
    # Terminal result is result-only.
    set_screen('UIF-08','SCR-047','COMPLETED')
    chk('BJ08 completed result has no mutation CTA', p.locator('[data-ic08-action="approve"],[data-ic08-action="cancel-open"],[data-ic08-action="submit-recount"]').count()==0)
    set_screen('UIF-08','SCR-047','UNKNOWN')
    chk('BJ08 UNKNOWN offers verification handoff, not blind retry', p.locator('[data-ic08-action="verify-result"]').count()==1 and 'Thử lại' not in p.locator('#app-screen').inner_text())
    # Width/overflow gate for target screens.
    ov=[]
    for f,s,st in [('UIF-01','SCR-001','READY'),('UIF-01','SCR-003','READY'),('UIF-08','SCR-042','READY'),('UIF-08','SCR-043','READY'),('UIF-08','SCR-044','BLIND_COUNT'),('UIF-08','SCR-045','RECOUNT_REQUIRED'),('UIF-08','SCR-046','APPROVAL_REQUIRED'),('UIF-08','SCR-047','COMPLETED')]:
        set_screen(f,s,st); x=p.evaluate("()=>{const x=document.querySelector('#app-screen .v-page-scaffold');return x?x.scrollWidth-x.clientWidth:999}"); ov.append((s,x))
    chk('BJ01/BJ08 target screens have no horizontal overflow', all(x<=0.5 for _,x in ov), str(ov))
    b.close()
chk('No browser page errors during target QA', not errors, '; '.join(errors))
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'checks':checks,'passed':sum(x['pass'] for x in checks),'total':len(checks),'browserErrors':errors}
(OUT/'BJ01-BJ08-FIGMA-DS-QA-v2.4.0.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ01 + BJ08 Figma DS / Product QA — v2.4.0','',f'**Result: {status} · {res["passed"]}/{res["total"]} checks**','']
for x in checks: lines.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] else ''))
(OUT/'BJ01-BJ08-FIGMA-DS-QA-v2.4.0.md').write_text('\n'.join(lines)+'\n')
print(status,res['passed'],res['total'])
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL:',x['name'],x['note'])
    raise SystemExit(1)
