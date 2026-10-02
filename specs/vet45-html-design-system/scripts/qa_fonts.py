#!/usr/bin/env python3
from __future__ import annotations
import base64, json, os
from fontTools.ttLib import TTFont
from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
FLUTTER=Path(os.environ.get('VET45_FLUTTER_DS_ROOT','/mnt/data/flutter_ds_fresh/vet45_design_system'))
fonts=FLUTTER/'assets/fonts'
if not fonts.exists():
    print(json.dumps({'status':'SKIP','reason':'Flutter font source not present'},indent=2)); raise SystemExit(0)

def dataurl(p:Path):
    return 'data:font/ttf;base64,'+base64.b64encode(p.read_bytes()).decode()
inter=fonts/'ttf_Inter'
mono=fonts/'ttf_JetBrainsMono'
# Verify the exact font builds supplied by the Flutter authority package.
def font_version(path:Path):
    ft=TTFont(path, lazy=True)
    try:
        for rec in ft['name'].names:
            if rec.nameID==5:
                try: return rec.toUnicode().replace('Version ','').strip()
                except Exception: pass
    finally: ft.close()
    return None
inter_version=font_version(inter/'Inter-Regular.ttf')
mono_version=font_version(mono/'JetBrainsMono-Regular.ttf')
faces=[]
for weight,name in [(400,'Inter-Regular.ttf'),(500,'Inter-Medium.ttf'),(600,'Inter-SemiBold.ttf'),(700,'Inter-Bold.ttf'),(800,'Inter-ExtraBold.ttf')]:
    faces.append(f"@font-face{{font-family:'Inter';font-style:normal;font-weight:{weight};src:url('{dataurl(inter/name)}') format('truetype')}}")
for weight,name in [(400,'JetBrainsMono-Regular.ttf'),(500,'JetBrainsMono-Medium.ttf'),(600,'JetBrainsMono-SemiBold.ttf'),(700,'JetBrainsMono-Bold.ttf'),(800,'JetBrainsMono-ExtraBold.ttf')]:
    faces.append(f"@font-face{{font-family:'JetBrains Mono';font-style:normal;font-weight:{weight};src:url('{dataurl(mono/name)}') format('truetype')}}")
css=[]
for name in ['fonts.css','tokens.css','base.css']:
    raw=(ROOT/'src'/name).read_text()
    raw='\n'.join(x for x in raw.splitlines() if not x.strip().startswith('@import'))
    if name=='fonts.css':
        # Host-only local() faces are validated separately; remove them so the exact
        # Flutter data-backed faces below are the only faces participating in metrics.
        import re
        raw=re.sub(r'@font-face\{[^}]*\}', '', raw)
    css.append(raw)
findings=[]
def fail(x): findings.append(x)
if inter_version!='4.001;git-9221beed3': fail('Inter source version '+repr(inter_version))
if not (mono_version or '').startswith('2.304'): fail('JetBrains Mono source version '+repr(mono_version))
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
    page=browser.new_page(viewport={'width':800,'height':600})
    html=f"<!doctype html><style>{''.join(css)}\n{''.join(faces)}</style><div id='h1' class='v-text' data-v-variant='headingH1'>VET45 Aa 123</div><div id='body' class='v-text' data-v-variant='bodyDefault'>VET45 Aa 123</div><div id='mono' class='v-text' data-v-variant='monoNumeric'>0123456789</div>"
    page.set_content(html,wait_until='load')
    page.evaluate("document.fonts.ready")
    page.evaluate("""async()=>{await Promise.all([
      document.fonts.load('400 14px Inter'),document.fonts.load('500 14px Inter'),document.fonts.load('600 14px Inter'),document.fonts.load('700 28px Inter'),document.fonts.load('800 40px Inter'),
      document.fonts.load('400 14px \"JetBrains Mono\"'),document.fonts.load('500 14px \"JetBrains Mono\"'),document.fonts.load('600 14px \"JetBrains Mono\"'),document.fonts.load('700 18px \"JetBrains Mono\"'),document.fonts.load('800 40px \"JetBrains Mono\"')
    ])}""")
    checks=page.evaluate("""() => ({
      inter400:document.fonts.check('400 14px Inter'), inter500:document.fonts.check('500 14px Inter'), inter600:document.fonts.check('600 14px Inter'), inter700:document.fonts.check('700 28px Inter'), inter800:document.fonts.check('800 40px Inter'), mono400:document.fonts.check('400 14px "JetBrains Mono"'), mono500:document.fonts.check('500 14px "JetBrains Mono"'), mono600:document.fonts.check('600 14px "JetBrains Mono"'), mono700:document.fonts.check('700 18px "JetBrains Mono"'), mono800:document.fonts.check('800 40px "JetBrains Mono"'),
      synthesis:getComputedStyle(document.documentElement).fontSynthesis,
      h1:{family:getComputedStyle(h1).fontFamily,weight:getComputedStyle(h1).fontWeight,size:getComputedStyle(h1).fontSize,line:getComputedStyle(h1).lineHeight,tracking:getComputedStyle(h1).letterSpacing,width:h1.getBoundingClientRect().width},
      body:{family:getComputedStyle(body).fontFamily,weight:getComputedStyle(body).fontWeight,size:getComputedStyle(body).fontSize,line:getComputedStyle(body).lineHeight},
      mono:{family:getComputedStyle(mono).fontFamily,weight:getComputedStyle(mono).fontWeight,size:getComputedStyle(mono).fontSize,line:getComputedStyle(mono).lineHeight,variant:getComputedStyle(mono).fontVariantNumeric}
    })""")
    for k in ['inter400','inter500','inter600','inter700','inter800','mono400','mono500','mono600','mono700','mono800']:
        if checks[k] is not True: fail('font not loaded '+k)
    if checks.get('synthesis')!='none': fail('font synthesis '+repr(checks.get('synthesis')))
    if not checks['h1']['family'].startswith('Inter') or checks['h1']['weight']!='700' or checks['h1']['size']!='28px' or checks['h1']['line']!='34px' or checks['h1']['tracking']!='-0.5px': fail('headingH1 font metrics '+repr(checks['h1']))
    if not checks['body']['family'].startswith('Inter') or checks['body']['weight']!='500' or checks['body']['size']!='14px' or checks['body']['line']!='22px': fail('body font metrics '+repr(checks['body']))
    if not checks['mono']['family'].lstrip('\"').startswith('JetBrains Mono') or checks['mono']['weight']!='500' or checks['mono']['size']!='14px' or checks['mono']['line']!='20px' or 'tabular-nums' not in checks['mono']['variant']: fail('mono font metrics '+repr(checks['mono']))
    browser.close()
print(json.dumps({'status':'FAIL' if findings else 'PASS','findings':findings},ensure_ascii=False,indent=2))
raise SystemExit(1 if findings else 0)
