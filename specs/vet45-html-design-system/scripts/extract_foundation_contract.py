#!/usr/bin/env python3
from __future__ import annotations
import json, re, os, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FLUTTER = Path(os.environ.get('VET45_FLUTTER_DS_ROOT','/mnt/data/flutter_ds_fresh/vet45_design_system'))
TOK = FLUTTER/'lib/src/tokens'
THEME = FLUTTER/'lib/src/theme'

def read(name: str) -> str:
    p = TOK/name
    if not p.exists(): p = THEME/name
    return p.read_text(encoding='utf-8')

def num(s: str) -> float:
    s=s.strip()
    if '/' in s:
        a,b=s.split('/',1); return float(a.strip())/float(b.strip())
    return float(s)

def parse_colors(txt):
    out={}
    for n,h in re.findall(r'static const Color\s+(\w+)\s*=\s*Color\(0x([0-9A-Fa-f]{8})\)',txt):
        out[n]='#'+h[-6:].upper()
    return out

def parse_simple_doubles(txt):
    out={}
    vals={}
    for n,v in re.findall(r'static const double\s+(\w+)\s*=\s*([^;]+);',txt):
        v=v.strip()
        try:
            if v in vals: x=vals[v]
            elif re.fullmatch(r'[0-9.]+',v): x=float(v)
            else: continue
            vals[n]=x; out[n]=x
        except: pass
    return out

def parse_duration(txt):
    return {n:int(v) for n,v in re.findall(r'static const Duration\s+(\w+)\s*=\s*Duration\(milliseconds:\s*(\d+)\)',txt)}

def parse_breakpoints(txt):
    return {n:float(v) for n,v in re.findall(r'static const double\s+(tablet|desktop)\s*=\s*([0-9.]+)',txt)}

def parse_density(txt):
    out={}
    for mode,body in re.findall(r'static const VDensity\s+(comfortable|compact)\s*=\s*VDensity\((.*?)\n\s*\);',txt,re.S):
        d={}
        for k,v in re.findall(r'(controlHeightSmall|controlHeightMedium|controlHeightLarge|fieldVerticalPadding|fieldHorizontalPadding):\s*([0-9.]+)',body):
            d[k]=float(v)
        out[mode]=d
    return out

def weight_num(w):
    return int(w)

def parse_typography(txt):
    out={}
    for name,body in re.findall(r'static const TextStyle\s+(\w+)\s*=\s*TextStyle\((.*?)\n\s*\);',txt,re.S):
        famm=re.search(r'fontFamily:\s*(\w+)',body)
        sizem=re.search(r'fontSize:\s*([0-9.]+)',body)
        hm=re.search(r'height:\s*([^,\n]+)',body)
        wm=re.search(r'fontWeight:\s*FontWeight\.w(\d+)',body)
        lsm=re.search(r'letterSpacing:\s*([-0-9.]+)',body)
        if not (famm and sizem and hm and wm): continue
        size=float(sizem.group(1)); h=num(hm.group(1)); line=size*h
        out[name]={
            'family': 'Inter' if famm.group(1)=='fontFamily' else ('JetBrains Mono' if famm.group(1)=='monoFontFamily' else famm.group(1)),
            'fontSize': size,
            'lineHeight': round(line,5),
            'fontWeight': weight_num(wm.group(1)),
            'letterSpacing': float(lsm.group(1)) if lsm else 0.0,
            'tabularFigures': 'FontFeature.tabularFigures()' in body,
        }
    return out

def parse_shadows(txt):
    out={}
    for name,body in re.findall(r'static const List<BoxShadow>\s+(e\d+)\s*=\s*\[(.*?)\];',txt,re.S):
        cm=re.search(r'Color\(0x([0-9A-Fa-f]{8})\)',body)
        bm=re.search(r'blurRadius:\s*([0-9.]+)',body)
        om=re.search(r'offset:\s*Offset\(\s*([0-9.-]+)\s*,\s*([0-9.-]+)\s*\)',body)
        if cm and bm and om:
            argb=cm.group(1).upper(); a=int(argb[:2],16)/255
            out[name]={'rgb':'#'+argb[-6:],'alpha':round(a,10),'blur':float(bm.group(1)),'offsetX':float(om.group(1)),'offsetY':float(om.group(2))}
    return out

contract={
    'authority':'vet45_design_system Flutter 1.4.1',
    'colors':parse_colors(read('v_colors.dart')),
    'spacing':parse_simple_doubles(read('v_spacing.dart')),
    'radius':parse_simple_doubles(read('v_radius.dart')),
    'borders':{'thin':1.0,'thick':2.0},
    'opacity':{'disabled':0.4},
    'durationMs':parse_duration(read('v_duration.dart')),
    'breakpoints':parse_breakpoints(read('v_breakpoints.dart')),
    'density':parse_density((THEME/'v_density.dart').read_text()),
    'typography':parse_typography(read('v_typography.dart')),
    'shadows':parse_shadows(read('v_shadows.dart')),
}

if '--stdout' in sys.argv:
    print(json.dumps(contract,ensure_ascii=False,indent=2))
else:
    path=ROOT/'contracts/foundation-values.json'
    path.write_text(json.dumps(contract,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(path)
