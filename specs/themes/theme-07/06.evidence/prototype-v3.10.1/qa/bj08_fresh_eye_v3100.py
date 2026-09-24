#!/usr/bin/env python3
from pathlib import Path
import re,json,sys
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1];QA=Path(__file__).resolve().parent;CAP=QA/'v3100-bj08-captures';CAP.mkdir(exist_ok=True)
def inline(root):
 h=(root/'index.html').read_text();h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
 for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
  p=root/fn.split('?')[0];h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text()}</style>' if p.exists() else '',h,count=1)
 for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
  p=root/fn.split('?')[0];h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text()}</script>' if p.exists() else '')
 return h
checks=[]
def ck(n,c,note=''):checks.append({'name':n,'pass':bool(c),'note':str(note)[:800]})
errs=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);p=b.new_page(viewport={'width':1450,'height':1050});p.set_default_timeout(5000);p.on('pageerror',lambda e:errs.append(str(e)));p.set_content(inline(ROOT),wait_until='load',timeout=30000)
 def go(s,st='READY'):
  p.evaluate('([s,t])=>{activeFlowId="UIF-08";activeScreenId=s;stateByScreen[s]=t;render()}',[s,st]);p.wait_for_timeout(10);p.locator('#app-screen').screenshot(path=str(CAP/f'{s}-{st}.png'));return p.locator('#app-screen').inner_text()
 t=go('SCR-042');search=p.locator('input[placeholder="Tìm phiên kiểm kê"]');ck('list is task-oriented and keeps search/filter',search.count()==1 and p.locator('[data-v350-ic08-filter]').count()==3,t[:400]);ck('browse list exposes no destructive cancel',p.locator('[data-v3100-ic08-action="cancel-open"]').count()==0)
 t=go('SCR-043');ck('open form uses business copy without technical English',not re.search(r'\b(?:Cut-off|UOM|UNKNOWN|snapshot|hash|backend|commit)\b',t,re.I),t);ck('open form explains lock/cutoff in user terms','Phạm vi được khóa khi mở phiên' in t and 'Thời điểm chốt' in t,t)
 t=go('SCR-043','COUNT_SCOPE_HAS_UNRESOLVED_VALUATION');ck('unresolved valuation blocker is actionable Vietnamese','Chưa thể mở phiên' in t and 'xác nhận giá trị' in t and 'COUNT_SCOPE' not in t,t)
 t=go('SCR-044','BLIND_COUNT');ck('blind count truly hides book and variance','Theo sổ' not in t and 'Chênh lệch' not in t,t);ck('physical stock state distinguishes otherwise similar goods','Bán được' in t and 'Cách ly' in t,t);ck('counter has no price field','Nhập giá' not in t and p.locator('input').evaluate_all("els=>els.filter(e=>/giá|price/i.test((e.name||'')+' '+(e.placeholder||''))).length")==0,t)
 p.evaluate('ic08Counts={amox:"18",glove:"7"};activeScreenId="SCR-045";stateByScreen["SCR-045"]="RECOUNT_REQUIRED";render()');t=p.locator('#app-screen').inner_text();p.locator('#app-screen').screenshot(path=str(CAP/'SCR-045-RECOUNT_REQUIRED.png'));ck('recount presents book, first count and variance together',all(x in t for x in ['Theo sổ','Lần đếm đầu','Chênh lệch']),t);ck('recount makes prior evidence preservation understandable','Kết quả vòng trước được giữ nguyên trong lịch sử' in t,t)
 t=go('SCR-045','PRICE_BASIS_REQUIRED');ck('missing surplus value basis blocks without asking counter for price','Thiếu căn cứ giá hàng thừa' in t and 'người đếm không nhập giá' in t.lower(),t)
 p.evaluate('ic08Counts={amox:"18",glove:"7"};ic08Recounts={amox:"18",glove:"7"};activeScreenId="SCR-046";stateByScreen["SCR-046"]="APPROVAL_REQUIRED";render()');t=p.locator('#app-screen').inner_text();p.locator('#app-screen').screenshot(path=str(CAP/'SCR-046-APPROVAL_REQUIRED.png'));ck('approval is read-only and decision-focused',p.locator('[data-ic08-keypad-open]').count()==0 and 'không sửa số đếm' in t.lower(),t);ck('approval has no cancel action',p.locator('[data-v3100-ic08-action="cancel-open"]').count()==0);ck('financial risk is not exposed as unmasked amount','₫' not in t and re.search(r'\b\d{1,3}(?:\.\d{3})+\b',t) is None,t)
 go('SCR-042');p.click('[data-v3100-ic08-action="new"]');p.click('[data-v3100-ic08-action="open"]');p.click('[data-v3100-ic08-action="confirm-open"]');p.evaluate('ic08Counts={amox:"20",glove:"6"};render()');p.click('[data-v3100-ic08-action="submit-first"]');p.click('[data-v3100-ic08-action="confirm-first"]');t=p.locator('#app-screen').inner_text();p.locator('#app-screen').screenshot(path=str(CAP/'SCR-047-ZERO.png'));ck('zero result says no adjustment and unlocked','Không cần tạo điều chỉnh' in t and 'Không tạo' in t and 'Đã mở' in t,t)
 t=go('SCR-047','UNKNOWN');ck('UNKNOWN UI prohibits blind retry and offers verification','Không gửi lại thao tác' in t and 'Chuyển sang xác minh' in t,t)
 # geometry all focused screens/current states
 bad=[]
 for sid,st in [('SCR-042','READY'),('SCR-043','READY'),('SCR-044','BLIND_COUNT'),('SCR-045','RECOUNT_REQUIRED'),('SCR-046','APPROVAL_REQUIRED'),('SCR-047','COMPLETED')]:
  p.evaluate('([s,t])=>{activeScreenId=s;stateByScreen[s]=t;render()}',[sid,st]);m=p.evaluate('''()=>{const r=document.querySelector('#app-screen'),c=r.querySelector('.app-content');return [r.offsetWidth,r.offsetHeight,r.scrollWidth-r.clientWidth,c?(c.scrollWidth-c.clientWidth):0]}''');
  if m[0]!=402 or m[1]!=874 or m[2]>.75 or m[3]>.75:bad.append((sid,m))
 ck('focused BJ08 surfaces fit canonical 402x874',not bad,bad);ck('fresh-eye browser has no errors',not errs,errs)
 b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL';out={'version':'3.10.0','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errs,'captures':len(list(CAP.glob('*.png')))}
(QA/'BJ08-FRESH-EYE-QA-v3.10.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n');(QA/'BJ08-FRESH-EYE-QA-v3.10.0.md').write_text('\n'.join(['# BJ08 Fresh-eye QA — v3.10.0','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks])+'\n');print(status,out['passed'],out['total'],'captures',out['captures']);sys.exit(0 if status=='PASS' else 1)
