from pathlib import Path
import json, hashlib, re
ROOT=Path(__file__).resolve().parents[1]
PARENT=Path('/mnt/data/work_t07_v212/VET45-Theme7-Prototype-Harness-v2.1.2/specs/themes/theme-07/prototype/html')
CON=ROOT.parent/'contracts'/'figma-ds'
RT=ROOT/'figma-ds-runtime'
checks=[]
def ck(name,cond,detail=''): checks.append((name,bool(cond),str(detail)))

# Frozen Product implementation
for fn in ['app.js','styles.css','workbench-data.js','workbench-data.json']:
    a=hashlib.sha256((PARENT/fn).read_bytes()).hexdigest(); b=hashlib.sha256((ROOT/fn).read_bytes()).hexdigest()
    ck(f'Product {fn} byte-identical to v2.1.2',a==b,b)

# Exact source locks
var=json.loads((CON/'figma-variable-manifest.exact.json').read_text())
allvars=[v for c in var['collections'] for v in c.get('variables',[])]
ck('119 exact Figma variables remain locked',len(allvars)==119,len(allvars))
st=json.loads((CON/'figma-style-manifest.exact.json').read_text())
ck('15 text styles locked',len(st['textStyles'])==15,len(st['textStyles']))
ck('21 paint styles locked',len(st['paintStyles'])==21,len(st['paintStyles']))
ck('4 effect styles locked',len(st['effectStyles'])==4,len(st['effectStyles']))
cr=json.loads((CON/'figma-component-registry.json').read_text())
pr=json.loads((CON/'figma-pattern-template-registry.json').read_text())
ck('64 component assets indexed',len(cr['assets'])==64,len(cr['assets']))
ck('22 pattern/template assets indexed',len(pr['assets'])==22,len(pr['assets']))

# Corrected live source / icon governance
src=json.loads((CON/'FIGMA-DS-SOURCE-LOCK.json').read_text())
ck('source identity lock now exposes migration gates',src['status']=='SOURCE_IDENTITY_LOCKED_MIGRATION_GATES_OPEN',src['status'])
ap=json.loads((CON/'figma-approved-icon-library.json').read_text())
ck('approved Product Icon Library has 28 entries',ap['approvedCount']==28,ap['approvedCount'])
ck('approved icon entries are unique',len({x['glyph'] for x in ap['approvedIcons']})==28,len({x['glyph'] for x in ap['approvedIcons']}))
ck('raw Lucide catalog is vendor-only',src['inventory']['icons']['fullExposedLucideCatalog'].get('role')=='VENDOR_SOURCE_POOL_ONLY',src['inventory']['icons']['fullExposedLucideCatalog'].get('role'))
ck('source governance forbids raw Lucide direct Product use',src['governance'].get('noRawLucideDirectProductUse') is True,src['governance'].get('noRawLucideDirectProductUse'))

# High-demand live binding evidence matches checked-in exact variable mirror
live=json.loads((CON/'figma-live-binding-evidence-v2.2.0.json').read_text())
css=(ROOT/'figma-ds.exact.css').read_text()
defs=dict(re.findall(r'(--vet45-v2-[a-z0-9-]+)\s*:\s*([^;]+);',css))
def resolve(k,seen=None):
    seen=set() if seen is None else seen
    if k in seen: return None
    seen.add(k)
    v=defs.get(k)
    if v is None:return None
    v=v.strip()
    m=re.fullmatch(r'var\((--vet45-v2-[a-z0-9-]+)\)',v)
    return resolve(m.group(1),seen) if m else v.lower()
for node in live['nodes'].values():
    for k,v in node['bindings'].items():
        got=resolve(k)
        exp=(v+'px').lower() if re.fullmatch(r'\d+(?:\.\d+)?',str(v)) else str(v).lower()
        if got and re.fullmatch(r'\d+(?:\.\d+)?px',got) and re.fullmatch(r'\d+(?:\.\d+)?px',exp):
            ok=float(got[:-2])==float(exp[:-2])
        else: ok=got==exp
        ck(f'live binding {node["name"]} {k} matches exact mirror',ok,f'{got} vs {exp}')

