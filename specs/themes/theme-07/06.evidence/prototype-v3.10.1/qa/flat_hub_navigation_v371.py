from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys

VERSION='3.7.1'
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'qa'
CAP=OUT/'v371-flat-hub-captures'
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

expected={'UIF-01','UIF-02','UIF-03','UIF-04','UIF-05','UIF-06','UIF-07','UIF-08','UIF-09','UIF-10','UIF-11','UIF-12','UIF-13','UIF-14','UIF-15','UIF-16','UIF-17','CAP-01'}
frequent={'UIF-01','UIF-02','UIF-05','UIF-06','UIF-08','UIF-14','UIF-15'}

with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1600,'height':1100})
    page.set_default_timeout(5000)
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.set_content(inline(ROOT),wait_until='load',timeout=30000)

    ck('runtime version',page.evaluate('window.__VET45_PROTOTYPE__?.version')==VERSION,page.evaluate('window.__VET45_PROTOTYPE__?.version'))
    ck('two workbench tabs preserved',page.locator('button[data-workbench-mode]').count()==2)
    ck('BJ/UIF remains default',page.evaluate('document.body.dataset.workbenchMode')=='bj')

    page.locator('button[data-workbench-mode="theme"]').click()
    ck('full-theme mode starts at Them',page.locator('#current-screen-name').inner_text()=='Thêm')
    page.locator('[data-theme-app-route="inventory"]').click()
    ck('Kho root reachable directly from Them',page.locator('#current-screen-name').inner_text()=='Kho')
    ck('flat hub marker rendered',page.locator('.t7-flat-hub-shell').count()==1)
    ck('no category navigation routes introduced',page.locator('[data-theme-category-route]').count()==0)
    ck('priority section rendered',page.locator('.t7-hub-section--priority [data-theme-entry-flow]').count()==2)
    ck('frequent section exposes seven direct BJ destinations',set(page.locator('.t7-hub-frequent-list [data-theme-entry-flow]').evaluate_all('(els)=>els.map(e=>e.dataset.themeEntryFlow)'))==frequent)
    ck('rare journeys are not rendered before disclosure',page.locator('[data-theme-hub-more-content]').count()==0)
    ck('single inline disclosure is present',page.locator('[data-theme-hub-toggle]').count()==1 and page.locator('[data-theme-hub-toggle]').get_attribute('aria-expanded')=='false')
    url_before=page.url
    page.locator('#device-preview').screenshot(path=str(CAP/'01-KHO-COLLAPSED.png'))

    page.locator('[data-theme-hub-toggle]').click()
    ck('disclosure expands in place',page.locator('[data-theme-hub-toggle]').get_attribute('aria-expanded')=='true' and page.locator('[data-theme-hub-more-content]').count()==1)
    ck('expansion does not push a new navigation route',page.url==url_before and 'app=inventory' in page.url,page.url)
    all_ids=page.locator('[data-theme-entry-flow]').evaluate_all('(els)=>els.map(e=>e.dataset.themeEntryFlow)')
    ck('all 17 BJ plus CAP-01 remain reachable after expand',set(all_ids)==expected,all_ids)
    ck('every unique Theme 7 destination remains a direct Navigation List Row',page.locator('[data-theme-entry-flow]').evaluate_all('(els)=>els.every(e=>e.dataset.dsComponent==="DS v2 / List Row"&&e.dataset.dsPropType==="Navigation"&&e.tagName==="BUTTON"&&!e.disabled&&!!e.querySelector(".ds24-list-row__trailing .icon"))'))
    page.locator('#device-preview').screenshot(path=str(CAP/'02-KHO-EXPANDED.png'))

    # Rare destination must still be only one route transition from Kho after inline reveal.
    page.locator('[data-theme-entry-flow="UIF-16"]').click()
    ck('rare BJ opens shared runtime directly from Kho',page.evaluate('activeFlowId')=='UIF-16' and page.locator('[data-theme-app-back-to-inventory]').count()==1)
    page.locator('[data-theme-app-back-to-inventory]').click()
    ck('flow entry Back returns straight to Kho',page.locator('#current-screen-name').inner_text()=='Kho')

    # Frequent destination does the same without disclosure.
    if page.locator('[data-theme-hub-toggle]').get_attribute('aria-expanded')=='true':
        page.locator('[data-theme-hub-toggle]').click()
    page.locator('[data-theme-entry-flow="UIF-01"]').click()
    ck('frequent BJ opens shared runtime directly',page.evaluate('activeFlowId')=='UIF-01' and page.locator('[data-theme-app-back-to-inventory]').count()==1)
    page.locator('[data-theme-app-back-to-inventory]').click()

    page.locator('button[data-workbench-mode="bj"]').click()
    ck('legacy BJ/UIF tab still restores unchanged review mode',page.evaluate('document.body.dataset.workbenchMode')=='bj' and page.locator('#flow-selector').is_visible())
    ck('no browser page errors',len(errors)==0,errors[:10])
    browser.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':VERSION,'status':status,'checks':checks,'browserErrors':errors}
(OUT/f'FLAT-HUB-NAVIGATION-QA-v{VERSION}.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=[f'# Flat Hub Navigation QA — v{VERSION}','',f'**Result: {status} · {sum(x["pass"] for x in checks)}/{len(checks)} PASS**','',
    '- Pattern: **Flat Hub + Priority + Frequent + Inline Progressive Disclosure**.','- No intermediate category route is introduced.','- All **17 BJ + CAP-01** remain directly reachable from the same Kho screen.','- Existing **Theo BJ / UIF** workbench mode is preserved.','', '## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': {x["note"]}' if x['note'] and not x['pass'] else '') for x in checks]
(OUT/f'FLAT-HUB-NAVIGATION-QA-v{VERSION}.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
sys.exit(0 if status=='PASS' else 1)
