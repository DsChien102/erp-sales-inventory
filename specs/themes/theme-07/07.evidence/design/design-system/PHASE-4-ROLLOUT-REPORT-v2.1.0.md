# Phase 4 — Full Figma DS Rollout Report v2.1.0

**Parent:** v2.0.2  
**Figma DS authority:** v2.0.2  
**Business/behavior change:** none by design.

## Outcome

- 17/17 active UIFs use the Figma-migrated shell and exact template responsibility.
- 73 distinct canonical active screens are covered; shared screens retain per-UIF task context without cloning business behavior.
- Product canvas corrected to true 402×874; workbench bezel no longer consumes Product pixels.
- Active generic `VCard` and `VQuantitySelector` annotations are eliminated.
- Active runtime mapping resolves 10,543 annotations with zero migration-debt/gap/card statuses.

## Template distribution

- `Mobile / Detail` (`551:1396`): **32 flow/screen mappings**
- `Mobile / Form` (`551:1452`): **20 flow/screen mappings**
- `Mobile / State` (`551:1746`): **17 flow/screen mappings**
- `Mobile / Root List` (`551:549`): **13 flow/screen mappings**
- `Mobile / Nested List` (`551:1277`): **2 flow/screen mappings**
- `Mobile / Search & Select` (`551:1621`): **1 flow/screen mappings**

## Exact flow/screen template matrix

