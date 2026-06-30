# Template tài liệu theme (harness)

> Copy cấu trúc này khi tạo theme mới (`TH-12-...`). Reference: [TH-03-partner/](TH-03-partner/)

## Bốn tầng tài liệu

```text
T1 Product Foundation     docs/product/ (optional, toàn sản phẩm)
T2 Platform Architecture  docs/architecture/ (CQRS, module layout — một lần)
T3 Theme package          docs/themes/TH-xx/ (product + harness per theme)
T4 Slice / code           modules/, FR harness khi implement
```

Theme `in_progress` cần **README + harness/** + cây Epic/US/FR.

## Cấu trúc folder

```text
docs/themes/TH-xx-{{slug}}/
├── README.md                         # Index, status, epic rollup
├── 01-business-scope.md              # Purpose, scope, epic map
├── harness/
│   ├── 00-agent-ritual.md            # Thứ tự đọc khi implement FR
│   ├── 01-domain-model.md            # Aggregate, commands, events
│   ├── 02-module-map.md              # Owner/supporting, contracts
│   ├── 03-architecture-and-flows.md  # Flows, RPC (link T2)
│   ├── 04-slice-roadmap.md           # Slice order, deps, status
│   ├── 05-traceability.md            # FR → layer → test id
│   └── 06-harness-notes.md           # Guards, flywheel
├── Epic-{nn}-{slug}/
│   ├── 01-overview.md
│   └── US-{nn}/
│       ├── 01-overview.md
│       └── FR-{nn}.md
└── references.md                     # optional
```

---

## README.md

```markdown
# {{TH-xx}}: {{Tên theme}}

**Trạng thái deliver:** planned | in_progress | mvp | done

## Module tham gia
## Epic index (link)
## Harness: [harness/](harness/)
## Platform: [docs/architecture/](../../architecture/README.md)
```

---

## harness/00-agent-ritual.md

Thứ tự: AGENTS.md → README → slice-roadmap → US/FR → domain-model → skills → verify.

Link [docs/architecture/README.md](../../architecture/README.md) — không duplicate CQRS.

---

## harness/05-traceability.md

```markdown
<!-- exemplar-complete: deferred | e01/u02 -->
| Req ID | Enforce layer | Artifact | Test id | Status |
```

Test id: `scn_e01_u02_fr06_01`

---

## Trạng thái deliver

| Status | Yêu cầu |
| ------ | ------- |
| `planned` | README optional; Epic tree khi có SRS |
| `in_progress` | README + harness/00..06 + Epic/US/FR |
| `mvp` / `done` | Giống `in_progress` + traceability exemplar |

---

## Verify

```bash
./scripts/ci/guard_theme_structure.sh
./scripts/ci/verify_harness.sh
```
