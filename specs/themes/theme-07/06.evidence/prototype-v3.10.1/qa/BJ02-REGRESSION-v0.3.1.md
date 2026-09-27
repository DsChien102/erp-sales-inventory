# BJ-02 Protected Baseline Regression — v0.3.1

## Purpose
Prove that adding BJ-01 to the shared workbench did not re-design or replace BJ-02 v0.2.9.

## Results
- Original v0.2.9 Chromium runtime suite executed against a temporary clone of v0.3.1: **78/78 PASS**.
- Default rendered Product DOM for `SCR-006`, `007`, `008`, `009`, `084`, `010`, `011`, `012`, `013`: **9/9 identical** to the exact v0.2.9 baseline after normalizing only the runtime-generated `LOT-DRAFT-<timestamp>` identifier in SCR-084.
- BJ-02 flow file, UIF-02 component-usage contracts, SCR-006..013 + SCR-084 contracts, BJ02 pilot-review history and canonical v0.2.9 screenshot files remain byte-identical in the package: **23/23**.
- Historical `RUNTIME-SMOKE-v0.2.9.md`, `CONFORMANCE-REPORT.md` and screenshots are not overwritten by v0.3.1 QA.

## Static validator note
The historical `validate_contract.py` from v0.2.9 was run on a temporary v0.3.1 clone and returned **219/221**. The only two failed assertions are hard-coded release metadata expectations (`manifest.version == 0.2.9` and calibration `BJ-02/UIF-02`). All other 219 legacy checks pass. The historical validator itself is preserved unchanged in canonical v0.3.1.

## Visual determinism note
The old screenshot smoke script has small sub-pixel/caret differences even between two independent runs of the **same** v0.2.9 baseline, so newly rendered PNGs are not used as a strict byte/pixel identity gate. The canonical screenshot files inside v0.3.1 remain byte-identical to the uploaded v0.2.9 files, and the normalized Product DOM + original 78 runtime assertions are used as the regression gate.

**Result: PASS — BJ-02 v0.2.9 remains the protected behavior/structure baseline.**
