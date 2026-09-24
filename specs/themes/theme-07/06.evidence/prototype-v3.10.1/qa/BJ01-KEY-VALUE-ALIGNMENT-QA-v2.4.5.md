# BJ01 Key-value Alignment QA — v2.4.5

**Result: FAIL · 32/34 checks**

Scope: Key-value Row alignment hardening with exact component-owned typography preserved; prior BJ01 DS fidelity and overflow gates remain protected.

- PASS — Theme7AvailabilitySummary remains removed
- PASS — BJ01 availability source composes only Key-value Row
- PASS — JetBrains Mono is requested with Inter
- PASS — Availability renders four canonical Key-value Rows
- PASS — Availability renders no Info Row
- PASS — Primary Khả dụng is Emphasis
- PASS — Supporting quantities are Default Key-value Rows
- PASS — Emphasis row preserves live Figma 338x44 geometry
- PASS — Emphasis label typography matches Figma
- PASS — Emphasis value typography matches Figma
- PASS — Default Key-value Row preserves live Figma 338x44 geometry
- PASS — Default label typography matches Figma
- PASS — Default numeric value typography uses JetBrains Mono
- PASS — Key-value labels and values preserve Figma shrink-0 semantics
- PASS — Key-value labels and values stay on one line
- PASS — Supporting quantity values align on one right edge
- PASS — Supporting labels and values never visually stick together
- PASS — 338px Key-value master is centered in 370px Product column
- PASS — One-line VBanner hugs content instead of forcing 96px
- PASS — VBanner shell geometry matches Figma
- PASS — VBanner copy width/gap match live master
- PASS — VBanner semantic icon is direct 20px without decorative circle
- PASS — Longer VBanner grows from content
- PASS — VSearchBar remains exact 370x44 with 20px icon
- PASS — VSearchBar input fills remaining control width
- PASS — VChip expanded hit area is anchored to each chip
- PASS — Info Row is retained only for supporting provenance metadata
- FAIL — Metadata Info Row preserves canonical 44px / 8px-gap anatomy — {'height': '44px', 'columnGap': '0px', 'justifyContent': 'space-between', '__x': 539, '__y': 834, '__w': 338, '__h': 44}
- FAIL — Provenance VBottomSheet has no horizontal overflow
- PASS — VBottomSheet still matches live master geometry
- PASS — SCR-001 creates no Theme7 component identity
- PASS — SCR-003 creates no Theme7 component identity
- PASS — BJ01 main states have no horizontal overflow
- PASS — No browser page errors
