#!/usr/bin/env python3
"""Đồng bộ phần prototype trong specs/themes/theme-07/09.generated sau khi sửa prototype.

Chạy từ bất kỳ đâu: python3 tools/sync-registry.py
- artifact-registry.csv / .json: bỏ dòng của file prototype đã xoá, cập nhật sha256 + size, thêm file mới.
- package-checksums.sha256: tạo lại (giữ danh sách file ngoài prototype, thay toàn bộ phần prototype).
Bỏ qua tools/.golden*.
"""
import csv, hashlib, io, json, os

THEME = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))
os.chdir(THEME)
PROTO = '03.design/prototype/'


def sha(p):
    return hashlib.sha256(open(p, 'rb').read()).hexdigest()


proto = []
for dp, dn, fn in os.walk(PROTO.rstrip('/')):
    dn[:] = [d for d in dn if not d.startswith('.')]
    proto += [os.path.join(dp, f) for f in fn]
proto = sorted(proto)

reg = '09.generated/registries/artifact-registry'
rows = list(csv.reader(open(reg + '.csv', newline='')))
hdr, body = rows[0], rows[1:]
pi, si, zi = hdr.index('path'), hdr.index('sha256'), hdr.index('size')
kept, seen = [], set()
for r in body:
    if r[pi].startswith(PROTO) and not os.path.exists(r[pi]):
        continue
    if os.path.exists(r[pi]):
        r[si], r[zi] = sha(r[pi]), str(os.path.getsize(r[pi]))
    kept.append(r)
    seen.add(r[pi])
for p in proto:
    if p not in seen:
        r = [''] * len(hdr)
        r[pi], r[si], r[zi] = p, sha(p), str(os.path.getsize(p))
        kept.append(r)
kept.sort(key=lambda r: r[pi])
out = io.StringIO()
w = csv.writer(out, lineterminator='\n')
w.writerow(hdr)
w.writerows(kept)
open(reg + '.csv', 'w').write(out.getvalue())

d = json.load(open(reg + '.json'))
arts, seen = [], set()
for a in d['artifacts']:
    if a['path'].startswith(PROTO) and not os.path.exists(a['path']):
        continue
    if os.path.exists(a['path']):
        a['sha256'], a['size'] = sha(a['path']), os.path.getsize(a['path'])
    arts.append(a)
    seen.add(a['path'])
for p in proto:
    if p not in seen:
        arts.append({'path': p, 'id': '', 'type': '', 'owner': '', 'status': '', 'theme': '', 'title': '', 'source_baseline': '', 'sha256': sha(p), 'size': os.path.getsize(p)})
arts.sort(key=lambda a: a['path'])
d['artifacts'], d['artifact_count'] = arts, len(arts)
open(reg + '.json', 'w').write(json.dumps(d, ensure_ascii=False, indent=2) + '\n')

ck = '09.generated/indexes/package-checksums.sha256'
paths = [l.split('  ', 1)[1] for l in open(ck).read().splitlines() if '  ' in l]
paths = sorted({p for p in paths if not p.startswith(PROTO) and os.path.exists(p) and p != ck} | set(proto))
open(ck, 'w').write(''.join(f'{sha(p)}  {p}\n' for p in paths))
print(f'registry {len(kept)} dòng, checksums {len(paths)} file')
