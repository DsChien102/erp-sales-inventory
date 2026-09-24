# Isolation Report — v1.3.4

Parent: `v0.3.4` cumulative package.

## File-level result

- Parent files: **711**
- Final files before this report: **735**
- Existing files byte-identical: **643**
- Existing files intentionally modified: **68**
- Added artifacts: **24**
- Deleted parent files: **0**
- Modified files outside allowlist: **0**

## Protected baseline checks

**20/20 PASS** for explicit protected files, including BJ-01 flow/component/screen contracts, `index.html`, `tokens.generated.css`, and UIF flow docs outside the v1.3.4 design scope.

BJ-01 renderer lives in shared `app.js`, which is modified for new UIF renderers; runtime regression for BJ-01 is therefore covered separately by the 150/150 Chromium suite.

## Intended modification scope

- BJ-02 `SCR-084` quantity semantics + UIF02 usage/flow metadata.
- BJ-04…BJ-07 flow, screen/component contracts and context-aware HTML renderer/CSS/workbench data.
- Phase-A control decisions back-propagated to Decision Register and the affected BJ/UC source docs.
- Central registry/manifest/README metadata needed to describe v1.3.4.
- Shared SCR-036/037/038/041 are changed only to add/lock UIF07 context behavior; their other UIF uses remain regression-tested.

## Deleted files

None.

## Unexpected modifications

None.

## Legacy package validator

The repository-level `validate_package.py` fails on both parent v0.3.4 and v1.3.4 before content validation because `prototype/screen-map.md` is absent in the inherited package. This is a pre-existing validator/package mismatch, not a new v1.3.4 regression. Runtime, DS and isolation gates above are independent and pass.
