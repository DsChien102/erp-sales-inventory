#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,sys
CUR=Path(__file__).resolve().parents[6]
PARENT=Path('/mnt/data/v3100_work/VET45-Theme7-Prototype-Harness-v3.10.0')
QA=Path(__file__).resolve().parent
rel=Path('specs/themes/theme-07/harness/frozen-source')

def hashes(root):
    out={}
    for p in sorted(root.rglob('*')):
        if p.is_file(): out[str(p.relative_to(root))]=hashlib.sha256(p.read_bytes()).hexdigest()
    return out
ha,hb=hashes(PARENT/rel),hashes(CUR/rel)
added=sorted(set(hb)-set(ha));removed=sorted(set(ha)-set(hb));changed=sorted(k for k in set(ha)&set(hb) if ha[k]!=hb[k])
status='PASS' if not added and not removed and not changed and len(ha)==len(hb)==108 else 'FAIL'
out={'version':'3.10.1','status':status,'baseline':'direct parent directory v3.10.0','filesCompared':len(ha),'candidateFiles':len(hb),'added':added,'removed':removed,'changed':changed}
(QA/'FROZEN-SOURCE-IMMUTABILITY-QA-v3.10.1.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'FROZEN-SOURCE-IMMUTABILITY-QA-v3.10.1.md').write_text(f'# Frozen Source Immutability QA — v3.10.1\n\n**Result: {status}**  \nBaseline: direct parent directory v3.10.0  \nFiles compared: **{len(ha)}**  \nCandidate files: **{len(hb)}**\n\n- Added: {len(added)}\n- Removed: {len(removed)}\n- Changed: {len(changed)}\n',encoding='utf-8')
print(status,len(ha),'files','candidate',len(hb),'added',len(added),'removed',len(removed),'changed',len(changed))
sys.exit(0 if status=='PASS' else 1)
