/**
 * Mosaic Retail Flutter font bridge.
 *
 * The HTML package intentionally does not redistribute font binaries.  This
 * loader points the browser at the exact font files already present in the
 * authoritative Flutter checkout so HTML and Flutter rasterize the same
 * typefaces/weights.
 */
const FONT_FACES = [
  ['Inter',400,'ttf_Inter/Inter-Regular.ttf'],
  ['Inter',500,'ttf_Inter/Inter-Medium.ttf'],
  ['Inter',600,'ttf_Inter/Inter-SemiBold.ttf'],
  ['Inter',700,'ttf_Inter/Inter-Bold.ttf'],
  ['Inter',800,'ttf_Inter/Inter-ExtraBold.ttf'],
  ['JetBrains Mono',400,'ttf_JetBrainsMono/JetBrainsMono-Regular.ttf'],
  ['JetBrains Mono',500,'ttf_JetBrainsMono/JetBrainsMono-Medium.ttf'],
  ['JetBrains Mono',600,'ttf_JetBrainsMono/JetBrainsMono-SemiBold.ttf'],
  ['JetBrains Mono',700,'ttf_JetBrainsMono/JetBrainsMono-Bold.ttf'],
  ['JetBrains Mono',800,'ttf_JetBrainsMono/JetBrainsMono-ExtraBold.ttf'],
];

const stripSlash = value => String(value || '').replace(/\/+$/, '');

async function registerFace(family, weight, url) {
  const face = new FontFace(family, `url("${url}") format("truetype")`, {
    style: 'normal',
    weight: String(weight),
    display: 'block',
  });
  const loaded = await face.load();
  document.fonts.add(loaded);
  return loaded;
}

export async function loadFlutterParityFonts(options = {}) {
  if (typeof document === 'undefined' || typeof FontFace === 'undefined') {
    return { exact: false, reason: 'FontFace API unavailable', loaded: [] };
  }
  const root = stripSlash(options.fontRoot);
  if (!root) return { exact: false, reason: 'fontRoot not configured', loaded: [] };

  const loaded = [];
  const failed = [];
  await Promise.all(FONT_FACES.map(async ([family, weight, rel]) => {
    try {
      await registerFace(family, weight, `${root}/${rel}`);
      loaded.push(`${family}:${weight}`);
    } catch (error) {
      failed.push(`${family}:${weight}`);
    }
  }));

  const exact = failed.length === 0;
  document.documentElement.dataset.c45FlutterFonts = exact ? 'exact' : 'incomplete';
  window.__C45_FONT_PARITY__ = { exact, loaded, failed, fontRoot: root };
  return window.__C45_FONT_PARITY__;
}

export async function autoLoadFlutterParityFonts() {
  if (typeof window === 'undefined') return { exact: false, reason: 'no window', loaded: [] };
  const query = new URLSearchParams(window.location.search);
  const config = window.__C45_FLUTTER_ASSETS__ || {};
  const fontRoot = query.get('flutterFontRoot') || config.fontRoot || '';
  const result = await loadFlutterParityFonts({ fontRoot });
  if (!result.exact) {
    document.documentElement.dataset.c45FontParity = 'fallback';
  } else {
    document.documentElement.dataset.c45FontParity = 'exact';
  }
  return result;
}

export const flutterFontContract = Object.freeze({
  authority: 'c45_design_system 1.4.1',
  root: 'assets/fonts',
  faces: FONT_FACES.map(([family, weight, path]) => ({ family, weight, path })),
});
