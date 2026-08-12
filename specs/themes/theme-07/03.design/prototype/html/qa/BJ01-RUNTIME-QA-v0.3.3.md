# BJ-01 Runtime / Flutter DS Smoke v0.3.3

**Result: 42/42 PASS**

Runs the cumulative renderer in headless Chromium at 402 × 874.

## Checks

- [x] mobile frame 402x874 — [402, 874]
- [x] SCR001 uses VPageScaffold
- [x] SCR001 uses VAppBar
- [x] SCR001 uses shared VSearchBar profile
- [x] SCR001 uses 5 VChip filters
- [x] SCR001 has one list VCard container
- [x] SCR001 not card-per-product
- [x] SCR001 product rows compose DS primitives
- [x] SCR001 whole row tap only, no open CTA
- [x] SCR001 no tracking text
- [x] SCR001 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] SCR001 all may show VBadge statuses
- [x] LOW filter keeps VChip selected state
- [x] LOW filter does not repeat row status badge
- [x] filter empty retains VSearchBar/VChip
- [x] empty recovery uses VButton secondary
- [x] opens SCR003
- [x] detail summary is one VCard
- [x] detail summary has one available hero
- [x] detail breakdown exactly physical/sellable/reserved — ['Tồn vật lý', 'Đủ điều kiện bán', 'Đã giữ']
- [x] normal detail has no VBanner
- [x] LOT list in one VCard
- [x] LOT rows use VBadge for expiry only when needed
- [x] provenance entry is interactive VCard
- [x] detail no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] LOT uses VBottomSheet
- [x] LOT sheet uses standard handle/title/divider/content
- [x] LOT sheet has no custom close icon/button
- [x] near expiry uses VBanner warning in sheet
- [x] LOT backdrop dismiss returns SCR003
- [x] provenance uses VBottomSheet
- [x] provenance has no custom close
- [x] provenance handoff uses VButton secondary
- [x] provenance has no technical English
- [x] LOW uses VBanner.warning
- [x] LOW banner carries threshold/suggestion
- [x] no custom attention-row visual remains
- [x] OUT uses VBanner.error
- [x] STALE uses warning banner and secondary VButton
- [x] refresh returns READY
- [x] permission uses VEmptyState
- [x] permission omits inventory summary/lot data

## Boundary

- Validates BJ01 public Flutter-DS mapping, layout/interaction, content hygiene and 402×874 overflow.
- Does not assert external Vercel pixel parity because the external site is not available in this runtime.
