#!/usr/bin/env python3
from pathlib import Path
import json,re,subprocess,sys
import yaml
ROOT=Path(__file__).resolve().parents[6]
T=ROOT/'specs/themes/theme-07'; QA=T/'prototype/html/qa'
checks=[]
def ck(n,c,note=''): checks.append({'name':n,'pass':bool(c),'note':str(note)[:1200]})
# Parse JSON/YAML across cumulative package
jfiles=sorted(ROOT.rglob('*.json')); yfiles=sorted(list(ROOT.rglob('*.yaml'))+list(ROOT.rglob('*.yml')))
jerr=[]; yerr=[]
for f in jfiles:
    try: json.loads(f.read_text(encoding='utf-8'))
    except Exception as e: jerr.append(f'{f.relative_to(ROOT)}: {e}')
for f in yfiles:
    try: yaml.safe_load(f.read_text(encoding='utf-8'))
    except Exception as e: yerr.append(f'{f.relative_to(ROOT)}: {e}')
ck('all JSON parses',not jerr,{'files':len(jfiles),'errors':jerr[:10]})
ck('all YAML parses',not yerr,{'files':len(yfiles),'errors':yerr[:10]})
# Active relative links; historical snapshots are intentionally not live navigation.
pat=re.compile(r'\[[^\]]+\]\(([^)]+)\)'); broken=[]; active_links=0
skip=('harness/frozen-source/','outbound/','migration/','validation/','prototype/legacy/')
for f in T.rglob('*.md'):
    rel=f.relative_to(T).as_posix()
    if rel.startswith(skip): continue
    fenced=False
    for line_no,line in enumerate(f.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        if line.lstrip().startswith('```'): fenced=not fenced; continue
        if fenced: continue
        for href in pat.findall(line):
            if href.startswith(('http://','https://','mailto:','#','javascript:')): continue
            target=href.split('#',1)[0].split('?',1)[0]
            if not target: continue
            active_links+=1
            if not (f.parent/target).resolve().exists(): broken.append(f'{rel}:{line_no}:{href}')
ck('active relative links resolve',not broken,{'checked':active_links,'broken':broken[:20]})
# JS syntax for executable HTML layers.
jsfiles=sorted((T/'prototype/html').glob('*.js')); jserr=[]
for f in jsfiles:
    p=subprocess.run(['node','--check',str(f)],capture_output=True,text=True)
    if p.returncode: jserr.append(f'{f.name}: {p.stderr.strip()}')
ck('prototype JavaScript syntax passes',not jserr,{'files':len(jsfiles),'errors':jserr[:10]})
# Registry identity/uniqueness and expected current scope.
def load(p): return json.loads(p.read_text(encoding='utf-8'))
reg=load(T/'prototype/contracts/screen-registry.json'); acts=load(T/'prototype/contracts/action-registry.json'); flows=load(T/'prototype/flows/ui-flow-registry.json'); wb=load(T/'prototype/html/workbench-data.json'); manifest=load(T/'prototype/html/manifest.json'); p1=load(T/'prototype/prototype.manifest.json'); p2=load(T/'prototype/html/prototype.manifest.json')
sids=[x.get('id') for x in reg.get('screens',[])]; aids=[x.get('id') for x in acts.get('actions',[])]; fids=[x.get('id') for x in flows.get('flows',[])]; wfids=[x.get('id') for x in wb.get('flows',[])]
ck('screen registry has 89 unique IDs',len(sids)==89 and len(sids)==len(set(sids)),len(sids))
ck('action registry IDs are unique',len(aids)==len(set(aids)),len(aids))
ck('flow registry has 17 BJ + CAP-01 unique',len(fids)==18 and len(fids)==len(set(fids)) and set(fids)=={f'UIF-{i:02d}' for i in range(1,18)}|{'CAP-01'},fids)
ck('workbench flow identity matches registry',set(wfids)==set(fids),sorted(set(wfids)^set(fids)))
ck('current release versions agree',all(x=='3.10.1' for x in [manifest.get('version'),p1.get('version'),p2.get('version'),reg.get('version'),acts.get('version'),wb.get('version')]))
ck('current parent versions agree',manifest.get('parentVersion')==p1.get('parentVersion')==p2.get('parentVersion')=='3.10.0')
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.10.1','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'jsonFiles':len(jfiles),'yamlFiles':len(yfiles),'activeLinksChecked':active_links,'javascriptFiles':len(jsfiles),'checks':checks}
(QA/'STRUCTURAL-PACKAGE-QA-v3.10.1.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'STRUCTURAL-PACKAGE-QA-v3.10.1.md').write_text('\n'.join(['# Structural Package QA — v3.10.1','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','',f'- JSON: **{len(jfiles)} files · {len(jerr)} errors**',f'- YAML: **{len(yfiles)} files · {len(yerr)} errors**',f'- Active relative links checked: **{active_links} · broken {len(broken)}**',f'- Prototype JS syntax: **{len(jsfiles)} files · errors {len(jserr)}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'],'JSON',len(jfiles),'YAML',len(yfiles),'links',active_links,'JS',len(jsfiles))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
