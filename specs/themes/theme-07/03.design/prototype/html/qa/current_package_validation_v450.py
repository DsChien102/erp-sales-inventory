from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[4]
QA=Path(__file__).resolve().parent
checks=[]; findings=[]
def ck(name,cond,detail=''):
    checks.append({'name':name,'pass':bool(cond),'detail':detail})
    if not cond: findings.append({'severity':'HIGH','name':name,'detail':detail})
readme=(ROOT/'README.md').read_text(encoding='utf-8')
ck('Root version v4.5.0','version: v4.5.0' in readme)
ck('Parent v4.4.0','parent: v4.4.0' in readme)
wb=json.load(open(ROOT/'03.design/prototype/html/workbench-data.json',encoding='utf-8'))
pm=json.load(open(ROOT/'03.design/prototype/html/prototype.manifest.json',encoding='utf-8'))
rm=json.load(open(ROOT/'03.design/prototype/html/manifest.json',encoding='utf-8'))
ck('Workbench version',wb.get('version')=='4.5.0',str(wb.get('version')))
ck('Prototype manifest version',pm.get('version')=='4.5.0' and pm.get('parentVersion')=='4.4.0',str((pm.get('version'),pm.get('parentVersion'))))
ck('Runtime manifest version',rm.get('version')=='4.5.0' and rm.get('parentVersion')=='4.4.0',str((rm.get('version'),rm.get('parentVersion'))))
expected={'UIF-03':['SCR-014','SCR-015','SCR-017','SCR-019'],'UIF-13':['SCR-085','SCR-086','SCR-088','SCR-089'],'UIF-14':['SCR-072','SCR-074','SCR-077']}
for fid,sids in expected.items():
    f=next(x for x in wb['flows'] if x['id']==fid); ck(f'{fid} topology',f['screens']==sids,str(f['screens']))
active=[x for f in wb['flows'] for x in f['screens']]
ck('Active route occurrences = 86',len(active)==86,str(len(active)))
missing=[sid for sid in set(active) if not (ROOT/'03.design/screens'/f'{sid}.md').exists()]
ck('All active screens have Screen Contract',not missing,str(missing))
idx=(ROOT/'03.design/prototype/html/index.html').read_text(encoding='utf-8')
css_refs=re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx)
js_refs=re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^"]*)?)"',idx)
ck('v450 CSS loaded last',css_refs and css_refs[-1]=='v450-theme-visual-qa.css',str(css_refs[-4:]))
ck('v450 JS loaded last',js_refs and js_refs[-1].split('?')[0]=='v450-theme-visual-qa.js',str(js_refs[-4:]))
# Canonical links evidence generated at package root.
linkp=ROOT/'06.evidence/EVD-CANONICAL-LINKS-v4.5.0.json'
links=json.load(open(linkp,encoding='utf-8')) if linkp.exists() else {}
ck('Canonical links resolve',links.get('status')=='PASS' and links.get('broken')==[],str((links.get('links_checked'),len(links.get('broken',[])))))
# Semantic immutability evidence.
semp=ROOT/'06.evidence/EVD-SEMANTIC-IMMUTABILITY-v4.5.0.json'; sem=json.load(open(semp,encoding='utf-8')) if semp.exists() else {}
ck('BJ/UC/UIF/Screen semantic files unchanged',sem.get('status')=='PASS',str(sem.get('changed')))
# Runtime QA artifacts.
qafiles=['SNAPSHOT-LED-VISUAL-QA-v4.5.0.json','ALL-FLOWS-RUNTIME-SMOKE-v4.5.0.json','VALUATION-FLOW-E2E-v4.5.0.json','VALUATION-VISUAL-INTEGRITY-v4.5.0.json','VALUATION-FULL-STATE-SMOKE-v4.5.0.json','VALUATION-GROUPED-SURFACE-v4.5.0.json','THEME-WIDE-GROUPED-SURFACE-v4.5.0.json']
for fn in qafiles:
    p=QA/fn; ok=p.exists() and json.load(open(p,encoding='utf-8')).get('status')=='PASS'; ck(f'QA PASS {fn}',ok)
snap=json.load(open(QA/'SNAPSHOT-LED-VISUAL-QA-v4.5.0.json',encoding='utf-8'))
ck('82 active screen snapshots',snap.get('activeScreenCaptures')==82,str(snap.get('activeScreenCaptures')))
ck('17 UIF contact sheets',snap.get('contactSheets')==17,str(snap.get('contactSheets')))
ck('486 all-state visual renders',snap.get('allStatePassed')==486 and snap.get('allStateRenders')==486,str((snap.get('allStatePassed'),snap.get('allStateRenders'))))
ck('13 high-risk state snapshots',snap.get('riskStateCaptures')==13,str(snap.get('riskStateCaptures')))
# Figma DS evidence remains canonical.
prof=(ROOT/'03.design/design-system/design-system-profile.md').read_text(encoding='utf-8')
for token in ['505:5890','526:4215','525:351','525:358']:
    ck(f'DS profile evidence {token}',token in prof)
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'status':status,'version':'4.5.0','parent':'4.4.0','checks':checks,'findings':findings,'canonical_links_checked':links.get('links_checked')}
(QA/'CURRENT-PACKAGE-VALIDATION-v4.5.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'CURRENT-PACKAGE-VALIDATION-v4.5.0.md').write_text('\n'.join(['# Current Package Validation v4.5.0','',f'**Result: {status}**','']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']} — {x['detail']}" for x in checks])+'\n',encoding='utf-8')
print(status,'checks',sum(x['pass'] for x in checks),'/',len(checks),'findings',len(findings))
if status!='PASS':
    print([x for x in checks if not x['pass']]); raise SystemExit(1)
