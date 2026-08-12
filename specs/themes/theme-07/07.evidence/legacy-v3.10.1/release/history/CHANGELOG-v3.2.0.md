# CHANGELOG — VET45 Theme 7 v3.2.0

Parent: `v3.1.0`

## Audit & Control UI correction

- Removed the redundant `Phiên đang thực hiện` heading from BJ08/SCR-042.
- Removed the visible `Hủy phiên` CTA from the browse/list screen; destructive session cancellation is no longer presented as a peer action to list navigation/create.
- Re-audited all Audit & Control root list screens for the same heading/action-placement error.
- Removed duplicate in-content headings where the AppBar already supplies the same context (BJ09 history, BJ15 report/source views).
- Replaced count-list free heading with existing `DS v2 / List Top Bar` count responsibility.
- Hardened dense VChip rows as intentional horizontal scrollers with complete labels.
- Preserved all v3.1.0 business states, handlers, actor boundaries and cumulative behavior.
- Added v3.2.0 UI-specific QA gates and refreshed contact-sheet visual review.
