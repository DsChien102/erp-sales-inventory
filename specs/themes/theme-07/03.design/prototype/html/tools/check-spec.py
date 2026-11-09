#!/usr/bin/env python3
"""Script kiểm tra tính toàn vẹn đặc tả Theme 7.

Cách dùng:
  python3 specs/themes/theme-07/03.design/prototype/html/tools/check-spec.py [--freeze]
  hoặc chạy từ bất kỳ thư mục nào.

Kiểm tra:
  C1: (chỉ khi --freeze) tệp trong FREEZE_SCOPE có status: IN_REVIEW
  C2: dòng (ngoài RETIRED.md, INDEX.md) nhắc một màn đã bỏ mà không khớp MARK
  C3: SCR-NNN được nhắc nhưng không có tệp screens/SCR-NNN* và không có trong RETIRED.md
  C4: INDEX.md thiếu màn có tệp, ghi trạng thái khác status: của tệp, hoặc màn trong RETIRED.md
      không ghi RETIRED; màn trong RETIRED.md mà tệp vẫn còn
  C5: link ](....md) tương đối trỏ tới tệp không có
  C6: dòng bắt đầu ### v<số> trong screens/, flows/
  C7: version: của README.md theme (bỏ tiền tố v) khác version của manifest.json
"""

import json
import os
import re
import sys

THEME = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))

FREEZE_SCOPE = (
    '02.specification/behavior',
    '02.specification/domain',
    '03.design/flows',
    '03.design/screens',
    '03.design/patterns',
    'README.md',
)

MARK = re.compile(
    r'gộp|đã bỏ|bỏ `?SCR|retire|Bỏ từ|thay bằng|thay `?SCR|hợp nhất|link cũ|trước đây|SCR-\d{3}`? cũ|không còn',
    re.I,
)

SKIP = ('03.design/prototype', '09.generated', '06.evidence', '04.harness')


