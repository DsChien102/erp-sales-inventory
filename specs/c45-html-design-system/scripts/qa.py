from pathlib import Path
import json,re,hashlib,sys,subprocess
ROOT=Path(__file__).resolve().parents[1]
SRC=Path(__import__('os').environ.get('C45_FLUTTER_DS_ROOT','/mnt/data/flutter_ds_fresh/c45_design_system'))
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
fail=[]
source=json.load(open(ROOT/'contracts/flutter-source.json'))
if source['version']!='1.4.1': fail.append('Flutter version must be 1.4.1')
if (ROOT/'VERSION').read_text().strip()!='2.0.2': fail.append('HTML DS version must be 2.0.2')
if (SRC/'lib/design_system.dart').exists() and sha(SRC/'lib/design_system.dart')!=source['publicBarrelSha256']: fail.append('public barrel hash mismatch')
# Full Flutter lib/src source-tree fidelity.  The source is optional for an installed
# HTML package, but when the project-supplied Flutter package is present every
# mapped Dart file must still match its frozen fingerprint.
source_tree=json.load(open(ROOT/'contracts/flutter-source-tree.json'))
source_items=source_tree.get('items',[])
if len(source_items)!=99: fail.append(f"Flutter source-tree contract {len(source_items)}")
flutter_src_root=SRC/'lib/src'
if flutter_src_root.exists():
    for item in source_items:
        target=flutter_src_root/item['flutter']
        if not target.exists():
            fail.append('Flutter source missing '+item['flutter'])
        elif sha(target)!=item['sha256']:
            fail.append('Flutter source hash '+item['flutter'])
for group in ['tokens','theme','foundation','patterns','primitives','components','forms','audit']:
    if not (ROOT/'src'/group).exists(): fail.append('HTML source taxonomy missing src/'+group)

api=json.load(open(ROOT/'contracts/flutter-public-api.json'))
if api['exportCount']!=94: fail.append(f"export count {api['exportCount']}")
tests=json.load(open(ROOT/'contracts/flutter-test-contracts.json'))
if tests['testCount']!=287: fail.append(f"Flutter test contract {tests['testCount']}")
icons=json.load(open(ROOT/'contracts/flutter-icons.json'))
if icons['count']!=108: fail.append(f"icon count {icons['count']}")
if any(i.get('codepoint') is None or not i.get('lucide') for i in icons['icons']): fail.append('icon codepoint/name parity incomplete')
visual=json.load(open(ROOT/'contracts/visual-parity.json'))
if visual.get('flutterReferenceVersion')!='1.4.1': fail.append('visual parity Flutter authority')
if visual.get('icons',{}).get('semanticAliasCount')!=108 or visual.get('icons',{}).get('fallbackCoverage')!='108/108' or visual.get('icons',{}).get('emptyPlaceholderAllowed') is not False: fail.append('visual icon coverage contract')
if visual.get('typography',{}).get('requiredWeights')!=[400,500,600,700,800] or visual.get('typography',{}).get('syntheticWeightsAllowed') is not False: fail.append('visual typography contract')
for p in ROOT.rglob('*'):
    if p.is_file() and p.suffix.lower() in {'.ttf','.otf','.woff','.woff2'}: fail.append('bundled font '+str(p.relative_to(ROOT)))
css=(ROOT/'src/tokens.css').read_text()
checks=['--v-primary-50:#E8F6EC','--v-space-0:1px','--v-opacity-disabled:.4','--v-type-h4:600 14px/19.25px','--v-type-body:500 14px/22px','--v-density-medium:44px']
for c in checks:
    if c not in css: fail.append('token '+c)
allcss='\n'.join(p.read_text() for p in (ROOT/'src').glob('*.css'))
reg=json.load(open(ROOT/'contracts/canonical-registry.json'))
for x in reg['items']:
    if x['selector'] not in allcss and x['selector'] not in (ROOT/'src/c45-ds.js').read_text(): fail.append('selector '+x['api']+' '+x['selector'])
