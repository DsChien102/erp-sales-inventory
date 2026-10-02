from __future__ import annotations
import json, os, socket, threading, time
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
findings=[]
def fail(msg): findings.append(msg)

class Quiet(SimpleHTTPRequestHandler):
    def log_message(self, *args): pass

def free_port():
    s=socket.socket(); s.bind(('127.0.0.1',0)); p=s.getsockname()[1]; s.close(); return p

# Chromium navigation to localhost may be blocked by the host harness, so QA is
# self-contained: inline the exact package CSS/JS and execute them in Chromium.
css_parts=[]
for name in ["fonts.css","tokens.css","base.css","components.css","forms.css","patterns.css"]:
    raw=(ROOT/"src"/name).read_text()
    raw="\n".join(line for line in raw.splitlines() if not line.strip().startswith("@import"))
    css_parts.append(raw)
INLINE_CSS="\n".join(css_parts)
INLINE_JS=(ROOT/"src"/"vet45-ds.js").read_text().replace("export ","")

fixture='''
<div id="qa-fixture" style="padding:20px;width:1200px;position:relative;background:#fff">
  <button id="btn-s" class="v-btn" data-v-size="small">Small</button>
  <button id="btn-m" class="v-btn">Medium</button>
  <button id="btn-l" class="v-btn" data-v-size="large">Large</button>
  <button id="btn-dis" class="v-btn" disabled>Disabled</button>
  <div id="card" class="v-card">Card</div>
  <div id="banner" class="v-banner"><div class="v-banner__head"><span class="v-banner__icon"></span><span class="v-banner__title">Title</span></div><div class="v-banner__description">Description</div></div>
  <label id="field" class="v-field"><span class="v-field__label">Label</span><input id="control" class="v-control" value="x"></label>
  <div id="verify" class="v-verification"><input><input><input><input></div>
  <div id="verify-small" class="v-verification" style="width:260px"><input><input><input><input><input><input></div>
  <div id="date" class="v-date-picker" data-v-date-picker style="width:300px"><button class="v-date-picker__trigger" data-v-date-trigger><span data-v-icon="calendar" data-v-icon-size="sm"></span><span class="v-date-picker__value" data-v-date-value>01/10/2026</span></button><input type="date" hidden></div>
  <span id="weighted-icon" class="qa-icon-slot" style="display:inline-block;width:32px;height:32px" data-v-icon="search" data-v-icon-size="lg" data-v-icon-color="primary" data-v-icon-weight="semiBold"></span>
  <button id="interactive-icon-host" aria-label="Close" data-v-icon="close"></button>
  <div id="appbar" class="v-appbar"><div class="v-appbar__title">Title</div></div>
  <div id="appbar-sub" class="v-appbar"><div><div class="v-appbar__title">Title</div><div class="v-appbar__subtitle">Subtitle</div></div></div>
  <div id="dropzone" class="v-dropzone"><div class="v-dropzone__icon"></div><div class="v-dropzone__title">File</div><div class="v-dropzone__subtitle">Description</div></div>
  <div id="empty" class="v-empty-state"><div class="v-empty-state__header"><div class="v-empty-state__media"></div><div class="v-empty-state__title">Empty</div></div><div class="v-empty-state__content">Action</div></div>
  <div id="loading" class="v-loading"><div class="v-loading__spinner"></div></div>
  <div id="seg" class="v-segmented" data-v-segmented><button class="v-segmented__item" data-v-segmented-item data-v-selected="true">A</button><button class="v-segmented__item" data-v-segmented-item data-v-selected="false">B</button></div>
  <div id="sheet" class="v-bottom-sheet"><div class="v-bottom-sheet__handle"></div><div class="v-bottom-sheet__header">Header</div><div id="sheet-body" class="v-bottom-sheet__body">Body</div></div>
  <div id="keypad" class="v-keypad-sheet" data-v-keypad-sheet><div class="v-keypad-sheet__handle"></div><div class="v-keypad-sheet__display" data-v-keypad-display>0</div><div class="v-keypad-grid"><button data-v-key="1">1</button><button data-v-key="2">2</button><button data-v-key="3">3</button></div></div>
  <div id="bottomnav" class="v-bottom-nav"><button class="v-bottom-nav__item" aria-label="Home"><span data-v-icon="home"></span><span class="v-bottom-nav__label">Home</span></button></div>
  <div id="select" class="v-select" data-v-select><button class="v-select__trigger" data-v-select-trigger><span class="v-select__value" data-v-select-value data-v-placeholder="true">Choose</span><span class="v-select__chevron"></span></button><div class="v-select__menu" data-v-select-menu hidden><button class="v-select__item" data-v-select-item data-value="b">B</button></div></div>
  <div id="tabs" class="v-tabs" data-v-tabs><div class="v-tabs__list"><button class="v-tabs__trigger" data-v-tab-trigger>A</button><button class="v-tabs__trigger" data-v-tab-trigger>B</button></div><div class="v-tabs__content" data-v-tab-content>A content</div><div class="v-tabs__content" data-v-tab-content>B content</div></div>
  <div id="money" class="v-money-field" data-v-money-field><input class="v-control" value=""></div>
  <div id="number" class="v-number-field" data-v-number-field data-v-allow-decimal="true"><input class="v-control" value=""></div>
  <div id="page-parent" style="width:1200px"><div id="page-pad" class="v-page-padding">Padding</div></div>
  <div id="cw-parent" style="width:900px"><div id="content-width" class="v-content-width">Content</div></div>
  <div id="cw-parent2" style="width:1200px"><div id="content-width2" class="v-content-width">Content</div></div>
  <div id="grid-parent" style="width:900px"><div id="grid" class="v-responsive-grid"><div>1</div><div>2</div><div>3</div></div></div>
  <div id="textarea" class="v-text-area"><textarea rows="2"></textarea></div>
  <div id="avatar" class="v-avatar">HV</div>
  <span id="badge" class="v-badge">Badge</span>
  <span id="badge-small" class="v-badge" data-v-size="small"><span class="v-badge__dot"></span>Small</span>
  <span id="chip" class="v-chip" data-v-tone="primary"><span class="v-icon" data-v-icon="search"></span>Chip</span>
  <span id="iconbox" class="v-icon-box" data-v-icon="home"></span>
  <button id="fab" class="v-fab"><span class="v-icon" data-v-icon="add"></span></button>
  <div id="toast" class="v-toast"><span class="v-toast__icon" data-v-tone="success"></span><span>Toast</span><button class="v-toast__close"></button></div>
  <div id="progress" class="v-progress"><div class="v-progress__bar" style="width:50%"></div></div>
  <div id="steps" class="v-steps"><div class="v-step" data-v-status="current"><span class="v-step__indicator">1</span><span class="v-step__copy"><span class="v-step__title">Step</span></span></div></div>
  <div id="combobox" class="v-combobox"><div class="v-combobox__control"><input class="v-combobox__input"><button class="v-combobox__toggle"></button></div><div class="v-combobox__content"><div class="v-combobox__list"><button class="v-combobox__item">Item</button></div></div></div>
  <div id="txt-h1" class="v-text" data-v-variant="headingH1">Heading</div>
  <div id="txt-mono" class="v-text" data-v-variant="monoNumeric">123456</div>
  <div id="txt-danger" class="v-text" data-v-variant="bodyDefault" data-v-tone="danger">Danger</div>
</div>'''

