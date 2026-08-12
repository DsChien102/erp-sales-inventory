from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys

VERSION='3.8.0'
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'qa'
CAP=OUT/'v380-task-driven-home-captures'
CAP.mkdir(exist_ok=True)

def inline(root: Path) -> str:
    h=(root/'index.html').read_text(encoding='utf-8')
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^"]*)?)"[^>]*>',h):
        p=root/fn.split('?')[0]
        rep=f'<style>\n{p.read_text(encoding="utf-8")}\n</style>' if p.exists() else ''
        h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',rep,h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^"]*)?)"[^>]*>\s*</script>',h):
        p=root/fn.split('?')[0]
        h=h.replace(f'<script src="{fn}"></script>',f'<script>\n{p.read_text(encoding="utf-8")}\n</script>' if p.exists() else '')
    return h

checks=[]
def ck(name,ok,note=''):
    checks.append({'name':name,'pass':bool(ok),'note':note})

with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1600,'height':1100})
    page.set_default_timeout(5000)
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.set_content(inline(ROOT),wait_until='load',timeout=30000)

    ck('runtime version',page.evaluate('window.__VET45_PROTOTYPE__?.version')==VERSION,page.evaluate('window.__VET45_PROTOTYPE__?.version'))
    ck('two workbench tabs preserved',page.locator('button[data-workbench-mode]').count()==2)
    ck('BJ/UIF remains default review mode',page.evaluate('document.body.dataset.workbenchMode')=='bj')

    page.locator('button[data-workbench-mode="theme"]').click()
    ck('full-theme mode still starts at Thêm',page.locator('#current-screen-name').inner_text()=='Thêm')
    page.locator('[data-theme-app-route="inventory"]').click()
    ck('Kho task-driven home reachable',page.locator('#current-screen-name').inner_text()=='Kho' and page.locator('.t380-warehouse-home').count()==1)

    visible_tasks=page.locator('.t380-work-list [data-t380-target-screen]').count()
    product_entries=page.locator('[data-theme-entry-flow]').count()
    ck('only three concrete work items are visible by default',visible_tasks==3,visible_tasks)
    ck('Product home has five direct choices total before expansion',product_entries==5,product_entries)
    ck('home does not expose old flat-hub catalog',page.locator('.t7-hub-frequent-list,.t7-hub-more,[data-theme-hub-toggle]').count()==0)
    body_text=page.locator('#app-screen').inner_text()
    ck('contextual/setup/recovery journey labels are absent from home',all(x not in body_text for x in ['Giữ hàng theo đơn bán','Hủy & sửa sai nghiệp vụ','Khởi tạo tồn đầu kỳ','Xác minh kết quả','Chính sách tồn & cận hạn']),body_text)
    ck('search + work + utility + one create CTA are present',page.locator('[data-t380-inventory-search]').count()==1 and page.locator('.t380-work-section').count()==1 and page.locator('.t380-utility-section').count()==1 and page.locator('[data-t380-manual-open]').count()==1)
    page.locator('#device-preview').screenshot(path=str(CAP/'01-KHO-WORK-CENTER.png'))

    # Inline work expansion must not create a route.
    url_before=page.url
    page.locator('[data-t380-task-toggle]').click()
    ck('work list expands inline to five concrete tasks',page.locator('.t380-work-list [data-t380-target-screen]').count()==5)
    ck('task expansion does not push navigation',page.url==url_before and 'app=inventory' in page.url,page.url)
    ck('expanded home still avoids exhaustive Theme catalog',page.locator('[data-theme-entry-flow]').count()==7,page.locator('[data-theme-entry-flow]').count())
    page.locator('#device-preview').screenshot(path=str(CAP/'02-KHO-WORK-EXPANDED.png'))
    page.locator('[data-t380-task-toggle]').click()

    # Concrete task direct entry: receipt skips operation catalog and returns directly to Kho.
    page.locator('[data-t380-context="receipt-document"]').click()
    ck('receipt work item routes directly to existing BJ02 work screen',page.evaluate('activeFlowId')=='UIF-02' and page.evaluate('activeScreenId')=='SCR-009' and page.evaluate('flowMode')=='document')
    ck('direct task entry Back returns to Kho',page.locator('[data-t380-back-home]').count()==1)
    page.locator('[data-t380-back-home]').click()
    ck('receipt task Back lands on Kho work center',page.locator('.t380-warehouse-home').count()==1)

    # Inventory search acts as accelerator into BJ01 and preserves query.
    search=page.locator('[data-t380-inventory-search]')
    search.fill('Amox')
    search.press('Enter')
    ck('inventory search opens BJ01 with the query',page.evaluate('activeFlowId')=='UIF-01' and page.evaluate('activeScreenId')=='SCR-001' and page.evaluate('bj01Query')=='Amox')
    ck('search direct entry Back returns to Kho',page.locator('[data-t380-back-home]').count()==1)
    page.locator('[data-t380-back-home]').click()

    # Manual action sheet exposes only genuinely user-initiated actions.
    page.locator('[data-t380-manual-open]').click()
    ck('manual action opens canonical bottom sheet',page.locator('.t380-manual-sheet[data-ds-component="VBottomSheet"]').count()==1)
    manual=page.locator('.t380-manual-sheet [data-t380-target-screen]')
    ck('manual action sheet contains exactly four actions',manual.count()==4,manual.count())
    manual_labels=manual.locator('.ds24-list-row__copy strong').all_inner_texts()
    ck('manual action labels are the intended four',manual_labels==['Nhập hàng nhanh','Tạo phiên kiểm kê','Chuyển tình trạng hàng','Tạo yêu cầu tiêu hủy'],manual_labels)
    page.locator('#device-preview').screenshot(path=str(CAP/'03-TAO-THAO-TAC.png'))
    page.locator('[data-t380-context="quick-receipt"]').click()
    ck('quick receipt action routes directly to SCR-008',page.evaluate('activeFlowId')=='UIF-02' and page.evaluate('activeScreenId')=='SCR-008' and page.evaluate('flowMode')=='quick')
    ck('manual direct entry Back returns to Kho',page.locator('[data-t380-back-home]').count()==1)
    page.locator('[data-t380-back-home]').click()

    # Count action target.
    page.locator('[data-t380-manual-open]').click()
    page.locator('[data-t380-context="new-count"]').click()
    ck('new count action routes directly to create-count screen',page.evaluate('activeFlowId')=='UIF-08' and page.evaluate('activeScreenId')=='SCR-043')
    page.locator('[data-t380-back-home]').click()

    # Exhaustive access remains in review tab, not Product UI.
    page.locator('button[data-workbench-mode="bj"]').click()
    options=page.locator('#flow-selector option').evaluate_all('(els)=>els.map(e=>e.value)')
    ck('review tab still exposes all 17 BJ + CAP-01',len(options)==18 and 'CAP-01' in options and 'UIF-17' in options,options)
    ck('legacy BJ/UIF review controls remain visible',page.locator('#flow-selector').is_visible())

    # Geometry and error gate.
    page.locator('button[data-workbench-mode="theme"]').click(); page.locator('[data-theme-app-route="inventory"]').click()
    geom=page.evaluate('''()=>{const r=document.querySelector('#app-screen').getBoundingClientRect(),d=document.querySelector('.device-preview').getBoundingClientRect(),c=document.querySelector('#app-screen .app-content');return {rw:r.width,rh:r.height,dw:d.width,dh:d.height,x:document.querySelector('#app-screen').scrollWidth-document.querySelector('#app-screen').clientWidth,cx:c.scrollWidth-c.clientWidth}}''')
    ck('canonical 402x874 product / 418x890 review frame preserved',abs(geom['rw']-402)<.75 and abs(geom['rh']-874)<.75 and abs(geom['dw']-418)<.75 and abs(geom['dh']-890)<.75,geom)
    ck('Warehouse Home has no horizontal overflow',geom['x']<=.75 and geom['cx']<=.75,geom)
    ck('no browser page errors',len(errors)==0,errors[:10])
    browser.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':VERSION,'status':status,'checks':checks,'browserErrors':errors}
(OUT/f'TASK-DRIVEN-WAREHOUSE-HOME-QA-v{VERSION}.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=[f'# Task-driven Warehouse Home QA — v{VERSION}','',f'**Result: {status} · {sum(x["pass"] for x in checks)}/{len(checks)} PASS**','',
    '- Product-like `Toàn Theme 7` mode uses **Search + Concrete Work + Utilities + one Manual Action CTA**.','- Exhaustive **17 BJ + CAP-01** access is reserved for `Theo BJ / UIF`.','- Direct task/manual entries reuse existing BJ renderers and return straight to Kho from their direct entry screen.','', '## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': {x["note"]}' if x['note'] and not x['pass'] else '') for x in checks]
(OUT/f'TASK-DRIVEN-WAREHOUSE-HOME-QA-v{VERSION}.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
sys.exit(0 if status=='PASS' else 1)
