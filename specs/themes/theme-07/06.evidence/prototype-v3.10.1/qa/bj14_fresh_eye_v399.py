#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]; QA=Path(__file__).resolve().parent
def inline_html():
 h=(ROOT/'index.html').read_text(); h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
 for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
  p=ROOT/fn.split('?')[0]; h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text()}</style>' if p.exists() else '',h,count=1)
 for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
  p=ROOT/fn.split('?')[0]; h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text()}</script>' if p.exists() else '')
 return h
checks=[]; errors=[]
def ck(n,v,note=''):checks.append({'name':n,'pass':bool(v),'note':str(note)[:1200]})
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':1440,'height':1080}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_default_timeout(7000); p.set_content(inline_html(),wait_until='load',timeout=30000)
 p.evaluate("()=>{activeFlowId='UIF-14';activeScreenId='SCR-072';stateByScreen['SCR-072']='READY';render();}")
 txt=p.locator('#app-screen').inner_text(); ck('Worklist immediately distinguishes dirty work','Cần tính lại' in txt and 'nguyên nhân cần đối soát' in txt,txt[:1300]); ck('Worklist does not expose implementation identifiers',not any(x in txt.lower() for x in ['dirty_scope','hash','sequence']),txt[:1200])
 p.locator('[data-val14-run="COST-0903"]').click(); txt=p.locator('#app-screen').inner_text(); ck('Dirty work opens a constrained setup task',p.evaluate('activeScreenId')=='SCR-073' and 'Phạm vi cần tính lại' in txt); ck('Dirty Product set cannot be silently omitted',p.locator('[data-val14-scope]').count()==0); ck('Setup distinguishes calculation and posting period','Kỳ tính' in txt and 'Kỳ ghi nhận' in txt)
 p.evaluate("()=>{val14SelectedRunId='COST-0826';activeScreenId='SCR-074';stateByScreen['SCR-074']='READY';render();}"); txt=p.locator('#app-screen').inner_text(); ck('Result explains policy method and comparison without a method decision','Bình quân liên hoàn' in txt and 'Bình quân cuối kỳ' in txt and 'Theo chính sách' in txt); ck('Result exposes decision-relevant per-product change','Nobivac DHPPi' in txt and 'Có thay đổi' in txt); ck('Result calls the write effect a delta','Chênh lệch cần ghi' in txt)
 p.locator('[data-val14-action="review-publish"]').click(); txt=p.locator('#app-screen').inner_text(); ck('Review is a single final decision surface',p.evaluate('activeScreenId')=='SCR-076' and p.locator('[data-val14-action="publish"]').count()==1); ck('Review has no second method selector',p.locator('select[data-val14-method],input[name="method"]').count()==0); ck('Review makes forward-effective rule understandable','Không sớm hơn thời điểm công bố' in txt)
 p.locator('[data-val14-action="publish"]').click(); txt=p.locator('#app-screen').inner_text(); ck('Publication reaches terminal result without extra confirmation modal',p.evaluate('activeScreenId')=='SCR-077'); ck('Result tells user what was actually reconciled','Sản phẩm đã đối soát' in txt and 'Phiên bản giá vốn mới' in txt); ck('Result uses actual publication effective time, not historical planned date','17/09/2026 · 08:41' in txt and '01/09/2026 · 00:00' not in txt)
 p.evaluate("()=>{activeScreenId='SCR-077';stateByScreen['SCR-077']='UNKNOWN';render();}"); txt=p.locator('#app-screen').inner_text(); ck('Unknown finality is non-actionable and does not invite retry','Không gửi lại lệnh công bố' in txt and p.locator('[data-val14-action="publish"]').count()==0)
 ck('Fresh-eye walk has no browser errors',not errors,errors); b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'; out={'version':'3.9.9','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(QA/'BJ14-FRESH-EYE-QA-v3.9.9.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n'); (QA/'BJ14-FRESH-EYE-QA-v3.9.9.md').write_text('\n'.join(['# BJ14 Fresh-eye QA — v3.9.9','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' for x in checks])+'\n'); print(status,out['passed'],out['total']); sys.exit(0 if status=='PASS' else 1)
