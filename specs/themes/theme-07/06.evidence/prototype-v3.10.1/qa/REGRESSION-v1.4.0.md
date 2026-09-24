# Regression — protected cumulative baselines under v1.4.0

**Result: PASS**

v1.4.0 changes the shared renderer/data only for BJ03/UIF03 and scopes new visual rules under `body[data-active-uif="UIF-03"]`.

## Protected Inventory Operations baselines

Executed against the final v1.4.0 renderer in a temporary regression copy so historical evidence files are not regenerated:

- BJ05 end-user regression (`bj05_end_user_v137.py`) → **PASS 48/48**.
- BJ06 end-user regression (`bj06_end_user_v138.py`) → **PASS 65/65**.
- BJ07 end-user regression (`bj07_end_user_v139.py`) → **PASS 65/65**.
- All-flow runtime smoke (`all_flows_smoke_v140.py`) → **PASS 87 flow/screen renders**.

## UIF13 shared-screen isolation

Current v1.4.0 and pristine v1.3.9 were rendered side-by-side for UIF13 READY state. Rendered Product text is **identical** on:

- `SCR-014`
- `SCR-015`
- `SCR-018`
- `SCR-017`
- `SCR-019`

The shared workbench payload for `SCR-014/015/017/019` is also preserved semantically from the parent; only UIF03-owned `SCR-016` data is deep-corrected.

This gate proves v1.4.0 did not hijack UIF13 while correcting shared screen IDs. It does **not** declare UIF13 Product-ready; UIF13 is intentionally deferred to its own deep-correction release.
