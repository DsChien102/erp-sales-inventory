# Template tài liệu theme

> Copy cấu trúc này khi tạo theme mới (`TH-12-...`). Thay `{{TH-xx}}`, `{{Tên theme}}`, nội dung placeholder.

## Cấu trúc folder

```text
docs/themes/TH-xx-{{slug}}/
├── README.md
├── 01-business-scope.md
├── 02-module-map.md          # File quan trọng nhất
├── 03-architecture-and-flows.md
├── 04-implementation-roadmap.md
└── 05-references.md
```

---

## README.md

```markdown
# {{TH-xx}}: {{Tên theme}}

**Trạng thái deliver:** planned | in_progress | mvp | done

## Mục tiêu

(Một đoạn mô tả giá trị sản phẩm.)

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| ... | owner / supporting | modules/... |

## Tài liệu trong theme

- [01-business-scope.md](01-business-scope.md)
- [02-module-map.md](02-module-map.md)
- ...
```

---

## 01-business-scope.md

```markdown
# {{TH-xx}} — Business scope

## Purpose

(Tóm tắt từ SRS — không copy business rules.)

## Epic map

| Epic | Mô tả |
| ---- | ----- |
| ... | ... |

## In scope

- ...

## Out of scope

- ...

## Actors

- Chủ cửa hàng, nhân viên bán hàng, ...
```

---

## 02-module-map.md

```markdown
# {{TH-xx}} — Module map

## Bảng module

| Module | Vai trò trong theme | Owner / Supporting | Package | Module doc | Trạng thái |
| ------ | ------------------- | ------------------ | ------- | ---------- | ---------- |

## Sơ đồ phụ thuộc

(mermaid flowchart)

## Public contracts

- Integration events: ...
- Snapshot DTOs: ...
- Permissions: link IAM_PERMISSION_MATRIX

## Ghi chú ranh giới

(Điều gì theme không làm trực tiếp — delegate sang module khác.)
```

---

## 03-architecture-and-flows.md

```markdown
# {{TH-xx}} — Architecture & flows

## Luồng chính

(sequence hoặc flowchart mermaid)

## Điểm commit

| Bước | Aggregate / RPC |
| ---- | ----------------- |

## Read vs write

- Writes: Command → Gateway → RPC
- Reads: Query → Read gateway / view

## ADR liên quan

- ...
```

---

## 04-implementation-roadmap.md

```markdown
# {{TH-xx}} — Implementation roadmap

## Phase deliver

| Phase | Phạm vi | Module |
| ----- | ------- | ------ |

## Epic → checklist

| Epic/US | Module | Command/Query | Trạng thái |
| ------- | ------ | ------------- | ---------- |

## SQL / RPC

- supabase/migrations/...

## ERP presentation

- apps/erp/lib/features/...

## Definition of Done (theme slice)

- [ ] ...
```

---

## 05-references.md

```markdown
# {{TH-xx}} — References

## SRS

- ...

## Module blueprints

- docs/Modules/...

## ADR & playbooks

- ...

## Diagrams

- docs/C4/...

## Alias cũ (nếu có)

| Alias | Mã TH-xx |
```
