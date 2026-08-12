# Prototype HTML QA — v0.2.4

## Corrected against Flutter DS source

- Fixed semantic `VBanner` colors and removed non-DS banner borders.
- Restored Flutter `VBanner.error` default icon mapping to `VIcons.close`.
- Replaced success SVG approximation from `circle-check-big` to `circle-check`.
- Fixed `VToast`: close icon is plain `VIcons.close` (20px), no colored circular container.
- Switched `PERMISSION_DENIED` to screen-level `VEmptyState` + danger-toned `VEmptyMedia`.
- Standard mobile review frame is `402 × 874`.
- Theme 7 footer action profile is now `VButtonSize.medium` / 44px.
- Kept `VAppBarTitle` at Flutter-authoritative `VTypography.headingH3` (18/24, w700); no non-token 16px override.
- Removed the standalone approval status badge from `APPROVAL_ALREADY_DECIDED`; the persistent state surface carries the message.

## Contract propagation

- Updated Theme 7 component usage profile.
- Updated all 17 UIF component-usage YAML files.
- Updated canonical Screen contracts so permission masking no longer points to `VBanner.error`.
- Updated Harness generation script to preserve the new rules.
