#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,sys,zipfile
CUR=Path(__file__).resolve().parents[6]
BASE_ZIP=Path('/mnt/data/VET45-Theme7-Prototype-Harness-v3.9.8.zip')
QA=Path(__file__).resolve().parent
rel=Path('specs/themes/theme-07/harness/frozen-source')
cur_root=CUR/rel

def current_hashes(root):
    out={}
    for p in sorted(root.rglob('*')):
        if p.is_file(): out[str(p.relative_to(root))]=hashlib.sha256(p.read_bytes()).hexdigest()
    return out

def zip_hashes(zpath):
    out={}
    marker='/'+rel.as_posix()+'/'
    with zipfile.ZipFile(zpath) as z:
        for name in sorted(z.namelist()):
            if name.endswith('/') or marker not in '/'+name:
                continue
            after=('/'+name).split(marker,1)[1]
            out[after]=hashlib.sha256(z.read(name)).hexdigest()
    return out

ha,hb=zip_hashes(BASE_ZIP),current_hashes(cur_root)
added=sorted(set(hb)-set(ha));removed=sorted(set(ha)-set(hb));changed=sorted(k for k in set(ha)&set(hb) if ha[k]!=hb[k])
status='PASS' if not added and not removed and not changed and len(ha)==108 else 'FAIL'
out={'version':'3.9.9','status':status,'baseline':'parent ZIP v3.9.8','filesCompared':len(ha),'candidateFiles':len(hb),'added':added,'removed':removed,'changed':changed}
(QA/'FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.9.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
(QA/'FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.9.md').write_text(f'# Frozen Source Immutability QA — v3.9.9\n\n**Result: {status}**  \nBaseline: parent ZIP v3.9.8  \nFiles compared: **{len(ha)}**  \nCandidate files: **{len(hb)}**\n\n- Added: {len(added)}\n- Removed: {len(removed)}\n- Changed: {len(changed)}\n')
print(status,len(ha),'files','candidate',len(hb),'added',len(added),'removed',len(removed),'changed',len(changed));sys.exit(0 if status=='PASS' else 1)
