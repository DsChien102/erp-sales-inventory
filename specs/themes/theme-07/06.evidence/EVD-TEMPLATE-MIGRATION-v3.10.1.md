---
id: EVD-TEMPLATE-MIGRATION-v3.10.1
type: evidence
theme: theme-07
title: "Template migration evidence — v3.10.1"
owner: HARNESS
status: FROZEN
---
# EVD-TEMPLATE-MIGRATION-v3.10.1 — Template migration evidence

## 1. Mục tiêu

Chuyển nội dung baseline `VET45-Theme7-Harness-v3.10.1-new-structure` sang hình dạng của `theme-template.zip` mà không chủ đích thay đổi business decision/semantic.

## 2. Prototype runtime

- Không còn folder legacy `theme-07/prototype/` ngoài cấu trúc mới.
- Manifest prototype canonical: `03.design/prototype/README.md`.
- Frozen runtime HTML v3.10.1: `03.design/prototype/html/`.
- Runtime được carry byte-preserved từ baseline v3.10.1 để package chạy prototype độc lập.
- QA nằm bên trong frozen runtime bundle được giữ nguyên vì các manifest runtime tham chiếu trực tiếp; evidence canonical của package vẫn nằm ở `07.evidence/`.
- Runtime không phải nguồn business semantics.

## 3. Source accounting

| Hạng mục | Kết quả |
|---|---:|
| Source files | 3913 |
| Mapped hoặc preserved | 3912 |
| Explicitly excluded | 1 |
| Unmapped | 0 |
| Runtime files preserved | 2928 |

Artifact bị loại duy nhất: `01.knowledge/know-how/quizz.html` — derived quiz HTML, không phải Theme 7 prototype runtime và template hiện không có canonical quiz artifact.

## 4. Kết luận

Migration giữ cấu trúc template mới và vẫn bảo toàn prototype chạy được tại `03.design/prototype/html/`.
