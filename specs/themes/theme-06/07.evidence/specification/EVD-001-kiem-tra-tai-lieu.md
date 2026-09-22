---
id: EVD-001
type: evidence
theme: theme-06
title: Kiểm tra tính nhất quán bộ tài liệu Công nợ v2.1.1
owner: QA
status: IN_REVIEW
---
# EVD-001 — Kiểm tra tính nhất quán bộ tài liệu Công nợ v2.1.1

## 1. Phạm vi

Kiểm tra tĩnh snapshot v2.1.1 gồm README, Knowledge, Overview, sáu Business Journey, Domain Foundation, Entity Catalog/Entity documents và Aggregate Candidate Catalog/Aggregate documents.

## 2. Kết quả validator

| Kiểm tra | Kết quả |
|---|---:|
| Markdown documents | 43 |
| Frontmatter IDs | 43 unique |
| Internal Markdown links | 297 checked / 0 lỗi |
| Decisions | 40 / mọi reference resolve |
| Domain documents | 1 |
| Entity documents | 10 |
| Aggregate documents | 7 |
| Hard-coded GitLab branch URL | 0 |
| Legacy `CN` technical identifier | 0 |
| Old-version remnant | 0 |

**Static verdict:** `READY_FOR_REVIEW`.

## 3. Review độc lập

- [EVD-002 — Senior BA / Domain Review](EVD-002-domain-review.md): ownership, boundary, invariant và negative scope.
- [EVD-003 — Delivery Simulation](EVD-003-delivery-simulation.md): Opening Balance, Payment Allocation và Debt Offset.
- [EVD-004 — Red-team Review](EVD-004-red-team.md): concurrency, stale approval, duplicate handoff, source conflict và out-of-scope leakage.

## 4. Giới hạn evidence

- Aggregate đang `IN_REVIEW`; chưa phải Architecture Freeze.
- Chưa có UC/BC hoàn chỉnh nên chưa thể chứng minh đầy đủ command semantics, transaction, `UNKNOWN`/recovery và integration runtime.
- Chưa có Screen Contract/prototype/implementation/E2E trong scope.
- Vì vậy không dùng verdict `RELEASE_READY`.

## 5. Artifact evidence

- `ket-qua-kiem-tra.json` — machine-readable result/gates.
- `package-manifest.json` — version/scope/status.
- `checksums.sha256` — checksum cuối của candidate.
