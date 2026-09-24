from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys

VERSION='3.8.3'
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'qa'
CAP=OUT/'v383-warehouse-home-captures'
CAP.mkdir(exist_ok=True)

def inline(root: Path) -> str:
    h=(root/'index.html').read_text(encoding='utf-8')
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
        p=root/fn.split('?')[0]
        rep=f'<style>\n{p.read_text(encoding="utf-8")}\n</style>' if p.exists() else ''
        h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',rep,h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
        p=root/fn.split('?')[0]
        h=h.replace(f'<script src="{fn}"></script>',f'<script>\n{p.read_text(encoding="utf-8")}\n</script>' if p.exists() else '')
    return h

checks=[]
def ck(name,ok,note=''):
    checks.append({'name':name,'pass':bool(ok),'note':note})

with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1600,'height':1100})
    page.set_default_timeout(6000)
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.set_content(inline(ROOT),wait_until='load',timeout=30000)

    ck('runtime version',page.evaluate('window.__VET45_PROTOTYPE__?.version')==VERSION,page.evaluate('window.__VET45_PROTOTYPE__?.version'))
    ck('two workbench modes preserved',page.locator('button[data-workbench-mode]').count()==2)
    page.locator('button[data-workbench-mode="theme"]').click()
    page.locator('[data-theme-app-route="inventory"]').click()

    ck('Warehouse Home remains task-driven',page.locator('.t380-warehouse-home').count()==1)
    ck('collapsed work queue shows three concrete tasks',page.locator('.t380-work-list .t380-work-item').count()==3)
    ck('work header owns one disclosure action',page.locator('.t380-section-title [data-t380-task-toggle]').count()==1)
    ck('collapsed disclosure copy is user-readable',page.locator('.t383-task-overview-action').inner_text().strip()=='Xem tất cả (5)')
    align=page.evaluate('''()=>{const h=document.querySelector('.t380-work-section .t380-section-title h2').getBoundingClientRect();const b=document.querySelector('.t383-task-overview-action').getBoundingClientRect();return {hc:(h.top+h.bottom)/2,bc:(b.top+b.bottom)/2}}''')
    ck('section title and disclosure are vertically aligned',abs(align['hc']-align['bc'])<=1.5,align)
    ck('old mixed action row is removed',page.locator('.t382-work-actions').count()==0)
    ck('start-new is one canonical Navigation List Row',page.locator('[data-t383-start-new][data-ds-component="DS v2 / List Row"][data-ds-prop-type="Navigation"]').count()==1)
    ck('start-new uses user language instead of system term',page.locator('[data-t383-start-new] strong').inner_text().strip()=='Bắt đầu việc mới' and 'Tạo thao tác' not in page.locator('#app-screen').inner_text())
    ck('start-new helper explains examples, not architecture',page.locator('[data-t383-start-new] small').inner_text().strip()=='Nhập hàng nhanh, kiểm kê hoặc xử lý hàng')
    page.locator('#device-preview').screenshot(path=str(CAP/'01-KHO-WORK-HIERARCHY.png'))

    page.locator('.t383-task-overview-action').click()
    ck('header disclosure expands to all five tasks',page.locator('.t380-work-list .t380-work-item').count()==5)
    ck('expanded disclosure becomes Thu gọn',page.locator('.t383-task-overview-action').inner_text().strip()=='Thu gọn')
    ck('start-new row remains after expansion',page.locator('[data-t383-start-new]').count()==1)
    page.locator('.t383-task-overview-action').click()
    ck('collapse returns to three tasks',page.locator('.t380-work-list .t380-work-item').count()==3)

    page.locator('[data-t383-start-new]').click()
    ck('manual chooser opens from Start new work row',page.locator('.t380-manual-sheet').count()==1)
    ck('sheet is titled Bắt đầu việc mới',page.locator('.t380-manual-sheet h3').inner_text().strip()=='Bắt đầu việc mới')
    ck('sheet keeps exactly four manual starts',page.locator('.t380-manual-sheet [data-t380-target-screen]').count()==4)
    ck('sheet has no explanatory helper or redundant Close CTA',page.locator('.t380-manual-sheet .t380-sheet-heading p').count()==0 and page.locator('.t380-manual-sheet button[data-t380-manual-close]').count()==0)
    page.locator('#device-preview').screenshot(path=str(CAP/'02-BAT-DAU-VIEC-MOI.png'))
    page.keyboard.press('Escape')
    ck('Escape dismisses manual chooser',page.locator('.t380-manual-sheet').count()==0)

    page.locator('[data-t381-catalog-open]').click()
    ids=page.locator('[data-t381-catalog-flow]').evaluate_all('(els)=>els.map(e=>e.dataset.t381CatalogFlow)')
    ck('catalog still represents all 17 BJ + CAP-01',len(ids)==18 and len(set(ids))==18 and 'CAP-01' in ids,ids)
    ck('catalog has no explanatory badges',page.locator('.t381-catalog-screen .ds24-badge').count()==0)
    uif04=page.locator('[data-t381-catalog-flow="UIF-04"]')
    ck('context-only reservation uses canonical Disabled List Row',uif04.count()==1 and uif04.is_disabled() and uif04.get_attribute('data-ds-prop-state')=='Disabled')
    ck('context-only reservation explains its source in helper text',uif04.locator('small').inner_text().strip()=='Thực hiện từ chi tiết đơn bán')
    ck('disabled context-only row cannot be routed directly',uif04.get_attribute('data-theme-entry-flow') is None)
    page.locator('#device-preview').screenshot(path=str(CAP/'03-TAT-CA-CHUC-NANG-KHO-NO-BADGES.png'))
    uif04.scroll_into_view_if_needed()
    page.locator('#device-preview').screenshot(path=str(CAP/'04-CONTEXTUAL-DISABLED-ROW.png'))
    page.locator('[data-t381-catalog-back]').click()

    geom=page.evaluate('''()=>{const a=document.querySelector('#app-screen'),r=a.getBoundingClientRect(),d=document.querySelector('.device-preview').getBoundingClientRect(),c=a.querySelector('.app-content');return {rw:r.width,rh:r.height,dw:d.width,dh:d.height,x:a.scrollWidth-a.clientWidth,cx:c.scrollWidth-c.clientWidth}}''')
    ck('canonical 402x874 product / 418x890 review frame preserved',abs(geom['rw']-402)<.75 and abs(geom['rh']-874)<.75 and abs(geom['dw']-418)<.75 and abs(geom['dh']-890)<.75,geom)
    ck('Warehouse Home has no horizontal overflow',geom['x']<=.75 and geom['cx']<=.75,geom)
    ck('no browser page errors',len(errors)==0,errors[:10])
    browser.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':VERSION,'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/f'WAREHOUSE-HOME-CLARITY-QA-v{VERSION}.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=[f'# Warehouse Home Clarity QA — v{VERSION}','',f'**Result: {status} · {res["passed"]}/{res["total"]} PASS**','',
    '- `Việc của bạn` owns its disclosure action in the section header (`Xem tất cả (5)` / `Thu gọn`).',
    '- `Bắt đầu việc mới` is a canonical Navigation List Row, not a competing CTA beside disclosure.',
    '- The manual chooser uses the same user-facing name and keeps only four genuinely user-initiated starts.',
    '- Full-function catalog removes explanatory badges; contextual reservation is represented by canonical Disabled state.',
    '', '## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': {x["note"]}' if x['note'] and not x['pass'] else '') for x in checks]
(OUT/f'WAREHOUSE-HOME-CLARITY-QA-v{VERSION}.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,res['passed'],'/',res['total'],'errors',len(errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
sys.exit(0 if status=='PASS' else 1)
