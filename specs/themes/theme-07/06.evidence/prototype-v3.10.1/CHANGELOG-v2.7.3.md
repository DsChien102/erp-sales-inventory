# CHANGELOG v2.7.3

Parent: v2.7.2. Business behavior unchanged.

- Full review of migrated BJ01/BJ02/BJ04/BJ05/BJ08 against live Figma DS + cross-theme Product composition references.
- Corrected sparse Summary Card misuse: BJ01/SCR-003, BJ02/SCR-084, BJ05/SCR-027 use Status/Compact List Row context where semantically appropriate.
- BJ05/SCR-025 and SCR-026 preserve one Navigation/Default List Row collection; unavailable records use Disabled state rather than switching Type/removing chevron.
- Corrected Compact List Row geometry to the live master: 370×52, p4/16, gap8, radius8.
- Removed BJ02 Record Card internal 2px width drift.
- Added explicit cross-theme Figma composition-reference rule.
- Added `prototype.manifest.json`, runtime contract markers and `window.__VET45_PROTOTYPE__`; removed external font network references so the harness runtime is offline.
- Added focused cross-BJ clipping/overflow/footer-reachability QA and refreshed BJ05/all-flow regression gates.
