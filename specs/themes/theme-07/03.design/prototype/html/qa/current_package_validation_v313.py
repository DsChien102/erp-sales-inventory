from pathlib import Path
import json,re,hashlib
ROOT=Path(__file__).resolve().parents[4]  # theme-07
QA=Path(__file__).resolve().parent
checks=[]; findings=[]
def ck(name,cond,detail=''):
    checks.append({'name':name,'pass':bool(cond),'detail':detail})
    if not cond: findings.append({'severity':'HIGH','name':name,'detail':detail})
# versions
readme=(ROOT/'README.md').read_text(encoding='utf-8')
ck('Root version v3.13.0','version: v3.13.0' in readme)
ck('Parent v3.12.0','parent: v3.12.0' in readme)
# workbench / manifests
wb=json.load(open(ROOT/'03.design/prototype/html/workbench-data.json',encoding='utf-8'))
pm=json.load(open(ROOT/'03.design/prototype/html/prototype.manifest.json',encoding='utf-8'))
rm=json.load(open(ROOT/'03.design/prototype/html/manifest.json',encoding='utf-8'))
ck('Workbench version',wb.get('version')=='3.13.0',str(wb.get('version')))
ck('Prototype manifest version',pm.get('version')=='3.13.0' and pm.get('parentVersion')=='3.12.0')
ck('Runtime manifest version',rm.get('version')=='3.13.0' and rm.get('parentVersion')=='3.12.0')
expected={'UIF-03':['SCR-014','SCR-015','SCR-017','SCR-019'],'UIF-13':['SCR-085','SCR-086','SCR-088','SCR-089'],'UIF-14':['SCR-072','SCR-074','SCR-077']}
for fid,sids in expected.items():
    f=next(x for x in wb['flows'] if x['id']==fid)
    ck(f'{fid} topology',f['screens']==sids,str(f['screens']))
retired={'SCR-016','SCR-018','SCR-087','SCR-073','SCR-075','SCR-076'}
active=set(x for f in wb['flows'] for x in f['screens'])
ck('Retired valuation screens absent from active flows',not(active & retired),str(sorted(active & retired)))
ck('Active route occurrences = 86',sum(len(f['screens']) for f in wb['flows'])==86,str(sum(len(f['screens']) for f in wb['flows'])))
# Screen contracts exist
missing=[sid for sid in active if not (ROOT/'03.design/screens'/f'{sid}.md').exists()]
ck('All active screens have Screen Contract',not missing,str(missing))
# v313 layer is last CSS/JS
idx=(ROOT/'03.design/prototype/html/index.html').read_text(encoding='utf-8')
css_refs=re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx)
js_refs=re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"',idx)
ck('v313 CSS loaded last',css_refs and css_refs[-1]=='v313-valuation-design.css',str(css_refs[-3:]))
ck('v313 JS loaded last',js_refs and js_refs[-1].split('?')[0]=='v313-valuation-design.js',str(js_refs[-3:]))
# Active product-copy guard in new runtime
js=(ROOT/'03.design/prototype/html/v313-valuation-design.js').read_text(encoding='utf-8')
for term in ['DirectCostBasis','giá nhập thực tế','Ghi chi phí mua bổ sung','Nguồn chi phí','Chi phí đã ghi','OfficialCostVersion']:
    ck(f'No stale product copy: {term}',term not in js)
# canonical relative Markdown links: current authority areas + root, excluding historical QA/evidence
roots=[ROOT/'README.md',ROOT/'01.knowledge',ROOT/'02.specification',ROOT/'03.design/screens',ROOT/'03.design/patterns',ROOT/'03.design/design-system',ROOT/'03.design/prototype/README.md',ROOT/'04.harness/slices',ROOT/'09.generated/matrices/design/bj-ui-flow-map.md']
md=[]
for r in roots:
    if r.is_file(): md.append(r)
    elif r.exists(): md.extend(r.rglob('*.md'))
pat=re.compile(r'\[[^\]]*\]\(([^)]+)\)')
broken=[];count=0
for f in md:
    text=f.read_text(encoding='utf-8',errors='ignore')
    for link in pat.findall(text):
        link=link.strip().split()[0].strip('<>')
        if not link or link.startswith(('#','http://','https://','mailto:','javascript:')): continue
        target=link.split('#')[0]
        if not target: continue
        count+=1
        q=(f.parent/target).resolve()
        if not q.exists(): broken.append({'file':str(f.relative_to(ROOT)),'link':link})
ck('Canonical relative links resolve',not broken,f'checked={count}, broken={broken[:20]}')
# registry parity
reg=json.load(open(ROOT/'09.generated/registries/design/ui-flow-registry.json',encoding='utf-8'))
for fid,sids in expected.items():
    f=next(x for x in reg['flows'] if x['id']==fid)
    ck(f'{fid} registry parity',f['screen_ids']==sids and f.get('prototype_status')=='DESIGN_PARITY_v3.13.0',str(f.get('screen_ids')))
# Runtime QA artifacts
for fn in ['ALL-FLOWS-RUNTIME-SMOKE-v3.13.0.json','VALUATION-FLOW-E2E-v3.13.0.json','VALUATION-VISUAL-INTEGRITY-v3.13.0.json']:
    p=QA/fn
    ok=p.exists() and json.load(open(p,encoding='utf-8')).get('status')=='PASS'
    ck(f'QA PASS {fn}',ok)
contact=QA/'v313-valuation-captures/VALUATION-CONTACT-SHEET-v3.13.0.png'
ck('Valuation visual contact sheet exists',contact.exists() and contact.stat().st_size>0,str(contact))
# Figma evidence in design system profile
prof=(ROOT/'03.design/design-system/design-system-profile.md').read_text(encoding='utf-8')
for token in ['505:5890','4695:6353','547:1594','525:519','526:4215','Layout/Mobile width','Opacity/Disabled']:
    ck(f'DS profile evidence {token}',token in prof)
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'status':status,'checks':checks,'findings':findings}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.13.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Current Package Validation v3.13.0','',f'**Result: {status}**','']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']} — {x['detail']}" for x in checks]
(QA/'CURRENT-PACKAGE-VALIDATION-v3.13.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(status,'checks',sum(x['pass'] for x in checks),'/',len(checks),'links',count,'broken',len(broken),'findings',len(findings))
if status!='PASS':
    print([x for x in checks if not x['pass']][:20]); raise SystemExit(1)
