from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1];OUT=Path(__file__).resolve().parent;CAP=OUT/'v430-valuation-captures';CAP.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8');styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    q=ROOT/fn
    if q.exists(): styles.append(q.read_text(encoding='utf-8'))
    idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^"]*)?)"[^>]*>\s*</script>',html):
    q=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>', '<script>'+q.read_text(encoding='utf-8')+'</script>' if q.exists() else '')
checks=[];errors=[]
def ck(name,cond,detail=''): checks.append({'name':name,'pass':bool(cond),'detail':detail})
def geometry(page):
    return page.evaluate("""() => {const s=document.querySelector('#app-screen'),c=document.querySelector('.app-content');return {screenOverflow:s.scrollWidth-s.clientWidth,contentOverflow:c?c.scrollWidth-c.clientWidth:0,contentPad:c?getComputedStyle(c).paddingLeft:null};}""")
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage','--allow-file-access-from-files'])
    p=b.new_page(viewport={'width':1440,'height':1100});p.set_default_timeout(6000);p.on('pageerror',lambda e:errors.append(str(e)));p.set_content(html,wait_until='load')
    states=[]
    # BJ03 list + doc conflict + quick form sheet
    p.evaluate("activeFlowId='UIF-03';activeScreenId='SCR-014';stateByScreen['SCR-014']='READY';render()")
    states.append(('03-014-list',geometry(p)));p.locator('#device-preview').screenshot(path=str(CAP/'03-014-list.png'))
    p.locator('[data-v430-val03-receipt="VAL03-R1"]').click();states.append(('03-015-doc-conflict',geometry(p)));p.locator('#device-preview').screenshot(path=str(CAP/'03-015-doc-conflict.png'))
    p.evaluate("activeScreenId='SCR-014';render()");p.locator('[data-v430-val03-receipt="VAL03-R2"]').click();p.locator('[data-v430-val03-add-basis]').click();states.append(('03-015-form-sheet',geometry(p)));p.locator('#device-preview').screenshot(path=str(CAP/'03-015-form-sheet.png'))
    sg=p.evaluate("""() => {const s=document.querySelector('.v430-form-sheet'),body=document.querySelector('.v430-form-sheet__body'),foot=document.querySelector('.v430-sheet-footer'),h=document.querySelector('.v430-sheet-handle');const r=s.getBoundingClientRect(),fr=foot.getBoundingClientRect(),br=body.getBoundingClientRect();return {w:r.width,h:r.height,overflow:s.scrollWidth-s.clientWidth,handle:[h.offsetWidth,h.offsetHeight],footerH:fr.height,bodyBottom:br.bottom,footerTop:fr.top,grid:getComputedStyle(s).gridTemplateRows};}""")
    ck('Form Sheet 402px and no horizontal overflow',abs(sg['w']-402)<1 and sg['overflow']<=1,str(sg));ck('Form Sheet handle 48×4',sg['handle']==[48,4],str(sg));ck('Form Sheet fixed footer 92px',abs(sg['footerH']-92)<1 and abs(sg['bodyBottom']-sg['footerTop'])<1,str(sg))
    # Form controls/touch targets.
    ts=p.evaluate("""() => Array.from(document.querySelectorAll('.v430-form-sheet button,.v430-form-sheet input,.v430-form-sheet textarea,.v430-form-sheet select')).filter(e=>{const r=e.getBoundingClientRect();return r.width>0&&r.height>0}).map(e=>({tag:e.tagName,h:e.getBoundingClientRect().height,w:e.getBoundingClientRect().width,aria:e.getAttribute('aria-label')||''}))""")
    bad=[x for x in ts if x['tag']!='TEXTAREA' and x['h']<43.5]
    ck('Form interactive targets >=44px',not bad,json.dumps(bad,ensure_ascii=False))
    # BJ13 edit/review
    p.evaluate("activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';render()");p.locator('[data-v430-val13-task="LC13-004"]').click();states.append(('13-086-edit',geometry(p)));p.locator('#device-preview').screenshot(path=str(CAP/'13-086-edit.png'))
    # BJ14 ready + confirmation
    p.evaluate("activeFlowId='UIF-14';activeScreenId='SCR-072';stateByScreen['SCR-072']='READY';render()");p.locator('[data-v430-val14-run="COST-0826"]').click();states.append(('14-074-ready',geometry(p)));p.locator('#device-preview').screenshot(path=str(CAP/'14-074-ready.png'));p.locator('[data-v430-val14-open-publish]').click();states.append(('14-074-confirm',geometry(p)));p.locator('#device-preview').screenshot(path=str(CAP/'14-074-confirm.png'))
    cg=p.evaluate("""() => {const s=document.querySelector('.v430-confirmation');const r=s.getBoundingClientRect();return {w:r.width,overflow:s.scrollWidth-s.clientWidth,component:s.dataset.dsComponent,figma:s.dataset.figmaNode};}""")
    ck('Publish Confirmation Sheet matches DS pattern',abs(cg['w']-402)<1 and cg['overflow']<=1 and cg['component']=='DS v2 / Confirmation Sheet' and cg['figma']=='550:1058',str(cg))
    # All captured states no horizontal overflow and 16px mobile edge.
    for name,g in states:
        ck(name+' no horizontal overflow',g['screenOverflow']<=1 and g['contentOverflow']<=1,str(g));ck(name+' mobile edge 16',g['contentPad']=='16px',str(g))
    # Avoid old custom valuation sheet and legacy titles in current states.
    ck('No old custom valuation sheet in live DOM',p.locator('.v313-sheet').count()==0)
    # Card density heuristic: no more than one Summary Card on ready BJ14 root.
    p.locator('button[data-v430-val14-publish-close]').click();
    ck('BJ14 ready has at most one Summary Card',p.locator('#app-screen [data-ds-component="DS v2 / Summary Card"]').count()<=1,str(p.locator('#app-screen [data-ds-component="DS v2 / Summary Card"]').count()))
    b.close()
status='PASS' if all(x['pass'] for x in checks) and not errors else 'FAIL'
payload={'status':status,'version':'4.3.0','checks':checks,'errors':errors,'captures':sorted(x.name for x in CAP.glob('*.png'))}
(OUT/'VALUATION-VISUAL-INTEGRITY-v4.3.0.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'VALUATION-VISUAL-INTEGRITY-v4.3.0.md').write_text('\n'.join(['# Valuation Visual Integrity v4.3.0','',f'**Result: {status}**','']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']} {x['detail']}" for x in checks]+['',f'- Browser errors: {len(errors)}'])+'\n',encoding='utf-8')
print(status,'checks',sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors))
if status!='PASS':
    print([x for x in checks if not x['pass']],errors);raise SystemExit(1)
