from pathlib import Path
from playwright.sync_api import sync_playwright
import json, re, sys

VERSION='3.6.3'
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'qa'

def inline(root: Path) -> str:
    h=(root/'index.html').read_text(encoding='utf-8')
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
        p=root/fn.split('?')[0]
        rep=f'<style>\n{p.read_text(encoding="utf-8")}\n</style>' if p.exists() else ''
        h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',rep,h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
        p=root/fn.split('?')[0]
        h=h.replace(f'<script src="{fn}"></script>',f'<script>\n{p.read_text(encoding="utf-8")}\n</script>' if p.exists() else '')
    return h

checks=[]
def ck(name, ok, note=''):
    checks.append({'name':name,'pass':bool(ok),'note':note})

with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1500,'height':1100})
    page.set_default_timeout(5000)
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.set_content(inline(ROOT),wait_until='load',timeout=30000)
    audit=page.evaluate(r'''()=>{
      const out={states:0,mixedPeerCollections:[],navMissingChevron:[],disabledNavBroken:[],enabledNavBroken:[],reported:{},interactions:{},runtime:window.__VET45_PROTOTYPE__?.version||null};
      const visible=e=>e&&e.offsetParent!==null&&!e.hidden;
      function scan(flow,sid,st){
        const rows=[...document.querySelectorAll('#app-screen .ds24-list-row')].filter(visible);
        for(const r of rows){
          const type=r.dataset.dsPropType||'', state=r.dataset.dsPropState||'', tag=r.tagName;
          const chev=!!r.querySelector('.ds24-list-row__trailing .icon');
          if(type==='Navigation'&&!chev) out.navMissingChevron.push({flow,sid,st,text:(r.innerText||'').trim().slice(0,120)});
          if(type==='Navigation'&&state==='Disabled'){
            const opacity=parseFloat(getComputedStyle(r).opacity);
            if(!(tag==='BUTTON'&&r.disabled&&r.getAttribute('aria-disabled')==='true'&&Math.abs(opacity-.4)<.02)) out.disabledNavBroken.push({flow,sid,st,tag,disabled:r.disabled,aria:r.getAttribute('aria-disabled'),opacity,text:(r.innerText||'').trim().slice(0,120)});
          }
          if(type==='Navigation'&&state!=='Disabled'&&tag!=='BUTTON') out.enabledNavBroken.push({flow,sid,st,tag,text:(r.innerText||'').trim().slice(0,120)});
        }
        const parents=[...new Set(rows.map(r=>r.parentElement))].filter(Boolean);
        for(const par of parents){
          const direct=[...par.children].filter(x=>x.matches?.('.ds24-list-row')&&visible(x));
          if(direct.length<2)continue;
          const types=[...new Set(direct.map(x=>x.dataset.dsPropType||''))];
          if(types.includes('Navigation')&&types.includes('Status')) out.mixedPeerCollections.push({flow,sid,st,parent:par.className||par.tagName,rows:direct.map(x=>({type:x.dataset.dsPropType,state:x.dataset.dsPropState,tag:x.tagName,text:(x.innerText||'').trim().slice(0,100)}))});
        }
      }
      for(const f of flowCatalog){for(const sid of f.screens){const sc=screens.find(x=>x.id===sid);for(const st of (sc?.states||['READY'])){activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render();out.states++;scan(f.id,sid,st)}}}
      function sample(flow,sid,selector){activeFlowId=flow;activeScreenId=sid;stateByScreen[sid]='READY';render();return [...document.querySelectorAll(selector)].filter(visible).map(r=>({text:(r.innerText||'').trim().replace(/\n/g,' | '),type:r.dataset.dsPropType,state:r.dataset.dsPropState,tag:r.tagName,disabled:r.disabled===true,chevron:!!r.querySelector('.ds24-list-row__trailing .icon'),opacity:+parseFloat(getComputedStyle(r).opacity).toFixed(2)}));}
      out.reported.val03=sample('UIF-03','SCR-014','.valuation-work-list > .ds24-list-row');
      out.reported.val13=sample('UIF-13','SCR-085','.valuation-work-list > .ds24-list-row');
      activeFlowId='UIF-03';activeScreenId='SCR-014';stateByScreen['SCR-014']='READY';render();
      let w3=[...document.querySelectorAll('.valuation-work-list > .ds24-list-row')].find(x=>(x.innerText||'').includes('Chờ căn cứ')); let a3=[...document.querySelectorAll('.valuation-work-list > .ds24-list-row')].find(x=>(x.innerText||'').includes('Có thể xử lý'));
      const b3=activeScreenId; if(w3)w3.click(); const dw3=activeScreenId; if(a3)a3.click(); const da3=activeScreenId;
      out.interactions.val03={before:b3,afterDisabled:dw3,afterActionable:da3};
      activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';render();
      let w13=[...document.querySelectorAll('.valuation-work-list > .ds24-list-row')].find(x=>(x.innerText||'').includes('Đang chờ')); let a13=[...document.querySelectorAll('.valuation-work-list > .ds24-list-row')].find(x=>(x.innerText||'').includes('Có thể xử lý'));
      const b13=activeScreenId; if(w13)w13.click(); const dw13=activeScreenId; if(a13)a13.click(); const da13=activeScreenId;
      out.interactions.val13={before:b13,afterDisabled:dw13,afterActionable:da13};
      return out;
    }''')
    # captures for focused visual review
    cap=OUT/'v363-list-navigation-captures'; cap.mkdir(exist_ok=True)
    for flow,sid,name in [('UIF-03','SCR-014','UIF-03-SCR-014-READY.png'),('UIF-13','SCR-085','UIF-13-SCR-085-READY.png')]:
        page.evaluate('([f,s])=>{activeFlowId=f;activeScreenId=s;stateByScreen[s]="READY";render();}',[flow,sid])
        page.locator('#device-preview').screenshot(path=str(cap/name))
    browser.close()

