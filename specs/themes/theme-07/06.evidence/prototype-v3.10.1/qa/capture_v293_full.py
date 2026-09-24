from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image,ImageOps,ImageDraw
import re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent/'v293-focused-captures'; OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8');styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
 p=ROOT/fn
 if p.exists():styles.append(p.read_text(encoding='utf-8'));idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf-8")}</script>')
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox']);p=b.new_page(viewport={'width':1600,'height':1000});p.set_content(html,wait_until='load')
 shots=[
 ('BJ05-SCR028.png',"()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';const o=io05CurrentOrder();o.lines.forEach(l=>l.allocations.forEach(a=>a.picked=Math.min(Number(a.qty||0),Math.max(1,Number(a.picked||0)))));activeScreenId='SCR-028';stateByScreen['SCR-028']='PARTIAL_ALLOWED';render();}"),
 ('BJ06-SCR035.png',"()=>{activeFlowId='UIF-06';io06SelectedRequestId='RET-260827-05';const r=io06CurrentRequest();r.classified=true;activeScreenId='SCR-035';stateByScreen['SCR-035']='COMPLETED';render();}"),
 ('BJ07-SCR037.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=false;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07VerifySheetOpen=false;render();}"),
 ('BJ07-SCR039.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});r.reviewSourceVersion=r.sourceVersion;activeScreenId='SCR-039';stateByScreen['SCR-039']='READY';io07VerifySheetOpen=false;render();}"),
 ('BJ07-SCR041.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';const r=io07Current();io07LastResult={operationId:'IO-RTV-QA',requestId:r.id,supplier:r.supplier,source:r.source,sourceVersion:r.sourceVersion,warehouse:r.warehouse,lines:io07Allocations(r).map(({group,allocation:a})=>({name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty}))};activeScreenId='SCR-041';stateByScreen['SCR-041']='COMPLETED';render();}"),
 ('BJ07-SCR037-VERIFY.png',"()=>{activeFlowId='UIF-07';io07Selected='RTV-260827-02';activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';io07OpenVerification('RTV-A1');render();}")]
 for name,js in shots:
  p.evaluate(js);p.wait_for_timeout(30);p.locator('#app-screen').screenshot(path=str(OUT/name))
 b.close()
# contact sheet
files=sorted(OUT.glob('*.png'))
thumbs=[]
for f in files:
 im=Image.open(f).convert('RGB'); im.thumbnail((241,524)); canvas=Image.new('RGB',(261,564),'white'); canvas.paste(im,((261-im.width)//2,20));
 d=ImageDraw.Draw(canvas); d.text((10,544),f.stem,fill='black'); thumbs.append(canvas)
cols=3; rows=(len(thumbs)+cols-1)//cols
sheet=Image.new('RGB',(cols*261,rows*564),(238,240,242))
for i,t in enumerate(thumbs):sheet.paste(t,((i%cols)*261,(i//cols)*564))
sheet.save(OUT/'CONTACT-SHEET.jpg',quality=90)
print('captured',len(files),'focused screens')
