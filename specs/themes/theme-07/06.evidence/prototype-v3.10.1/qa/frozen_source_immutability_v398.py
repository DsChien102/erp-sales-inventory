#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,sys
CUR=Path(__file__).resolve().parents[6]
BASE=Path('/mnt/data/vet45_v397_work/VET45-Theme7-Prototype-Harness-v3.9.7')
QA=Path(__file__).resolve().parent
rel=Path('specs/themes/theme-07/harness/frozen-source')
a=BASE/rel;b=CUR/rel

def hashes(root):
    out={}
    for p in sorted(root.rglob('*')):
        if p.is_file():out[str(p.relative_to(root))]=hashlib.sha256(p.read_bytes()).hexdigest()
    return out
ha,hb=hashes(a),hashes(b);added=sorted(set(hb)-set(ha));removed=sorted(set(ha)-set(hb));changed=sorted(k for k in set(ha)&set(hb) if ha[k]!=hb[k])
status='PASS' if not added and not removed and not changed else 'FAIL'
out={'version':'3.9.8','status':status,'baseline':'3.9.7','filesCompared':len(ha),'added':added,'removed':removed,'changed':changed}
(QA/'FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.8.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
(QA/'FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.8.md').write_text(f'# Frozen Source Immutability QA — v3.9.8\n\n**Result: {status}**  \nFiles compared: **{len(ha)}**\n\n- Added: {len(added)}\n- Removed: {len(removed)}\n- Changed: {len(changed)}\n')
print(status,len(ha),'files','added',len(added),'removed',len(removed),'changed',len(changed));sys.exit(0 if status=='PASS' else 1)
