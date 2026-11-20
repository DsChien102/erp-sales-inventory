---
target: Theme 7 prototype index.html
total_score: 24
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 2
target_identity: "file:/Users/macbook/Documents/Đồ án/specs/themes/theme-07/03.design/prototype/html/index.html"
target_fingerprint: "sha256:703adc3fe8011629fc93384b701eade761c27fcd4bc5b15ca79a861ce55206d0"
target_path: /Users/macbook/Documents/Đồ án/specs/themes/theme-07/03.design/prototype/html/index.html
timestamp: 2026-10-15T17-12-32Z
slug: me-07-03-design-prototype-html-index-html-050831a4
---
# Critique: Theme 7 prototype harness (index.html)
Method: dual-agent (A: design review · B: detector + headless Chrome)

## Heuristics (24/40, Acceptable)
| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of status | 3 | SCR-012 COMMIT_UNKNOWN: spinner + "Xác minh kết quả" CTA together; no reference/time |
| 2 | Real world match | 2 | Jargon (SCR-079, SCR-011); "kéo tệp" on phone (SCR-008) |
| 3 | User control | 2 | No back on SCR-001; "Hủy phiên" equal weight next to "Nộp kết quả đếm" (SCR-044) |
| 4 | Consistency | 2 | Two Warehouse Homes; bottom nav vs spec; uneven key-value padding |
| 5 | Error prevention | 3 | Approver on SCR-011 cannot see document vs received quantity |
| 6 | Recognition | 2 | SCR-010 shows only "1 lô · 120 hộp"; disabled CTA without reason (SCR-015) |
| 7 | Flexibility | 2 | No barcode scan or stepper (SCR-009, SCR-044); Kho behind "Thêm" |
| 8 | Minimalist | 2 | 5–7 metadata rows push goods below the fold (SCR-010/011) |
| 9 | Error recovery | 3 | SCR-008 good; PERMISSION_DENIED tells Owner to contact admin |
| 10 | Help | 3 | Good context banners; receipt modes weakly explained |

## Specificity
The domain logic and copy are authored for this product. The visuals are interchangeable: white list rows on gray. The prototype palette (#3B9448, #D98A0B, #2F6FE0) predates DESIGN.md (#2F7A3A, #935A0A, #2559C4), so most contrast hits are prototype-only. Semantic color misuse carries over to Flutter.

Detector: 306 folder findings, mostly token-source mismatch and noise. In-app contrast findings: success badge 3.2:1, warning badge 2.5:1, primary button 3.8:1, muted text on shelf gray 4.4:1. Also 9px bottom-nav labels and 2 nested cards (SCR-008, SCR-010).

## Priority issues
- [P0] Color carries no or the wrong meaning for money and stock (SCR-074, 011, 001, 003, 045). Fix: neutral mono money, signed deltas, amber for risk, DS badge + icon for stock state. Commands: colorize, clarify.
- [P1] Review and approval screens bury the decision (SCR-010/011). Fix: 2-line summary, exception lines first with document vs actual, reason next to the CTA. Commands: distill, layout.
- [P1] IA and navigation unresolved: two homes, Kho under "Thêm", nav differs from spec, missing back buttons. Commands: layout, distill.
- [P2] UNKNOWN, denied and disabled states are dead ends (SCR-012, SCR-001, SCR-015/009). Command: harden, clarify.
- [P2] Jargon and desktop-isms in copy; spec strings are normative, so propose changes to the Screen Contract. Command: clarify.

## Personas
Casey: cancel next to submit, keyboard-only counting, clipped chip strip. Jordan: two homes, 15 options, unexplained valuation terms. Sam: sub-4.5 muted text, color-only stock state, 9px nav. Owner: no at-a-glance low/expiring stock, green 13M risk.

## Minor
No inner padding on key-value rows (SCR-045, SCR-003); mono applied to unit words; empty NCC in the SCR-009 fixture; SCR-012 COMPLETED has a weak peak and no next step; all "Cần chú ý" items amber; quick flow SCR-010 shows document data.

## Questions
1. Should Kho be a tab or a Home card? 2. Should single-person shops see maker/approver? 3. Which screen should the committee remember?
