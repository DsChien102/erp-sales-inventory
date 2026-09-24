from pathlib import Path
from PIL import Image, ImageChops
from playwright.sync_api import sync_playwright
import tempfile

CHILD_ROOT=Path(__file__).resolve().parents[1]
PARENT_ROOT=Path('/mnt/data/v141_work/VET45-Theme7-Prototype-Harness-v1.4.0/specs/themes/theme-07/prototype/html')
OUT=Path(__file__).resolve().parent


def inline(root: Path):
    idx=(root/'index.html').read_text(encoding='utf8')
    css=(root/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(root/'styles.css').read_text(encoding='utf8')
    data=(root/'workbench-data.js').read_text(encoding='utf8')
    app=(root/'app.js').read_text(encoding='utf8')
    return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')

PARENT=inline(PARENT_ROOT)
CHILD=inline(CHILD_ROOT)
checks=[]
def ck(name,cond): checks.append((name,bool(cond)))

CASES=[
    ('SCR-014','READY',''),
    ('SCR-015','READY','val03SelectedReceiptId="VAL03-R1";'),
    ('SCR-016','READY','val03SelectedReceiptId="VAL03-R1";'),
    ('SCR-017','READY','val03SelectedReceiptId="VAL03-R1";'),
    ('SCR-019','UNKNOWN',''),
]

def render(page, html, sid, state, setup):
    page.goto('about:blank')
    page.set_content(html,wait_until='load')
    page.wait_for_timeout(25)
    page.evaluate('''(x)=>{activeFlowId="UIF-03";activeScreenId=x.sid;stateByScreen[x.sid]=x.state;if(x.setup){eval(x.setup);}render();}''',{'sid':sid,'state':state,'setup':setup})
    page.wait_for_timeout(25)
    return page.locator('#app-screen').inner_text()

with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1400,'height':1050})
    with tempfile.TemporaryDirectory() as td:
        td=Path(td)
        for sid,state,setup in CASES:
            ptxt=render(page,PARENT,sid,state,setup)
            pp=td/f'parent-{sid}-{state}.png'; page.locator('#device-preview').screenshot(path=str(pp))
            ctxt=render(page,CHILD,sid,state,setup)
            cp=td/f'child-{sid}-{state}.png'; page.locator('#device-preview').screenshot(path=str(cp))
            ck(f'{sid}/{state} text identical to v1.4.0',ptxt==ctxt)
            a=Image.open(pp).convert('RGB'); b=Image.open(cp).convert('RGB')
            ck(f'{sid}/{state} pixel-identical to v1.4.0',a.size==b.size and ImageChops.difference(a,b).getbbox() is None)
            ck(f'{sid}/{state} remains 402x874',b.size==(402,874))
    browser.close()

passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# UIF03 Regression v1.4.1','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',
       'Parent: `v1.4.0` · Child: `v1.4.1`. Inventory Operations corrections must not regress the valuation Product design introduced in v1.4.0.','',
       'The five canonical UIF03 surfaces are compared for rendered Product text and exact 402×874 pixels in the same Chromium runtime.','',
       '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'REGRESSION-UIF03-v1.4.1.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
