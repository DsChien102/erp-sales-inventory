#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]; QA=Path(__file__).resolve().parent

def inline_html():
 h=(ROOT/'index.html').read_text(encoding='utf-8')
 h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
 for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
  p=ROOT/fn.split('?')[0];h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text(encoding="utf-8")}</style>' if p.exists() else '',h,count=1)
 for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
  p=ROOT/fn.split('?')[0];h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')
 return h
checks=[];errs=[]
def ck(n,v,note=''):checks.append({'name':n,'pass':bool(v),'note':note})
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);p=b.new_page(viewport={'width':1400,'height':1000});p.on('pageerror',lambda e:errs.append(str(e)));p.set_content(inline_html(),wait_until='load',timeout=30000)
 p.evaluate("()=>{activeFlowId='UIF-03';activeScreenId='SCR-014';stateByScreen['SCR-014']='READY';render();}")
 txt=p.locator('#app-screen').inner_text();ck('Operator can distinguish actionable vs waiting work without source-architecture explanation','Có thể xử lý' in txt and 'Chờ căn cứ' in txt and 'entry point' not in txt.lower(),txt[:900])
 p.locator('[data-val03-receipt="VAL03-R1"]').click();txt=p.locator('#app-screen').inner_text();ck('Scope screen tells user what can be selected next','Hàng cần xác nhận giá' in txt and 'Rà soát xác nhận' in txt,txt[:900]);ck('Technical tokens are not exposed on scope screen',not any(x in txt.lower() for x in ['basis_hash','scope_version','sourceversion','sha256']),txt[:1000])
 p.locator('[data-val03-slice="VAL03-S1"]').click();p.locator('[data-val03-action="open-review"]').click();txt=p.locator('#app-screen').inner_text();ck('Review answers cost, basis, scope and availability consequence in one mental task',all(x in txt for x in ['Giá nhập thực tế','Căn cứ giá','Lô DH2507','Khả dụng']),txt[:1300]);ck('Review has one commit CTA',p.locator('[data-val03-action="confirm-value"]').count()==1 and p.locator('#app-screen .button--primary').count()==1);ck('Review avoids normal-state badge noise','Sẵn sàng' not in txt,txt[:1100]);ck('Normalized base-UOM consequence is visible only when it changes meaning','Quy đổi lọ' in txt and '8.170 đ/lọ' in txt,txt[:1300])
 p.locator('[data-val03-action="confirm-value"]').click();txt=p.locator('#app-screen').inner_text();ck('Result is authoritative and final rather than a transient toast','Đã xác nhận giá' in txt and 'Giá trị đã ghi' in txt and p.locator('#app-screen .app-back-button').count()==0,txt[:1200]);ck('Result separates business time from recording time','Ngày nghiệp vụ' in txt and 'Ghi nhận lúc' in txt,txt[:1200]);ck('Result does not expose raw technical operation/hash/version tokens',not any(x in txt.lower() for x in ['basis_hash','scope_version','sha256-fixture','operationid']),txt[:1400])
 # Conflict path from a clean fixture
 p.goto('about:blank');p.set_content(inline_html(),wait_until='load',timeout=30000);p.evaluate("()=>{activeFlowId='UIF-03';val03SelectedReceiptId='VAL03-R1';activeScreenId='SCR-015';stateByScreen['SCR-015']='READY';render();}");p.locator('[data-val03-slice="VAL03-S4"]').click();p.locator('[data-val03-action="open-evidence-sheet"]').last.click();txt=p.locator('.val03-evidence-sheet').inner_text();ck('Conflict path asks for a business decision, not technical recovery','Chọn một căn cứ giá hoàn chỉnh' in txt and 'Lý do chọn căn cứ' in txt and 'retry' not in txt.lower(),txt[:1100]);ck('Conflict has no silent preselection',p.locator('[data-val03-source="VAL03-G2"][aria-pressed="true"]').count()==0)
 ck('Fresh-eye browser has no page errors',not errs,errs)
 b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL';out={'version':'3.9.7','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errs}
(QA/'BJ03-FRESH-EYE-QA-v3.9.7.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'BJ03-FRESH-EYE-QA-v3.9.7.md').write_text('\n'.join(['# BJ03 Fresh-eye QA — v3.9.7','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','','Re-walked as an end user after the Atomic Change Set: worklist → exact scope → review → commit result, plus conflict handling.','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'],'errors',len(errs))
if status!='PASS':
 for x in checks:
  if not x['pass']:print('FAIL',x)
 sys.exit(1)
