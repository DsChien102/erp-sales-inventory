#!/usr/bin/env python3
"""Chỉ đọc: so token Dart (nguồn của app Flutter) với token CSS của prototype.

Dùng: python3 packages/vet45_design_system/tool/check_prototype_tokens.py [--html ra.html]
Mặc định không sửa file nào; --write ghi đè các token nền nhạt/viền (surface-*, border-brand) trong tokens.css theo Dart. Thoát mã 1 nếu có token lệch (dùng làm kiểm tra CI sau này).
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[3]
SRC = ROOT / 'packages/vet45_design_system/lib/src'
CSS = ROOT / 'specs/prototype/shared/tokens.css'

colors = {m.group(1): '#' + m.group(2)[2:].upper() for m in re.finditer(
    r'static const Color (\w+)\s*=\s*Color\(0x([0-9A-Fa-f]{8})\)', (SRC / 'tokens/v_colors.dart').read_text(encoding='utf-8'))}
scheme_src = (SRC / 'theme/v_color_scheme.dart').read_text(encoding='utf-8')
light = scheme_src[scheme_src.index('static final VColorScheme light'):scheme_src.index('static final VColorScheme dark')]
scheme = {}
for m in re.finditer(r'(\w+):\s*VColors\.(\w+)', light):
    if m.group(2) in colors: scheme[m.group(1)] = colors[m.group(2)]
def nums(file, cls):
    t = (SRC / file).read_text(encoding='utf-8')
    return {m.group(1): float(m.group(2)) for m in re.finditer(r'static const double (\w+)\s*=\s*([0-9.]+);', t)}
spacing = nums('tokens/v_spacing.dart', 'VSpacing'); radius = nums('tokens/v_radius.dart', 'VRadius')
css = {m.group(1): m.group(2).strip() for m in re.finditer(r'--vet45-v2-([\w-]+):\s*([^;]+);', CSS.read_text(encoding='utf-8'))}

SEMANTIC = {  # token CSS -> trường VColorScheme.light
 'surface-canvas': 'background', 'surface-default': 'surface', 'surface-brand': 'surfaceBrand',
 'surface-success': 'successBg', 'surface-warning': 'warningBg', 'surface-danger': 'dangerBg', 'surface-info': 'infoBg',
 'surface-toast': 'toastSurface', 'border-default': 'borderDefault', 'border-strong': 'borderStrong',
 'border-input': 'borderInput', 'border-brand': 'borderBrand', 'text-primary': 'textPrimary',
 'text-secondary': 'textSecondary', 'text-muted': 'textMuted', 'text-brand': 'textBrand', 'text-inverse': 'textInverse',
 'text-success': 'success', 'text-warning': 'warning', 'text-danger': 'danger', 'text-info': 'info',
 'action-primary-default': 'primary', 'action-primary-pressed': 'primaryPressed',
 'action-danger-default': 'danger', 'action-danger-pressed': 'dangerPressed', 'focus-ring': 'focusRing',
}
rows = []  # (nhóm, tên css, css, dart, trạng thái)
for k, f in SEMANTIC.items():
    d = scheme.get(f); c = css.get(k, '').upper()
    rows.append(('màu vai trò', k, c, d, 'khớp' if d and c[:7] == d else ('thiếu' if not d else 'LỆCH')))
for k, v in css.items():
    m = re.match(r'neutral-(\d+)$', k)
    if m and f'neutral{m.group(1)}' in colors:
        d = colors[f'neutral{m.group(1)}']; c = v.upper(); rows.append(('màu gốc neutral', k, c, d, 'khớp' if c == d else 'LỆCH'))
    elif m: rows.append(('màu gốc neutral', k, v.upper(), None, 'chỉ có ở CSS'))
for k, v in css.items():
    m = re.match(r'space-(\d+)$', k)
    if m and f'space{m.group(1)}' in spacing:
        d = spacing[f'space{m.group(1)}']; c = float(v.replace('px', '')); rows.append(('khoảng cách', k, v, f'{d:g}px', 'khớp' if c == d else 'LỆCH'))
RAD = {'radius-1': 'r4', 'radius-2': 'r6', 'radius-3': 'r8', 'radius-4': 'r12', 'radius-5': 'r16', 'radius-6': 'r20',
       'radius-button': 'button', 'radius-card': 'card', 'radius-input': 'input', 'radius-sheet': 'sheet', 'radius-icon-box': 'iconBox', 'radius-pill': 'pill'}
for k, f in RAD.items():
    if k in css and f in radius:
        d = radius[f]; c = float(css[k].replace('px', '')); rows.append(('bo góc', k, css[k], f'{d:g}px', 'khớp' if c == d else 'LỆCH'))

WRITABLE = {'surface-brand','surface-success','surface-warning','surface-danger','surface-info','border-brand'}
if '--write' in sys.argv:
    text = CSS.read_text(encoding='utf-8')
    for r in rows:
        if r[4] == 'LỆCH' and r[1] in WRITABLE and str(r[3]).startswith('#'):
            text = re.sub(rf'(--vet45-v2-{r[1]}:\s*)[^;]+;', lambda m: m.group(1) + r[3] + ';', text)
            print(f'ghi {r[1]}: {r[2]} -> {r[3]}')
    CSS.write_text(text, encoding='utf-8')
    css = {m.group(1): m.group(2).strip() for m in re.finditer(r'--vet45-v2-([\w-]+):\s*([^;]+);', text)}
    rows = [(g, k, (css.get(k, '').upper() if g == 'màu vai trò' else c), d, ('khớp' if g == 'màu vai trò' and d and css.get(k, '').upper()[:7] == d else st)) for g, k, c, d, st in rows]

bad = [r for r in rows if r[4] in ('LỆCH', 'thiếu')]
for g in dict.fromkeys(r[0] for r in rows):
    sub = [r for r in rows if r[0] == g]
    print(f'{g}: {sum(r[4] == "khớp" for r in sub)}/{len(sub)} khớp')
print()
for r in rows:
    if r[4] != 'khớp': print(f'  {r[4]:<12} {r[1]:<26} CSS={r[2]:<10} Dart={r[3]}')
if '--html' in sys.argv:
    out = pathlib.Path(sys.argv[sys.argv.index('--html') + 1])
    cells = ''.join(f'<tr><td>{r[1]}</td><td><span class="s" style="background:{r[2]}"></span>{r[2]}</td><td><span class="s" style="background:{r[3]}"></span>{r[3]}</td><td>{r[4]}</td></tr>'
                    for r in rows if r[4] == 'LỆCH' and str(r[3]).startswith('#'))
    out.write_text(f'<meta charset=utf-8><style>body{{font:14px Inter,system-ui;margin:24px}}td{{padding:6px 14px;border-bottom:1px solid #ddd}}.s{{display:inline-block;width:64px;height:28px;border:1px solid #bbb;margin-right:10px;vertical-align:middle}}</style><h3>Token màu lệch: CSS prototype vs Dart Flutter</h3><table><tr><th align=left>Token</th><th align=left>CSS (prototype)</th><th align=left>Dart (Flutter)</th><th></th></tr>{cells}</table>', encoding='utf-8')
sys.exit(1 if bad else 0)
