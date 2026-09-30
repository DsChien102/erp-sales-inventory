#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
fail(){ echo "FAIL: $*" >&2; exit 1; }
pass(){ echo "PASS: $*"; }

required=(
  VERSION package.json README.md CHANGELOG.md index.html showcase/index.html
  src/tokens.css src/base.css src/components.css src/patterns.css src/templates.css src/vet45-ds.js
  contracts/figma-source.json contracts/figma-token-snapshot.json contracts/component-map.json contracts/pattern-map.json
  contracts/canonical-registry.json contracts/icon-registry.json contracts/variant-contracts.json contracts/qa-baseline.json
  contracts/flutter-source.json contracts/flutter-public-api.json contracts/flutter-test-contracts.json contracts/flutter-vicons-map.json contracts/parity-matrix.json
  docs/governance.md docs/foundations.md docs/patterns-and-templates.md docs/maintenance.md docs/parity-audit-v1.5.0.md
)
for f in "${required[@]}"; do [[ -s "$f" ]] || fail "missing or empty $f"; done
pass "required release artifacts"

# Never ship font binaries from this package.
if find . -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' \) | grep -q .; then
  fail "font binary found in package"
fi
pass "no font binaries"

python3 - <<'PY'
import html, json, pathlib, re
r=pathlib.Path('.')
version=(r/'VERSION').read_text().strip()
pkg=json.load(open(r/'package.json'))
fig=json.load(open(r/'contracts/figma-source.json'))
qb=json.load(open(r/'contracts/qa-baseline.json'))
fs=json.load(open(r/'contracts/flutter-source.json'))
api=json.load(open(r/'contracts/flutter-public-api.json'))
tests=json.load(open(r/'contracts/flutter-test-contracts.json'))
pm=json.load(open(r/'contracts/parity-matrix.json'))
cm=json.load(open(r/'contracts/component-map.json'))
pat=json.load(open(r/'contracts/pattern-map.json'))
canon=json.load(open(r/'contracts/canonical-registry.json'))
icons=json.load(open(r/'contracts/icon-registry.json'))
vc=json.load(open(r/'contracts/variant-contracts.json'))
vicons=json.load(open(r/'contracts/flutter-vicons-map.json'))
tokens=json.load(open(r/'contracts/figma-token-snapshot.json'))

assert version=='1.5.0', version
assert pkg['version']==version
for x in (fig,qb,pm,canon,tokens): assert x['htmlDsVersion']==version
assert fs['version']=='1.4.1' and fs['lucideIconsFlutter']=='3.1.15'
assert len(cm['masters'])==65 and cm['expectedMasterCount']==65
assert len(pat['masters'])==22 and pat['expectedMasterCount']==22
assert vc['setCount']==59 and len(vc['sets'])==59
assert icons['approvedCount']==35 and len(icons['icons'])==35
assert icons['runtimeGlyphCount']>=38 and len(icons['runtimeGlyphs'])==icons['runtimeGlyphCount']
assert vicons['count']==108 and len(vicons['mapping'])==108
assert canon['masterCount']==87 and len(canon['masters'])==87
assert api['flutterDsVersion']=='1.4.1' and api['exportCount']==94 and len(api['items'])==94
assert sum(x['status']=='implemented' for x in api['items'])==59
assert sum(x['status']=='non-visual' for x in api['items'])==35
assert tests['flutterDsVersion']=='1.4.1' and tests['testFileCount']==43 and tests['testCount']>=280
# Flutter names must be real symbols parsed from exported Dart source, never filename-derived guesses.
public_symbols={sym['name'] for item in api['items'] for sym in item.get('symbols',[])}
for x in canon['masters']:
    mapped=x.get('flutterPublicApi')
    if mapped:
        assert mapped in public_symbols, f'invented/non-public Flutter API mapping: {x["figmaName"]} -> {mapped}'
assert next(x for x in canon['masters'] if x['figmaName']=='VModal')['flutterPublicApi']=='VConfirmDialog'

# Canonical registry must preserve exact Figma identity and may only map Flutter separately.
source={(x['id'],x['figma']):(x['kind'],x['html']) for x in cm['masters']+pat['masters']}
assert len(source)==87
for x in canon['masters']:
    key=(x['figmaNodeId'],x['figmaName'])
    assert key in source, f'canonical identity drift: {key}'
    assert x['namingAuthority']=='figma'
    assert x['htmlSelector']==source[key][1]

# Exact headings in explorer must be Figma names after HTML entity decoding.
index=(r/'index.html').read_text()
expected=[x['figma'] for x in cm['masters']+pat['masters']]
card_pairs=re.findall(r'<article class="component-card" id="master-([^"]+)".*?<h3>(.*?)</h3>',index,re.S)
assert len(card_pairs)==87, len(card_pairs)
seen={}
for cid,h in card_pairs:
    name=html.unescape(re.sub(r'<[^>]+>','',h)).strip()
    seen[cid]=name
