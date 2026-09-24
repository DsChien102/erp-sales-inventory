from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys

VERSION='3.7.0'
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'qa'
CAP=OUT/'v370-integrated-navigation-captures'
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
    ck('exactly two workbench mode tabs',page.locator('button[data-workbench-mode]').count()==2,page.locator('button[data-workbench-mode]').count())
    ck('existing BJ/UIF mode is default and selector remains visible',page.evaluate('document.body.dataset.workbenchMode')=='bj' and page.locator('#flow-selector').is_visible())

    page.locator('button[data-workbench-mode="theme"]').click()
    ck('Theme 7 tab switches to integrated mode',page.evaluate('document.body.dataset.workbenchMode')=='theme')
    ck('integrated mode starts at Them',page.locator('#current-screen-name').inner_text()=='Thêm',page.locator('#current-screen-name').inner_text())
    more_rows=page.locator('#app-screen .ds24-list-row')
    ck('Them screen exposes Kho as the single enabled Theme 7 module entry',more_rows.count()==8 and page.locator('[data-theme-app-route="inventory"]').count()==1)
    disabled=page.locator('#app-screen .ds24-list-row[data-ds-prop-state="Disabled"]')
    ck('out-of-scope More rows are true Disabled Navigation rows',disabled.count()==7 and disabled.evaluate_all('(els)=>els.every(e=>e.tagName==="BUTTON"&&e.disabled&&e.getAttribute("aria-disabled")==="true"&&!!e.querySelector(".ds24-list-row__trailing .icon"))'),disabled.count())
    page.locator('#device-preview').screenshot(path=str(CAP/'01-MORE.png'))

    page.locator('[data-theme-app-route="inventory"]').click()
    ck('Kho module root is reachable from Them',page.locator('#current-screen-name').inner_text()=='Kho')
    entries=page.locator('[data-theme-entry-flow]')
    entry_ids=entries.evaluate_all('(els)=>els.map(e=>e.dataset.themeEntryFlow)')
    expected={'UIF-01','UIF-02','UIF-03','UIF-04','UIF-05','UIF-06','UIF-07','UIF-08','UIF-09','UIF-10','UIF-11','UIF-12','UIF-13','UIF-14','UIF-15','UIF-16','UIF-17','CAP-01'}
    ck('Kho root exposes all 17 BJ plus CAP-01',len(entry_ids)==18 and set(entry_ids)==expected,entry_ids)
    ck('Kho root uses Navigation List Row anatomy for every entry',entries.evaluate_all('(els)=>els.every(e=>e.dataset.dsComponent==="DS v2 / List Row"&&e.dataset.dsPropType==="Navigation"&&e.tagName==="BUTTON"&&!e.disabled&&!!e.querySelector(".ds24-list-row__trailing .icon"))'))
    page.locator('#device-preview').screenshot(path=str(CAP/'02-INVENTORY.png'))
    page.screenshot(path=str(CAP/'03-WORKBENCH-THEME.png'),full_page=True)

    route_results=[]
    for fid in entry_ids:
        page.locator(f'[data-theme-entry-flow="{fid}"]').click()
        flow=page.evaluate('activeFlowId')
        screen=page.evaluate('activeScreenId')
        phone_title=page.locator('#app-screen .app-appbar-copy h3').first.inner_text() if page.locator('#app-screen .app-appbar-copy h3').count() else ''
        back_count=page.locator('[data-theme-app-back-to-inventory]').count()
        route_results.append({'entry':fid,'flow':flow,'screen':screen,'phoneTitle':phone_title,'backCount':back_count})
        if flow!=fid or back_count!=1:
            break
        page.locator('[data-theme-app-back-to-inventory]').click()
        if page.locator('#current-screen-name').inner_text()!='Kho':
            break
    ck('every Theme 7 entry opens its own shared flow runtime',len(route_results)==18 and all(x['entry']==x['flow'] for x in route_results),route_results)
    ck('every Theme 7 flow entry has a deterministic Back to Kho',len(route_results)==18 and all(x['backCount']==1 for x in route_results) and page.locator('#current-screen-name').inner_text()=='Kho',route_results)

    # Open BJ08 and make sure screen-level navigation remains the existing renderer, not a clone.
    page.locator('[data-theme-entry-flow="UIF-08"]').click()
    ck('integrated mode reuses BJ08 existing screen renderer',page.evaluate('activeScreenId')=='SCR-042' and 'KK-0709-03' in page.locator('#app-screen').inner_text())
    page.locator('[data-theme-app-back-to-inventory]').click()

    # Switch back to the old tab; it must remain functional.
    page.locator('button[data-workbench-mode="bj"]').click()
    ck('switching back restores BJ/UIF workbench mode',page.evaluate('document.body.dataset.workbenchMode')=='bj' and page.locator('#flow-selector').is_visible())
    ck('legacy screen navigation remains rendered',page.locator('#screen-navigation [data-screen]').count()>0,page.locator('#screen-navigation [data-screen]').count())
    ck('no browser page errors',len(errors)==0,errors[:10])
    browser.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':VERSION,'status':status,'checks':checks,'routeResults':route_results,'browserErrors':errors}
(OUT/f'INTEGRATED-THEME-NAVIGATION-QA-v{VERSION}.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=[f'# Integrated Theme Navigation QA — v{VERSION}','',f'**Result: {status} · {sum(x["pass"] for x in checks)}/{len(checks)} PASS**','',
    '- Workbench modes: **Theo BJ / UIF** + **Toàn Theme 7**.','- Integrated entry: **Thêm → Kho**.','- Kho coverage: **17 BJ + CAP-01 = 18 entries**.','- Runtime strategy: **shared renderers/state; no duplicated business screens**.','', '## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': {x["note"]}' if x['note'] and not x['pass'] else '') for x in checks]
(OUT/f'INTEGRATED-THEME-NAVIGATION-QA-v{VERSION}.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,sum(x['pass'] for x in checks),'/',len(checks),'routes',len(route_results),'errors',len(errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
sys.exit(0 if status=='PASS' else 1)
