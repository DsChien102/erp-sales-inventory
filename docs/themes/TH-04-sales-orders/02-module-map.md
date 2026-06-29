# TH-09 — Module map

| Module | Vai trò | Owner / Supporting | Trạng thái |
| ------ | ------- | ------------------ | ---------- |
| Reporting* | Read models, queries | **Owner** | planned |
| Mọi module nghiệp vụ | Publish events / views | Supporting | — |

```mermaid
flowchart LR
  Sales --> R[reporting_read_models]
  Catalog --> R
  TH05 --> R
  TH06 --> R
  R --> UI[Dashboard_UI]
```

Permission: `report.view` (đã seed IAM catalogue).
