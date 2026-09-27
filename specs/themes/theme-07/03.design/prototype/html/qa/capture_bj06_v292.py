from pathlib import Path
from playwright.sync_api import sync_playwright
import re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent/'v292-bj06-all'; OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(); styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
 p=ROOT/fn
 if p.exists():styles.append(p.read_text());idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text()}</script>')
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox']);p=b.new_page(viewport={'width':1600,'height':900});p.set_content(html,wait_until='load')
 setups={
 'SCR-030':"io06SelectedRequestId='RET-260827-03';io06QueueFilter='ALL';io06Query='';",
 'SCR-031':"io06SelectedRequestId='RET-260827-03';",
 'SCR-032':"io06SelectedRequestId='RET-260827-03';io06ActiveLineId='RET-L1A';",
 'SCR-033':"io06SelectedRequestId='RET-260827-05';io06ClassificationOpen=false;",
 'SCR-034':"io06ApproverListMode=true;",
 'SCR-035':"io06SelectedRequestId='RET-260827-05';io06CurrentRequest().classified=false;",
 }
 for sid,setup in setups.items():
  state='TASK_LIST' if sid=='SCR-034' else ('RECEIVED_PENDING_CLASSIFICATION' if sid=='SCR-035' else 'READY')
  p.evaluate("([sid,setup,state])=>{activeFlowId='UIF-06';eval(setup);activeScreenId=sid;stateByScreen[sid]=state;render();}",[sid,setup,state]);p.wait_for_timeout(50);p.locator('#device-preview').screenshot(path=str(OUT/f'{sid}.png'))
 b.close()
