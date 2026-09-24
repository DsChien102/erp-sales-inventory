from pathlib import Path
from playwright.sync_api import sync_playwright
import re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent/'v293-bj07-captures';OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8');styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
 p=ROOT/fn
 if p.exists():
  styles.append(p.read_text(encoding='utf-8'));idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
 html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf-8")}</script>')
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 p=b.new_page(viewport={'width':1600,'height':900});p.set_default_timeout(5000);p.set_content(html,wait_until='load',timeout=30000)
 def shot(name,js):
  p.evaluate(js);p.wait_for_timeout(50);p.locator('#device-preview').screenshot(path=str(OUT/name))
 shot('SCR036-QUEUE.png',"()=>{activeFlowId='UIF-07';activeScreenId='SCR-036';stateByScreen['SCR-036']='READY';io07Query='';io07QueueFilter='ALL';render();}")
 shot('SCR037-PREPARE.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=false;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07VerifySheetOpen=false;render();}")
 shot('SCR037-SOURCE-UPDATED.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-04';const r=io07Current();const a5=io07FindAllocation('RTV-A5',r).allocation,a6=io07FindAllocation('RTV-A6',r).allocation;a5.verified=false;a5.affectedByChange=true;a5.physicalMismatch=false;a6.verified=true;a6.affectedByChange=false;a6.physicalMismatch=false;activeScreenId='SCR-037';stateByScreen['SCR-037']='SOURCE_UPDATED';io07VerifySheetOpen=false;render();}")
 shot('SCR037-VERIFY-SHEET.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07VerifySheetOpen=false;render();io07OpenVerification('RTV-A1');renderAppScreen();}")
 shot('SCR037-VERIFY-MISMATCH.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07ActiveAllocationId='RTV-A1';io07ScanLot='SAI-LOT';io07VerifySheetOpen=true;render();}")
 shot('SCR039-REVIEW.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});r.reviewSourceVersion=r.sourceVersion;activeScreenId='SCR-039';stateByScreen['SCR-039']='READY';io07VerifySheetOpen=false;render();}")
 shot('SCR039-SOURCE-CHANGED.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-04';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false});r.reviewSourceVersion=r.sourceVersion-1;activeScreenId='SCR-039';stateByScreen['SCR-039']='SOURCE_CHANGED';io07VerifySheetOpen=false;render();}")
 shot('SCR041-COMPLETED.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07LastResult={operationId:'IO-RTV-TEST',requestId:r.id,supplier:r.supplier,source:r.source,sourceVersion:r.sourceVersion,warehouse:r.warehouse,lines:io07Allocations(r).map(({group,allocation:a})=>({name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty}))};activeScreenId='SCR-041';stateByScreen['SCR-041']='COMPLETED';render();}")
 shot('SCR041-UNKNOWN.png',"()=>{activeFlowId='UIF-07';activeScreenId='SCR-041';stateByScreen['SCR-041']='UNKNOWN';render();}")
 b.close()
print('captured',len(list(OUT.glob('*.png'))),'images to',OUT)
