from pathlib import Path
import json,re,hashlib
ROOT=Path(__file__).resolve().parents[1]
PROTO=ROOT.parent
DS=PROTO/'contracts/figma-ds'
PARENT=Path('/mnt/data/work_t07_v211/VET45-Theme7-Prototype-Harness-v2.1.1')
PHTML=PARENT/'specs/themes/theme-07/prototype/html'
OUT=Path(__file__).resolve().parent
checks=[]
def ck(name,cond,detail=''): checks.append((name,bool(cond),detail))
def fnv(s):
    h=2166136261
    for ch in s:
        h ^= ord(ch); h=(h*16777619)&0xffffffff
    return f'{h:08x}'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
lock=json.loads((DS/'FIGMA-DS-SOURCE-LOCK.json').read_text())
vm=json.loads((DS/'figma-variable-manifest.exact.json').read_text())
sm=json.loads((DS/'figma-style-manifest.exact.json').read_text())
cm=json.loads((DS/'figma-component-registry.json').read_text())
pm=json.loads((DS/'figma-pattern-template-registry.json').read_text())
im=json.loads((DS/'figma-icon-registry.json').read_text())
ilock=json.loads((DS/'FIGMA-DS-ICON-SOURCE-LOCK.json').read_text())
status=json.loads((DS/'UIF-MIGRATION-STATUS.json').read_text())
manifest=json.loads((ROOT/'manifest.json').read_text())
# Source lock identity
ck('Figma DS version locked to 2.0.2',lock['designSystemVersion']=='2.0.2' and lock['lastUpdated']=='26 August 2026')
ck('three canonical DS pages locked',[(x['id'],x['role']) for x in lock['pages']]==[('505:5889','foundations-icons'),('505:5890','components'),('505:5891','patterns-templates')])
# Variables normalized parity with live Figma signature captured in this readiness pass
vlines=[]
for c in vm['collections']:
    for v in c['variables']:
        vlines.append('|'.join([c['name'],c['mode'],v['name'],str(v['value'])]))
vhash=fnv('\n'.join(sorted(vlines)))
ck('119 exact Figma variables',len(vlines)==119,f'{len(vlines)}')
ck('variable values/aliases parity signature matches live Figma',vhash==lock['inventory']['variables']['cssNormalizedSignatureFNV1a32'],vhash)
css=(ROOT/'figma-ds.exact.css').read_text()
css_defs=re.findall(r'^\s*(--vet45-v2-[a-z0-9-]+):\s*([^;]+);',css,re.M)
ck('exact CSS exposes all 119 official --vet45-v2-* variables',len(css_defs)==119,f'{len(css_defs)}')
expected={v['cssName']:v['cssValue'] for c in vm['collections'] for v in c['variables']}
actual=dict(css_defs)
ck('exact CSS names and values equal exact manifest',actual==expected,f'missing={sorted(set(expected)-set(actual))[:5]} extra={sorted(set(actual)-set(expected))[:5]}')
# Styles normalized parity
text=sorted('|'.join(map(str,[x['id'],x['name'],x['font'],x['size'],x['lineHeight'],round(x['letterSpacing'],6)])) for x in sm['textStyles'])
paint=sorted('|'.join([x['id'],x['name'],x['boundVariable']]) for x in sm['paintStyles'])
effect=sorted('|'.join([x['id'],x['name'],x['css']]) for x in sm['effectStyles'])
nh=lock['inventory']['styles']['normalizedSignaturesFNV1a32']
ck('15 exact text styles',len(text)==15 and fnv('\n'.join(text))==nh['text'],fnv('\n'.join(text)))
ck('21 exact paint styles bound to canonical variables',len(paint)==21 and fnv('\n'.join(paint))==nh['paint'],fnv('\n'.join(paint)))
ck('4 exact effect styles',len(effect)==4 and fnv('\n'.join(effect))==nh['effect'],fnv('\n'.join(effect)))
# Components/patterns tuple parity
ca=sorted(cm['assets'],key=lambda x:'|'.join(map(str,x)))
pa=sorted(pm['assets'],key=lambda x:'|'.join(map(str,x)))
ch=fnv('\n'.join('|'.join(map(str,x)) for x in ca)); ph=fnv('\n'.join('|'.join(map(str,x)) for x in pa))
ck('64 canonical component assets indexed',len(ca)==64 and cm['counts']=={'componentSets':49,'standaloneComponents':15},str(cm['counts']))
ck('component tuple signature matches live Figma',ch==lock['inventory']['components']['tupleSignatureFNV1a32'],ch)
ck('22 canonical pattern/template assets indexed',len(pa)==22,f'{len(pa)}')
ck('pattern/template tuple signature matches live Figma',ph==lock['inventory']['patternsTemplates']['tupleSignatureFNV1a32'],ph)
# Icon governance
pairs={(x['size'],x['tone']) for x in im['variants']}
expected_pairs={(s,t) for s in [16,20,24,32,48,72] for t in ['Primary','Secondary','Muted','Brand','Success','Warning','Danger','Info','Inverse']}
ck('DS v2 / Icon exact component set id',im['componentSet']=={'id':'511:673','name':'DS v2 / Icon'})
ck('54 exact icon wrapper variants',len(im['variants'])==54 and pairs==expected_pairs,f'{len(im["variants"])}')
ck('icon source policy is strict li:* Lucide', 'li:*' in im['sourcePolicy'] and '0.4' in im['disabledOpacityVariable'])
wrap_lines=sorted(f"{x['id']}|{x['name']}|{x['size']}|{x['size']}" for x in im['variants'])
ck('icon wrapper signature matches live Figma',fnv('\n'.join(wrap_lines))==lock['inventory']['icons']['wrapperComponentSet']['signatureFNV1a32'] if 'signatureFNV1a32' in lock['inventory']['icons']['wrapperComponentSet'] else fnv('\n'.join(wrap_lines))=='ebd6e207',fnv('\n'.join(wrap_lines)))
ck('local li icon cache signature locked',im['localLiCache']==lock['inventory']['icons']['localLiCache'])
ck('full Figma Lucide catalog locked at 1,676 sources',ilock['glyphCatalog']['uniqueLiSources']==1676 and ilock['glyphCatalog']['remoteMainComponents']==1514 and ilock['glyphCatalog']['localComponents']==162,str(ilock['glyphCatalog']))
ck('full Figma Lucide catalog signature locked',ilock['glyphCatalog']['signatureFNV1a32']=='c5105795',ilock['glyphCatalog']['signatureFNV1a32'])
ck('icon asset policy forbids hand-authored or approximate glyphs',any('No hand-authored' in x for x in ilock['rules']) and 'component key' in ' '.join(ilock['rules']))
# Product implementation is explicitly NOT falsely marked migrated
ck('17 UIFs explicitly legacy-not-structurally-migrated',len(status['uifs'])==17 and all(x['implementation']=='LEGACY_NOT_STRUCTURALLY_MIGRATED' for x in status['uifs']))
ck('manifest truthfully says real replacement not started',manifest['figmaReadiness']['productMigration']=='NOT_STARTED_REAL_REPLACEMENT')
# No Product renderer/style mutation vs parent
ck('app.js byte-identical to v2.1.1',sha(ROOT/'app.js')==sha(PHTML/'app.js'))
ck('styles.css byte-identical to v2.1.1',sha(ROOT/'styles.css')==sha(PHTML/'styles.css'))
# Source/business protection
for rel in ['contracts/screen-registry.json','contracts/screen-registry.md']:
    pp=PARENT/'specs/themes/theme-07/prototype'/rel; cp=PROTO/rel
    ck(f'{rel} byte-identical to v2.1.1',sha(pp)==sha(cp))
