# UIF-04 — Component Usage Contract v3.9.6

> UI authority: live VET45 Figma Design System. Business authority: BJ-04 / UC-04 / T7-DR-144…149.

`SCR-021` là active read-only contextual surface duy nhất.

| UI responsibility | Figma DS asset | Rule |
|---|---|---|
| Mobile detail | `Mobile / Detail`, `VPageScaffold`, `VAppBar`, `VPagePadding` | 402×874, back only |
| Order context | `DS v2 / Info Row` | no custom context card |
| Line projection | `DS v2 / List Row · Type=Status` | non-interactive source-line fact |
| Shortage/lifecycle exception | `VBadge` | only when meaningful |
| Persistent exception | `VBanner` | shortage or no-current-hold info |
| Loading/access | `VSkeleton`, `VEmptyState` | canonical |

Deliberate non-usage: no `VCard`, no mutation `VButton`, no `VToast`, no success badge for normal/full, no custom reservation component, no architectural business-note text.
