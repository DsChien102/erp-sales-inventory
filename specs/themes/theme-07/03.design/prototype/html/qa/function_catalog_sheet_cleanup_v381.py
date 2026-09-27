from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys

VERSION='3.8.1'
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'qa'
CAP=OUT/'v381-function-catalog-captures'
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
    page.set_default_timeout(6000)
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.set_content(inline(ROOT),wait_until='load',timeout=30000)

    ck('runtime version',page.evaluate('window.__VET45_PROTOTYPE__?.version')==VERSION,page.evaluate('window.__VET45_PROTOTYPE__?.version'))
    ck('two workbench tabs preserved',page.locator('button[data-workbench-mode]').count()==2)
    page.locator('button[data-workbench-mode="theme"]').click()
    page.locator('[data-theme-app-route="inventory"]').click()

    ck('task-driven Warehouse Home remains primary',page.locator('.t380-warehouse-home').count()==1)
    ck('three work items remain visible by default',page.locator('.t380-work-list [data-t380-target-screen]').count()==3)
    ck('manual entry remains a single CTA',page.locator('[data-t380-manual-open]').count()==1)
    ck('secondary full-function entry is present once',page.locator('[data-t381-catalog-open]').count()==1)
    ck('secondary entry is not part of the primary work queue',page.locator('.t380-work-list [data-t381-catalog-open]').count()==0)
    home_text=page.locator('#app-screen').inner_text()
    ck('home still hides long-tail journey names',all(x not in home_text for x in ['Giữ hàng theo đơn bán','Hủy & sửa sai nghiệp vụ','Xác minh kết quả','Chính sách tồn & cận hạn']),home_text)
    page.locator('#device-preview').screenshot(path=str(CAP/'01-KHO-TASK-DRIVEN-WITH-CATALOG-ENTRY.png'))

    # Manual sheet: no redundant close CTA or architecture helper; backdrop and Escape dismiss.
    page.locator('[data-t380-manual-open]').click()
    ck('manual sheet still has exactly four manual actions',page.locator('.t380-manual-sheet [data-t380-target-screen]').count()==4)
    ck('manual sheet no longer has explicit Close CTA',page.locator('.t380-manual-sheet button[data-t380-manual-close]').count()==0)
    ck('manual sheet no longer shows explanatory helper',page.locator('.t380-manual-sheet .t380-sheet-heading > p').count()==0)
    page.locator('#device-preview').screenshot(path=str(CAP/'02-TAO-THAO-TAC-NO-CLOSE-CTA.png'))
    page.keyboard.press('Escape')
    ck('Escape dismisses manual sheet',page.locator('.t380-manual-sheet').count()==0)
    page.locator('[data-t380-manual-open]').click()
    page.locator('.t380-manual-overlay').click(position={'x':5,'y':5})
    ck('backdrop dismisses manual sheet',page.locator('.t380-manual-sheet').count()==0)

    # Secondary catalog: full 17 BJ + CAP-01 discoverability.
    page.locator('[data-t381-catalog-open]').click()
    ck('full-function catalog opens as a secondary screen',page.locator('.t381-catalog-screen').count()==1 and page.locator('#app-screen h3').first.inner_text()=='Tất cả chức năng kho')
    rows=page.locator('[data-t381-catalog-flow]')
    ids=rows.evaluate_all('(els)=>els.map(e=>e.dataset.t381CatalogFlow)')
    ck('catalog exposes exactly all 17 BJ + CAP-01',len(ids)==18 and len(set(ids))==18 and 'UIF-01' in ids and 'UIF-17' in ids and 'CAP-01' in ids,ids)
    ck('catalog uses six visual groups without extra category routes',page.locator('.t381-catalog-section').count()==6)
    ck('contextual/exception/setup entries are labeled with origin cues',all(page.locator(f'[data-t381-catalog-flow="{i}"] .ds24-badge').count()==1 for i in ['UIF-04','UIF-11','UIF-12','UIF-16','UIF-17','CAP-01']))
    page.locator('#device-preview').screenshot(path=str(CAP/'03-TAT-CA-CHUC-NANG-KHO.png'))

    # Catalog origin must be restored on Back from a capability entry.
    page.locator('[data-t381-catalog-flow="UIF-01"]').click()
    ck('catalog row enters shared existing BJ runtime',page.evaluate('activeFlowId')=='UIF-01' and page.evaluate('activeScreenId')=='SCR-001')
    ck('catalog entry screen has module Back',page.locator('[data-theme-app-back-to-inventory]').count()==1)
    page.locator('[data-theme-app-back-to-inventory]').click()
    ck('Back from catalog-launched flow returns to catalog',page.locator('.t381-catalog-screen').count()==1)

    # Explicit catalog Back returns to task-driven Kho home.
    page.locator('[data-t381-catalog-back]').click()
    ck('catalog Back returns to task-driven Warehouse Home',page.locator('.t380-warehouse-home').count()==1 and page.locator('[data-t381-catalog-open]').count()==1)

    # Primary manual action still routes directly and returns Home, not Catalog.
    page.locator('[data-t380-manual-open]').click()
    page.locator('[data-t380-context="quick-receipt"]').click()
    ck('manual quick receipt still enters direct SCR-008',page.evaluate('activeFlowId')=='UIF-02' and page.evaluate('activeScreenId')=='SCR-008')
    ck('manual direct entry keeps direct Back-to-Kho contract',page.locator('[data-t380-back-home]').count()==1)
    page.locator('[data-t380-back-home]').click()
    ck('manual direct Back returns to Warehouse Home',page.locator('.t380-warehouse-home').count()==1)

    # Geometry / overflow.
    geom=page.evaluate('''()=>{const a=document.querySelector('#app-screen'),r=a.getBoundingClientRect(),d=document.querySelector('.device-preview').getBoundingClientRect(),c=a.querySelector('.app-content');return {rw:r.width,rh:r.height,dw:d.width,dh:d.height,x:a.scrollWidth-a.clientWidth,cx:c.scrollWidth-c.clientWidth}}''')
    ck('canonical 402x874 product / 418x890 review frame preserved',abs(geom['rw']-402)<.75 and abs(geom['rh']-874)<.75 and abs(geom['dw']-418)<.75 and abs(geom['dh']-890)<.75,geom)
    ck('Warehouse Home has no horizontal overflow',geom['x']<=.75 and geom['cx']<=.75,geom)
    ck('no browser page errors',len(errors)==0,errors[:10])
    browser.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':VERSION,'status':status,'checks':checks,'browserErrors':errors}
(OUT/f'FUNCTION-CATALOG-SHEET-QA-v{VERSION}.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=[f'# Function Catalog & Bottom-sheet QA — v{VERSION}','',f'**Result: {status} · {sum(x["pass"] for x in checks)}/{len(checks)} PASS**','',
    '- Kho remains task-driven; exhaustive capability discovery is a low-emphasis secondary route.',
    '- `Tất cả chức năng kho` exposes all 17 BJ + CAP-01 without putting the catalog back on Warehouse Home.',
    '- Dismissible chooser/viewer sheets do not spend a CTA on `Đóng`; cancel/confirmation actions remain where edits/decisions need protection.',
    '', '## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': {x["note"]}' if x['note'] and not x['pass'] else '') for x in checks]
(OUT/f'FUNCTION-CATALOG-SHEET-QA-v{VERSION}.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
sys.exit(0 if status=='PASS' else 1)
