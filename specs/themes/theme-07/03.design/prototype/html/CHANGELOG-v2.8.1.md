# Changelog — v2.8.1

Parent: v2.8.0.

## Fixed

- Corrected the shared review-device geometry regression from v2.8.0.
- Product canvas remains canonical 402×874.
- The decorative 8px phone bezel now sits outside the Product canvas: device border-box 418×890, content box 402×874.
- Restored symmetric 16px Product edge spacing; content is no longer visually clipped/tight on the right.
- Restored the missing 8px at the bottom of the Product canvas as well.
- No BJ business behavior or DS component anatomy changed.

## Prevention

QA now asserts device border-box/content-box geometry and symmetric mobile edge spacing, rather than only asserting that the inner screen reports offsetWidth=402.