# Typography discrepancies are resolved to live bound styles in exact manifest
styles={x['name']:x for x in st['textStyles']}
ls=styles.get('VET45 v2 / Label / Small',{})
mn=styles.get('VET45 v2 / Mono / Numeric',{})
ck('Label / Small exact style is 12/16',ls.get('size')==12 and ls.get('lineHeight')==16,(ls.get('size'),ls.get('lineHeight')))
ck('Mono / Numeric exact style is 14/22',mn.get('size')==14 and mn.get('lineHeight')==22,(mn.get('size'),mn.get('lineHeight')))

# Structural evidence proves current runtime is not yet exact
se=json.loads((CON/'figma-live-structure-evidence-v2.2.0.json').read_text())
ck('live VButton has 48 variants',se['nodes']['521:529']['variantCount']==48,se['nodes']['521:529']['variantCount'])
ck('live Icon wrapper has 54 variants',se['nodes']['511:673']['variantCount']==54,se['nodes']['511:673']['variantCount'])
ck('Sticky Footer includes 5 live variants',len(se['nodes']['549:927']['variants'])==5,len(se['nodes']['549:927']['variants']))

# Icon demand audit
ia=json.loads((ROOT/'qa'/'FIGMA-DS-ICON-DEMAND-v2.2.0.json').read_text())
blocked=[x for x in ia['global'] if x['status']!='APPROVED_ICON_LIBRARY']
ck('icon demand audited across all 497 declared state renders',ia['renders']==497,ia['renders'])
ck('7 actually-rendered legacy icon semantics remain source-gated',len(blocked)==7,[x['legacySemantic'] for x in blocked])
ck('all rendered legacy SVGs are at least semantically annotated',ia['legacySvgWithoutDataDsIconOccurrencesAcrossRenders']==0,ia['legacySvgWithoutDataDsIconOccurrencesAcrossRenders'])

# Overlay register
ov=json.loads((CON/'FIGMA-DS-OVERLAY-MIGRATION-REGISTER-v2.2.0.json').read_text())
ck('12 legacy generic-sheet contexts inventoried',ov['summary']['total']==12,ov['summary']['total'])
ck('4 read-only/detail sheet contexts need source decision',ov['summary']['sourceDecisionRequired']==4,ov['summary']['sourceDecisionRequired'])
ck('8 generic-sheet contexts already resolve to exact patterns',ov['summary']['resolvableExact']==8,ov['summary']['resolvableExact'])

# Runtime candidate isolation and explicit status
rr=json.loads((RT/'runtime-registry.json').read_text())
ck('runtime status reflects live reconnection with gates open',rr['status']=='IN_PROGRESS_LIVE_SOURCE_RECONNECTED_GATES_OPEN',rr['status'])
ck('runtime Product wiring OFF',rr['productWiring'] is False,rr['productWiring'])
ck('runtime retains at least 9 source-captured specimens',len(rr['exactImplementedFromCapturedContext'])>=9,len(rr['exactImplementedFromCapturedContext']))
ck('runtime blockers are concrete and non-empty',len(rr.get('blockers',[]))>=5,len(rr.get('blockers',[])))

idx=(ROOT/'index.html').read_text(); app=(ROOT/'app.js').read_text(); styles_css=(ROOT/'styles.css').read_text()
ck('Product index does not load runtime.js','figma-ds-runtime/runtime.js' not in idx)
ck('Product index does not load runtime.css','figma-ds-runtime/runtime.css' not in idx)
ck('Product app.js does not import runtime candidate','VET45_DS_RUNTIME' not in app)
ck('Product styles.css does not import runtime candidate','figma-ds-runtime' not in styles_css)