| UIF | Screen | Figma template | Node |
|---|---|---|---|
| UIF-01 | SCR-001 | `Mobile / Root List` | `551:549` |
| UIF-01 | SCR-003 | `Mobile / Detail` | `551:1396` |
| UIF-02 | SCR-006 | `Mobile / Nested List` | `551:1277` |
| UIF-02 | SCR-007 | `Mobile / Nested List` | `551:1277` |
| UIF-02 | SCR-008 | `Mobile / Form` | `551:1452` |
| UIF-02 | SCR-009 | `Mobile / Form` | `551:1452` |
| UIF-02 | SCR-084 | `Mobile / Search & Select` | `551:1621` |
| UIF-02 | SCR-010 | `Mobile / Detail` | `551:1396` |
| UIF-02 | SCR-011 | `Mobile / Detail` | `551:1396` |
| UIF-02 | SCR-012 | `Mobile / State` | `551:1746` |
| UIF-02 | SCR-013 | `Mobile / Detail` | `551:1396` |
| UIF-03 | SCR-014 | `Mobile / Root List` | `551:549` |
| UIF-03 | SCR-015 | `Mobile / Form` | `551:1452` |
| UIF-03 | SCR-017 | `Mobile / Detail` | `551:1396` |
| UIF-03 | SCR-019 | `Mobile / State` | `551:1746` |
| UIF-04 | SCR-021 | `Mobile / Detail` | `551:1396` |
| UIF-05 | SCR-025 | `Mobile / Root List` | `551:549` |
| UIF-05 | SCR-026 | `Mobile / Detail` | `551:1396` |
| UIF-05 | SCR-027 | `Mobile / Form` | `551:1452` |
| UIF-05 | SCR-028 | `Mobile / Detail` | `551:1396` |
| UIF-05 | SCR-029 | `Mobile / State` | `551:1746` |
| UIF-06 | SCR-030 | `Mobile / Root List` | `551:549` |
| UIF-06 | SCR-031 | `Mobile / Detail` | `551:1396` |
| UIF-06 | SCR-032 | `Mobile / Form` | `551:1452` |
| UIF-06 | SCR-034 | `Mobile / Detail` | `551:1396` |
| UIF-06 | SCR-033 | `Mobile / Form` | `551:1452` |
| UIF-06 | SCR-035 | `Mobile / State` | `551:1746` |
| UIF-07 | SCR-036 | `Mobile / Root List` | `551:549` |
| UIF-07 | SCR-037 | `Mobile / Detail` | `551:1396` |
| UIF-07 | SCR-039 | `Mobile / Detail` | `551:1396` |
| UIF-07 | SCR-041 | `Mobile / State` | `551:1746` |
| UIF-08 | SCR-042 | `Mobile / Root List` | `551:549` |
| UIF-08 | SCR-043 | `Mobile / Form` | `551:1452` |
| UIF-08 | SCR-044 | `Mobile / Form` | `551:1452` |
| UIF-08 | SCR-045 | `Mobile / Form` | `551:1452` |
| UIF-08 | SCR-046 | `Mobile / Detail` | `551:1396` |
| UIF-08 | SCR-047 | `Mobile / State` | `551:1746` |
| UIF-09 | SCR-036 | `Mobile / Root List` | `551:549` |
| UIF-09 | SCR-037 | `Mobile / Detail` | `551:1396` |
| UIF-09 | SCR-038 | `Mobile / Form` | `551:1452` |
| UIF-09 | SCR-041 | `Mobile / State` | `551:1746` |
| UIF-09 | SCR-056 | `Mobile / Detail` | `551:1396` |
| UIF-10 | SCR-036 | `Mobile / Root List` | `551:549` |
| UIF-10 | SCR-037 | `Mobile / Detail` | `551:1396` |
| UIF-10 | SCR-040 | `Mobile / Form` | `551:1452` |
| UIF-10 | SCR-041 | `Mobile / State` | `551:1746` |
| UIF-11 | SCR-048 | `Mobile / Root List` | `551:549` |
| UIF-11 | SCR-049 | `Mobile / Detail` | `551:1396` |
| UIF-11 | SCR-052 | `Mobile / Form` | `551:1452` |
| UIF-11 | SCR-050 | `Mobile / Form` | `551:1452` |
| UIF-11 | SCR-053 | `Mobile / State` | `551:1746` |
| UIF-11 | SCR-051 | `Mobile / Detail` | `551:1396` |
| UIF-12 | SCR-066 | `Mobile / State` | `551:1746` |
| UIF-12 | SCR-067 | `Mobile / Form` | `551:1452` |
| UIF-12 | SCR-068 | `Mobile / State` | `551:1746` |
| UIF-12 | SCR-069 | `Mobile / Detail` | `551:1396` |
| UIF-12 | SCR-070 | `Mobile / Detail` | `551:1396` |
| UIF-12 | SCR-071 | `Mobile / State` | `551:1746` |
| UIF-13 | SCR-085 | `Mobile / Root List` | `551:549` |
| UIF-13 | SCR-086 | `Mobile / Form` | `551:1452` |
| UIF-13 | SCR-087 | `Mobile / Form` | `551:1452` |
| UIF-13 | SCR-088 | `Mobile / Detail` | `551:1396` |
| UIF-13 | SCR-089 | `Mobile / State` | `551:1746` |
| UIF-14 | SCR-072 | `Mobile / Root List` | `551:549` |
| UIF-14 | SCR-073 | `Mobile / Form` | `551:1452` |
| UIF-14 | SCR-074 | `Mobile / Detail` | `551:1396` |
| UIF-14 | SCR-076 | `Mobile / Detail` | `551:1396` |
| UIF-14 | SCR-077 | `Mobile / State` | `551:1746` |
| UIF-15 | SCR-054 | `Mobile / Form` | `551:1452` |
| UIF-15 | SCR-055 | `Mobile / Detail` | `551:1396` |
| UIF-15 | SCR-056 | `Mobile / Detail` | `551:1396` |
| UIF-15 | SCR-057 | `Mobile / Detail` | `551:1396` |
| UIF-15 | SCR-058 | `Mobile / Detail` | `551:1396` |
| UIF-15 | SCR-059 | `Mobile / State` | `551:1746` |
| UIF-16 | SCR-078 | `Mobile / Root List` | `551:549` |
| UIF-16 | SCR-079 | `Mobile / Detail` | `551:1396` |
| UIF-16 | SCR-080 | `Mobile / Form` | `551:1452` |
| UIF-16 | SCR-081 | `Mobile / Detail` | `551:1396` |
| UIF-16 | SCR-082 | `Mobile / Detail` | `551:1396` |
| UIF-16 | SCR-083 | `Mobile / State` | `551:1746` |
| UIF-17 | SCR-078 | `Mobile / Root List` | `551:549` |
| UIF-17 | SCR-079 | `Mobile / Detail` | `551:1396` |
| UIF-17 | SCR-080 | `Mobile / Form` | `551:1452` |
| UIF-17 | SCR-082 | `Mobile / Detail` | `551:1396` |
| UIF-17 | SCR-083 | `Mobile / State` | `551:1746` |

## Rollout decisions

1. List/record surfaces follow `DS v2 / List Row` when anatomy is navigation/selection/status; list containers are layout composition, not a new card component.
2. Read-only facts use `DS v2 / Info Row`; compact summary facts use `DS v2 / Summary Card`; token-based `VSection` is allowed only as layout composition.
3. Plain numeric quantity input uses `VTextField`; the historical `VQuantitySelector` no longer appears in active Product output.
4. Search/filter follows actual task semantics. A filter affordance is not added when there is no real filter task merely to mimic a specimen.
5. State/result presentation uses `Mobile / State` responsibility without changing commit/finality/recovery semantics.
6. Figma DS governs UI expression; BJ/UIF/contracts continue to govern business meaning and behavior.

## Evidence

- `PHASE-4-VALIDATION-v2.1.0.md`
- `../../html/qa/FIGMA-DS-FULL-ROLLOUT-QA-v2.1.0.md`
- `../../html/qa/FIGMA-DS-MAPPING-QA-v2.1.0.md`
- `../../html/qa/VISUAL-QA-v2.1.0.md`
