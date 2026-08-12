from pathlib import Path
import hashlib

CHILD = Path(__file__).resolve().parents[2]
PARENT = Path('/mnt/data/work_t07_v201/VET45-Theme7-Prototype-Harness-v2.0.0/specs/themes/theme-07/prototype')
checks = []
diffs = []

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def exact_file(rel):
    a, b = PARENT / rel, CHILD / rel
    ok = a.exists() and b.exists() and digest(a) == digest(b)
    checks.append((rel, ok))
    if not ok:
        diffs.append(rel)

def exact_tree(rel):
    pa, pb = PARENT / rel, CHILD / rel
    aa = {str(x.relative_to(pa)): digest(x) for x in pa.rglob('*') if x.is_file()}
    bb = {str(x.relative_to(pb)): digest(x) for x in pb.rglob('*') if x.is_file()}
    ok = aa == bb
    checks.append((rel + '/**', ok))
    if not ok:
        keys = sorted(set(aa) | set(bb))
        diffs.extend([rel + '/' + k for k in keys if aa.get(k) != bb.get(k)][:100])

def normalize_authority(text):
    pairs = [
        ('Figma DS v2.0.2 là UI authority; HTML là renderer; Flutter DS chỉ là historical renderer provenance.', '{{UI_AUTHORITY_WITH_RENDERER}}'),
        ('Flutter DS là UI authority; HTML là renderer.', '{{UI_AUTHORITY_WITH_RENDERER}}'),
        ('Figma DS v2.0.2 là UI authority; Flutter DS chỉ là historical renderer provenance.', '{{UI_AUTHORITY}}'),
        ('Flutter DS là UI authority.', '{{UI_AUTHORITY}}'),
        ('UI authority: Figma Design System v2.0.2 locked by `FIGMA-DS-LOCK.json`; `FLUTTER-DS-LOCK.json` chỉ còn historical provenance.', '{{UI_AUTHORITY_LOCK}}'),
        ('UI authority: Flutter Design System locked by `FLUTTER-DS-LOCK.json`.', '{{UI_AUTHORITY_LOCK}}'),
    ]
    for old, token in pairs:
        text = text.replace(old, token)
    return text

def normalized_markdown_tree(rel):
    pa, pb = PARENT / rel, CHILD / rel
    aa = {str(x.relative_to(pa)): normalize_authority(x.read_text(encoding='utf-8')) for x in pa.rglob('*.md')}
    bb = {str(x.relative_to(pb)): normalize_authority(x.read_text(encoding='utf-8')) for x in pb.rglob('*.md')}
    ok = aa == bb
    checks.append((rel + '/** business content; UI-authority metadata normalized', ok))
    if not ok:
        keys = sorted(set(aa) | set(bb))
        diffs.extend([rel + '/' + k for k in keys if aa.get(k) != bb.get(k)][:100])

# Frozen business source.
exact_tree('../srs')
# Machine-readable behavior registries remain byte-identical.
exact_file('flows/ui-flow-registry.json')
exact_file('contracts/action-registry.json')
# Human-readable flow/screen contracts may update only the UI-authority sentence.
normalized_markdown_tree('flows')
normalized_markdown_tree('contracts/screens')
# Phase 1 foundation adapter remains protected.
exact_file('html/tokens.generated.css')
# Theme manifest remains protected.
manifest = CHILD.parent / 'theme.manifest.yaml'
parent_manifest = PARENT.parent / 'theme.manifest.yaml'
if manifest.exists() and parent_manifest.exists():
    checks.append(('theme.manifest.yaml', digest(manifest) == digest(parent_manifest)))

result = all(v for _, v in checks)
out = Path(__file__).resolve().parent / 'FIGMA-DS-SOURCE-REGRESSION-v2.0.1.md'
lines = [
    '# Phase 2 — Source/Behavior Regression v2.0.1', '',
    f'**Result: {"PASS" if result else "FAIL"} · {sum(v for _, v in checks)}/{len(checks)} protected gates**', '',
    'Phase 2 may change Figma mapping metadata, component-usage migration notices, workbench Inspect code, QA evidence, and stale UI-authority metadata in human-readable flow/screen documents. Business semantics and machine-readable behavior remain protected.', '',
    '## Gates', ''
] + [f'- {"PASS" if v else "FAIL"} — `{n}`' for n, v in checks]
if diffs:
    lines += ['', '## Differences'] + [f'- `{x}`' for x in diffs]
out.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(('PASS' if result else 'FAIL'), sum(v for _, v in checks), '/', len(checks))
if not result:
    raise SystemExit(1)
