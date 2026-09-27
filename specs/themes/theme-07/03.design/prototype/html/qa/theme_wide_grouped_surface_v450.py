from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
CAP=OUT/'v450-theme-wide-grouped-surface-captures'; CAP.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8'); styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    q=ROOT/fn
    if q.exists(): styles.append(q.read_text(encoding='utf-8'))
    idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
    q=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>','<script>'+q.read_text(encoding='utf-8').replace('</script>','<\\/script>')+'</script>' if q.exists() else '')
ROW='[data-ds-component="DS v2 / Info Row"],[data-ds-component="DS v2 / Key-value Row"]'
AUDIT=r'''() => {
  const root=document.querySelector('#app-screen');
  const rowSelector='[data-ds-component="DS v2 / Info Row"],[data-ds-component="DS v2 / Key-value Row"]';
  const alpha=(value)=>{const t=String(value||'');if(!t||t==='transparent')return 0;const m=t.match(/rgba?\(([^)]+)\)/i);if(!m)return 1;const p=m[1].split(',').map(v=>v.trim());return p.length<4?1:Number(p[3]);};
  const surface=(el)=>{if(!el)return false;const s=getComputedStyle(el);const b=[s.borderTopWidth,s.borderRightWidth,s.borderBottomWidth,s.borderLeftWidth].some(v=>(parseFloat(v)||0)>.1);return alpha(s.backgroundColor)>.01||b||(s.boxShadow&&s.boxShadow!=='none');};
  const boundary=(el)=>!el||el===root||el.matches?.('#app-screen,.app-content,.app-body,.app-shell,.device-screen');
  const groups=[];
  root?.querySelectorAll('*').forEach(el=>{
    const rows=[...el.children].filter(ch=>ch.matches?.(rowSelector));
    if(rows.length<2)return;
    if([...el.children].some(ch=>[...ch.children].filter(g=>g.matches?.(rowSelector)).length>=2))return;
    let owner=null,current=el;
    for(let depth=0;current&&depth<3&&!boundary(current);depth++,current=current.parentElement){if(surface(current)){owner=current;break;}}
    const s=getComputedStyle(el); const r=el.getBoundingClientRect();
    const rowCards=rows.filter(row=>{const rs=getComputedStyle(row);return (parseFloat(rs.borderTopWidth)||0)>.1&&(parseFloat(rs.borderTopLeftRadius)||0)>.1&&!row.matches('[data-ds-prop-state="Emphasis"]');}).length;
    groups.push({cls:String(el.className||''),rows:rows.length,owner:owner?String(owner.className||owner.tagName):null,auto:el.getAttribute('data-v440-grouped-surface')||null,bg:s.backgroundColor,border:s.borderTopWidth,radius:s.borderTopLeftRadius,rowCards,w:Math.round(r.width),h:Math.round(r.height),text:(el.innerText||'').trim().replace(/\s+/g,' ').slice(0,160)});
  });
  const app=document.querySelector('#app-screen'),content=document.querySelector('.app-content');
  return {groups,overflow:{app:app?app.scrollWidth-app.clientWidth:0,content:content?content.scrollWidth-content.clientWidth:0},nestedAuto:root?root.querySelectorAll('.v440-grouped-surface .v440-grouped-surface').length:0};
}'''
checks=[]; errors=[]; render_rows=[]; flow_auto={}; captures={}
def ck(name,cond,detail=''): checks.append({'name':name,'pass':bool(cond),'detail':detail})
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(7000)
    p.on('pageerror',lambda e: errors.append(str(e))); p.set_content(html,wait_until='load')
    data=p.evaluate("() => ({flows:VET45_HARNESS_DATA.flows.map(f=>({id:f.id,screens:f.screens})),screens:VET45_HARNESS_DATA.screens.map(s=>({id:s.id,states:s.states||[]}))})")
    smap={s['id']:s['states'] for s in data['screens']}
    for flow in data['flows']:
        if not flow['id'].startswith('UIF-'): continue
        for sid in flow['screens']:
            for state in smap.get(sid) or ['READY']:
                before=len(errors)
                p.evaluate("([f,s,st])=>{activeFlowId=f;activeScreenId=s;if(stateByScreen[s]!==undefined)stateByScreen[s]=st;render();}",[flow['id'],sid,state])
                p.wait_for_timeout(2)
                a=p.evaluate(AUDIT)
                bad=[g for g in a['groups'] if not g['owner']]
                card_soup=[g for g in a['groups'] if g['rowCards']>0]
                auto=sum(1 for g in a['groups'] if g['auto']=='auto')
                flow_auto[flow['id']]=flow_auto.get(flow['id'],0)+auto
                ok=not bad and not card_soup and a['overflow']['app']<=1 and a['overflow']['content']<=1 and a['nestedAuto']==0 and len(errors)==before
                render_rows.append({'flow':flow['id'],'screen':sid,'state':state,'pass':ok,'autoGroups':auto,'groups':len(a['groups']),'bad':bad,'cardSoup':card_soup,'overflow':a['overflow'],'nestedAuto':a['nestedAuto']})
    # Representative screenshots for every flow that required an automatic repair in the current dataset.
    reps=[('UIF-01','SCR-003','READY','01-scr003.png'),('UIF-02','SCR-010','READY','02-scr010.png'),('UIF-05','SCR-028','READY','05-scr028.png'),('UIF-03','SCR-015','READY','03-existing-surface.png'),('UIF-07','SCR-041','COMPLETED','07-existing-subgroup-surface.png')]
    for flow,sid,state,name in reps:
        p.evaluate("([f,s,st])=>{activeFlowId=f;activeScreenId=s;if(stateByScreen[s]!==undefined)stateByScreen[s]=st;render();}",[flow,sid,state]);p.wait_for_timeout(10)
        p.locator('#device-preview').screenshot(path=str(CAP/name)); captures[name]={'flow':flow,'screen':sid,'state':state}
    b.close()
