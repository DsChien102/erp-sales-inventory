---
id: EVD-UIF-CANONICALIZATION-v4.0.0
type: evidence
theme: theme-07
title: "Canonical UIF reintroduction and BJ/UC trace closure"
owner: BA/QA
status: PASS
version: v4.0.0
parent: v3.12.0
---
# Evidence — Canonical UIF v4.0.0

## Mục tiêu

Khôi phục UI Flow thành artifact canonical first-class mà không đưa screen flow trở lại Business Journey và không sao chép business behavior của Use Case.

## Kết quả

- 17/17 Business Journey có đúng một `ui_flow` canonical và relative link tới `03.design/flows/`.
- 17/17 UIF có Begin/terminal contract, Mermaid screen flow, Transition Contract, UC/Screen coverage, Back/Cancel/reload/recovery và reverse link về BJ/UC.
- 64/64 UC canonical có direct link tới UIF của BJ tương ứng.
- `00-business-journey-map` có ma trận điều hướng `BJ ↔ UC ↔ UIF`.
- Generated `ui-flow-registry.json`, `bj-ui-flow-map.md` và `ui-traceability.json` chỉ dùng UC canonical hiện hành; loại bỏ `UC-03-02/03`, `UC-13-02/03`, `UC-14-02/03` khỏi active UIF trace.
- `SCR-038` được sửa contradiction: active trace chỉ còn `BJ-09 / UIF-09`; `UIF-07` dùng system/source-driven preparation và không đưa user qua screen chuyển trạng thái.

## Actor handoff gate

Các flow có maker/approver độc lập được kiểm riêng: `UIF-02`, `UIF-06`, `UIF-08`, `UIF-09`, `UIF-10`, `UIF-11`, `UIF-12`.

Mỗi flow đều biểu diễn maker submit → `HANDOFF`/task boundary → approver entry riêng; không auto-navigate maker sang approver screen. Approval chỉ ghi quyết định khi contract quy định; system-owned effect không bị biến thành CTA người dùng.

## Valuation parity boundary

`UIF-03`, `UIF-13`, `UIF-14` đã align với semantic BJ/UC v3.12.0, nhưng HTML/Screen copy carry-forward vẫn còn debt. v4.0.0 không tuyên bố full visual/runtime parity và không redesign prototype.
