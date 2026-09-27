# Parity Matrix v2.9.3 — Cross-BJ DS density & hierarchy correction

Baseline: v2.9.2. Business behavior is frozen. This release changes layout/composition only where the same semantic collection was over-carded.

| UIF | Screen | Role | States / scenarios | Actions that must remain | v2.9.3 visual responsibility |
|---|---|---|---|---|---|
| UIF-05 | SCR-025 | Warehouse picker | READY, LOADING, EMPTY, FILTER_EMPTY, PERMISSION_DENIED | Open eligible order; unavailable order remains disabled | Regression only; one homogeneous list |
| UIF-05 | SCR-026 | Warehouse picker | READY, STALE_RECOVERED, SHORTAGE, LOADING, PERMISSION_DENIED | Continue to pick detail | Regression only |
| UIF-05 | SCR-027 | Warehouse picker | READY, STALE_RECOVERED, PERMISSION_DENIED; multi-LOT | Open LOT editor; replace LOT | Regression only; compact multi-LOT remains |
| UIF-05 | SCR-028 | Warehouse picker | READY, PARTIAL_ALLOWED, PARTIAL_BLOCKED, SOURCE_CHANGED, PERMISSION_DENIED | Edit actual handover; submit when guard permits | **Change:** one grouped collection surface; Product+UOM uses canonical Status/Compact List Row; raw quantities are data, never VBadge; allocation facts/inputs remain canonical rows/fields |
| UIF-05 | SCR-029 | Warehouse picker | COMPLETED, PARTIAL_COMPLETED, UNKNOWN, REJECTED_EXECUTION, PERMISSION_DENIED | Terminal/recovery behavior unchanged | Regression only |
| UIF-06 | SCR-030 | Return receiver | READY, LOADING, EMPTY, FILTER_EMPTY, PERMISSION_DENIED | Open eligible return | Regression only |
| UIF-06 | SCR-031 | Return receiver | READY, LOADING, WAITING_APPROVAL, RETURN_CAP_CHANGED, SOURCE_CHANGED, CONFLICT, LOCKED, PERMISSION_DENIED | Go to receipt / classification | Regression only |
| UIF-06 | SCR-032 | Return receiver | READY, VALIDATION_ERROR, APPROVED_EXCEPTION, REJECTED_EXCEPTION, PENDING_APPROVAL, CONFLICT, LOCKED, PERMISSION_DENIED | Record received quantities / wrong-LOT handoff | Regression only |
| UIF-06 | SCR-033 | Return receiver | READY, VALIDATION_ERROR, EXPIRED_GUARD, SOURCE_CHANGED, CONFLICT, LOCKED, PERMISSION_DENIED | Classify authoritative quantities | Regression only |
| UIF-06 | SCR-034 | Wrong-LOT approver | TASK_LIST, READY, APPROVED, REJECTED, PERMISSION_DENIED | Approve/reject wrong-LOT exception | Regression only; actor-handoff Back path remains isolated |
| UIF-06 | SCR-035 | Return receiver | RECEIVED_PENDING_CLASSIFICATION, COMPLETED, UNKNOWN, REJECTED_EXECUTION, PERMISSION_DENIED | Terminal/recovery behavior unchanged | **Change:** one result grouped surface; Product+UOM uses canonical Status/Compact List Row with semantic status; child evidence uses Info Row; raw quantity is not a badge |
| UIF-07 | SCR-036 | Supplier-return operator | READY, LOADING, EMPTY, FILTER_EMPTY, PERMISSION_DENIED, EXPIRED | Open eligible return; unavailable row disabled | Regression only; one homogeneous list, no stage headings |
| UIF-07 | SCR-037 | Supplier-return operator | READY, LOADING, EXPIRED, LOCKED, PERMISSION_DENIED, FINANCIAL_RESTRICTED; many LOT / no-LOT / mixed UOM | Verify individual allocation; review when complete | **Change:** one grouped collection surface, no card per Product; Product+UOM = Status/Compact List Row; actionable LOT = Navigation/Default List Row; subgroup separation via layout divider/spacing |
| UIF-07 | SCR-039 | Supplier-return operator | READY, SOURCE_CHANGED, PHYSICAL_MISMATCH, VALIDATION_ERROR, PERMISSION_DENIED | Recheck / confirm physical handover as guarded | **Change:** one grouped read-only collection surface; Product+UOM = Status/Compact with true semantic status; LOT = Key-value Row; raw quantity not VBadge |
| UIF-07 | SCR-041 | Supplier-return operator | PROCESSING, COMPLETED, PENDING_APPROVAL, REJECTED_EXECUTION, UNKNOWN, EXPIRED, PERMISSION_DENIED | Terminal/recovery behavior unchanged | **Change:** same hierarchy as SCR-039; Product+UOM semantic completion status; LOT evidence = Key-value Row |

## Cross-BJ regression scope

UIF-01, UIF-02, UIF-04 and UIF-08 remain behavior/layout frozen unless the visual audit finds the same exact anti-pattern. Audit gates still apply to every migrated canonical screen.

## Hard gates

1. Product viewport remains 402×874; 16px page edge; workbench scaling cannot alter Product geometry.
2. Canonical DS claims must map to live Figma masters: List Row `525:519`, Info Row `525:351`, Key-value Row `525:358`, VBadge `525:309`, Sticky Footer canonical pattern.
3. A raw quantity such as `6 hộp`, `5 lọ`, `4 hộp` must not be rendered as VBadge. Badge content must be a semantic state/progress label.
4. One semantic homogeneous collection may have at most one dominant grouped-surface boundary. Do not render one outer card per repeated Product subgroup.
5. Product subgroup and child LOT/allocation must have distinct responsibilities: parent context = Status/Compact; actionable child = Navigation/Default; read-only child fact = Info/Key-value Row.
6. No browser error, clipping, horizontal overflow, serif fallback, hidden CTA, or inaccessible interaction target.
7. Visual review is mandatory after automated QA; automated PASS cannot override obvious hierarchy/card-soup defects.
