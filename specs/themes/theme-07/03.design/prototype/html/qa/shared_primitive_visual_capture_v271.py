from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent/'v271-shared-captures'
OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text()
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
        idx=idx.replace(line+'\n','').replace(line,'')
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
          .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
          .replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>'))
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1200,'height':1000})
    p.set_content(html,wait_until='load',timeout=30000)
    p.evaluate("()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';activeScreenId='SCR-026';stateByScreen['SCR-026']='READY';render();showToast('Đã lưu thay đổi','success');}")
    p.wait_for_timeout(220)
    p.locator('#app-screen .v-page-scaffold').screenshot(path=str(OUT/'TOAST-SUCCESS-WITH-FOOTER.png'))
    p.evaluate("()=>{activeFlowId='UIF-05';activeScreenId='SCR-025';stateByScreen['SCR-025']='READY';render();showToast('Cần kiểm tra lại dữ liệu','warning');}")
    p.wait_for_timeout(220)
    p.locator('#app-screen .v-page-scaffold').screenshot(path=str(OUT/'TOAST-WARNING-NO-FOOTER.png'))
    p.close(); b.close()
print(OUT)
