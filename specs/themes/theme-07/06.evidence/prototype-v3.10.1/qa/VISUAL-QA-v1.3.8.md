# Visual QA v1.3.8 — BJ06 deep correction

**Result: PASS · 12 focused specimens reviewed at 402×874**

Review performed after end-user/state QA. Automated checks are not treated as visual approval; each specimen below was inspected for hierarchy, wrapping, clipping, sticky actions, information density, semantic feedback and mobile task clarity.

## Specimens

- `BJ06-SCR030-all.png` — default `Tất cả`, chip order, queue scanability.
- `BJ06-SCR031-unverified.png` — source facts separated from physical confirmation; 0/4 verified.
- `BJ06-SCR031-exception-draft.png` — one wrong-LOT draft among multi-line request.
- `BJ06-SCR031-waiting-approval.png` — maker read-only while approval cases pending.
- `BJ06-SCR031-cap-changed.png` — cap/source change blocker and safe refresh.
- `BJ06-SCR032-wrong-lot-evidence.png` — explicit `Lô khác`, actual LOT and exception warning.
- `BJ06-SCR034-pending-detail.png` — approver sees exact case evidence including viewable LOT-label image.
- `BJ06-SCR034-rejected.png` — final rejected decision, no repeat decision CTA.
- `BJ06-SCR033-editor.png` — classification Bottom Sheet with `Hủy / Xong` and expiry hard guard.
- `BJ06-SCR033-ready-complete.png` — multi-line classification overview ready to commit.
- `BJ06-SCR035-received.png` — receipt result per line/UOM, no mixed-UOM aggregate, safe next actions.
- `BJ06-SCR035-classified.png` — final classification result and safe queue CTA.

## Visual conclusions

- No horizontal overflow in SCR-030…035 in runtime geometry checks.
- Sticky footer actions remain reachable without covering decisive content.
- Normal/source information uses quiet presentation; warning/error banners are reserved for actual blocker/exception states.
- Multi-LOT rows remain distinguishable without card inflation.
- Approver evidence is visually inspectable; filename is not the only evidence surface.
- Classification editor is escapable and does not trap the user when data is incomplete.
- Result surfaces have finality and do not expose Back into consumed mutation screens.

The generated evidence image is a QA fixture only; it is not business truth or a mandated document format.
