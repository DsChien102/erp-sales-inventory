from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image, ImageOps, ImageDraw
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent/'v230-bj08-captures'; OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(); css='\n'.join((ROOT/x).read_text() for x in ['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css']); data=(ROOT/'workbench-data.js').read_text(); fmap=(ROOT/'figma-ds-runtime-map.js').read_text(); app=(ROOT/'app.js').read_text()
html=(idx.replace('<link rel="stylesheet" href="figma-ds.exact.css" />','').replace('<link rel="stylesheet" href="figma-ds.styles.exact.css" />','').replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>'))
shots=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':1500,'height':1100}); p.set_content(html,wait_until='load'); p.add_style_tag(content='*{animation:none!important;transition:none!important}')
 for sid,st in [('SCR-042','READY'),('SCR-043','READY'),('SCR-044','BLIND_COUNT'),('SCR-045','RECOUNT_REQUIRED'),('SCR-046','APPROVAL_REQUIRED'),('SCR-047','COMPLETED')]:
  p.evaluate('x=>{activeFlowId="UIF-08";activeScreenId=x.s;stateByScreen[x.s]=x.st;ic08ConfirmKind=null;ic08KeypadTarget=null;ic08ScopeSheetOpen=false;ic08ProductSheetOpen=false;render();}',{'s':sid,'st':st})
  f=OUT/f'{sid}.png'; p.locator('.device-preview:not(.is-wide) > .app-screen').screenshot(path=str(f)); shots.append(f)
 b.close()
# 3x2 contact sheet with simple labels
ims=[Image.open(x).convert('RGB') for x in shots]
w=max(im.width for im in ims); h=max(im.height for im in ims)
canvas=Image.new('RGB',(w*3,(h+28)*2),'white')
for i,(im,f) in enumerate(zip(ims,shots)):
 x=(i%3)*w; y=(i//3)*(h+28); canvas.paste(im,(x,y+28));
 d=ImageDraw.Draw(canvas); d.text((x+8,y+7),f.stem,fill='black')
canvas.save(OUT/'BJ08-contact-sheet.png')
print(OUT/'BJ08-contact-sheet.png')
