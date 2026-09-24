from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]

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
    p=b.new_page(viewport={'width':1500,'height':1100});p.set_default_timeout(5000);p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(inline(ROOT),wait_until='load',timeout=30000)
    def goto(flow,screen,state):
        p.evaluate("([f,s,st])=>{activeFlowId=f;activeScreenId=s;stateByScreen[s]=st;render()}",[flow,screen,state])
        p.wait_for_timeout(8)
        return p.locator('#app-screen').inner_text()

    t=goto('UIF-02','SCR-084','READY')
    ck('BJ02 direct product-detail READY owns a real product context','Nobivac DHPPi' in t and 'Chưa chọn sản phẩm' not in t,t[:240])

    t=goto('UIF-02','SCR-011','READY')
    ck('BJ02 direct approval READY exposes an actual approval reason','121 hộp' in t and 'Vượt chứng từ' in t and 'Chưa xong' not in t,t[:320])

    t=goto('UIF-02','SCR-012','COMPLETED')
    ck('BJ02 direct completed receipt shows handled source quantities',('120 hộp' in t or '121 hộp' in t) and '24 chai' in t and 'Chưa xong' not in t,t[:320])

    t=goto('UIF-03','SCR-019','COMPLETED')
    ck('BJ03 direct completed valuation is non-zero and scoped','4.085.000' in t and 'Nobivac' in t and '0 đ' not in [x.strip() for x in t.splitlines()],t[:320])

    t=goto('UIF-10','SCR-041','COMPLETED')
    ck('BJ10 direct disposal result reflects approved completion quantity','6 hộp' in t and '0 hộp' in t,t[:320])

    # Terminal defaults need a visible executable exit, not just static result copy.
    terminal=[('UIF-02','SCR-012','COMPLETED'),('UIF-03','SCR-019','COMPLETED'),('UIF-05','SCR-029','COMPLETED'),('UIF-07','SCR-041','COMPLETED'),('UIF-08','SCR-047','COMPLETED'),('UIF-09','SCR-041','COMPLETED'),('UIF-10','SCR-041','COMPLETED'),('UIF-12','SCR-071','COMPLETED'),('UIF-13','SCR-089','COMPLETED'),('UIF-14','SCR-077','COMPLETED'),('UIF-15','SCR-059','COMPLETED'),('UIF-16','SCR-083','RESOLVED'),('UIF-17','SCR-083','RESOLVED'),('CAP-01','SCR-065','COMPLETED')]
    bad=[]
    for flow,screen,state in terminal:
        goto(flow,screen,state)
        n=p.locator('#app-screen button:not([disabled]),#app-screen a[href],#app-screen [data-back]').count()
        if n<1: bad.append((flow,screen,state))
    ck('representative terminal states expose at least one executable exit',not bad,bad)

    # The destructive confirmation must fully own the visual layer; underlying sticky action cannot leak through.
    goto('UIF-08','SCR-044','BLIND_COUNT')
    p.locator('[data-ic08-action="cancel-open"]').click();p.wait_for_timeout(12)
    overlay=p.locator('.sheet-backdrop:has(.ds24-confirmation)').count()
    footer=p.locator('.v-page-scaffold > .app-actions')
    footer_vis=footer.evaluate("e=>getComputedStyle(e).visibility") if footer.count() else 'missing'
    boxes=p.evaluate('''()=>{const r=document.querySelector('#app-screen').getBoundingClientRect(),o=document.querySelector('.sheet-backdrop:has(.ds24-confirmation)').getBoundingClientRect();return {rootBottom:r.bottom,overlayBottom:o.bottom,delta:r.bottom-o.bottom}}''') if overlay else {'delta':999}
    ck('BJ08 confirmation fully masks the underlying session footer',overlay==1 and footer_vis=='hidden' and boxes['delta']<=16.1,f"overlay={overlay} footer={footer_vis} boxes={boxes}")

    ck('representative-coherence pass has no browser errors',not errors,errors[:8])
    b.close()

out={'version':'3.9.9','passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(ROOT/'qa'/'REPRESENTATIVE-COHERENCE-QA-v3.9.9.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
md=['# Representative Coherence QA — v3.9.9','',f"**Result: {out['passed']}/{out['total']} PASS**",'']
md += [f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}" + (f": {x['note']}" if x['note'] and not x['pass'] else '') for x in checks]
(ROOT/'qa'/'REPRESENTATIVE-COHERENCE-QA-v3.9.9.md').write_text('\n'.join(md)+'\n')
print(('PASS' if out['passed']==out['total'] else 'FAIL'),out['passed'],'/',out['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],'::',x['note'])
sys.exit(0 if out['passed']==out['total'] else 1)