html=(ROOT/'showcase/index.html').read_text()
root_html=(ROOT/'index.html').read_text()
if 'Heading H4 — 16px' in html or 'Heading H4 — 16px' in root_html: fail.append('stale H4 preview label 16px')
if 'Heading H4 — 14px' not in html or 'Heading H4 — 14px' not in root_html: fail.append('H4 preview label must be 14px')
semantics={i['semantic'] for i in icons['icons']}
for preview_name,preview_html in [('index.html',root_html),('showcase/index.html',html)]:
    used=set(re.findall(r'data-v-icon=\"([^\"]+)\"',preview_html))
    bad=sorted(used-semantics)
    if bad: fail.append(preview_name+' non-semantic icons '+','.join(bad))
for t in ['Tokens','Primitives','Components','Forms','UI Audit']:
    if t not in html: fail.append('preview tab '+t)
if 'compat-v1.6.css' in (ROOT/'src/templates.css').read_text(): fail.append('legacy imported by default')
# Current docs must not declare Figma as authority.
for name in ['foundations.md','governance.md','maintenance.md','patterns-and-templates.md']:
    txt=(ROOT/'docs'/name).read_text().lower()
    if 'figma is authority' in txt or 'figma ds: canonical' in txt or 'product/bj/uc/ui contract → figma' in txt: fail.append('stale Figma authority '+name)
# Source-fidelity spot checks
comp=(ROOT/'src/components.css').read_text()
for c in ['.v-progress{background:var(--v-surface-alt)}','.v-icon-box{background:var(--v-surface);color:var(--v-text-primary)}','.v-empty-state__media{width:64px;height:64px','.v-badge{border:0;background:var(--v-surface-alt);color:var(--v-text-primary)}']:
    if c not in comp: fail.append('component fidelity '+c)
js=(ROOT/'src/c45-ds.js').read_text()
if '"search":{"lucide":"search","codepoint":57681}' not in js: fail.append('exact Lucide codepoint map missing')
# Every Flutter semantic alias must have a non-empty SVG fallback when the Lucide font is absent.
icon_aliases=[i['semantic'] for i in icons['icons']]
m=re.search(r'const FALLBACK=(\{.*?\});\nconst V_ICON_SIZES',js,re.S)
if not m:
    fail.append('FALLBACK map missing')
else:
    fallback=json.loads(m.group(1))
    missing_aliases=[a for a in icon_aliases if a not in fallback]
    if missing_aliases: fail.append('icon fallback aliases '+','.join(missing_aliases))
    # Gather path keys from the base object and the extension object.
    path_keys=set(re.findall(r"(?:^|[,\n ]+)(?:'([^']+)'|\"([^\"]+)\"|([A-Za-z][A-Za-z0-9_-]*))\s*:\s*'|(?:^|[,\n ]+)(?:'([^']+)'|\"([^\"]+)\"|([A-Za-z][A-Za-z0-9_-]*))\s*:\s*\"", js[:js.find('const ICONS=')], re.M))
    flat=set()
    for tup in path_keys:
        for v in tup:
            if v: flat.add(v)
    # Simpler source-level guard: each fallback target must occur as an object key before ICONS.
    missing_paths=[]
    pre=js[:js.find('const ICONS=')]
    for key in sorted(set(fallback.values())):
        pats=[f"'{key}':",f'\"{key}\":',f'{key}:']
        if not any(x in pre for x in pats): missing_paths.append(key)
    if missing_paths: fail.append('icon fallback paths '+','.join(missing_paths))

# Exact high-risk source contracts ported from Flutter 1.4.1.
forms=(ROOT/'src/forms.css').read_text()
for c in ['.v-verification input{width:48px;height:56px', '.v-text-area textarea{min-height:70px', 'padding:12px 8px']:
    if c not in forms: fail.append('form fidelity '+c)
patterns=(ROOT/'src/patterns.css').read_text()
for c in ['.v-page-padding{padding-inline:var(--v-page-horizontal,var(--v-screen-mobile))', 'max-width:840px', 'max-width:1120px', '--v-columns-tablet,2', '--v-columns-desktop,3']:
    if c not in patterns: fail.append('pattern fidelity '+c)
