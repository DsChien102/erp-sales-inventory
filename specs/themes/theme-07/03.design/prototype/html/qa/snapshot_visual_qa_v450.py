from pathlib import Path
import re,json,math
from playwright.sync_api import sync_playwright
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
CAP=OUT/'v450-snapshot-review'; CONTACT=OUT/'v450-snapshot-contact-sheets'; RISK=OUT/'v450-risk-state-captures'
for d in (CAP,CONTACT,RISK): d.mkdir(parents=True,exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8')
# Inline local CSS/JS in document order.
for m in re.findall(r'<link[^>]+rel=["\']stylesheet["\'][^>]+href=["\']([^"\']+)["\'][^>]*>',idx):
    p=ROOT/m
    if p.is_file():
        pat=re.compile(r'<link[^>]+rel=["\']stylesheet["\'][^>]+href=["\']'+re.escape(m)+r'["\'][^>]*>')
        idx=pat.sub(lambda _: '<style data-src="'+m+'">\n'+p.read_text(encoding='utf-8')+'\n</style>',idx,1)
for m in re.findall(r'<script[^>]+src=["\']([^"\']+)["\'][^>]*></script>',idx):
    p=ROOT/m.split('?')[0]
    if p.is_file():
        pat=re.compile(r'<script[^>]+src=["\']'+re.escape(m)+r'["\'][^>]*></script>')
        idx=pat.sub(lambda _: '<script data-src="'+m+'">\n'+p.read_text(encoding='utf-8').replace('</script>','<\\/script>')+'\n</script>',idx,1)

AUDIT=r'''() => {
 const root=document.querySelector('#app-screen');
 const visible=e=>{const s=getComputedStyle(e),r=e.getBoundingClientRect();return s.display!=='none'&&s.visibility!=='hidden'&&r.width>1&&r.height>1};
 const out={hOverflow:(root?.scrollWidth||0)-(root?.clientWidth||0),banners:[],rows:[],progress:[],blank:!(root?.innerText||'').trim()};
 root?.querySelectorAll('[data-ds-component="VBanner"],.v-banner').forEach(e=>{if(!visible(e))return;const r=e.getBoundingClientRect();out.banners.push({density:e.getAttribute('data-ds-prop-density')||'',h:r.height,ch:e.clientHeight,sh:e.scrollHeight,overflow:e.scrollHeight>e.clientHeight+2,text:(e.innerText||'').trim().replace(/\s+/g,' ').slice(0,220)});});
 root?.querySelectorAll('[data-ds-component="DS v2 / Info Row"],[data-ds-component="DS v2 / Key-value Row"]').forEach(e=>{if(!visible(e))return;const r=e.getBoundingClientRect();out.rows.push({component:e.getAttribute('data-ds-component'),w:r.width,h:r.height,cw:e.clientWidth,sw:e.scrollWidth,ch:e.clientHeight,sh:e.scrollHeight,overflow:e.scrollWidth>e.clientWidth+2||e.scrollHeight>e.clientHeight+2,text:(e.innerText||'').trim().replace(/\s+/g,' ').slice(0,180)});});
 root?.querySelectorAll('[data-ds-component="VProgress"]').forEach(e=>{if(!visible(e))return;out.progress.push({text:(e.innerText||'').trim(),h:e.getBoundingClientRect().height});});
 return out;
}'''

risk_cases=[
 ('UIF-02','SCR-008','READY'),('UIF-02','SCR-008','VALIDATION_ERROR'),
 ('UIF-03','SCR-019','COMPLETED'),('UIF-13','SCR-088','READY'),
 ('UIF-04','SCR-021','READY'),('UIF-06','SCR-031','RETURN_CAP_CHANGED'),
 ('UIF-07','SCR-039','READY'),('UIF-07','SCR-039','SOURCE_CHANGED'),
 ('UIF-09','SCR-037','EXPIRED'),('UIF-11','SCR-049','BLOCKED_PHYSICAL_HANDOVER'),
 ('UIF-14','SCR-074','CALCULATING'),('UIF-16','SCR-081','REBUILDING'),
 ('UIF-13','SCR-086','READY')]
records=[]; allstates=[]; errors=[]; risk_out=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1500,'height':1100}); p.set_default_timeout(8000); p.on('pageerror',lambda e: errors.append(str(e))); p.set_content(idx,wait_until='load',timeout=60000)
    data=p.evaluate("() => ({flows:VET45_HARNESS_DATA.flows.map(f=>({id:f.id,name:f.name||'',screens:f.screens})),screens:VET45_HARNESS_DATA.screens.map(s=>({id:s.id,name:s.name||s.title||'',states:s.states||[]}))})")
    sm={s['id']:s for s in data['screens']}
    # Screenshot every active/canonical flow occurrence using its preferred default state.
    for f in data['flows']:
        if not f['id'].startswith('UIF-'): continue
        fd=CAP/f['id']; fd.mkdir(exist_ok=True)
        for sid in f['screens']:
            states=sm.get(sid,{}).get('states') or []
            st='READY' if 'READY' in states or not states else states[0]
            p.evaluate('([f,s,st])=>{activeFlowId=f;activeScreenId=s;if(typeof stateByScreen!=="undefined")stateByScreen[s]=st;render();}',[f['id'],sid,st]); p.wait_for_timeout(8)
            audit=p.evaluate(AUDIT); fn=fd/f'{sid}-{st}.png'; p.locator('#device-preview').screenshot(path=str(fn))
            records.append({'flow':f['id'],'flowName':f['name'],'screen':sid,'screenName':sm.get(sid,{}).get('name',''),'state':st,'path':str(fn.relative_to(OUT)),'audit':audit})
    # All canonical states: metric gate, no screenshots required.
    for f in data['flows']:
        if not f['id'].startswith('UIF-'): continue
        for sid in f['screens']:
            for st in sm.get(sid,{}).get('states') or ['READY']:
                before=len(errors); p.evaluate('([f,s,st])=>{activeFlowId=f;activeScreenId=s;if(typeof stateByScreen!=="undefined")stateByScreen[s]=st;render();}',[f['id'],sid,st]); p.wait_for_timeout(2); a=p.evaluate(AUDIT)
                bad_banner=[x for x in a['banners'] if x['overflow']]
                bad_rows=[x for x in a['rows'] if x['overflow']]
                bad_progress=[x for x in a['progress'] if x['text']]
                ok=not a['blank'] and a['hOverflow']<=1 and not bad_banner and not bad_rows and not bad_progress and len(errors)==before
                allstates.append({'flow':f['id'],'screen':sid,'state':st,'pass':ok,'hOverflow':a['hOverflow'],'badBanners':bad_banner,'badRows':bad_rows,'badProgress':bad_progress})
    # High-risk states that caused or exposed previous regressions.
    for f,sid,st in risk_cases:
        p.evaluate('([f,s,st])=>{activeFlowId=f;activeScreenId=s;if(typeof stateByScreen!=="undefined")stateByScreen[s]=st;render();}',[f,sid,st]); p.wait_for_timeout(8)
        fn=RISK/f'{f}-{sid}-{st}.png'; p.locator('#device-preview').screenshot(path=str(fn)); risk_out.append({'flow':f,'screen':sid,'state':st,'path':str(fn.relative_to(OUT))})
    b.close()