ps=PARENT/'specs/themes/theme-07/srs'; cs=ROOT.parents[1]/'srs'
pfiles=sorted(x.relative_to(ps) for x in ps.rglob('*') if x.is_file()); cfiles=sorted(x.relative_to(cs) for x in cs.rglob('*') if x.is_file())
ck('106 SRS files byte-identical to v2.1.1',pfiles==cfiles and len(pfiles)==106 and all(sha(ps/r)==sha(cs/r) for r in pfiles),f'{len(pfiles)}')
# Root discoverability
ck('root index launcher exists', (ROOT.parents[4]/'index.html').exists())
# Exact file loading order in HTML
idx=(ROOT/'index.html').read_text()
order=[idx.find('figma-ds.exact.css'),idx.find('figma-ds.styles.exact.css'),idx.find('tokens.generated.css'),idx.find('styles.css')]
ck('exact Figma layers load before transitional legacy adapter',all(x>=0 for x in order) and order==sorted(order),str(order))
# Transitional adapter must not introduce canonical definitions with raw literals
adapter=(ROOT/'tokens.generated.css').read_text()
raw_canonical=re.findall(r'^\s*(--vet45-v2-[^:]+):',adapter,re.M)
ck('transitional adapter defines zero canonical --vet45-v2-* variables',not raw_canonical,str(raw_canonical[:5]))
passed=sum(ok for _,ok,_ in checks); result='PASS' if passed==len(checks) else 'FAIL'
report={'release':'2.1.2','result':result,'passed':passed,'checks':len(checks),'checksDetail':[{'name':n,'pass':ok,'detail':d} for n,ok,d in checks]}
(OUT/'FIGMA-DS-SOURCE-READINESS-v2.1.2.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
lines=['# Figma DS Source Readiness QA — v2.1.2','',f'**Result: {result} · {passed}/{len(checks)} gates**','', 'This validates exact source-readiness only. It intentionally does **not** claim any UIF/BJ Product renderer has been structurally migrated.','', '## Gates','']
lines += [f'- [{"x" if ok else " "}] {n}' + (f' — `{d}`' if d else '') for n,ok,d in checks]
(OUT/'FIGMA-DS-SOURCE-READINESS-v2.1.2.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({'result':result,'passed':passed,'checks':len(checks),'failures':[n for n,ok,_ in checks if not ok]},ensure_ascii=False))