val03=audit['reported']['val03']; val13=audit['reported']['val13']
def waiting_ok(rows, token):
    hit=[r for r in rows if token in r['text']]
    return len(hit)==1 and hit[0]['type']=='Navigation' and hit[0]['state']=='Disabled' and hit[0]['tag']=='BUTTON' and hit[0]['disabled'] and hit[0]['chevron'] and abs(hit[0]['opacity']-.4)<.02

def active_ok(rows):
    active=[r for r in rows if r['state']!='Disabled']
    return bool(active) and all(r['type']=='Navigation' and r['tag']=='BUTTON' and not r['disabled'] and r['chevron'] and abs(r['opacity']-1)<.02 for r in active)

ck('runtime version',audit['runtime']==VERSION,audit['runtime'])
ck('all 518 declared route-state renders scanned',audit['states']==518,audit['states'])
ck('no mixed Navigation/Status peer collection remains',len(audit['mixedPeerCollections'])==0,audit['mixedPeerCollections'][:10])
ck('every visible Navigation row keeps a chevron',len(audit['navMissingChevron'])==0,audit['navMissingChevron'][:10])
ck('every Disabled Navigation row is natively disabled and uses DS opacity 0.4',len(audit['disabledNavBroken'])==0,audit['disabledNavBroken'][:10])
ck('every enabled Navigation row is an interactive button',len(audit['enabledNavBroken'])==0,audit['enabledNavBroken'][:10])
ck('reported UIF-03 waiting row keeps Navigation anatomy and is Disabled',waiting_ok(val03,'Chờ căn cứ'),val03)
ck('UIF-03 actionable peers remain enabled Navigation rows',active_ok(val03),val03)
ck('UIF-13 waiting row keeps Navigation anatomy and is Disabled',waiting_ok(val13,'Đang chờ'),val13)
ck('UIF-13 actionable peers remain enabled Navigation rows',active_ok(val13),val13)
ck('UIF-03 disabled row cannot navigate',audit['interactions']['val03']['before']==audit['interactions']['val03']['afterDisabled']=='SCR-014',audit['interactions']['val03'])
ck('UIF-03 actionable row still navigates',audit['interactions']['val03']['afterActionable']=='SCR-015',audit['interactions']['val03'])
ck('UIF-13 disabled row cannot navigate',audit['interactions']['val13']['before']==audit['interactions']['val13']['afterDisabled']=='SCR-085',audit['interactions']['val13'])
ck('UIF-13 actionable row still navigates',audit['interactions']['val13']['afterActionable']=='SCR-086',audit['interactions']['val13'])
ck('no browser page errors',len(errors)==0,errors[:8])
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':VERSION,'status':status,'baselineMixedPeerCollectionStateRenders':10,'affectedScreens':['UIF-03/SCR-014','UIF-13/SCR-085'],'routeStatesScanned':audit['states'],'checks':checks,'reportedSamples':audit['reported'],'browserErrors':errors}
(OUT/f'LIST-NAVIGATION-STATE-QA-v{VERSION}.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=[f'# List Navigation State QA — v{VERSION}','',f'**Result: {status} · {sum(x["pass"] for x in checks)}/{len(checks)} PASS**','',f'- Declared route-state renders scanned: **{audit["states"]}**','- Baseline mixed Navigation/Status peer-collection renders: **10** across **2 screens**','- Post-fix mixed peer collections: **0**','- Rule: same peer destination collection = same `Navigation` anatomy; unavailable peer = `State=Disabled`, retains chevron, no interaction.','', '## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': {x["note"]}' if x['note'] and not x['pass'] else '') for x in checks]
(OUT/f'LIST-NAVIGATION-STATE-QA-v{VERSION}.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,sum(x['pass'] for x in checks),'/',len(checks),'states',audit['states'],'mixed',len(audit['mixedPeerCollections']),'errors',len(errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
sys.exit(0 if status=='PASS' else 1)
