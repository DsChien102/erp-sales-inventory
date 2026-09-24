from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
VERSION='3.8.1'
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'qa'

def inline(root):
    h=(root/'index.html').read_text()
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
        p=root/fn.split('?')[0]
        h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>\n{p.read_text()}\n</style>' if p.exists() else '',h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
        p=root/fn.split('?')[0]
        h=h.replace(f'<script src="{fn}"></script>',f'<script>\n{p.read_text()}\n</script>' if p.exists() else '')
    return h
checks=[]
def ck(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=browser.new_page(viewport={'width':1500,'height':1100}); p.set_default_timeout(5000)
    errors=[];p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(inline(ROOT),wait_until='load',timeout=30000)
    data=p.evaluate(r'''()=>{
      const visible=e=>e&&e.offsetParent!==null&&!e.hidden;
      const transparent=c=>c==='rgba(0, 0, 0, 0)'||c==='transparent';
      const out={version:window.__VET45_PROTOTYPE__?.version,states:0,badHelpers:[],vRadio:[],legacyChoiceCards:0};
      for(const f of flowCatalog){for(const sid of f.screens){const sc=screens.find(x=>x.id===sid);for(const st of (sc?.states||['READY'])){activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render();out.states++;
        const helpers=[...document.querySelectorAll('#app-screen small, #app-screen .field-help, #app-screen .helper-text, #app-screen [class$="__helper"]')].filter(visible);
        for(const h of helpers){const cs=getComputedStyle(h);if(!transparent(cs.backgroundColor)){out.badHelpers.push({flow:f.id,sid,st,cls:h.className,text:(h.innerText||'').trim().slice(0,80),bg:cs.backgroundColor});}}
        out.legacyChoiceCards += [...document.querySelectorAll('#app-screen .choice-card[data-ds-component="VRadio"]')].filter(visible).length;
      }}}
      activeFlowId='UIF-09';activeScreenId='SCR-038';stateByScreen['SCR-038']='READY';render();
      out.vRadio=[...document.querySelectorAll('#app-screen [data-ds-component="VRadio"]')].filter(visible).map(x=>({cls:x.className,state:x.dataset.dsPropState,text:(x.innerText||'').trim().replace(/\n/g,' | '),helperBg:(()=>{const h=x.querySelector('small');return h?getComputedStyle(h).backgroundColor:null})(),checked:!!x.querySelector('input:checked'),control:!!x.querySelector('.v364-radio-control')}));
      return out;
    }''')
    cap=OUT/'v364-radio-helper-captures';cap.mkdir(exist_ok=True)
    p.evaluate("()=>{activeFlowId='UIF-09';activeScreenId='SCR-038';stateByScreen['SCR-038']='READY';render();}")
    p.locator('#device-preview').screenshot(path=str(cap/'UIF-09-SCR-038-READY.png'))
    browser.close()
ck('runtime version',data['version']==VERSION,data['version'])
ck('all 518 declared route-state renders scanned',data['states']==518,data['states'])
ck('no visible helper/supporting text has a non-transparent background',len(data['badHelpers'])==0,data['badHelpers'][:12])
ck('no reachable legacy choice-card is mislabeled as VRadio',data['legacyChoiceCards']==0,data['legacyChoiceCards'])
ck('BJ09 choices render as canonical VRadio instances',len(data['vRadio'])>=3,data['vRadio'])
ck('BJ09 VRadio choices keep helper text transparent',all(x['helperBg'] in (None,'rgba(0, 0, 0, 0)','transparent') for x in data['vRadio']),data['vRadio'])
ck('BJ09 VRadio choices expose canonical radio control',all(x['control'] for x in data['vRadio']),data['vRadio'])
ck('exactly one BJ09 choice remains selected',sum(1 for x in data['vRadio'] if x['checked'])==1,data['vRadio'])
ck('no browser page errors',len(errors)==0,errors[:8])
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':VERSION,'status':status,'routeStatesScanned':data['states'],'checks':checks,'sample':data['vRadio'],'browserErrors':errors}
(OUT/f'RADIO-HELPER-DS-QA-v{VERSION}.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
md=[f'# Radio / Helper DS QA — v{VERSION}','',f'**Result: {status} · {sum(x["pass"] for x in checks)}/{len(checks)} PASS**','',f'- Route-state renders scanned: **{data["states"]}**','- Rule: helper/supporting text is plain text; badge/pill backgrounds require an explicit badge/status component.','- BJ09 state choices use canonical `VRadio` anatomy (`522:7410`).','','## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': {x["note"]}' if x['note'] and not x['pass'] else '') for x in checks]
(OUT/f'RADIO-HELPER-DS-QA-v{VERSION}.md').write_text('\n'.join(md)+'\n')
print(status,sum(x['pass'] for x in checks),'/',len(checks),'badHelpers',len(data['badHelpers']),'legacy',data['legacyChoiceCards'],'errors',len(errors))
if status!='PASS':
  for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
sys.exit(0 if status=='PASS' else 1)
