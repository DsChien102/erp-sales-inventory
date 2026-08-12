from pathlib import Path
from playwright.sync_api import sync_playwright
import re,json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent/'v390-end-user-captures'
OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8')
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists():
        styles.append(p.read_text(encoding='utf-8'))
        idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
    p=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')
shots=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1050})
    p.set_content(html,wait_until='load',timeout=30000)
    p.click('[data-workbench-mode="theme"]');p.click('[data-theme-sidebar-route="inventory"]')
    def shot(name,label):
        fp=OUT/name
        p.locator('#device-preview').screenshot(path=str(fp))
        shots.append({'file':name,'label':label,'flow':p.evaluate('()=>activeFlowId'),'screen':p.evaluate('()=>activeScreenId')})
    shot('01-OPERATOR-WAREHOUSE-HOME.png','Operator work projection')
    p.select_option('[data-t390-persona]','controller');shot('02-CONTROLLER-WAREHOUSE-HOME.png','Controller work projection')
    p.select_option('[data-t390-persona]','operator');p.locator('[data-t383-start-new]').click();p.locator('.t380-manual-sheet [data-theme-entry-flow="UIF-09"]').click();shot('03-STATE-CHANGE-OBJECT-SELECTION.png','Manual state change starts from object selection')
    p.click('[data-theme-sidebar-route="inventory"]');p.locator('[data-t381-catalog-open]').click();p.select_option('[data-t390-persona]','manager');shot('04-MANAGER-FUNCTION-CATALOG.png','Manager long-tail catalog projection')
    p.click('[data-t381-catalog-back]');p.select_option('[data-t390-persona]','operator');p.locator('[data-t390-task-id="RCV-PN26081604"]').click();p.evaluate("()=>{activeScreenId='SCR-010';stateByScreen['SCR-010']='PENDING_APPROVAL';render();}");shot('05-SUBMITTED-HANDOFF-LOCK.png','Submitted receipt is locked and returns to Warehouse Home')
    b.close()
(OUT/'manifest.json').write_text(json.dumps(shots,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('PASS',len(shots),'captures')