assert index.count('class="component-card"')==87
for x in cm['masters']+pat['masters']:
    cid=x['id'].replace(':','-')
    assert cid in seen, 'missing card '+cid
    assert seen[cid]==x['figma'].strip(), (cid,seen[cid],x['figma'])

# Protect exact source typos/spaces rather than silently fixing them.
assert any(v=='DS v2 / Avata Card' for v in seen.values())
assert 'VSegmentedControl ' in expected
av=next(s for s in vc['sets'] if s['name']=='DS v2 / Avata Card')
assert 'Defualt' in av['axes']['State']
assert 'Disable' in av['axes']['State']

print('version/source/naming/inventory OK')
PY
pass "version, exact Figma names, inventory and Flutter coverage"

node --check src/vet45-ds.js >/dev/null
node --input-type=module - <<'JS'
import fs from 'node:fs';
import {VET45_DS_VERSION,ICON_REGISTRY,resolveIconName,icon} from './src/vet45-ds.js';
if(VET45_DS_VERSION!=='1.5.0')process.exit(2);
const iconContract=JSON.parse(fs.readFileSync('./contracts/icon-registry.json','utf8'));
const missingRuntime=iconContract.runtimeGlyphs.filter((x)=>!ICON_REGISTRY.includes(x));
if(missingRuntime.length){console.error('runtime glyphs missing from HTML registry',missingRuntime);process.exit(3);}
if(resolveIconName('warning')!=='triangle-alert')process.exit(4);
if(resolveIconName('image')!=='image')process.exit(5);
if(resolveIconName('banknoteArrowDown')!=='banknote-arrow-down')process.exit(6);
// Do not conflate arrows with chevrons.
if(resolveIconName('arrowLeft')==='chevron-left')process.exit(7);
let threw=false;try{icon('definitely-not-a-vet45-icon',{strict:true})}catch{threw=true}
if(!threw)process.exit(8);
const pathCount=(name)=> (icon(name).match(/<path\b/g)||[]).length;
const exactShapeCounts={plus:2,x:2,info:3,'circle-check':2,'triangle-alert':3,'circle-x':3,image:3,'banknote-arrow-down':6};
for(const [name,count] of Object.entries(exactShapeCounts)){
  const out=icon(name);
  if(pathCount(name)!==count || !out.includes('fill=\"currentColor\"')){
    console.error('critical exact SVG drift',name,pathCount(name),count);process.exit(9);
  }
}
JS
pass "JavaScript syntax, all Figma runtime glyph names, strict icons and no wrong arrow/chevron alias"

python3 - <<'PY'
import json,re
from pathlib import Path
index=Path('index.html').read_text()
css='\n'.join((Path('src')/x).read_text() for x in ['tokens.css','base.css','components.css','patterns.css','templates.css'])
flat=css.replace('\n','')

# Every v-* class actually used in the explorer must have a CSS selector.
classes=set()
for raw in re.findall(r'class=["\']([^"\']+)["\']',index):
    classes.update(x for x in raw.split() if x.startswith('v-'))
missing=[]
for c in sorted(classes):
    if not re.search(r'\.'+re.escape(c)+r'(?![\w-])',css): missing.append(c)
if missing: raise SystemExit('catalog classes without CSS: '+repr(missing))
assert len(classes)>=200, len(classes)

# Every direct data-v-icon reference used by the explorer must resolve through JS source.
js=Path('src/vet45-ds.js').read_text()
refs=sorted(set(re.findall(r'data-v-icon=["\']([^"\']+)',index)))
# Direct registry names or explicit semantic aliases must be present in JS source.
missing_icons=[x for x in refs if (f"'{x}'" not in js and f'"{x}"' not in js)]
if missing_icons: raise SystemExit('catalog icon refs absent from runtime source: '+repr(missing_icons))

# Critical exact Figma geometry/anatomy from the user-reported failures.
checks={
 'avata root':'.v-avatar-card{display:block;position:relative;width:370px;max-width:100%;height:92px',
 'avata avatar':'.v-avatar-card__avatar{position:absolute;left:12px;top:20px;width:52px;height:52px',
 'avata name':'.v-avatar-card__name{position:absolute;left:78px;top:14px;width:220px;height:21px',
 'product root':'.v-product-result{width:370px;max-width:100%;height:104px;padding:12px;display:flex;align-items:flex-start;gap:12px',
 'product media':'.v-product-result__image{width:56px;height:56px',
 'order row':'.v-order-line{width:370px;max-width:100%;height:64px;min-height:64px;padding:8px;position:relative',
 'order qty hit':'.v-order-line__hit{width:44px;height:44px',
 'toast root':'.v-toast{width:370px;max-width:100%;height:56px;padding:0 16px',
 'toast semantic':'.v-toast__icon{width:24px;height:24px',
 'empty root':'.v-empty-state{width:370px;max-width:100%;height:272px;padding:24px',
 'empty icon':'.v-empty-state__icon{width:64px;height:64px',
 'modal root':'.v-modal{width:360px;max-width:100%;height:250px;min-height:250px;padding:20px',
 'modal actions':'.v-modal__actions{width:320px;max-width:100%;height:44px;display:flex;gap:8px',
}
for k,v in checks.items():
    if v not in flat: raise SystemExit('critical user-issue parity missing: '+k)
