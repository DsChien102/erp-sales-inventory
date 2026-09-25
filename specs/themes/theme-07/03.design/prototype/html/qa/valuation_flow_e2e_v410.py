from pathlib import Path
from playwright.sync_api import sync_playwright
import re,json
ROOT=Path(__file__).resolve().parents[1];OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8');styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    q=ROOT/fn
    if q.exists():styles.append(q.read_text(encoding='utf-8'));idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
    q=ROOT/fn.split('?')[0];html=html.replace(f'<script src="{fn}"></script>',f'<script>{q.read_text(encoding="utf-8")}</script>' if q.exists() else '')
checks=[];errors=[]
def ck(name,cond,detail=''): checks.append({'name':name,'pass':bool(cond),'detail':detail})
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100});p.set_default_timeout(5000);p.on('pageerror',lambda e:errors.append(str(e)));p.set_content(html,wait_until='load')
    # BJ03 quick direct basis
    p.evaluate("activeFlowId='UIF-03';activeScreenId='SCR-014';stateByScreen['SCR-014']='READY';render()")
    p.locator('[data-v313-val03-receipt="VAL03-R2"]').click(); ck('BJ03 Quick opens SCR-015',p.evaluate('activeScreenId')=='SCR-015')
    ck('Quick shows add basis',p.locator('[data-v313-val03-add-basis]').count()==1)
    p.locator('[data-v313-val03-add-basis]').click();
    p.locator('[data-v313-basis-price]').fill('110000');p.locator('[data-v313-basis-source]').fill('Xác nhận NCC');p.locator('[data-v313-basis-reason]').fill('Nhập nhanh chưa có chứng từ mua');p.locator('[data-v313-val03-sheet="save"]').click()
    ck('Direct basis saved and selected',p.locator('[data-v313-val03-review]').is_enabled())
    p.locator('[data-v313-val03-review]').click();ck('BJ03 review screen',p.evaluate('activeScreenId')=='SCR-017')
    ck('No Official Cost copy','Official Cost' not in p.locator('#app-screen').inner_text() and 'đơn giá chính thức' not in p.locator('#app-screen').inner_text().lower())
    p.locator('[data-v313-val03-confirm]').click();ck('BJ03 completed',p.evaluate('activeScreenId')=='SCR-019');ck('Result says initial value','giá trị nhập ban đầu' in p.locator('#app-screen').inner_text().lower())
    # document conflict cannot choose arbitrary source
    p.evaluate("activeScreenId='SCR-014';render()")
    p.locator('[data-v313-val03-receipt="VAL03-R1"]').click();txt=p.locator('#app-screen').inner_text().lower();ck('Document conflict shown','cần đối chiếu' in txt);ck('No legacy basis radio',p.locator('[data-val03-source]').count()==0)
    # BJ13 signed negative adjustment
    p.evaluate("activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';render()")
    p.locator('[data-v313-val13-task="LC13-004"]').click();ck('BJ13 merged scope/allocation',p.evaluate('activeScreenId')=='SCR-086');txt=p.locator('#app-screen').inner_text();ck('Negative adjustment visible','− 350.000 đ' in txt or '- 350.000 đ' in txt)
    p.locator('[data-v313-val13-review]').click();ck('BJ13 review',p.evaluate('activeScreenId')=='SCR-088');p.locator('[data-v313-val13-confirm]').click();ck('BJ13 result',p.evaluate('activeScreenId')=='SCR-089');ck('Negative result semantic','giảm giá trị' in p.locator('#app-screen').inner_text().lower())
    # BJ14 policy & work-oriented flow
    p.evaluate("activeFlowId='UIF-14';activeScreenId='SCR-072';stateByScreen['SCR-072']='READY';render()")
    txt=p.locator('#app-screen').inner_text();ck('BJ14 work queue','Cập nhật giá vốn' in txt and 'Chốt giá vốn' in txt);ck('Tenant method not a chooser',p.locator('[data-val14-kind]').count()==0)
    p.locator('[data-v313-val14-run="COST-0903"]').click();ck('Dirty opens central screen',p.evaluate('activeScreenId')=='SCR-074');txt=p.locator('#app-screen').inner_text();ck('Method read-only','Bình quân cuối kỳ' in txt and p.locator('#app-screen select').count()==0)
    # Ready publication on existing run
    p.evaluate("activeScreenId='SCR-072';render()")
    p.locator('[data-v313-val14-run="COST-0826"]').click();ck('Ready run opens SCR074',p.evaluate('activeScreenId')=='SCR-074');ck('Compare secondary','Xem đối chiếu' in p.locator('#app-screen').inner_text())
    p.locator('[data-v313-val14-open-publish]').click();ck('Publication uses bottom sheet',p.locator('.v313-sheet[data-ds-component="VBottomSheet"]').count()==1)
    p.locator('[data-v313-val14-publish]').click();ck('Published result SCR077',p.evaluate('activeScreenId')=='SCR-077');ck('No sales-price leakage','giá bán' not in p.locator('#app-screen').inner_text().lower())
    # retired screens absent from active flow catalogs
    screens_active=p.evaluate("flowCatalog.filter(f=>['UIF-13','UIF-14'].includes(f.id)).flatMap(f=>f.screens)")
    ck('Retired screens removed from active flow',all(x not in screens_active for x in ['SCR-087','SCR-073','SCR-075','SCR-076']),str(screens_active))
    b.close()
status='PASS' if all(x['pass'] for x in checks) and not errors else 'FAIL'
(OUT/'VALUATION-FLOW-E2E-v4.1.0.json').write_text(json.dumps({'status':status,'checks':checks,'errors':errors},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Valuation Flow E2E v4.1.0','',f'**Result: {status}**','']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']} {x['detail']}" for x in checks]+['',f'- Browser errors: {len(errors)}']
(OUT/'VALUATION-FLOW-E2E-v4.1.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(status,'checks',sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors))
if status!='PASS':
    print([x for x in checks if not x['pass']],errors);raise SystemExit(1)
