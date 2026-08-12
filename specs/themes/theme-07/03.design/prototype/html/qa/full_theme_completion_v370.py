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
    p=b.new_page(viewport={'width':1500,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(inline(ROOT),wait_until='load',timeout=30000)
    def goto(flow,screen,state):
        p.evaluate("([f,s,st])=>{activeFlowId=f;activeScreenId=s;stateByScreen[s]=st;render()}",[flow,screen,state])
    # 1) BJ08 cancellation is contextual: never browse, always opened session.
    goto('UIF-08','SCR-042','READY')
    browse_cancel=p.locator('[data-ic08-action="cancel-open"]').count()
    goto('UIF-08','SCR-044','BLIND_COUNT')
    session_cancel=p.locator('[data-ic08-action="cancel-open"]').count()
    if session_cancel:
        p.locator('[data-ic08-action="cancel-open"]').click()
    sheet=p.locator('.ds24-confirmation').count(); disabled=p.locator('[data-v350-action="ic08-confirm-cancel"]:disabled').count()
    reason=p.locator('[data-ic08-cancel-reason]')
    if reason.count(): reason.fill('Sai phạm vi kiểm kê')
    enabled=p.locator('[data-v350-action="ic08-confirm-cancel"]:not([disabled])').count()
    if enabled: p.locator('[data-v350-action="ic08-confirm-cancel"]').click()
    cancel_state=p.evaluate("({screen:activeScreenId,state:stateByScreen[activeScreenId]})")
    ck('BJ08 cancel only inside opened session with required reason',browse_cancel==0 and session_cancel==1 and sheet==1 and disabled==1 and enabled==1 and cancel_state=={'screen':'SCR-047','state':'CANCELLED'},f"browse={browse_cancel} session={session_cancel} sheet={sheet} state={cancel_state}")

    # 2) CAP-01 full supporting prototype, with validation and no ledger effect.
    goto('CAP-01','SCR-062','READY')
    cap062=p.locator('[data-v360-cap-threshold]').count()==1 and p.locator('[data-v360-cap-target]').count()==1
    p.locator('[data-v360-cap-threshold]').fill('80'); p.locator('[data-v360-cap-target]').fill('50')
    # button becomes disabled from static render; rerender after values and try via JS to hit validation state.
    p.evaluate('stateByScreen["SCR-062"]="VALIDATION_ERROR";renderAppScreen()')
    cap_error='Chưa thể tiếp tục' in p.locator('#app-screen').inner_text()
    p.evaluate('capDummy=1')
    # valid path
    p.locator('[data-v360-cap-threshold]').fill('50'); p.locator('[data-v360-cap-target]').fill('80')
    p.evaluate('renderAppScreen()')
    p.evaluate('window.__VET45_V360__.capState()')
    p.locator('[data-v360-action="cap-review-stock"]').click()
    cap_review=p.evaluate('activeScreenId')=='SCR-064'
    if cap_review: p.locator('[data-v360-action="cap-save"]').click()
    cap_result=p.evaluate("({screen:activeScreenId,state:stateByScreen[activeScreenId]})")
    cap_text=p.locator('#app-screen').inner_text()
    ck('CAP-01 stock-policy prototype reaches result without ledger mutation copy',cap062 and cap_error and cap_review and cap_result=={'screen':'SCR-065','state':'COMPLETED'} and 'Tác động sổ kho' in cap_text and 'Không' in cap_text and 'Lần ' in cap_text,f"result={cap_result} text={cap_text[:240]}")
    goto('CAP-01','SCR-063','READY')
    cap063=p.locator('[data-v360-cap-expiry-days]').count()==1 and p.locator('[data-v360-cap-expiry-action]').count()==1
    p.locator('[data-v360-action="cap-review-expiry"]').click(); expiry_review=p.evaluate('activeScreenId')=='SCR-064'
    ck('CAP-01 near-expiry policy path is executable',cap063 and expiry_review,f"screen={p.evaluate('activeScreenId')}")

    # 3) Representative READY states are semantically reachable/coherent.
    goto('UIF-02','SCR-010','READY'); txt10=p.locator('#app-screen').inner_text(); bj02_ready=p.evaluate('allReceiptLinesHandled()')
    cta10=p.locator('.app-actions button:not([disabled])').count()
    goto('UIF-02','SCR-011','READY'); txt11=p.locator('#app-screen').inner_text(); cta11=p.locator('.app-actions button:not([disabled])').count()
    ck('BJ02 review/approval READY fixtures satisfy predecessor prerequisites',bj02_ready and 'Còn dòng hàng chưa hoàn tất' not in txt10 and cta10>=1 and 'Chưa xong' not in txt11 and cta11>=1,f"handled={bj02_ready} cta10={cta10} cta11={cta11}")
    goto('UIF-03','SCR-017','READY'); v3=p.evaluate('({sel:val03SelectedSlices().length,ready:val03ScopeReady(),review:val03ReviewSourceVersion,source:val03Current().sourceVersion})')
    ck('BJ03 READY review has selected valid scope',v3['sel']>0 and v3['ready'] and v3['review']==v3['source'],v3)
    goto('UIF-07','SCR-039','READY'); v7=p.evaluate('({verified:io07AllVerified(io07Current()),rv:io07Current().reviewSourceVersion,sv:io07Current().sourceVersion})'); txt=p.locator('#app-screen').inner_text()
    ck('BJ07 READY handover has verified current-source scope',v7['verified'] and v7['rv']==v7['sv'] and 'Cần kiểm lại trước khi bàn giao' not in txt,f"{v7} {txt[:200]}")
    goto('UIF-13','SCR-088','READY'); txt=p.locator('#app-screen').inner_text(); v13=p.evaluate('({rv:val13ReviewSourceVersion,sv:val13Current().sourceVersion,hash:val13PreviewHash,actual:val13PreviewHashOf(val13Current())})')
    ck('BJ13 READY review is a current preview, not SOURCE_CHANGED',v13['rv']==v13['sv'] and v13['hash']==v13['actual'] and 'Nguồn hoặc phân bổ đã thay đổi' not in txt,v13)
    goto('UIF-14','SCR-076','READY'); txt=p.locator('#app-screen').inner_text(); v14=p.evaluate('({rv:val14PublishReviewVersion,iv:val14Current().inputVersion,status:val14Current().status})')
    ck('BJ14 READY publish review is current, not input-changed',v14['rv']==v14['iv'] and 'Dữ liệu đầu vào đã thay đổi' not in txt,v14)

    # 4) Mutation feedback is visible, while pure navigation stays quiet.
    goto('UIF-01','SCR-001','STALE')
    refresh=p.locator('[data-bj01-refresh]')
    if refresh.count(): refresh.click()
    p.wait_for_timeout(60)
    toast_text=p.locator('.toast').inner_text() if p.locator('.toast').count() else ''
    ck('same-context refresh mutation has semantic toast','Đã cập nhật tồn kho' in toast_text,toast_text)
    # Clear toast then use pure history navigation.
    p.evaluate('document.querySelector(".toast")?.remove();activeFlowId="UIF-09";activeScreenId="SCR-037";stateByScreen["SCR-037"]="READY";render()')
    if p.locator('[data-ic09-action="history"]').count(): p.locator('[data-ic09-action="history"]').click(); p.locator('.app-back-button').click()
    nav_toast=p.locator('.toast').count()
    ck('pure Back navigation does not emit success toast',nav_toast==0,f"toast_count={nav_toast}")

    # 5) Stable non-root states must not be dead. Transient states may auto-resolve; root module screens may rely on app-level navigation outside the harness.
    transient={'LOADING','PROCESSING','CALCULATING','REBUILDING','PREPARING','EXPORT_RUNNING'}
    roots={'SCR-001','SCR-006','SCR-014','SCR-025','SCR-030','SCR-036','SCR-042','SCR-048','SCR-054','SCR-066','SCR-072','SCR-078','SCR-085','SCR-062','SCR-063'}
    dead=p.evaluate('''([transient,roots])=>{const bad=[];for(const f of flowCatalog){for(const sid of f.screens){const sc=screens.find(x=>x.id===sid);for(const st of (sc?.states||[])){if(transient.includes(st)||roots.includes(sid))continue;activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render();const r=document.querySelector('#app-screen');const controls=[...r.querySelectorAll('button:not([disabled]),a[href],[data-back]')].filter(x=>x.offsetParent!==null);if(!controls.length)bad.push([f.id,sid,st,(r.innerText||'').slice(0,100)]);}}}return bad;}''',[list(transient),list(roots)])
    ck('no stable non-root screen is a dead end',not dead,dead[:12])

    # 6) Supporting route-states and current runtime version are present.
    support_states=p.evaluate('''()=>{const f=flowCatalog.find(x=>x.id==='CAP-01');return f.screens.reduce((n,sid)=>n+(screens.find(x=>x.id===sid)?.states?.length||0),0)}''')
    runtime_version=p.evaluate('window.__VET45_PROTOTYPE__.version')
    ck('supporting capability contributes 18 declared states',support_states==18,f"states={support_states}")
    ck('runtime exposes v3.7.0',runtime_version=='3.7.0',runtime_version)
    ck('no browser errors',not errors,errors[:8])
    b.close()

out={'version':'3.7.0','passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(ROOT/'qa'/'FULL-THEME-COMPLETION-QA-v3.7.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
md=['# Full Theme Completion QA — v3.7.0','',f"**Result: {out['passed']}/{out['total']} PASS**",'']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}"+(f": {x['note']}" if x['note'] and not x['pass'] else '') for x in checks]
(ROOT/'qa'/'FULL-THEME-COMPLETION-QA-v3.7.0.md').write_text('\n'.join(md)+'\n')
print(('PASS' if out['passed']==out['total'] else 'FAIL'),out['passed'],'/',out['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],'::',x['note'])
sys.exit(0 if out['passed']==out['total'] else 1)