# No cascade patching for roots that previously broke: exactly one canonical root rule each.
for root in ['v-avatar-card','v-product-result','v-order-line','v-toast','v-empty-state','v-modal']:
    count=len(re.findall(r'(?m)^\s*\.'+re.escape(root)+r'\{',css))
    if count!=1: raise SystemExit(f'stale/duplicate root rule {root}: {count}')
print(f'catalog CSS coverage OK: {len(classes)} classes; direct icons: {len(refs)}')
PY
pass "catalog has CSS for every used class and user-reported anatomy is locked"

python3 - <<'PY'
import json,re
from pathlib import Path
css=Path('src/tokens.css').read_text().replace(' ','').upper()
expected={
 '--VET45-V2-PRIMARY-50:#F1F9F2':'Primary/50',
 '--VET45-V2-PRIMARY-500:#3B9448':'Primary/500',
 '--VET45-V2-SURFACE-TOAST:#0E1116':'Surface/Toast',
 '--VET45-V2-SPACE-0:0PX':'Space/0',
 '--VET45-V2-SPACE-4:16PX':'Space/4',
 '--VET45-V2-RADIUS-4:12PX':'Radius/4',
 '--VET45-V2-TOUCH-MINIMUM:44PX':'Touch/Minimum',
 '--VET45-V2-LAYOUT-MOBILE-WIDTH:402PX':'Layout/Mobile width',
 '--VET45-V2-LAYOUT-MOBILE-HEIGHT:874PX':'Layout/Mobile height',
 '--VET45-V2-OPACITY-DISABLED:.4':'Opacity/Disabled',
}
for needle,label in expected.items():
    if needle not in css: raise SystemExit('live Figma token mismatch: '+label)
base=Path('src/base.css').read_text().replace(' ','')
assert '.v-h4{font-family:var(--vet45-font-sans);font-size:16px;line-height:22px;font-weight:600' in base
assert '.v-body{font-family:var(--vet45-font-sans);font-size:14px;line-height:22px;font-weight:400' in base
snap=json.load(open('contracts/figma-token-snapshot.json'))
assert snap['criticalResolved']['Primary/50']=='#F1F9F2'
assert snap['criticalResolved']['Space/0']==0
print('live Figma token/type locks OK')
PY
pass "live Figma variables and typography locks"

python3 - <<'PY'
import json
from pathlib import Path
api=json.load(open('contracts/flutter-public-api.json'))
css='\n'.join((Path('src')/x).read_text() for x in ['tokens.css','base.css','components.css','patterns.css','templates.css'])
missing=[]
for x in api['items']:
    if x['status']!='implemented': continue
    sel=x.get('html')
    if not sel: missing.append((x['export'],'NO_SELECTOR'))
    elif sel.startswith('.') and sel not in css: missing.append((x['export'],sel))
if missing: raise SystemExit('Flutter visual API selector gaps: '+repr(missing))
pm=json.load(open('contracts/parity-matrix.json'))
for key in ['Primary/50','Space/0','VBottomSheet shell','VNumericKeypadSheet']:
    assert any(x['area']==key for x in pm['drift']), key
print('Flutter mapping coverage and drift governance OK')
PY
pass "Flutter public API mapping and Figma-over-Flutter visual drift governance"

python3 - <<'PY'
from html.parser import HTMLParser
from pathlib import Path
import json
class P(HTMLParser): pass
for f in ['index.html','showcase/index.html']:
 p=P();p.feed(Path(f).read_text());p.close()
try:
 import tinycss2
 for f in ['tokens.css','base.css','components.css','patterns.css','templates.css']:
  errors=[x for x in tinycss2.parse_stylesheet((Path('src')/f).read_text(),skip_comments=True,skip_whitespace=True) if getattr(x,'type',None)=='error']
  if errors: raise SystemExit(f'{f}: {errors[0].message}')
except ImportError: pass
for f in Path('contracts').glob('*.json'): json.load(open(f))
print('HTML/CSS/JSON parsers OK')
PY
pass "markup, CSS and JSON parse"

echo "VET45 HTML DS v$(cat VERSION) QA PASS"