def js_style(page,sel,prop):
    return page.eval_on_selector(sel, f"e=>getComputedStyle(e).{prop}")
def numpx(v): return float(v.replace('px',''))
def approx(v, target, eps=.6): return abs(float(v)-target)<=eps

def rect(page,sel): return page.eval_on_selector(sel,'e=>{const r=e.getBoundingClientRect();return {w:r.width,h:r.height,x:r.x,y:r.y}}')

with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
    page=browser.new_page(viewport={'width':1400,'height':1400})
    page_errors=[]; console_errors=[]
    page.on('pageerror',lambda e:page_errors.append(str(e)))
    page.on('console',lambda m: console_errors.append(m.text) if m.type=='error' else None)
    page.set_content(f'<!doctype html><html><head><meta charset=\"utf-8\"><style>{INLINE_CSS}</style></head><body></body></html>',wait_until='load')
    page.add_script_tag(content=INLINE_JS)
    page.evaluate("html=>document.body.insertAdjacentHTML('beforeend',html)",fixture)
    page.evaluate("initVet45DS(document.getElementById('qa-fixture'))")
    # Render the complete Flutter VIcons semantic surface without any Lucide font.
    icon_aliases=[x['semantic'] for x in json.load(open(ROOT/'contracts/flutter-icons.json'))['icons']]
    page.evaluate("aliases=>{const host=document.createElement('div');host.id='all-icons';aliases.forEach(n=>{const s=document.createElement('span');s.dataset.vIcon=n;host.appendChild(s)});document.body.appendChild(host);initVet45DS(host)}",icon_aliases)
    page.wait_for_timeout(120)
    if page.locator('#all-icons [data-v-icon-missing]').count()!=0: fail('semantic icon rendered as empty placeholder')
    if page.locator('#all-icons svg.v-icon').count()!=len(icon_aliases): fail(f'icon SVG fallback coverage {page.locator("#all-icons svg.v-icon").count()}/{len(icon_aliases)}')
    if page.evaluate("getComputedStyle(document.documentElement).fontSynthesis") not in {'none','weight style small-caps position'}: fail('font synthesis must be disabled')

    # Geometry / computed style contracts
    for sel,target in [('#btn-s',36),('#btn-m',44),('#btn-l',52),('#control',44),('#appbar',56),('#appbar-sub',64)]:
        h=rect(page,sel)['h']
        if not approx(h,target): fail(f'{sel} height {h} != {target}')
    if js_style(page,'#btn-m','borderRadius')!='8px': fail('button radius')
    if js_style(page,'#btn-m','paddingLeft')!='16px': fail('button medium h padding')
    if float(js_style(page,'#btn-dis','opacity'))!=0.4: fail('disabled opacity')
    c=rect(page,'#card')
    if js_style(page,'#card','paddingLeft')!='16px' or js_style(page,'#card','borderRadius')!='12px': fail('card inset/radius')
    if js_style(page,'#card','borderTopWidth')!='1px': fail('card border')
    if js_style(page,'#banner','paddingLeft')!='16px' or js_style(page,'#banner','borderRadius')!='12px': fail('banner geometry')
    if js_style(page,'#banner .v-banner__description','marginLeft')!='32px': fail('banner indent')
    if js_style(page,'#control','paddingLeft')!='12px' or js_style(page,'#control','paddingTop')!='8px' or js_style(page,'#control','borderRadius')!='8px': fail('input geometry')
    vr=rect(page,'#verify input')
    if not approx(vr['w'],48) or not approx(vr['h'],56): fail(f'verification cell {vr}')
    vrs=rect(page,'#verify-small input')
    if not approx(vrs['w'],(260-40)/6,0.8) or not approx(vrs['h'],48,0.8): fail(f'verification responsive cell {vrs}')
    if not approx(rect(page,'#date .v-date-picker__trigger')['w'],300): fail('date picker must stretch to field width')
    wi=rect(page,'#weighted-icon')
    if not approx(wi['w'],32) or not approx(wi['h'],32) or not page.locator('#weighted-icon').count(): fail('VIcon size/class preservation')
    if page.eval_on_selector('#interactive-icon-host','e=>e.tagName')!='BUTTON' or page.locator('#interactive-icon-host > .v-icon').count()!=1: fail('interactive icon host semantics')
    dz=rect(page,'#dropzone')
    if dz['h']<147.5 or js_style(page,'#dropzone','paddingLeft')!='16px' or js_style(page,'#dropzone','paddingTop')!='24px': fail('dropzone geometry')
    dash=page.eval_on_selector('#dropzone .v-dropzone__border rect',"e=>({dash:getComputedStyle(e).strokeDasharray,cap:getComputedStyle(e).strokeLinecap,width:getComputedStyle(e).strokeWidth,rx:e.getAttribute('rx')})")
    if dash['dash'].replace('px','').replace(' ','') not in {'8,5','8px,5px'} or dash['cap']!='round' or float(dash['width'].replace('px',''))!=1.5: fail('dropzone dash contract '+repr(dash))
    if js_style(page,'#empty','paddingLeft')!='24px' or js_style(page,'#empty','borderRadius')!='12px': fail('empty geometry')
    if js_style(page,'#empty .v-empty-state__content','marginTop')!='32px': fail('empty content gap')
    if js_style(page,'#loading .v-loading__spinner','borderTopWidth')!='4px': fail('loading stroke')
    if rect(page,'#seg .v-segmented__item')['h']!=44: fail('segmented item height')
    if js_style(page,'#seg','paddingLeft')!='4px' or js_style(page,'#seg','borderRadius')!='10px': fail('segmented outer')
    sh=rect(page,'#sheet .v-bottom-sheet__handle')
    if not approx(sh['w'],36) or not approx(sh['h'],4) or js_style(page,'#sheet-body','paddingLeft')!='0px': fail('bottomsheet handle/body')
    if js_style(page,'#sheet','position')!='relative': fail('VBottomSheet component must be embeddable; modal host owns fixed positioning')
    if js_style(page,'#keypad','position')!='relative': fail('VNumericKeypadSheet component must be embeddable; modal host owns fixed positioning')
    kh=rect(page,'#keypad .v-keypad-sheet__handle'); key=rect(page,'#keypad .v-keypad-grid button')
    if not approx(kh['w'],48) or not approx(kh['h'],4) or not approx(key['h'],52) or js_style(page,'#keypad .v-keypad-grid button','borderRadius')!='12px': fail('keypad geometry')
    if js_style(page,'#bottomnav','paddingTop')!='10px' or float(js_style(page,'#bottomnav .v-bottom-nav__item','minHeight').replace('px',''))!=50: fail('bottom nav geometry')
    if js_style(page,'#bottomnav .v-bottom-nav__label','display')!='none' or not approx(rect(page,'#bottomnav .v-icon')['w'],29): fail('bottom nav icon-only rendering')
    if js_style(page,'#page-pad','paddingLeft')!='16px' or js_style(page,'#page-pad','paddingRight')!='16px': fail('VPagePadding default must remain 16 at 1200 parent')
    # Responsive patterns need ResizeObserver tick
    page.wait_for_timeout(80)
    cw=rect(page,'#content-width')['w']; cw2=rect(page,'#content-width2')['w']
    if not approx(cw,840): fail(f'content width tablet/900 parent {cw}')
    if not approx(cw2,1120): fail(f'content width desktop/1200 parent {cw2}')
    cols=page.eval_on_selector('#grid','e=>getComputedStyle(e).gridTemplateColumns.split(" ").length')
    if cols!=2: fail(f'grid parent900 columns {cols}')
    ta=rect(page,'#textarea textarea')['h']
    if not (69<=ta<=72): fail(f'textarea 2-line min height {ta}')
    # Primitive/component contracts explicitly defined by Flutter source.
    av=rect(page,'#avatar')
    if not approx(av['w'],40) or not approx(av['h'],40) or js_style(page,'#avatar','borderRadius') not in {'50%','20px'} or js_style(page,'#avatar','fontSize')!='14px': fail('avatar geometry')
    if js_style(page,'#badge','paddingLeft')!='10px' or js_style(page,'#badge','paddingTop')!='6px' or js_style(page,'#badge','borderTopWidth')!='0px': fail('badge regular geometry')
    if js_style(page,'#badge-small','paddingLeft')!='8px' or js_style(page,'#badge-small','paddingTop')!='2px' or not approx(rect(page,'#badge-small .v-badge__dot')['w'],8): fail('badge small/dot geometry')
    if js_style(page,'#chip','paddingLeft')!='12px' or js_style(page,'#chip','paddingTop')!='6px' or js_style(page,'#chip','borderTopWidth')!='1px' or not approx(rect(page,'#chip .v-icon')['w'],12): fail('chip geometry')
    ib=rect(page,'#iconbox')
    if not approx(ib['w'],40) or not approx(ib['h'],40) or js_style(page,'#iconbox','borderRadius')!='12px': fail('icon box geometry')
    fr=rect(page,'#fab')
    if not approx(fr['w'],56) or not approx(fr['h'],56) or not approx(rect(page,'#fab .v-icon')['w'],28): fail('FAB geometry')
    if js_style(page,'#toast','marginLeft')!='16px' or js_style(page,'#toast','marginTop')!='4px' or js_style(page,'#toast','paddingLeft')!='16px' or js_style(page,'#toast','paddingTop')!='14px' or js_style(page,'#toast','borderRadius')!='16px': fail('toast geometry')
    if not approx(rect(page,'#progress')['h'],8) or js_style(page,'#progress','backgroundColor')!=js_style(page,'#empty','backgroundColor') and js_style(page,'#progress','backgroundColor')=='rgba(0, 0, 0, 0)': fail('progress geometry')
    if not approx(rect(page,'#steps .v-step__indicator')['w'],32) or not approx(rect(page,'#steps .v-step__indicator')['h'],32): fail('steps circle geometry')
    if js_style(page,'#select .v-select__item','height')!='44px' or js_style(page,'#select .v-select__item','minHeight')!='44px': fail('select item height 44')
    if rect(page,'#combobox .v-combobox__item')['h'] < 43.5: fail('combobox item min height 44')
    if js_style(page,'#combobox .v-combobox__item','paddingTop')!='4px' or js_style(page,'#combobox .v-combobox__item','paddingLeft')!='8px': fail('combobox item padding')
    if js_style(page,'#txt-h1','fontSize')!='28px' or js_style(page,'#txt-h1','lineHeight')!='34px' or js_style(page,'#txt-h1','fontWeight')!='700': fail('VText headingH1 typography')
    if js_style(page,'#txt-mono','fontFamily').split(',')[0].strip(' \"')!='JetBrains Mono' or 'tabular-nums' not in js_style(page,'#txt-mono','fontVariantNumeric'): fail('VText monoNumeric typography')
    danger_expected=page.evaluate("getComputedStyle(document.documentElement).getPropertyValue('--v-danger').trim()")
    probe=page.evaluate("c=>{const e=document.createElement('i');e.style.color=c;document.body.appendChild(e);const v=getComputedStyle(e).color;e.remove();return v}", danger_expected)
    if js_style(page,'#txt-danger','color')!=probe: fail('VText danger tone')

    # Interactions / behavior
    page.click('#select [data-v-select-trigger]'); page.click('#select [data-v-select-item]')
    if page.locator('#select [data-v-select-value]').inner_text().strip()!='B': fail('select interaction')
    page.click('#seg [data-v-segmented-item]:nth-child(2)')
    if page.get_attribute('#seg [data-v-segmented-item]:nth-child(2)','data-v-selected')!='true': fail('segmented interaction')
    page.click('#tabs [data-v-tab-trigger]:nth-child(2)')
    if page.eval_on_selector_all('#tabs [data-v-tab-content]','es=>es[1].hidden') is not False: fail('tabs interaction')
    page.fill('#money input','2200000'); page.dispatch_event('#money input','input')
    if page.input_value('#money input')!='2,200,000': fail('money formatter')
    page.fill('#number input','1234567.89'); page.dispatch_event('#number input','input')
    if page.input_value('#number input')!='1,234,567.89': fail('number formatter')
    page.fill('#verify input:nth-child(1)','1'); page.dispatch_event('#verify input:nth-child(1)','input')
    focused=page.evaluate("document.activeElement===document.querySelector('#verify input:nth-child(2)')")
    if not focused: fail('verification autofocus next cell')

    # Public runtime helper parity (Flutter top-level behavior APIs).
    filtered=page.evaluate("filterDropdownEntries([{label:'Minh Dũng',value:1},{label:'An Việt',value:2},{label:'Khác',value:3}],'dung').map(x=>x.value)")
    if filtered!=[1]: fail('filterDropdownEntries Vietnamese normalization '+repr(filtered))
    if page.evaluate("matchesComboboxSearch('viet','An Việt')") is not True: fail('matchesComboboxSearch Vietnamese normalization')

    page.evaluate("() => { window.__confirmCount=0; window.__confirmDone=false; showVConfirmDialog({title:'Xác nhận',message:'Kiểm tra',onAction:()=>window.__confirmCount++}).then(()=>window.__confirmDone=true); }")
    page.wait_for_selector('.v-modal-backdrop [data-v-dialog-action]')
    page.click('.v-modal-backdrop [data-v-dialog-action]')
    page.wait_for_timeout(40)
    if page.evaluate("window.__confirmCount")!=1 or page.evaluate("window.__confirmDone") is not True or page.locator('.v-modal-backdrop').count()!=0: fail('showVConfirmDialog runtime helper')

    page.evaluate("() => { window.__sheetResult='__pending__'; const child=document.createElement('button'); child.textContent='Child'; showVBottomSheet({title:'Sheet',child}).then(v=>window.__sheetResult=v); }")
    page.wait_for_selector('.v-sheet-backdrop .v-bottom-sheet')
    page.evaluate("() => { const h=document.querySelector('.v-sheet-backdrop'); h.dispatchEvent(new CustomEvent('vclose',{detail:{value:'ok'}})); }")
    page.wait_for_timeout(40)
    if page.evaluate("window.__sheetResult")!='ok' or page.locator('.v-sheet-backdrop').count()!=0: fail('showVBottomSheet runtime helper')

    page.evaluate("() => { window.__keypadResult='__pending__'; showVNumericKeypadSheet({mode:'quantity',initialRaw:'2'}).then(v=>window.__keypadResult=v); }")
    page.wait_for_selector('.v-sheet-backdrop .v-keypad-sheet')
    page.click('.v-sheet-backdrop [data-v-key="1"]')
    page.click('.v-sheet-backdrop [data-v-keypad-save]')
    page.wait_for_timeout(40)
    
    _kr=page.evaluate("window.__keypadResult"); _kc=page.locator('.v-sheet-backdrop').count()
    if _kr!='21' or _kc!=0: fail('showVNumericKeypadSheet runtime helper result='+repr(_kr)+' backdrops='+str(_kc))

    # No external runtime errors; fonts are host contract and therefore excluded from console checks.
    if page_errors: fail('page errors: '+repr(page_errors))
    console_errors=[e for e in console_errors if 'font' not in e.lower()]
    if console_errors: fail('console errors: '+repr(console_errors))
    browser.close()
print(json.dumps({'status':'FAIL' if findings else 'PASS','findings':findings},ensure_ascii=False,indent=2))
raise SystemExit(1 if findings else 0)