if '@media' in patterns and '.v-page-padding' in patterns: fail.append('VPagePadding must not change automatically by viewport media query')
for c in ["return digits?VMoneyValidator.format(Number(digits)):''", "groupDigits", "wireResponsiveLayouts"]:
    if c not in js: fail.append('behavior fidelity '+c)
font_contract=json.load(open(ROOT/'contracts/font-contract.json'))
if font_contract['families']['sans']['requiredWeights'] != [400,500,600,700,800]: fail.append('Inter weight contract')
if font_contract['families']['mono']['requiredWeights'] != [400,500,600,700,800]: fail.append('JetBrains Mono weight contract')
if font_contract['families']['icons'].get('families',{}).get('semiBold') != 'Lucide600': fail.append('Lucide weighted family contract')
bridge=(ROOT/'src/flutter-font-bridge.js').read_text()
if 'Inter-Regular.ttf' not in bridge or 'JetBrainsMono-ExtraBold.ttf' not in bridge: fail.append('exact Flutter font bridge missing')
if 'data-preview-material-icon=\"home\"' not in root_html or 'data-preview-material-icon=\"receipt_long\"' not in root_html or 'data-preview-material-icon=\"more_horiz\"' not in root_html: fail.append('Flutter preview Material navigation icons missing')
variants=json.load(open(ROOT/'contracts/variant-contracts.json'))
if variants['VFileDropZone']['states'] != ['empty','valid','invalid','disabled']: fail.append('VFileDropZone enum contract')
if variants['VEmptyState']['mediaVariants'] != ['icon','plain']: fail.append('VEmptyMediaVariant contract')
if variants['VVerificationCodeField']['defaultLength'] != 6: fail.append('VVerificationCodeField default length')

# Public-symbol and Flutter-preview structure parity.
coverage=json.load(open(ROOT/'contracts/public-symbol-coverage.json'))
if coverage.get('symbolCount')!=155: fail.append(f"public symbol count {coverage.get('symbolCount')}")
if coverage.get('visualMappedCount')!=78: fail.append(f"visual mapped count {coverage.get('visualMappedCount')}")
allowed_status={'visual-mapped','nonvisual-enum','nonvisual-mapped','nonvisual-token','nonvisual-runtime','nonvisual-function'}
unknown=[x for x in coverage.get('items',[]) if x.get('status') not in allowed_status]
if unknown: fail.append('unclassified public symbols '+','.join(x.get('symbol','?') for x in unknown))
preview=json.load(open(ROOT/'contracts/preview-structure.json'))
if preview.get('tabOrder')!=['Tokens','Primitives','Components','Forms','UI Audit']: fail.append('Flutter preview tab order')
if preview.get('sectionCount')!=63: fail.append(f"Flutter preview section count {preview.get('sectionCount')}")
expected_preview_counts={'tokens_tab.dart':9,'primitives_tab.dart':8,'components_tab.dart':35,'forms_tab.dart':11,'ui_audit_tab.dart':0}
for tab in preview.get('tabs',[]):
    if expected_preview_counts.get(tab.get('file'))!=tab.get('count'):
        fail.append('Flutter preview section count '+str(tab.get('file')))
    for title in tab.get('sections',[]):
        if title not in html and title.replace('&','&amp;') not in html: fail.append('preview section '+title)

# Exact Select/Combobox row geometry from Flutter source.
if '.v-select__item{height:44px;min-height:44px;padding:0 8px;' not in forms: fail.append('VSelect item 44px contract')
if '.v-combobox__item{min-height:44px;padding:4px 8px;' not in forms: fail.append('VComboboxItem min 44px contract')

# Browser runtime behavior mappings for public Flutter helpers.
runtime_api=json.load(open(ROOT/'contracts/runtime-api.json'))
for item in runtime_api.get('items',[]):
    html_name=item['html'].split('(')[0].split(' ->')[0].strip()
    if html_name not in js: fail.append('runtime API '+item['flutter'])
