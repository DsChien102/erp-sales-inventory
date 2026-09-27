from pathlib import Path
import re,json,yaml,sys,subprocess
HERE=Path(__file__).resolve(); root=HERE.parents[2]; proto=root/'prototype'; checks=[]
def check(name,ok,detail=''): checks.append((name,bool(ok),str(detail)))
# structure
for rel in ['flows','contracts','contracts/component-usage','contracts/screens','html','reviews']:
    check(f'structure:{rel}',(proto/rel).is_dir())
check('legacy:ui-absent',not (root/'ui').exists()); check('legacy:ui-contracts-absent',not (root/'ui-contracts').exists())
# registries
fr=json.loads((proto/'flows/ui-flow-registry.json').read_text()); sr=json.loads((proto/'contracts/screen-registry.json').read_text()); ar=json.loads((proto/'contracts/action-registry.json').read_text())
fby={f['id']:f for f in fr['flows']}; sby={s['id']:s for s in sr['screens']}; aby={a['id']:a for a in ar['actions']}
active=set(s for f in fr['flows'] for s in f['screen_ids'])
check('flows:17',len(fr['flows'])==17,len(fr['flows'])); check('screens:catalog-83',len(sr['screens'])==83,len(sr['screens'])); check('screens:active-79',len(active)==79,len(active))
# component public API
barrel=Path('/mnt/data/flutter_ds_full/vet45_design_system/lib/design_system.dart')
public_text=barrel.read_text() if barrel.exists() else ''
# classes/enums exported are ultimately in files; validate against actual source symbol names too
src='\n'.join(p.read_text(errors='ignore') for p in Path('/mnt/data/flutter_ds_full/vet45_design_system/lib').rglob('*.dart')) if barrel.exists() else ''
# usage files
usage_md=sorted((proto/'contracts/component-usage').glob('UIF-??-COMPONENT-USAGE.md')); usage_y=sorted((proto/'contracts/component-usage').glob('UIF-??-COMPONENT-USAGE.yaml'))
check('usage-md:17',len(usage_md)==17,len(usage_md)); check('usage-yaml:17',len(usage_y)==17,len(usage_y))
usage_status=[]; bad_components=[]
for p in usage_y:
    try: d=yaml.safe_load(p.read_text()) or {}; ok=True
    except Exception as e: check(f'{p.stem}:parse',False,e); continue
    check(f'{p.stem}:parse',ok); check(f'{p.stem}:frozen',d.get('status')=='FROZEN',d.get('status'))
    check(f'{p.stem}:extends',d.get('extends')=='../THEME-07-COMPONENT-USAGE-PROFILE.yaml',d.get('extends'))
    miss=[s for s in d.get('screens',[]) if s not in active]; check(f'{p.stem}:active-screen-refs',not miss,miss)
    matrix=d.get('screenComponents',{})
    check(f'{p.stem}:screen-component-matrix',set(matrix)==set(d.get('screens',[])),f'{len(matrix)} vs {len(d.get("screens",[]))}')
    for c in d.get('componentAllowlist',[]):
        if not re.search(r'\b(class|enum|typedef)\s+'+re.escape(c)+r'\b',src) and not re.search(r'\b'+re.escape(c)+r'\s*\(',src): bad_components.append((p.name,c))
    for sid, row in matrix.items():
        for c in row.get('components',[]):
            if not re.search(r'\b(class|enum|typedef)\s+'+re.escape(c)+r'\b',src) and not re.search(r'\b'+re.escape(c)+r'\s*\(',src): bad_components.append((p.name,f'{sid}:{c}'))
check('usage:public-flutter-components',not bad_components,bad_components[:10])
# per screen full contract and action refs
bad_contract=[]; bad_action=[]; blocked=[]
for sid in sorted(active):
    p=proto/'contracts/screens'/f'{sid}.md'; t=p.read_text() if p.exists() else ''
    if not all(x in t for x in ['## 1. Identity & trace','## 2. Experience contract','## 3. Navigation & continuity','## 4. Information & interaction model','## 5. Action contract','## 6. State & feedback contract','## 7. Screen scenarios','## 8. Component Composition Contract','## 9. Design gate','Harness status: `FROZEN`']): bad_contract.append(sid)
    dr=sby[sid].get('design_readiness',{})
    if dr.get('harness_status')!='FROZEN': blocked.append((sid,dr.get('harness_status')))
    for aid in dr.get('visible_action_ids',[])+dr.get('trace_only_action_ids',[]):
        if aid not in aby: bad_action.append((sid,aid))
check('screens:79-full-contract',not bad_contract,bad_contract); check('screens:79-frozen',not blocked,blocked); check('screens:action-refs',not bad_action,bad_action)
# flow transition registry consistency + source refs
for f in fr['flows']:
    p=proto/'flows'/f['file']; text=p.read_text(); ids=set(re.findall(re.escape(f['id'])+r'-T\d+',text))
    check(f'{f["id"]}:transition-count',f.get('transition_count')==len(ids),f'{f.get("transition_count")} vs {len(ids)}')
    miss=[s for s in f['screen_ids'] if s not in active]; check(f'{f["id"]}:screen-refs',not miss,miss)
