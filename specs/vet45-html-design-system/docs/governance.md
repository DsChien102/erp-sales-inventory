# Governance — Flutter → HTML

## Authority chain

**Product/BJ/UC/UI Contract → Flutter DS 1.4.1 → HTML DS 2.0.0 → Theme prototype → Production**

- Product documents decide business meaning, flow, data and actions.
- Flutter DS 1.4.1 decides canonical visual/API expression: public component inventory, anatomy, variants, state, tokens, density and semantic icons.
- HTML DS 2.0.0 is the browser mirror of that Flutter contract.
- Theme HTML composes the canonical DS; it must not invent a visual replacement.
- Figma and HTML DS 1.6 are historical references only unless the project explicitly changes authority in a later decision.

## Canonical test

A component is canonical in HTML v2 only when it is represented by the Flutter public barrel `lib/design_system.dart`. A name present only in old Figma/HTML artifacts is not canonical.

## DS gaps

If a Theme needs an API not exported by Flutter, record a DS gap and resolve it in the shared Design System. Do not create a Theme-local component and label it as Flutter DS.
