from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent/'v272-bj05-captures'
OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text()
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
        idx=idx.replace(line+'\n','').replace(line,'')
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css','v272-detail-composition-fidelity.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
          .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
          .replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>'))

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    def make(name, setup, click=None):
        p=b.new_page(viewport={'width':1200,'height':1000})
        p.set_content(html,wait_until='load',timeout=30000)
        p.evaluate(setup)
        if click:
            p.locator(click).first.click()
        p.locator('#app-screen .v-page-scaffold').screenshot(path=str(OUT/name))
        p.close()
    make('SCR025-READY.png',"""()=>{activeFlowId='UIF-05';activeScreenId='SCR-025';stateByScreen['SCR-025']='READY';render();}""")
    make('SCR026-READY.png',"""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';activeScreenId='SCR-026';stateByScreen['SCR-026']='READY';render();}""")
    make('SCR026-SHORTAGE.png',"""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-24';activeScreenId='SCR-026';stateByScreen['SCR-026']='SHORTAGE';render();}""")
    make('SCR027-READY.png',"""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';activeScreenId='SCR-027';stateByScreen['SCR-027']='READY';render();}""")
    make('SCR027-OVERRIDE.png',"""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';activeScreenId='SCR-027';stateByScreen['SCR-027']='READY';render();}""",'[data-io05-open-override]')
    make('SCR028-PARTIAL.png',"""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';io05ResetHandover();activeScreenId='SCR-028';stateByScreen['SCR-028']='PARTIAL_ALLOWED';render();}""")
    make('SCR028-SOURCE-CHANGED.png',"""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';activeScreenId='SCR-028';stateByScreen['SCR-028']='SOURCE_CHANGED';render();}""")
    make('SCR029-PARTIAL.png',"""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';io05ResetHandover();io05ApplyHandover();activeScreenId='SCR-029';stateByScreen['SCR-029']='PARTIAL_COMPLETED';render();}""")
    make('SCR029-COMPLETED.png',"""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';const o=io05CurrentOrder();for(const l of o.lines){for(const a of l.allocations)a.picked=a.qty;}io05ResetHandover(o);io05ApplyHandover();activeScreenId='SCR-029';stateByScreen['SCR-029']='COMPLETED';render();}""")
    make('SCR029-UNKNOWN.png',"""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';activeScreenId='SCR-029';stateByScreen['SCR-029']='UNKNOWN';render();}""")
    b.close()
print(OUT)
