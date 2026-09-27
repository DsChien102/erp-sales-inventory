from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8');styles=[]
for fn in re.findall(r'<link rel=\"stylesheet\" href=\"([^\"]+\.css)\"',idx):
    q=ROOT/fn
    if q.exists(): styles.append(q.read_text(encoding='utf-8'))
    idx=re.sub(rf'\s*<link rel=\"stylesheet\" href=\"{re.escape(fn)}\"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src=\"([^\"]+\.js(?:\?[^\"]*)?)\"[^>]*>\s*</script>',html):
    q=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src=\"{fn}\"></script>', '<script>'+q.read_text(encoding='utf-8')+'</script>' if q.exists() else '')
checks=[]; errors=[]
def ck(name,cond,detail=''): checks.append({'name':name,'pass':bool(cond),'detail':detail})
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage','--allow-file-access-from-files'])
    p=b.new_page(viewport={'width':1440,'height':1100});p.set_default_timeout(6000);p.on('pageerror',lambda e:errors.append(str(e)))
    # Direct deep-link must render the latest layer on first paint.
    direct=html.replace('<script>/* VET45 Theme 7 v4.3.1',"<script>activeFlowId='UIF-03';activeScreenId='SCR-015';stateByScreen['SCR-015']='READY';render();</script><script>/* VET45 Theme 7 v4.3.1",1);p.set_content(direct,wait_until='load')
    ck('Direct link uses v4.3 renderer',p.locator('[data-v430-val03-review]').count()==1 and p.locator('[data-v313-val03-review]').count()==0)
    ck('No legacy BJ03 title on direct link','Chọn hàng cần xác nhận giá' not in p.locator('#app-screen').inner_text())
    # BJ03 quick direct basis: open, type, scroll, toggle tax, preserve values, save, review, commit.
    p.evaluate("activeFlowId='UIF-03';activeScreenId='SCR-014';stateByScreen['SCR-014']='READY';render()")
    p.locator('[data-v430-val03-receipt="VAL03-R2"]').click(); ck('BJ03 Quick opens canonical SCR-015',p.evaluate('activeScreenId')=='SCR-015')
    p.locator('[data-v430-val03-add-basis]').click();
    ck('Quick basis uses DS Form Sheet',p.locator('.v430-form-sheet[data-ds-component="DS v2 / Form Sheet"]').count()==1)
    ck('Form sheet has fixed Sticky Footer',p.locator('.v430-sheet-footer[data-ds-component="DS v2 / Sticky Footer"]').count()==1)
    price=p.locator('[data-v430-basis-price]'); source=p.locator('[data-v430-basis-source]'); reason=p.locator('[data-v430-basis-reason]')
    price.click();price.fill('110000');source.fill('Xác nhận NCC');reason.fill('Nhập nhanh chưa có chứng từ mua')
    p.locator('[data-v430-tax-mode="EXCLUDED"]').click();
    ck('Input values persist after tax mode change',price.input_value()=='110000' and source.input_value()=='Xác nhận NCC' and reason.input_value()=='Nhập nhanh chưa có chứng từ mua')
    p.locator('[data-v430-basis-tax]').fill('5000')
    p.locator('.v430-form-sheet__body').evaluate('(e)=>e.scrollTop=e.scrollHeight')
    ck('Save remains visible while form body scrolls',p.locator('[data-v430-val03-sheet="save"]').is_visible())
    p.locator('[data-v430-val03-sheet="save"]').click(); ck('Direct basis saved and selection enabled',p.locator('[data-v430-val03-review]').is_enabled())
    p.locator('[data-v430-val03-review]').click();ck('BJ03 review SCR-017',p.evaluate('activeScreenId')=='SCR-017')
    p.locator('[data-v430-val03-confirm]').click();ck('BJ03 result SCR-019',p.evaluate('activeScreenId')=='SCR-019')
    # Document conflict must be read-only warning, no source-radio conflict chooser.
    p.evaluate("activeScreenId='SCR-014';render()")
    p.locator('[data-v430-val03-receipt="VAL03-R1"]').click(); txt=p.locator('#app-screen').inner_text().lower()
    ck('Document conflict shown as warning','cần đối chiếu' in txt)
    ck('No commercial source radio chooser',p.locator('[data-val03-source], input[type=radio]').count()==0)
    # BJ13 merged canonical screen; own target/method handlers.
    p.evaluate("activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';render()")
    p.locator('[data-v430-val13-task="LC13-004"]').click();ck('BJ13 opens canonical SCR-086',p.evaluate('activeScreenId')=='SCR-086')
    ck('Negative adjustment visible','350.000' in p.locator('#app-screen').inner_text())
    if p.locator('[data-v430-val13-method]').count():
        sel=p.locator('[data-v430-val13-method]')
        opts=sel.locator('option').evaluate_all('(o)=>o.map(x=>x.value).filter(Boolean)')
        if opts: sel.select_option(opts[0])
    if not p.locator('[data-v430-val13-review]').is_enabled() and p.locator('[data-v430-val13-target]').count():
        p.locator('[data-v430-val13-target]').first.click()
    ck('BJ13 review action becomes available',p.locator('[data-v430-val13-review]').is_enabled())
    p.locator('[data-v430-val13-review]').click();ck('BJ13 review SCR-088',p.evaluate('activeScreenId')=='SCR-088')
    p.locator('[data-v430-val13-confirm]').click();ck('BJ13 result SCR-089',p.evaluate('activeScreenId')=='SCR-089')
    # BJ14: method is policy/read-only, publication uses Confirmation Sheet.
    p.evaluate("activeFlowId='UIF-14';activeScreenId='SCR-072';stateByScreen['SCR-072']='READY';render()")
    ck('BJ14 list uses new layer',p.locator('[data-v430-val14-run]').count()>0)
    p.locator('[data-v430-val14-run="COST-0826"]').click();ck('Ready run opens SCR-074',p.evaluate('activeScreenId')=='SCR-074')
    ck('Costing method is not user-selectable',p.locator('[data-val14-kind], input[type=radio]').count()==0)
    p.locator('[data-v430-val14-open-publish]').click();
    ck('Publish uses DS Confirmation Sheet',p.locator('.v430-confirmation[data-ds-component="DS v2 / Confirmation Sheet"]').count()==1)
    ck('Publish does not use generic VBottomSheet',p.locator('.v313-sheet[data-ds-component="VBottomSheet"]').count()==0)
    p.locator('[data-v430-val14-publish]').click();ck('BJ14 result SCR-077',p.evaluate('activeScreenId')=='SCR-077')
    # Legacy navigation calls are redirected to canonical merged screens.
    for flow,legacy,canon in [('UIF-03','SCR-016','SCR-015'),('UIF-13','SCR-087','SCR-086'),('UIF-14','SCR-073','SCR-074'),('UIF-14','SCR-075','SCR-074'),('UIF-14','SCR-076','SCR-074')]:
        p.evaluate(f"activeFlowId='{flow}';navigate('{legacy}')")
        ck(f'{legacy} redirects to {canon}',p.evaluate('activeScreenId')==canon,p.evaluate('activeScreenId'))
    p.evaluate("activeFlowId='UIF-03';navigate('SCR-018')")
    ck('SCR-018 hands off to BJ13 canonical queue',p.evaluate("activeFlowId==='UIF-13' && activeScreenId==='SCR-085'"),p.evaluate("activeFlowId+' '+activeScreenId"))
    b.close()
status='PASS' if all(x['pass'] for x in checks) and not errors else 'FAIL'
payload={'status':status,'version':'4.3.1','checks':checks,'errors':errors}
(OUT/'VALUATION-FLOW-E2E-v4.3.1.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'VALUATION-FLOW-E2E-v4.3.1.md').write_text('\n'.join(['# Valuation Flow E2E v4.3.1','',f'**Result: {status}**','']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']} {x['detail']}" for x in checks]+['',f'- Browser errors: {len(errors)}'])+'\n',encoding='utf-8')
print(status,'checks',sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors))
if status!='PASS':
    print([x for x in checks if not x['pass']],errors);raise SystemExit(1)
