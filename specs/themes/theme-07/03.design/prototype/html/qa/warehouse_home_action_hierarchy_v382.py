from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys

VERSION='3.8.2'
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'qa'
CAP=OUT/'v382-warehouse-home-captures'
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
    ck('work queue remains first decision section',page.locator('.t380-work-section').count()==1 and page.locator('.t380-work-list [data-t380-target-screen]').count()==3)
    ck('standalone primary create section removed',page.locator('.t380-create-section').count()==0)
    ck('exactly one Create action remains',page.locator('[data-t380-manual-open]').count()==1)
    ck('Create action moved into work context',page.locator('.t380-work-section .t382-work-actions [data-t380-manual-open]').count()==1)
    ck('Create action is Secondary, not Primary',page.locator('[data-t380-manual-open].ds24-button--secondary').count()==1 and page.locator('[data-t380-manual-open].ds24-button--primary').count()==0)
    ck('task disclosure and Create action share one action row',page.locator('.t382-work-actions [data-t380-task-toggle]').count()==1 and page.locator('.t382-work-actions [data-t380-manual-open]').count()==1)
    ck('Tra cứu remains below work context',page.evaluate('''()=>{const w=document.querySelector('.t380-work-section'),u=document.querySelector('.t380-utility-section');return !!w&&!!u&&w.getBoundingClientRect().top<u.getBoundingClientRect().top}'''))
    ck('full-function catalog remains after Tra cứu',page.evaluate('''()=>{const u=document.querySelector('.t380-utility-section'),c=document.querySelector('[data-t381-catalog-open]');return !!u&&!!c&&u.getBoundingClientRect().top<c.getBoundingClientRect().top}'''))
    page.locator('#device-preview').screenshot(path=str(CAP/'01-KHO-CORRECTED-ACTION-HIERARCHY.png'))

    # Create sheet continues to behave exactly as v3.8.1.
    page.locator('[data-t380-manual-open]').click()
    ck('Create sheet opens from new placement',page.locator('.t380-manual-sheet').count()==1)
    ck('Create sheet still has four user-initiated actions',page.locator('.t380-manual-sheet [data-t380-target-screen]').count()==4)
    ck('Create sheet still has no redundant Close CTA',page.locator('.t380-manual-sheet button[data-t380-manual-close]').count()==0)
    page.locator('#device-preview').screenshot(path=str(CAP/'02-TAO-THAO-TAC-FROM-WORK-CONTEXT.png'))
    page.keyboard.press('Escape')
    ck('Escape dismisses Create sheet',page.locator('.t380-manual-sheet').count()==0)

    # Expand/collapse work must preserve action placement.
    page.locator('[data-t380-task-toggle]').click()
    ck('work expansion shows all five tasks',page.locator('.t380-work-list [data-t380-target-screen]').count()==5)
    ck('Create remains in work action row after re-render',page.locator('.t382-work-actions [data-t380-manual-open]').count()==1)
    page.locator('#device-preview').screenshot(path=str(CAP/'03-KHO-EXPANDED-WITH-CREATE-ACTION.png'))

    # Full catalog is still available and complete.
    page.locator('[data-t381-catalog-open]').click()
    ids=page.locator('[data-t381-catalog-flow]').evaluate_all('(els)=>els.map(e=>e.dataset.t381CatalogFlow)')
    ck('secondary catalog still exposes all 17 BJ + CAP-01',len(ids)==18 and len(set(ids))==18 and 'CAP-01' in ids,ids)
    page.locator('[data-t381-catalog-back]').click()

    geom=page.evaluate('''()=>{const a=document.querySelector('#app-screen'),r=a.getBoundingClientRect(),d=document.querySelector('.device-preview').getBoundingClientRect(),c=a.querySelector('.app-content');return {rw:r.width,rh:r.height,dw:d.width,dh:d.height,x:a.scrollWidth-a.clientWidth,cx:c.scrollWidth-c.clientWidth}}''')
    ck('canonical 402x874 product / 418x890 review frame preserved',abs(geom['rw']-402)<.75 and abs(geom['rh']-874)<.75 and abs(geom['dw']-418)<.75 and abs(geom['dh']-890)<.75,geom)
    ck('Warehouse Home has no horizontal overflow',geom['x']<=.75 and geom['cx']<=.75,geom)
    ck('no browser page errors',len(errors)==0,errors[:10])
    browser.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':VERSION,'status':status,'checks':checks,'browserErrors':errors}
(OUT/f'WAREHOUSE-HOME-ACTION-HIERARCHY-QA-v{VERSION}.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=[f'# Warehouse Home Action Hierarchy QA — v{VERSION}','',f'**Result: {status} · {sum(x["pass"] for x in checks)}/{len(checks)} PASS**','',
    '- `Tạo thao tác` is no longer a standalone primary CTA after Tra cứu.',
    '- The action is Secondary and sits in the `Việc của bạn` work context alongside task disclosure.',
    '- Tra cứu and `Tất cả chức năng kho` stay below the work context; full catalog discoverability remains unchanged.',
    '', '## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': {x["note"]}' if x['note'] and not x['pass'] else '') for x in checks]
(OUT/f'WAREHOUSE-HOME-ACTION-HIERARCHY-QA-v{VERSION}.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
sys.exit(0 if status=='PASS' else 1)
