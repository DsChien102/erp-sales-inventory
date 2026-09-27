from pathlib import Path
from playwright.sync_api import sync_playwright
import re,json
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8'); styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    q=ROOT/fn
    if q.exists(): styles.append(q.read_text(encoding='utf-8'))
    idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
    q=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{q.read_text(encoding="utf-8")}</script>' if q.exists() else '')
checks=[]; errors=[]
def ck(name,cond,detail=''): checks.append({'name':name,'pass':bool(cond),'detail':detail})
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load')
    # Quick basis validation + accessible controls
    p.evaluate("activeFlowId='UIF-03';activeScreenId='SCR-014';render()")
    p.locator('[data-v313-val03-receipt="VAL03-R2"]').click(); p.locator('[data-v313-val03-add-basis]').click()
    p.locator('[data-v313-val03-sheet="save"]').click()
    ck('Quick basis invalid save remains in sheet',p.locator('.v313-sheet').count()==1 and p.locator('.v313-sheet.has-validation-error').count()==1)
    a11y=p.evaluate("""() => Array.from(document.querySelectorAll('.v313-sheet button,.v313-sheet input,.v313-sheet select')).filter(e=>e.getBoundingClientRect().width>0).map(e=>{let name=e.getAttribute('aria-label')||e.textContent.trim()||e.getAttribute('placeholder')||''; if(!name && e.closest('label')) name=e.closest('label').innerText.trim(); return {tag:e.tagName,name:name.trim(),h:e.getBoundingClientRect().height};})""")
    ck('Quick basis controls have accessible names',all(x['name'] for x in a11y),json.dumps(a11y,ensure_ascii=False))
    ck('Quick basis controls keep 44px target',all(x['h']>=43.5 for x in a11y),json.dumps(a11y,ensure_ascii=False))
    # save valid basis then stale source before confirm
    p.locator('[data-v313-basis-price]').fill('110000'); p.locator('[data-v313-basis-source]').fill('Xác nhận NCC'); p.locator('[data-v313-basis-reason]').fill('Nhập nhanh chưa có chứng từ mua'); p.locator('[data-v313-val03-sheet="save"]').click(); p.locator('[data-v313-val03-review]').click()
    p.evaluate("val03Current().sourceVersion = Number(val03Current().sourceVersion||0)+1")
    p.locator('[data-v313-val03-confirm]').click()
    ck('BJ03 stale source blocks commit',p.evaluate("activeScreenId==='SCR-017' && stateByScreen['SCR-017']==='SOURCE_CHANGED'"),str(p.evaluate("({screen:activeScreenId,state:stateByScreen['SCR-017']})")))
    # BJ13 stale source
    p.evaluate("activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';render()")
    p.locator('[data-v313-val13-task="LC13-004"]').click(); p.locator('[data-v313-val13-review]').click(); p.evaluate("val13Current().sourceVersion = Number(val13Current().sourceVersion||0)+1"); p.locator('[data-v313-val13-confirm]').click()
    ck('BJ13 stale source blocks adjustment',p.evaluate("activeScreenId==='SCR-088' && stateByScreen['SCR-088']==='SOURCE_CHANGED'"),str(p.evaluate("({screen:activeScreenId,state:stateByScreen['SCR-088']})")))
    # BJ14 changed input before publish
    p.evaluate("activeFlowId='UIF-14';activeScreenId='SCR-072';stateByScreen['SCR-072']='READY';render()")
    p.locator('[data-v313-val14-run="COST-0826"]').click(); p.locator('[data-v313-val14-open-publish]').click(); p.evaluate("val14Current().runInputHash='CHANGED-AFTER-REVIEW'"); p.locator('[data-v313-val14-publish]').click()
    ck('BJ14 changed input blocks publication',p.evaluate("activeScreenId==='SCR-074' && stateByScreen['SCR-074']==='INPUT_CHANGED'"),str(p.evaluate("({screen:activeScreenId,state:stateByScreen['SCR-074']})")))
    # No hidden active route to retired screens
    route=p.evaluate("flowCatalog.filter(f=>['UIF-03','UIF-13','UIF-14'].includes(f.id)).flatMap(f=>f.screens)")
    ck('No retired valuation route',all(x not in route for x in ['SCR-016','SCR-018','SCR-087','SCR-073','SCR-075','SCR-076']),str(route))
    b.close()
status='PASS' if all(x['pass'] for x in checks) and not errors else 'FAIL'
payload={'status':status,'checks':checks,'errors':errors}
(OUT/'VALUATION-ADVERSARIAL-QA-v4.1.0.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Valuation Adversarial QA v4.1.0','',f'**Result: {status}**','']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']} — {x['detail']}" for x in checks]+['',f'- Browser errors: {len(errors)}']
(OUT/'VALUATION-ADVERSARIAL-QA-v4.1.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(status,'checks',sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors))
if status!='PASS':
    print([x for x in checks if not x['pass']],errors); raise SystemExit(1)