# All UIF stay legacy/not structurally migrated
us=json.loads((CON/'UIF-MIGRATION-STATUS.json').read_text())
legacy=[u for u in us.get('uifs',[]) if u.get('implementation')=='LEGACY_NOT_STRUCTURALLY_MIGRATED']
ck('all 17 UIF remain legacy/not structurally migrated',len(legacy)==17,len(legacy))
ck('UIF source status does not falsely claim frozen runtime',us.get('sourceReadiness')=='MAPPING_EXACT_RUNTIME_GATES_OPEN',us.get('sourceReadiness'))

# Demand mapping completeness: exact canonical registry names count as resolved targets
mapping=json.loads((CON/'html-figma-ds-mapping.json').read_text())
allm={}
for sec in ['componentMappings','patternMappings','templateMappings','legacyMappings','themeMappings']:
    allm.update(mapping.get(sec,{}) or {})
canon_names={x[2] for x in cr['assets']}|{x[2] for x in pr['assets']}
demand=json.loads((ROOT/'qa'/'FIGMA-DS-MIGRATION-DEMAND-v2.1.2.json').read_text())['global']['dsNames']
unresolved=[n for n in demand if n not in allm and n not in canon_names]
ck('all legacy DS demand names resolve to a canonical target/composition/owned slot',not unresolved,unresolved)
pt_names={x[2] for x in pr['assets']}
tpl_unresolved=[n for n in json.loads((ROOT/'qa'/'FIGMA-DS-MIGRATION-DEMAND-v2.1.2.json').read_text())['global']['templates'] if n not in pt_names]
ck('all demanded page templates exist in live registry',not tpl_unresolved,tpl_unresolved)

# Runtime uses only exact locked variables; no guessed icons committed
refs=set(re.findall(r'var\((--vet45-v2-[a-z0-9-]+)',(RT/'runtime.css').read_text()))
missing=sorted(refs-set(defs))
ck('runtime CSS uses only locked Figma WEB variables',not missing,missing)
icons=list((RT/'assets'/'icons').glob('*')) if (RT/'assets'/'icons').exists() else []
ck('no guessed icon SVG assets have been committed',len(icons)==0,[x.name for x in icons])

pre=json.loads((ROOT/'qa'/'FIGMA-DS-LIVE-PREFLIGHT-v2.2.0.json').read_text())
ck('live preflight honestly says not yet 100% freeze-ready',pre['decision']=='NOT_YET_100_PERCENT_FREEZE_READY',pre['decision'])
ck('five explicit freeze gates remain open',len(pre['gates'])==5 and all(x['status']=='OPEN' for x in pre['gates']),[(x['id'],x['status']) for x in pre['gates']])

passed=sum(ok for _,ok,_ in checks); result='PASS' if passed==len(checks) else 'FAIL'
out=ROOT/'qa'/'FIGMA-DS-RUNTIME-CANDIDATE-QA-v2.2.0.md'
lines=['# Figma DS Runtime Candidate QA v2.2.0','',f'**{result} {passed}/{len(checks)}**','', '> PASS means the preflight evidence, source discipline, isolation and blocker accounting are internally consistent. It explicitly does NOT mean the runtime is frozen or Product-migration-ready.','']
lines += [f'- [{"x" if ok else " "}] {n}'+(f' — `{d}`' if d else '') for n,ok,d in checks]
out.write_text('\n'.join(lines)+'\n')
(ROOT/'qa'/'FIGMA-DS-RUNTIME-CANDIDATE-QA-v2.2.0.json').write_text(json.dumps({'result':result,'passed':passed,'checks':len(checks),'details':[{'name':n,'pass':ok,'detail':d} for n,ok,d in checks]},ensure_ascii=False,indent=2)+'\n')
print(result,passed,'/',len(checks))
for n,ok,d in checks:
    if not ok: print('FAIL:',n,d)
