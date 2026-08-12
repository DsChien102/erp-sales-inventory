from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]
AC=['UIF-08','UIF-09','UIF-10','UIF-11','UIF-12','UIF-15','UIF-16','UIF-17']

def inline(root):
    h=(root/'index.html').read_text()
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
        p=root/fn.split('?')[0]
        h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text()}</style>' if p.exists() else '',h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
        p=root/fn.split('?')[0]
        h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text()}</script>' if p.exists() else '')
    return h

checks=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':note})
errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1500,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(inline(ROOT),wait_until='load',timeout=30000)
    states=p.evaluate('''()=>{
      const out=[];
      for(const f of flowCatalog){for(const sid of f.screens){const sc=screens.find(x=>x.id===sid);for(const st of (sc?.states||['READY'])){
        let err='';try{activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render()}catch(e){err=String(e)}
        const root=document.querySelector('#app-screen'),content=root?.querySelector('.app-content'),device=document.querySelector('.device-preview');
        const chipParents=[...new Set([...root.querySelectorAll('[data-ds-component="VChip"]')].filter(e=>e.offsetParent!==null).map(e=>e.parentElement))].map(e=>{
          const cs=getComputedStyle(e),r=e.getBoundingClientRect(),chips=[...e.querySelectorAll(':scope > [data-ds-component="VChip"]')].filter(x=>x.offsetParent!==null);
          const tops=chips.map(x=>Math.round(x.getBoundingClientRect().top*10)/10);
          const first=chips[0]?.getBoundingClientRect(),last=chips[chips.length-1]?.getBoundingClientRect();
          const old=e.scrollLeft;e.scrollLeft=e.scrollWidth;const rr=e.getBoundingClientRect(),lr=chips[chips.length-1]?.getBoundingClientRect();
          const lastReachable=!lr||lr.right<=rr.right+.75&&lr.left>=rr.left-.75;e.scrollLeft=old;
          return {cls:e.className||'',wrap:cs.flexWrap,ox:cs.overflowX,oy:cs.overflowY,h:r.height,sw:e.scrollWidth,cw:e.clientWidth,tops,firstVisible:!first||first.left>=r.left-.75&&first.right<=r.right+.75,lastReachable};
        });
        const listSurfaces=[...root.querySelectorAll('.ac310-list-surface,.io-list-card,.val03-work-list,.val13-list,.val14-run-list,.generic-card-list,.cf-movement-list,.cr-case-list')].filter(e=>e.offsetParent!==null).map(e=>{const cs=getComputedStyle(e);return {cls:e.className||'',bg:cs.backgroundColor,overflow:cs.overflow,border:cs.border,borderRadius:cs.borderRadius,rowCount:e.querySelectorAll('.ds24-list-row,.io-product-row,.io-order-row,.val03-work-row,.val14-run-row,.cf-movement-row,.generic-data-card').length};});
        const visibleHidden=root?[...root.querySelectorAll('[hidden]')].filter(e=>getComputedStyle(e).display!=='none'&&e.offsetParent!==null).length:0;
        const badHeadings=root?[...root.querySelectorAll('.ac310-section-title,.ds24-section-title,.io-section-title,h2,h3')].filter(e=>['Công việc','Phiên đang thực hiện'].includes(e.textContent.trim())).map(e=>e.textContent.trim()):[];
        const listOverlap=root?[...root.querySelectorAll('.ds24-list-row')].filter(e=>e.offsetParent!==null).map(e=>{const c=e.querySelector('.ds24-list-row__copy'),t=e.querySelector('.ds24-list-row__trailing');if(!c||!t)return null;const a=c.getBoundingClientRect(),bb=t.getBoundingClientRect();return {over:a.right>bb.left+.5,text:e.innerText.slice(0,100)}}).filter(Boolean):[];
        const textClip=root?[...root.querySelectorAll('strong,small,p,span,label,button')].filter(e=>e.offsetParent!==null&&e.childElementCount===0&&(e.textContent||'').trim()).map(e=>{const cs=getComputedStyle(e);return {t:e.textContent.trim().slice(0,100),sw:e.scrollWidth,cw:e.clientWidth,sh:e.scrollHeight,ch:e.clientHeight,ox:cs.overflowX,oy:cs.overflowY,to:cs.textOverflow}}).filter(x=>(x.sw>x.cw+1&&x.ox!=='visible'&&x.to!=='ellipsis')||(x.sh>x.ch+1&&x.oy!=='visible')):[];
        const text=(root?.innerText||'').trim();const dr=device?.getBoundingClientRect(),rr=root?.getBoundingClientRect();
        out.push({u:f.id,s:sid,st,err,w:root?.offsetWidth,h:root?.offsetHeight,deviceW:dr?.width,deviceH:dr?.height,rootW:rr?.width,rootH:rr?.height,x:(root?.scrollWidth||0)-(root?.clientWidth||0),cx:content?(content.scrollWidth-content.clientWidth):0,text,chipParents,listSurfaces,visibleHidden,badHeadings,listOverlap,textClip});
      }}}
      return out;
    }''')
    bad=[x for x in states if x['err'] or x['w']!=402 or x['h']!=874 or abs(x['rootW']-402)>.75 or abs(x['rootH']-874)>.75 or abs(x['deviceW']-418)>.75 or abs(x['deviceH']-890)>.75 or x['x']>.75 or x['cx']>.75 or not x['text']]
    ck('all 518 declared states render on canonical device geometry',len(states)==518 and not bad,f"states={len(states)} bad={bad[:3]}")
    routes=p.evaluate('flowCatalog.reduce((n,f)=>n+f.screens.length,0)')
    ck('all 89 canonical flow-screen routes are represented',routes==89,f"routes={routes}")
    ac=[x for x in states if x['u'] in AC];acbad=[x for x in ac if x['err'] or x['x']>.75 or x['cx']>.75]
    ck('audit-control states render',len(ac)==272 and not acbad,f"states={len(ac)} bad={acbad[:3]}")

    chip_bad=[]
    for x in states:
        for c in x['chipParents']:
            if len(c['tops'])<2: continue
            if c['wrap']!='nowrap' or c['ox'] not in ('auto','scroll') or c['oy'] not in ('hidden','clip') or c['h']>46 or len(set(c['tops']))!=1 or not c['firstVisible'] or not c['lastReachable']:
                chip_bad.append((x['u'],x['s'],x['st'],c))
    ck('all multi-chip search/filter sets are one-line horizontal scroll strips',not chip_bad,chip_bad[:6])

    list_bad=[]
    for x in states:
        for s in x['listSurfaces']:
            if s['rowCount']>=2 and s['bg'] not in ('rgba(0, 0, 0, 0)','transparent'):
                # Semantic grouped product/fact surfaces are not selected by these independent-list classes.
                list_bad.append((x['u'],x['s'],x['st'],s))
    ck('independent list containers never paint background into row spacing',not list_bad,list_bad[:8])

    hidden=[(x['u'],x['s'],x['st'],x['visibleHidden']) for x in states if x['visibleHidden']]
    ck('hidden rows remain actually hidden',not hidden,hidden[:6])
    headings=[(x['u'],x['s'],x['st'],x['badHeadings']) for x in states if x['badHeadings']]
    ck('no forbidden redundant list headings',not headings,headings[:6])
    patt=re.compile(r'\bCut-off\b|\bUOM\b|\bLOT\b|\bUNKNOWN\b|\b[A-Za-z]+_UNKNOWN\b|\b(?:v7|v8)\b|\bledger\b|\bprojection\b|\bcommit\b|\brecovery\b|\bsnapshot\b|\bhash\b|\bbackend\b|\bfrontend\b',re.I)
    leaked=[(x['u'],x['s'],x['st'],patt.findall(x['text'])[:5]) for x in states if patt.search(x['text'])]
    ck('no technical English/enums/version leakage',not leaked,leaked[:8])
    garbage=re.compile(r'\bundefined\b|\[object Object\]|\bnull\b',re.I)
    garbage_hits=[(x['u'],x['s'],x['st']) for x in states if garbage.search(x['text'])]
    ck('no runtime garbage copy',not garbage_hits,garbage_hits[:8])
    overlaps=[(x['u'],x['s'],x['st'],r) for x in states for r in x['listOverlap'] if r['over']]
    ck('List Row copy never overlaps trailing status/action',not overlaps,overlaps[:8])
    textclips=[(x['u'],x['s'],x['st'],x['textClip'][:4]) for x in states if x['textClip']]
    ck('visible text has no non-ellipsis clipping',not textclips,textclips[:8])

    # BJ09 history: detail -> history -> back must return exactly to detail, not result.
    p.evaluate("activeFlowId='UIF-09';activeScreenId='SCR-036';stateByScreen['SCR-036']='READY';stateByScreen['SCR-037']='READY';stateByScreen['SCR-041']='COMPLETED';render()")
    p.locator('[data-ic09-item]').first.click(); before=p.evaluate("({screen:activeScreenId,state:stateByScreen['SCR-037'],result:stateByScreen['SCR-041'],selected:ic09Selected})")
    p.locator('[data-ic09-action="history"]').click(); hist=p.evaluate('activeScreenId')
    p.locator('.app-back-button').click(); after=p.evaluate("({screen:activeScreenId,state:stateByScreen['SCR-037'],result:stateByScreen['SCR-041'],selected:ic09Selected})")
    ck('BJ09 history back returns to launching detail without result mutation',hist=='SCR-056' and before==after and after['screen']=='SCR-037',f'before={before} history={hist} after={after}')

    # BJ15 drill-down return path is explicit as well: result -> movement -> source -> movement -> result.
    p.evaluate("activeFlowId='UIF-15';activeScreenId='SCR-055';stateByScreen['SCR-055']='READY';cf15ReportType='STOCK_CARD';cf15Product='P-NOB';cf15SelectedProduct='P-NOB';cf15From='2026-09-01';cf15To='2026-09-30';render()")
    mv=p.locator('[data-cf15-movement]').first
    bj15ok=False;seq=[]
    if mv.count():
        mv.click();seq.append(p.evaluate('activeScreenId'))
        p.locator('[data-cf15-action="source"]').click();seq.append(p.evaluate('activeScreenId'))
        p.locator('.app-back-button').click();seq.append(p.evaluate('activeScreenId'))
        p.locator('.app-back-button').click();seq.append(p.evaluate('activeScreenId'))
        bj15ok=seq==['SCR-056','SCR-057','SCR-056','SCR-055']
    ck('BJ15 auxiliary drill-down back path preserves parent context',bj15ok,f'seq={seq}')
    ck('no browser errors',not errors,errors[:8])
    b.close()

out={'version':'3.7.0','passed':sum(x['pass'] for x in checks),'total':len(checks),'declared_states':518,'audit_control_states':272,'canonical_routes':89,'checks':checks}
(ROOT/'qa'/'RUNTIME-UI-QA-v3.7.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
md=['# Runtime UI QA — v3.7.0','',f"**Result: {out['passed']}/{out['total']} PASS**",'',f"- Declared-state renders: {out['declared_states']}/{out['declared_states']}",f"- Audit & Control state renders: {out['audit_control_states']}/{out['audit_control_states']}",f"- Canonical flow-screen routes: {out['canonical_routes']}",'']
for x in checks: md.append(f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}" + (f": {x['note']}" if x['note'] and not x['pass'] else ''))
(ROOT/'qa'/'RUNTIME-UI-QA-v3.7.0.md').write_text('\n'.join(md)+'\n')
print(('PASS' if out['passed']==out['total'] else 'FAIL'),out['passed'],'/',out['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],'::',x['note'])
sys.exit(0 if out['passed']==out['total'] else 1)
