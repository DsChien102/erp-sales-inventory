# Baseline Validation — Theme 09 v0.1.0

**Scope:** Knowledge + Overview + Domain + Entities + Aggregate Candidate  
**Semantic freeze:** `NOT_FROZEN`  
**Static gate:** `PASS`

## 1. Gate results

| Gate | Result | Evidence |
|---|---|---|
| Baseline/source/parent | PASS | Greenfield parent `NONE`; authority và assumptions tách riêng |
| Structure theo template mới | PASS | Knowledge → Specification → Design placeholder → Architecture |
| Decision IDs | PASS | 52 decision, unique=True |
| Aggregate IDs | PASS | 10 aggregate candidate |
| Know-how | PASS | 10 bài |
| Ownership review | PASS | T05/T06/T07/T08/T10 không bị Theme 09 chiếm ownership |
| Freeze truthfulness | PASS | package `IN_REVIEW`, `NOT_FROZEN`, không claim release |
| BJ/UC/UI/API/runtime | NOT_RUN | Ngoài scope v0.1.0 |

## 2. Senior BA / domain review

**Kết quả:** PASS cho mục tiêu review baseline.

- Domain có một owner rõ cho ledger/period; source domains giữ business truth.
- Tách `AccountingFact` và `AccountingEntry` tránh duplicate authority và cho phép nhiều accounting scheme.
- Time semantics tách source effective/accounting/recorded time.
- Correction không mutate history.
- Tax là subdomain đề xuất, chưa giả vờ là decision frozen.

## 3. Delivery simulation

Sample: `SalesOrder` final → accounting fact → accounting case → policy → entry → book/tax projection.

Điểm có thể triển khai sau freeze: identity, period guard, entry immutability và posting result đã đủ rõ. Những gì Dev/QA vẫn phải hỏi và vì vậy **chưa được phép implement từ baseline này**: exact payload/API/event schema, late-event default, manual approval, tax form catalog, dimension minimum. Các điểm này đã có OQ tương ứng.

## 4. Red-team review

Đã kiểm các failure class: double posting, invoice double count, forecast posted as actual, manual journal che sai subledger, posting vào kỳ khóa, source correction overwrite history, technical timeout/UNKNOWN, cross-theme ownership drift. Baseline có invariant hoặc decision chặn từng lớp trên.

## 5. Findings

- Không có BLOCKER/HIGH trong scope static baseline.

## 6. Known review items (không phải validator failure)

- OQ-01: ownership vòng đời kê khai/nộp thuế.
- OQ-02: có bật TT58/2026 ngay Phase 1 hay không.
- OQ-04/OQ-05: manual journal và approval.
- OQ-06: default late-event khi kỳ khóa.
- OQ-08: recognition boundary SalesOrder ↔ invoice.
- OQ-09: legal mapping form catalog 2026.

**Verdict:** `BASELINE_READY_FOR_REVIEW` nếu static gate PASS. Không phải `FROZEN`, không phải `RELEASE_READY`.
