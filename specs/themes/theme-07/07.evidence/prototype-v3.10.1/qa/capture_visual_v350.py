from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image,ImageOps,ImageDraw,ImageFont
import re,json,math,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'qa'/'v350-visual-captures'; OUT.mkdir(parents=True,exist_ok=True)
OPS={'UIF-01','UIF-02','UIF-04','UIF-05','UIF-06','UIF-07'}
VAL={'UIF-03','UIF-13','UIF-14'}
AUD={'UIF-08','UIF-09','UIF-10','UIF-11','UIF-12','UIF-15','UIF-16','UIF-17'}

def inline(root):
    h=(root/'index.html').read_text()
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
        p=root/fn.split('?')[0]; h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text()}</style>' if p.exists() else '',h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
        p=root/fn.split('?')[0]; h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text()}</script>' if p.exists() else '')
    return h

def contact(items,name,cols=4,scale=.5):
    if not items:return
    cellw=int(402*scale)+20; cellh=int(874*scale)+64
    rows=math.ceil(len(items)/cols)
    sheet=Image.new('RGB',(cols*cellw,rows*cellh),'white'); d=ImageDraw.Draw(sheet)
    for i,it in enumerate(items):
        img=Image.open(it['path']).convert('RGB'); img=img.resize((int(402*scale),int(874*scale)))
        x=(i%cols)*cellw+10; y=(i//cols)*cellh+52
        sheet.paste(img,(x,y)); d.rectangle((x,y,x+img.width-1,y+img.height-1),outline=(180,180,180),width=1)
        label=f"{it['flow']} · {it['screen']} · {it['state']}\n{it['name']}"
        d.multiline_text((x,y-44),label,fill='black',spacing=2)
    path=OUT/name; sheet.save(path,optimize=True); return path

manifest=[]; errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1500,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(inline(ROOT),wait_until='load',timeout=30000)
    routes=p.evaluate('''()=>flowCatalog.flatMap(f=>f.screens.map(sid=>{const sc=screens.find(x=>x.id===sid);return {flow:f.id,screen:sid,name:sc?.name||sid,state:(sc?.states||['READY'])[0]}}))''')
    for i,r in enumerate(routes):
        p.evaluate('(x)=>{activeFlowId=x.flow;activeScreenId=x.screen;stateByScreen[x.screen]=x.state;render()}',r)
        p.wait_for_timeout(6)
        path=OUT/f"{i+1:03d}-{r['flow']}-{r['screen']}-{r['state']}.png"
        p.locator('#app-screen').screenshot(path=str(path))
        rec={**r,'path':path}
        manifest.append(rec)
    b.close()

for group,flows in [('OPERATIONS',OPS),('VALUATION',VAL),('AUDIT-CONTROL',AUD)]:
    contact([x for x in manifest if x['flow'] in flows],f'V350-{group}-CONTACT-SHEET.png')
# Key correction screens at larger 0.72 scale / 3 columns.
keys={('UIF-07','SCR-037'),('UIF-08','SCR-044'),('UIF-08','SCR-045'),('UIF-08','SCR-046'),('UIF-10','SCR-040'),('UIF-12','SCR-067'),('UIF-15','SCR-055'),('UIF-16','SCR-079'),('UIF-16','SCR-082'),('UIF-17','SCR-079'),('UIF-17','SCR-080'),('UIF-17','SCR-082')}
contact([x for x in manifest if (x['flow'],x['screen']) in keys],'V350-KEY-CORRECTIONS-CONTACT-SHEET.png',cols=3,scale=.72)
(OUT/'manifest.json').write_text(json.dumps([{**x,'path':x['path'].name} for x in manifest],ensure_ascii=False,indent=2)+"\n")
print('captured',len(manifest),'routes; errors',len(errors))
if errors: print(errors[:10])
sys.exit(1 if errors or len(manifest)!=85 else 0)