# Contact sheets — one per UIF, based on actual screenshots.
try:
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',14); small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',11)
except Exception:
    font=small=None
for flow in sorted({r['flow'] for r in records}):
    rs=[r for r in records if r['flow']==flow]
    thumbw,th,labelh,cols=220,480,48,3; rows=math.ceil(len(rs)/cols)
    canvas=Image.new('RGB',(cols*thumbw,rows*(th+labelh)),(238,241,243)); d=ImageDraw.Draw(canvas)
    for i,r in enumerate(rs):
        im=Image.open(OUT/r['path']).convert('RGB'); im.thumbnail((thumbw-16,th-12)); x=(i%cols)*thumbw+(thumbw-im.width)//2; y=(i//cols)*(th+labelh)+labelh; canvas.paste(im,(x,y))
        lx=(i%cols)*thumbw+8; ly=(i//cols)*(th+labelh)+5; d.text((lx,ly),f"{r['screen']} · {r['state']}",fill=(20,25,30),font=font)
        if r['screenName']: d.text((lx,ly+20),r['screenName'][:28],fill=(90,100,110),font=small)
    canvas.save(CONTACT/f'{flow}.png')

failed=[r for r in allstates if not r['pass']]
default_failed=[]
for r in records:
    a=r['audit'];
    if a['blank'] or a['hOverflow']>1 or any(x['overflow'] for x in a['banners']) or any(x['overflow'] for x in a['rows']) or any(x['text'] for x in a['progress']): default_failed.append(r)
status='PASS' if not errors and not failed and not default_failed and len(records)==82 and len(list(CONTACT.glob('UIF-*.png')))==17 else 'FAIL'
payload={'id':'SNAPSHOT-LED-VISUAL-QA-v4.5.0','version':'4.5.0','parent':'4.4.0','status':status,'activeScreenCaptures':len(records),'contactSheets':len(list(CONTACT.glob('UIF-*.png'))),'allStateRenders':len(allstates),'allStatePassed':sum(r['pass'] for r in allstates),'riskStateCaptures':len(risk_out),'browserErrors':errors,'defaultFailures':default_failed,'allStateFailures':failed,'captures':records,'riskCaptures':risk_out}
(OUT/'SNAPSHOT-LED-VISUAL-QA-v4.5.0.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'SNAPSHOT-LED-VISUAL-QA-v4.5.0.md').write_text('\n'.join([
 '# Snapshot-led Visual QA v4.5.0','',f'**Result: {status}**','',
 f'- Active screen snapshots: **{len(records)}/82**',f'- UIF contact sheets: **{len(list(CONTACT.glob("UIF-*.png")))}/17**',f'- All-state renders: **{sum(r["pass"] for r in allstates)}/{len(allstates)}**',f'- High-risk state snapshots: **{len(risk_out)}**',f'- Browser runtime errors: **{len(errors)}**','',
 '## Review method','',
 '- Mỗi active screen được chụp ở product viewport 402×874.',
 '- Contact sheet được ghép theo UIF để review typography, spacing, surface, hierarchy, banner, footer và list/form rhythm.',
 '- Mọi canonical state được render lại để bắt horizontal overflow, VBanner overflow, Info Row/Key-value Row overflow và VProgress composition sai.',
 '- High-risk states là các state từng gây regression ở v4.4.0 hoặc có warning/error/processing content dài.','',
 '## Failures','', '- None.' if status=='PASS' else json.dumps(failed[:20],ensure_ascii=False,indent=2)
 ])+'\n',encoding='utf-8')
print(status,'captures',len(records),'contacts',len(list(CONTACT.glob('UIF-*.png'))),'states',sum(r['pass'] for r in allstates),'/',len(allstates),'risk',len(risk_out),'errors',len(errors))
if status!='PASS': raise SystemExit(1)