# reports/status
locals=list((proto/'reviews').glob('LOCAL-REVIEW-UIF-??.md')); cums=list((proto/'reviews').glob('CUMULATIVE-REVIEW-UIF-??.md'))
check('reviews:local-17',len(locals)==17,len(locals)); check('reviews:cumulative-17',len(cums)==17,len(cums))
status=yaml.safe_load((proto/'HARNESS-STATUS.yaml').read_text())
check('status:17',len(status.get('uifs',[]))==17,len(status.get('uifs',[]))); check('status:all-frozen',all(x.get('status')=='FROZEN' for x in status.get('uifs',[]))); check('status:local-pass',all(x.get('localReview')=='PASS' for x in status.get('uifs',[]))); check('status:cumulative-pass',all(x.get('cumulativeReview') in ('PASS','SEED_PASS') for x in status.get('uifs',[])))
# special business/UX decisions
check('SCR012:auto-execution',sby['SCR-012']['design_readiness'].get('visible_action_ids')==[] and 'ACT-02-RECEIVE' in sby['SCR-012']['design_readiness'].get('trace_only_action_ids',[]))
check('SCR017:valuation-copy','đưa vào bán' not in (proto/'contracts/screens/SCR-017.md').read_text().lower())
check('UIF08:blind-count-dom-rule','MUST NOT be rendered in DOM' in (proto/'contracts/component-usage/UIF-08-COMPONENT-USAGE.yaml').read_text())
check('UIF11:auto-correction','ACT-10-CORRECT' in (proto/'flows/UIF-11-BJ-11.md').read_text() and 'hệ thống ghi correction chain' in (proto/'flows/UIF-11-BJ-11.md').read_text())
check('UIF12:approval-commit-separated','ACT-COMMON-DECIDE' in (proto/'flows/UIF-12-BJ-12.md').read_text() and 'ACT-13-COMMIT' in (proto/'flows/UIF-12-BJ-12.md').read_text())
# HTML workbench
hdata=json.loads((proto/'html/workbench-data.json').read_text()); check('html:flows-17',len(hdata['flows'])==17,len(hdata['flows'])); check('html:screens-active',set(x['id'] for x in hdata['screens'])==active,len(hdata['screens']))
ht=(proto/'html/index.html').read_text(); js=(proto/'html/app.js').read_text(); check('html:flow-selector','flow-selector' in ht and 'renderFlowSelector' in js); check('html:inspect','inspect-toggle' in ht and 'data-ds-component' in js); check('html:shared-data','workbench-data.js' in ht)
try:
    cp=subprocess.run(['node','--check',str(proto/'html/app.js')],capture_output=True,text=True,timeout=30); check('html:js-syntax',cp.returncode==0,cp.stderr.strip())
except Exception as e: check('html:js-syntax',False,e)
# no retired active paths
bad=[]
for arx in [root/'srs',root/'know-how',proto/'flows',proto/'contracts']:
    if not arx.exists(): continue
    for p in arx.rglob('*'):
        if not p.is_file() or p.suffix.lower() not in {'.md','.json','.yaml','.yml','.txt','.csv'}: continue
        t=p.read_text(errors='ignore')
        # migration/standard history can explicitly name legacy only in migration note outside these roots; active source may not.
        if re.search(r'(?<!prototype/)ui-contracts/screens|(?<!prototype/)ui/flows',t): bad.append(str(p.relative_to(root)))
check('retired-paths:no-active-reference',not bad,bad[:10])
# relative markdown links
pat=re.compile(r'\[[^\]]*\]\(([^)]+)\)'); broken=[]; count=0
for arx in [root/'srs',root/'know-how',proto]:
    if not arx.exists(): continue
    for p in arx.rglob('*.md'):
        t=re.sub(r'```.*?```','',p.read_text(errors='ignore'),flags=re.S)
        for m in pat.finditer(t):
            target=m.group(1).strip();
            if not target or target.startswith(('#','http://','https://','mailto:','data:')): continue
            target=target.split('#',1)[0].split('?',1)[0].strip('<>'); count+=1
            if not (p.parent/target).resolve().exists(): broken.append(f'{p.relative_to(root)} -> {target}')
check('links:active-relative-integrity',not broken,f'{count} checked; '+ '; '.join(broken[:10]))
# final report/checks
passed=sum(ok for _,ok,_ in checks); failed=[x for x in checks if not x[1]]
report={'schemaVersion':2,'run':'HARNESS-2026-08-25-17-ROUNDS','passed':passed,'total':len(checks),'failed':len(failed),'checks':[{'name':n,'pass':ok,'detail':d} for n,ok,d in checks]}
(proto/'HARNESS-VALIDATION.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
lines=['# Harness Validation Report','',f'- PASS: **{passed}/{len(checks)}**',f'- FAIL: **{len(failed)}**','','Runtime Flutter/Vercel pixel parity remains a separate visual gate; this report validates source/contract/HTML harness structure and semantics.','']
if failed: lines+=['## Failures','']+[f'- `{n}` — {d}' for n,_,d in failed]
else: lines+=['All configured 17-round Harness checks passed.']
(proto/'HARNESS-VALIDATION.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({'passed':passed,'total':len(checks),'failed':len(failed)},ensure_ascii=False))
for n,_,d in failed: print('FAIL',n,d)
if failed: sys.exit(1)
