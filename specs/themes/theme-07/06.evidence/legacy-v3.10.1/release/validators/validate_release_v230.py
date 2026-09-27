#!/usr/bin/env python3
from __future__ import annotations
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
T7 = ROOT / 'specs/themes/theme-07'
HTML = T7 / 'prototype/html'
CONTRACTS = T7 / 'prototype/contracts'

EXPECTED_BASELINE_HASHES = {
    'specs/themes/theme-07/prototype/contracts/action-registry.json': 'b44ae29e765485597ed9124bc04fa7b2a5b76db2ccca38bfde6c2178bbf53f09',
    'specs/themes/theme-07/prototype/contracts/screen-registry.json': '20d3abc7a229ba54aaa436942ffa767f9914b9af2e8c8e6f901b4049ceab5ebf',
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def load(rel: str):
    return json.loads((ROOT / rel).read_text(encoding='utf-8'))

checks = []

def check(name: str, ok: bool, detail):
    checks.append({'name': name, 'pass': bool(ok), 'detail': detail})

# Parse every JSON artifact in the package.
json_errors = []
json_count = 0
for p in sorted(ROOT.rglob('*.json')):
    if p.name == 'RELEASE-VALIDATION-v2.3.0.json':
        continue
    json_count += 1
    try:
        json.loads(p.read_text(encoding='utf-8'))
    except Exception as exc:
        json_errors.append({'path': p.relative_to(ROOT).as_posix(), 'error': str(exc)})
check('all JSON files parse', not json_errors, {'count': json_count, 'errors': json_errors})

# JS syntax.
js_results = []
for rel in [
    'specs/themes/theme-07/prototype/html/app.js',
    'specs/themes/theme-07/prototype/html/workbench-data.js',
]:
    cp = subprocess.run(['node', '--check', str(ROOT / rel)], text=True, capture_output=True)
    js_results.append({'path': rel, 'exit': cp.returncode, 'stderr': cp.stderr.strip()})
check('current Product JavaScript syntax', all(x['exit'] == 0 for x in js_results), js_results)

# Current release metadata.
wb = load('specs/themes/theme-07/prototype/html/workbench-data.json')
check('workbench release version', wb.get('version') == '2.3.0', wb.get('version'))
check('workbench topology', len(wb.get('flows', [])) == 17 and len(wb.get('screens', {})) == 85,
      {'flows': len(wb.get('flows', [])), 'activeScreenOccurrences': len(wb.get('screens', {}))})

status = load('specs/themes/theme-07/prototype/contracts/figma-ds/UIF-MIGRATION-STATUS.json')
migrated = [x.get('uif') for x in status.get('uifs', []) if str(x.get('implementation', '')).startswith('STRUCTURALLY_MIGRATED')]
legacy = [x.get('uif') for x in status.get('uifs', []) if x.get('implementation') == 'LEGACY_NOT_STRUCTURALLY_MIGRATED']
check('migration status release', status.get('release') == '2.3.0', status.get('release'))
check('UIF migration scope is exactly UIF-08', migrated == ['UIF-08'] and len(legacy) == 16,
      {'migrated': migrated, 'legacyCount': len(legacy)})

runtime = load('specs/themes/theme-07/prototype/html/figma-ds-runtime/runtime-registry.json')
check('runtime registry release', runtime.get('release') == '2.3.0', runtime.get('release'))
check('runtime Product wiring scope', runtime.get('productWiring') is True and runtime.get('productWiringScope') == ['UIF-08'],
      {'productWiring': runtime.get('productWiring'), 'scope': runtime.get('productWiringScope')})

# Frozen registries inherited byte-for-byte from v2.2.0.
actions = load('specs/themes/theme-07/prototype/contracts/action-registry.json')
screens = load('specs/themes/theme-07/prototype/contracts/screen-registry.json')
check('inherited action registry cardinality', len(actions.get('actions', [])) == 38, len(actions.get('actions', [])))
check('inherited screen registry cardinality', len(screens.get('screens', [])) == 89, len(screens.get('screens', [])))
for rel, expected in EXPECTED_BASELINE_HASHES.items():
    actual = sha256(ROOT / rel)
    check(f'v2.2.0 inherited hash preserved: {Path(rel).name}', actual == expected,
          {'expected': expected, 'actual': actual})

# BJ08 and all-flow runtime QA.
bj08 = load('specs/themes/theme-07/prototype/html/qa/BJ08-FIGMA-DS-MIGRATION-QA-v2.3.0.json')
smoke = load('specs/themes/theme-07/prototype/html/qa/ALL-FLOWS-RUNTIME-SMOKE-v2.3.0.json')
check('BJ08 Figma DS migration QA', bj08.get('result') == 'PASS' and bj08.get('passed') == 38 and bj08.get('checks') == 38 and not bj08.get('browserErrors'),
      {'result': bj08.get('result'), 'passed': bj08.get('passed'), 'checks': bj08.get('checks'), 'browserErrors': bj08.get('browserErrors')})
check('all-flow runtime smoke', smoke.get('status') == 'PASS' and smoke.get('renders') == 85 and not smoke.get('failures') and not smoke.get('errors'),
      {'status': smoke.get('status'), 'renders': smoke.get('renders'), 'failures': smoke.get('failures'), 'errors': smoke.get('errors')})

# Required release evidence and explicit DS gap.
required = [
    'specs/themes/theme-07/prototype/contracts/figma-ds/FIGMA-DS-WORKING-FREEZE-v2.3.0.md',
    'specs/themes/theme-07/prototype/contracts/figma-ds/THEME7-MIGRATION-READINESS-v2.3.0.md',
    'specs/themes/theme-07/prototype/contracts/figma-ds/BJ08-MIGRATION-CONTRACT-v2.3.0.md',
    'specs/themes/theme-07/prototype/contracts/figma-ds/BJ08-MIGRATION-CLOSURE-v2.3.0.json',
    'specs/themes/theme-07/prototype/html/qa/v230-bj08-captures/BJ08-contact-sheet.png',
]
missing = [rel for rel in required if not (ROOT / rel).is_file()]
check('required v2.3.0 evidence exists', not missing, {'missing': missing})
combined = (ROOT / 'README.md').read_text(encoding='utf-8') + '\n' + (ROOT / 'specs/themes/theme-07/prototype/contracts/figma-ds/BJ08-MIGRATION-CONTRACT-v2.3.0.md').read_text(encoding='utf-8')
check('VTimePicker gap remains explicit', 'VTimePicker' in combined, 'explicit; no unrelated community component promoted')
check('root launcher identifies v2.3.0', 'v2.3.0' in (ROOT / 'index.html').read_text(encoding='utf-8'), 'index.html')

# Historical validators are intentionally not release gates for v2.x Harness.
legacy_manifest = T7 / 'prototype/prototype.manifest.json'
check('historical v4.3.1 package validator classified, not silently passed', not legacy_manifest.exists(),
      {'classification': 'INHERITED_NOT_APPLICABLE_TO_V2X_HARNESS_BASELINE', 'missingLegacyArtifact': 'prototype/prototype.manifest.json'})

passed = sum(1 for x in checks if x['pass'])
result = {
    'release': '2.3.0',
    'parent': '2.2.0',
    'status': 'PASS' if passed == len(checks) else 'FAIL',
    'passed': passed,
    'checks': len(checks),
    'details': checks,
}
print(json.dumps(result, ensure_ascii=False, indent=2))
sys.exit(0 if result['status'] == 'PASS' else 1)
