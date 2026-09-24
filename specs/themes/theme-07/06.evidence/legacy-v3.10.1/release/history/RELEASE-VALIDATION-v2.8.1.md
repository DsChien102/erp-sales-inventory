# Release validation — v2.8.1

**Result: PASS**

Parent: **v2.8.0**. This is a shared review-device geometry correction only; business behavior is unchanged.

## Root cause

v2.8.0 forced the decorative `.device-preview` border-box to **402×874** even though that element also owns an **8px bezel on all sides**. With `box-sizing:border-box`, its actual content area therefore became **386×858**, while `#app-screen` correctly remained **402×874**. Because the device has `overflow:hidden`, **8px of the Product canvas was clipped on the right and bottom**. This is why otherwise-correct 16px Product padding looked almost flush to the right edge.

## Correction

- Product canvas remains exactly **402×874**.
- Decorative device border-box is **418×890** = Product canvas + 8px bezel on each edge.
- Product content box is therefore exactly **402×874** again.
- 370px components inside `VPagePadding` now render with **16px left + 16px right** symmetrically.
- Desktop review scaling now calculates available height from the device's actual padded start position, so the complete phone still fits without document scroll.

## QA

- Device-frame hard gate: **PASS 7/7**, covering **85/85 active screens**, **0 browser errors**.
- BJ06 Figma DS QA: **PASS 33/33**.
- Prior migrated BJ regression: **PASS 23/23**.
- All-flow runtime: **PASS 85/85**.
- Review workbench fit: **PASS 3/3** at 1366×768, 1600×900, 1920×1080.
- Mobile prototype validator: **PASS, 0 findings**.
- JavaScript syntax: **PASS**.

## Prevention gate

Future releases must assert both the Product viewport and the decorative device content box. Checking only `#app-screen.offsetWidth === 402` is insufficient because an outer `overflow:hidden` bezel can still clip that screen. The gate now requires `device.clientWidth === 402`, `device.clientHeight === 874`, inner-screen alignment on all four bezel edges, and symmetric 16px Product edges.
