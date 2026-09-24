from pathlib import Path
from playwright.sync_api import sync_playwright
import json, re, sys

VERSION='3.7.0'
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
def ck(name,ok,note=''):
    checks.append({'name':name,'pass':bool(ok),'note':note})

with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1500,'height':1100})
    page.set_default_timeout(5000)
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.set_content(inline(ROOT),wait_until='load',timeout=30000)
    audit=page.evaluate(r'''()=>{
      const out={scanned:0,collisions:[],joined:[],overflow:[],reported:null,bj15:[],timeline:[],runtime:window.__VET45_PROTOTYPE__?.version||null};
      const px=s=>parseFloat(s)||0, visible=e=>e&&e.offsetParent!==null&&!e.hidden;
      function radii(cs){return {tl:px(cs.borderTopLeftRadius),tr:px(cs.borderTopRightRadius),bl:px(cs.borderBottomLeftRadius),br:px(cs.borderBottomRightRadius)}}
      function candidate(e){
        if(!visible(e))return false;
        const r=e.getBoundingClientRect(),cs=getComputedStyle(e),rd=radii(cs),bw=Math.max(px(cs.borderTopWidth),px(cs.borderBottomWidth),px(cs.borderLeftWidth),px(cs.borderRightWidth));
        if(r.width<250||r.height<36||Math.max(rd.tl,rd.tr,rd.bl,rd.br)<8)return false;
        const bg=cs.backgroundColor;
        const surfaced=bg==='rgb(255, 255, 255)'||bg==='rgba(255, 255, 255, 1)'||e.matches('.ds24-list-row,.timeline-card,.io-product-row,[data-ds-component="VCard"],.review-card,.product-card');
        return surfaced&&bw>=1;
      }
      function scanCurrent(flow,sid,st){
        const app=document.querySelector('#app-screen'),content=app?.querySelector('.app-content');
        if(content&&content.scrollWidth>content.clientWidth+1)out.overflow.push({flow,screen:sid,state:st,kind:'content',client:content.clientWidth,scroll:content.scrollWidth});
        const nodes=[...document.querySelectorAll('#app-screen *')].filter(candidate), by=new Map();
        for(const n of nodes){const p=n.parentElement;if(!p)continue;if(!by.has(p))by.set(p,[]);by.get(p).push(n)}
        for(const [p,k0] of by){const kids=k0.filter(x=>x.parentElement===p).sort((a,b)=>a.getBoundingClientRect().top-b.getBoundingClientRect().top);for(let i=1;i<kids.length;i++){
          const a=kids[i-1],b=kids[i],ar=a.getBoundingClientRect(),br=b.getBoundingClientRect();
          const overlap=Math.min(ar.right,br.right)-Math.max(ar.left,br.left); if(overlap<Math.min(ar.width,br.width)*.8)continue;
          const gap=br.top-ar.bottom; if(gap<-1.5)continue;
          const ac=getComputedStyle(a),bc=getComputedStyle(b),ra=radii(ac),rb=radii(bc);
          const intentionallyJoined=gap<1&&ra.bl<1&&ra.br<1&&rb.tl<1&&rb.tr<1;
          const rec={flow,screen:sid,state:st,gap:+gap.toFixed(2),parent:p.className||p.tagName,a:a.className||a.tagName,b:b.className||b.tagName,aText:(a.innerText||'').trim().slice(0,80),bText:(b.innerText||'').trim().slice(0,80)};
          if(intentionallyJoined)out.joined.push(rec); else if(gap<7.5)out.collisions.push(rec);
        }}
      }
      for(const f of flowCatalog){for(const sid of f.screens){const sc=screens.find(x=>x.id===sid);for(const st of (sc?.states||['READY'])){activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render();out.scanned++;scanCurrent(f.id,sid,st)}}}
      // Explicit regression samples.
      activeFlowId='UIF-08';activeScreenId='SCR-042';stateByScreen['SCR-042']='READY';render();
      let rs=[...document.querySelectorAll('.ac320-session-list > .ds24-list-row')].filter(visible).map(e=>e.getBoundingClientRect());
      out.reported={count:rs.length,gap:rs.length>1?+(rs[1].top-rs[0].bottom).toFixed(2):null};
      for(const st of ['ARCHIVED_DATA','STALE']){activeFlowId='UIF-15';activeScreenId='SCR-055';stateByScreen['SCR-055']=st;render();let x=[...document.querySelectorAll('.io-list-card > .io-product-list > .io-product-row')].filter(visible).map(e=>e.getBoundingClientRect());out.bj15.push({state:st,count:x.length,gaps:x.slice(1).map((r,i)=>+(r.top-x[i].bottom).toFixed(2))})}
      for(const st of ['CONFLICT','LOCKED','FINANCIAL_RESTRICTED']){activeFlowId='UIF-09';activeScreenId='SCR-056';stateByScreen['SCR-056']=st;render();let x=[...document.querySelectorAll('.timeline > .timeline-card')].filter(visible).map(e=>e.getBoundingClientRect());out.timeline.push({state:st,count:x.length,gap:x.length>1?+(x[1].top-x[0].bottom).toFixed(2):null})}
      return out;
    }''')
    browser.close()

ck('runtime version',audit['runtime']==VERSION,audit['runtime'])
ck('all declared route-state renders scanned',audit['scanned']==518,audit['scanned'])
ck('no independent surfaced cards touch or collide',len(audit['collisions'])==0,audit['collisions'][:12])
ck('joined parent-child composites remain allowed',len(audit['joined'])==5,f"joined={len(audit['joined'])}")
ck('reported BJ08 session list uses 12px peer-card gap',audit['reported']['count']==2 and abs(audit['reported']['gap']-12)<=.5,audit['reported'])
ck('BJ15 fallback result card rhythm fixed',all(x['count']>=3 and all(abs(g-12)<=.5 for g in x['gaps']) for x in audit['bj15']),audit['bj15'])
ck('BJ09 history timeline cards separated',all(x['count']==2 and abs(x['gap']-12)<=.5 for x in audit['timeline']),audit['timeline'])
ck('no Product content horizontal overflow',len(audit['overflow'])==0,audit['overflow'][:10])
ck('no browser page errors',len(errors)==0,errors[:8])
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':VERSION,'status':status,'baselineIndependentCollisionPairs':8,'postFixIndependentCollisionPairs':len(audit['collisions']),'routeStatesScanned':audit['scanned'],'checks':checks,'joinedCompositePairs':audit['joined'],'browserErrors':errors}
(OUT/f'LIST-SURFACE-RHYTHM-QA-v{VERSION}.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=[f'# List Surface Rhythm QA — v{VERSION}','',f'**Result: {status} · {sum(x["pass"] for x in checks)}/{len(checks)} PASS**','',f'- Declared route-state renders scanned: **{audit["scanned"]}**',f'- Baseline independent zero-gap/collision pairs identified: **8**',f'- Post-fix independent collision pairs: **{len(audit["collisions"])}**',f'- Intentional joined parent→child composite pairs preserved: **{len(audit["joined"])}**','', '## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': {x["note"]}' if x['note'] and not x['pass'] else '') for x in checks]
(OUT/f'LIST-SURFACE-RHYTHM-QA-v{VERSION}.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,sum(x['pass'] for x in checks),'/',len(checks),'collisions',len(audit['collisions']),'joined',len(audit['joined']),'errors',len(errors))
if audit['collisions']:
    for x in audit['collisions'][:20]:print('COLLISION',x)
sys.exit(0 if status=='PASS' else 1)
