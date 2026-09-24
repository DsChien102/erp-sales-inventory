# CHANGELOG v2.7.2

## Detail composition sync

- Replaced BJ05 SCR-027 ad-hoc product header with the canonical Detail composition: `DS v2 / Summary Card` (`525:552`) + supporting `DS v2 / Info Row`.
- Corrected BJ01 product detail identity to the same canonical Summary Card responsibility.
- Corrected BJ02 product-summary composition so the Summary Card contains only canonical title/body anatomy; supporting quantity/action remain outside the master.
- Kept `VSection` structural and surface-free; visual grouping follows Layout rules.
- Kept BJ05 handover product as a Product UI grouped surface because each product is an independent business unit; it is explicitly a Layout composition, not a new component.
- Reviewed migrated BJ04 and BJ08 detail compositions and retained already-compliant structures.
- No business-rule or workflow change.
