#!/usr/bin/env python3
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[1]
files=[]
for p in sorted(ROOT.rglob('*')):
    if not p.is_file(): continue
    rel=p.relative_to(ROOT).as_posix()
    if rel=='SHA256SUMS.json' or '__pycache__' in rel or rel.endswith('.pyc'): continue
    b=p.read_bytes(); files.append({'path':rel,'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)})
out={'version':(ROOT/'VERSION').read_text().strip(),'flutterAuthority':'1.4.1','fileCount':len(files),'files':files}
(ROOT/'SHA256SUMS.json').write_text(json.dumps(out,indent=2,ensure_ascii=False)+'\n')
print(f'{len(files)} files')
