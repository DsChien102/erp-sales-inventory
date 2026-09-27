#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]; QA=Path(__file__).resolve().parent

def inline_html():
    h=(ROOT/'index.html').read_text(encoding='utf-8')
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
        p=ROOT/fn.split('?')[0]; h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text(encoding="utf-8")}</style>' if p.exists() else '',h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
        p=ROOT/fn.split('?')[0]; h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')
    return h

checks=[]; errors=[]
def ck(n,v,note=''):checks.append({'name':n,'pass':bool(v),'note':str(note)[:1400]})
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1080}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_default_timeout(8000); p.set_content(inline_html(),wait_until='load',timeout=30000)
    p.evaluate("()=>{activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';render();}")
    txt=p.locator('#app-screen').inner_text()
    ck('Worklist immediately explains what needs action','Chi phí mua bổ sung' in txt and 'VC-8842 · dòng 1' in txt and 'Chi phí vận chuyển' in txt,txt[:1000])
    ck('Normal actionable work is visually quiet','Có thể xử lý' not in p.locator('[data-val13-task="LC13-001"]').inner_text())
    ck('Blocked work tells user why it cannot proceed','Đang chờ' in p.locator('[data-val13-task="LC13-003"]').inner_text() and p.locator('[data-val13-task="LC13-003"]').get_attribute('aria-disabled')=='true')
    p.locator('[data-val13-task="LC13-001"]').click()
    ck('Choosing a task opens source/scope directly',p.evaluate('activeScreenId')=='SCR-086')
    txt=p.locator('#app-screen').inner_text()
    ck('Scope shows business evidence without technical IDs','Giá trị nguồn' in txt and 'Phạm vi liên quan' in txt and 'target_scope' not in txt.lower(),txt[:1500])
    ck('Fixed scope cannot be accidentally edited',p.locator('[data-val13-target]').count()==0)
    p.locator('[data-val13-action="scope-to-allocation"]').click()
    ck('Continue opens allocation task',p.evaluate('activeScreenId')=='SCR-087')
    sel=p.locator('[data-val13-method]'); sel.select_option('FIXTURE_VALUE')
    txt=p.locator('#app-screen').inner_text()
    ck('Allocation preview reconciles total before review','Kết quả phân bổ' in txt and 'Tổng phân bổ' in txt and '1.200.000' in txt,txt[:1600])
    ck('Period effect is stated in business language','Kỳ ghi nhận' in txt and 'kỳ mở' in txt.lower(),txt[:1800])
    p.locator('[data-val13-action="open-review"]').click()
    ck('Final review is one explicit confirmation surface',p.evaluate('activeScreenId')=='SCR-088' and p.locator('[data-val13-action="confirm-late-cost"]').count()==1)
    txt=p.locator('#app-screen').inner_text()
    ck('Review emphasizes decision consequences, not architecture','Chi phí sẽ ghi' in txt and 'Cần tính lại' in txt and 'LateLandedCost' not in txt and 'ValuationExposure' not in txt,txt[:1800])
    p.locator('[data-val13-action="confirm-late-cost"]').click()
    ck('Commit reaches terminal result without second modal',p.evaluate('activeScreenId')=='SCR-089')
    txt=p.locator('#app-screen').inner_text()
    ck('Result states what was recorded and what remains','Đã ghi chi phí mua bổ sung' in txt and 'Chi phí đã ghi' in txt and 'Cần tính lại' in txt,txt[:1800])
    ck('Result avoids raw implementation/finality identifiers',not any(x in txt for x in ['operationId','late_cost_basis_hash','allocation_hash','BJ14']),txt[:1800])
    p.locator('[data-val13-action="result-to-queue"]').click()
    ck('Result returns to worklist cleanly',p.evaluate('activeScreenId')=='SCR-085')
    ck('Fresh-eye walk has no browser errors',not errors,errors)
    b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'; out={'version':'3.9.8','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(QA/'BJ13-FRESH-EYE-QA-v3.9.8.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'BJ13-FRESH-EYE-QA-v3.9.8.md').write_text('\n'.join(['# BJ13 Fresh-eye QA — v3.9.8','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','','Re-walked as an end user after the Atomic Change Set: worklist → authoritative scope → allocation → final review → committed result → return to queue.','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'],'errors',len(errors))
if status!='PASS':
    [print('FAIL',x) for x in checks if not x['pass']];sys.exit(1)