def main():
    freeze = '--freeze' in sys.argv

    retired_file = os.path.join(THEME, '03.design', 'screens', 'RETIRED.md')
    index_file = os.path.join(THEME, '03.design', 'screens', 'INDEX.md')
    manifest_file = os.path.join(THEME, '03.design', 'prototype', 'html', 'manifest.json')
    readme_file = os.path.join(THEME, 'README.md')
    screens_dir = os.path.join(THEME, '03.design', 'screens')

    retired_screens = set()
    if os.path.exists(retired_file):
        for line in open(retired_file, 'r', encoding='utf-8', errors='ignore'):
            m = re.match(r'\|\s*(SCR-\d{3})\s*\|', line)
            if m:
                retired_screens.add(m.group(1))

    screen_files = {}
    if os.path.exists(screens_dir):
        for f in os.listdir(screens_dir):
            m = re.match(r'(SCR-\d{3})', f)
            if m and f.endswith('.md'):
                screen_files[m.group(1)] = f

    errors = {
        'C1': [],
        'C2': [],
        'C3': [],
        'C4': [],
        'C5': [],
        'C6': [],
        'C7': [],
    }

    status_counts = {}

    # C7: check version README.md vs manifest.json
    readme_ver = None
    if os.path.exists(readme_file):
        for line in open(readme_file, 'r', encoding='utf-8', errors='ignore'):
            if line.startswith('version:'):
                readme_ver = line.split(':', 1)[1].strip().lstrip('v')
                break
    manifest_ver = None
    if os.path.exists(manifest_file):
        try:
            manifest_ver = json.load(open(manifest_file, 'r', encoding='utf-8')).get('version')
        except Exception:
            pass
    if readme_ver != manifest_ver:
        errors['C7'].append(
            f'C7 README.md: version {readme_ver} khác manifest.json version {manifest_ver}'
        )

    # C4: check INDEX.md
    index_entries = {}
    if os.path.exists(index_file):
        for idx, line in enumerate(open(index_file, 'r', encoding='utf-8', errors='ignore'), 1):
            parts = [p.strip() for p in line.split('|')]
            if len(parts) >= 6 and re.match(r'^SCR-\d{3}$', parts[1]):
                scr = parts[1]
                st = parts[4]
                index_entries[scr] = (idx, st)

    for scr in sorted(retired_screens):
        if scr not in index_entries:
            errors['C4'].append(
                f'C4 03.design/screens/INDEX.md: thiếu dòng {scr} (đã ở RETIRED.md)'
            )
        elif index_entries[scr][1] != 'RETIRED':
            errors['C4'].append(
                f'C4 03.design/screens/INDEX.md:{index_entries[scr][0]}: {scr} trong RETIRED.md nhưng trạng thái ghi {index_entries[scr][1]}'
            )
        if scr in screen_files:
            errors['C4'].append(
                f'C4 03.design/screens/{screen_files[scr]}: tệp vẫn tồn tại nhưng {scr} đã ở RETIRED.md'
            )

    for scr, fname in sorted(screen_files.items()):
        if scr not in index_entries:
            errors['C4'].append(
                f'C4 03.design/screens/INDEX.md: thiếu màn {scr} (có tệp screens/{fname})'
            )
        else:
            f_path = os.path.join(screens_dir, fname)
            text_hdr = open(f_path, 'r', encoding='utf-8', errors='ignore').read(1500)
            m_st = re.search(r'status:\s*([A-Z_]+)', text_hdr)
            f_st = m_st.group(1) if m_st else 'NONE'
            idx_st = index_entries[scr][1]
            if f_st != idx_st:
                errors['C4'].append(
                    f'C4 03.design/screens/INDEX.md:{index_entries[scr][0]}: {scr} ghi trạng thái {idx_st} khác status {f_st} của tệp'
                )

    # Walk all .md files in THEME
    for root, dirs, files in os.walk(THEME):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        rel_dir = os.path.relpath(root, THEME)
        if rel_dir == '.':
            rel_dir = ''
        if any(rel_dir.startswith(p) for p in SKIP):
            continue

        for f in sorted(files):
            if not f.endswith('.md'):
                continue
            rel_p = os.path.normpath(os.path.join(rel_dir, f))
            if any(rel_p.startswith(p) for p in SKIP):
                continue

            abs_p = os.path.join(THEME, rel_p)
            try:
                content = open(abs_p, 'r', encoding='utf-8', errors='ignore').read()
            except Exception:
                continue

            in_scope = any(rel_p.startswith(s) for s in FREEZE_SCOPE)
            m_st = re.search(r'status:\s*([A-Z_]+)', content[:1500])
            if m_st:
                st = m_st.group(1)
                grp = 'scope' if in_scope else 'other'
                key = f'{grp}/{st}'
                status_counts[key] = status_counts.get(key, 0) + 1
                if freeze and in_scope and st == 'IN_REVIEW':
                    errors['C1'].append(f'C1 {rel_p}: còn status: IN_REVIEW')

            lines = content.splitlines()

            # C6: ### v<num> in screens/, flows/
            if rel_p.startswith(('03.design/screens', '03.design/flows')):
                for idx, line in enumerate(lines, 1):
                    if re.match(r'^###\s+v\d+', line):
                        errors['C6'].append(f'C6 {rel_p}:{idx}: chứa đề mục dạng ### v<số>')

            # C5, C2, C3
            for idx, line in enumerate(lines, 1):
                # C5: check relative links ](....md)
                for tgt in re.findall(r'\]\(([^)#]+\.md)(?:#[^)]*)?\)', line):
                    if tgt.startswith(('http://', 'https://', 'mailto:')):
                        continue
                    resolved = os.path.normpath(os.path.join(root, tgt))
                    if not os.path.exists(resolved):
                        errors['C5'].append(f'C5 {rel_p}:{idx}: link {tgt} (tệp không còn)')

                # C2 & C3
                if f not in ('RETIRED.md', 'INDEX.md'):
                    scrs = re.findall(r'SCR-\d{3}', line)
                    for scr in scrs:
                        if scr in retired_screens:
                            if not MARK.search(line):
                                errors['C2'].append(
                                    f'C2 {rel_p}:{idx}: nhắc màn đã bỏ {scr} mà không có từ khóa đánh dấu'
                                )
                        elif scr not in screen_files:
                            errors['C3'].append(
                                f'C3 {rel_p}:{idx}: nhắc {scr} nhưng không có tệp và không ở RETIRED.md'
                            )

    # Print summary
    counts_str = ', '.join(f'{k}={v}' for k, v in sorted(status_counts.items()))
    print(f'Trạng thái: {counts_str}')

    err_groups = {k: len(v) for k, v in errors.items() if len(v) > 0}
    if not err_groups:
        print('Lỗi theo nhóm: 0')
    else:
        print(f'Lỗi theo nhóm: {err_groups}')

    # Print detail
    for group in ('C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7'):
        for err in errors[group]:
            print(err)

    has_error = any(len(v) > 0 for v in errors.values())
    sys.exit(1 if has_error else 0)


if __name__ == '__main__':
    main()
