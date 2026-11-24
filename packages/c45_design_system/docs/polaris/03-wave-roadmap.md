# 03 — Wave Roadmap

## Wave 1 — Spec (docs-first)

- Tạo bộ Polaris docs (file này + 6 file còn lại)
- Cập nhật presentation skill + cursor rule
- Chốt 5 recipes vàng trong `06-design-system-spec.md`

**Done khi:** agent/PR có spec để follow; không refactor bulk.

## Wave 2 — Layout primitives

- `VGap`, `VPagePadding`, `VSection`, `VPageScaffold`
- Fix `VCard` default padding → `VSpacing.md`
- Example catalog + widget tests + component audit

**Done khi:** primitives export + demo trong example app.

## Wave 3 — Enforcement

- `scripts/ci/guard_design_system_usage.sh`
- Wire vào `verify_harness.sh`
- Cursor rule: feature UI mới dùng layout primitives

**Done khi:** CI fail trên magic spacing / raw overlay trong scope catalog.

## Wave 4 — Golden migration

- Product Control Center → `VPageScaffold`, `VGap`, `VText`, `showV*`
- Thắt allowlist guard cho control center files
- Document golden reference trong Polaris README

**Done khi:** control center pass guard; tests green.

## Wave 5 — Component contracts (Tone / Emphasis / State)

- Spec: [08-component-contracts.md](08-component-contracts.md)
- Matrix: `docs/audit/contract_matrix.yaml`
- Waves B–E: primitives → controls → overlays → KPI/CI `--fail-on-required`

**Done khi:** Action/Input/Toggle/Status required Pass; audit fail-on-required trong CI.

## Wave 6+ (ngoài scope contract sync)

- custom_lint plugin
- Migrate partner + catalog bulk
- Dark theme