for name in ['showVConfirmDialog','showVBottomSheet','showVNumericKeypadSheet','filterDropdownEntries','matchesComboboxSearch','matchesNormalizedComboboxSearch','VTextNormalizer']:
    if name not in js: fail.append('runtime helper '+name)

# Exhaustive source-exact foundation parity (all directly parseable Dart values).
foundation=json.load(open(ROOT/'contracts/foundation-values.json'))
def css_has(var,val):
    return f"--{var}:{val}" in css
for name,hexv in foundation['colors'].items():
    keb=re.sub(r'([a-z0-9])([A-Z])',r'\1-\2',name)
    keb=re.sub(r'([A-Za-z])(\d+)$',r'\1-\2',keb).lower()
    if not css_has('v-'+keb,hexv): fail.append('foundation color '+name+' '+hexv)
space_alias={'minTouchTarget':'touch-min','controlCompact':'control-compact','screenMobile':'screen-mobile','screenTablet':'screen-tablet','screenDesktop':'screen-desktop'}
for name,val in foundation['spacing'].items():
    if name.startswith('space'):
        key='v-space-'+name[5:]
    elif name in space_alias:
        key='v-'+space_alias[name]
    else:
        # xs/sm/md/lg/xl/xxl are aliases in Dart, not separate CSS vars.
        continue
    if not css_has(key,(str(int(val)) if float(val).is_integer() else str(val))+'px'): fail.append('foundation spacing '+name)
for name,val in foundation['radius'].items():
    key={'pill':'v-radius-pill','input':'v-radius-input','button':'v-radius-button','card':'v-radius-card','sheet':'v-radius-sheet','iconBox':'v-radius-icon-box'}.get(name,'v-radius-'+name[1:] if re.fullmatch(r'r\d+',name) else None)
    if key and not css_has(key,(str(int(val)) if float(val).is_integer() else str(val))+'px'): fail.append('foundation radius '+name)
for name,val in foundation['durationMs'].items():
    if not css_has('v-duration-'+name,str(val)+'ms'): fail.append('foundation duration '+name)
for name,val in foundation['breakpoints'].items():
    if not css_has('v-breakpoint-'+name,str(int(val))+'px'): fail.append('foundation breakpoint '+name)
for mode,d in foundation['density'].items():
    target=css if mode=='comfortable' else re.search(r'\[data-v-density="compact"\]\{([^}]*)\}',css).group(1)
    kv={'controlHeightSmall':'--v-density-small','controlHeightMedium':'--v-density-medium','controlHeightLarge':'--v-density-large','fieldVerticalPadding':'--v-density-field-v','fieldHorizontalPadding':'--v-density-field-h'}
    for k,varn in kv.items():
        v=str(int(d[k]))+'px'
        if f'{varn}:{v}' not in target: fail.append('foundation density '+mode+'.'+k)
# VText exposes every VTypography public style; HTML must expose all 20 variants.
basecss=(ROOT/'src/base.css').read_text()
for variant in foundation['typography']:
    if f'data-v-variant="{variant}"' not in basecss: fail.append('VText typography variant '+variant)

# Package checksum gate.
checksum_path=ROOT/'SHA256SUMS.json'
if checksum_path.exists():
    sums=json.load(open(checksum_path))
    for item in sums.get('files',[]):
        target=ROOT/item['path']
        if not target.exists() or sha(target)!=item['sha256']:
            fail.append('checksum '+item['path'])

# Node syntax
try:
    subprocess.run(['node','--check',str(ROOT/'src/c45-ds.js')],check=True,capture_output=True,text=True)
except Exception as e: fail.append('JS syntax')
print(json.dumps({'status':'FAIL' if fail else 'PASS','findings':fail,'exports':api['exportCount'],'tests':tests['testCount'],'icons':icons['count'],'canonicalSelectors':reg['componentCount']},ensure_ascii=False,indent=2))
sys.exit(1 if fail else 0)