failed=[r for r in render_rows if not r['pass']]
ck('All canonical UIF screen/state renders satisfy grouped-surface invariant',not failed,json.dumps(failed[:10],ensure_ascii=False))
ck('No browser runtime errors',not errors,json.dumps(errors[:10],ensure_ascii=False))
ck('Theme-wide audit includes all 17 canonical UIFs',len([k for k in flow_auto if k.startswith('UIF-')])==17,str(sorted(flow_auto)))
# Parent audit proved these were the true uncovered row groups outside valuation; ensure the generic rule repairs them.
for flow in ['UIF-01','UIF-02','UIF-05']:
    ck(f'{flow} receives at least one automatic grouped surface repair',flow_auto.get(flow,0)>0,str(flow_auto.get(flow,0)))
# Existing mature surfaces must not be needlessly nested.
ck('No nested automatic grouped surfaces',all(r['nestedAuto']==0 for r in render_rows),'')
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
payload={'status':status,'version':'4.5.0','parent':'4.4.0','renders':len(render_rows),'passed':sum(r['pass'] for r in render_rows),'checks':checks,'flowAutoGroupApplications':flow_auto,'browserErrors':errors,'captures':captures,'renderResults':render_rows}
(OUT/'THEME-WIDE-GROUPED-SURFACE-v4.5.0.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'THEME-WIDE-GROUPED-SURFACE-v4.5.0.md').write_text('\n'.join(['# Theme-wide Grouped Surface QA v4.5.0','',f'**Result: {status}**',f'**Renders: {payload["passed"]}/{payload["renders"]}**','']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']} {x['detail']}" for x in checks]+['',f'- Browser errors: {len(errors)}',f'- Automatic applications by UIF: `{json.dumps(flow_auto,ensure_ascii=False)}`'])+'\n',encoding='utf-8')
print(status,'renders',payload['passed'],'/',payload['renders'],'checks',sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors),'auto',flow_auto)
if status!='PASS': raise SystemExit(1)
