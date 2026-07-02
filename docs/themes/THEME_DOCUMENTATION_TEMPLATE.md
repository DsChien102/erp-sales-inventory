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
│   ├── 04-slice-roadmap.md           # Slice order, lane status (Contract/BE/FE/E2E)
│   ├── 05-traceability.md            # FR → Role → layer → test id
│   ├── 06-harness-notes.md           # Guards, flywheel
│   └── 07-api-contracts.md           # Commands/Queries/DTOs + fake scenarios (FE↔BE)
├── Epic-{nn}-{slug}/
│   ├── README.md
│   └── US-{nn}/
│       ├── README.md
│       └── FR-{nn}.md
└── references.md                     # optional
```

---

## README.md

```markdown
# {{TH-xx}}: {{Tên theme}}

**Trạng thái deliver:** planned | in_progress | mvp | done

## Module tham gia
## Epic index

| Epic | Folder | US | FR | Status |
| ---- | ------ | -- | -- | ------ |

## Tài liệu
## Harness: [harness/](harness/) (khi in_progress)
## Platform: [docs/architecture/](../../architecture/README.md)
```

Epic `README.md` — thêm **User stories** catalog (US → folder → FR count).

US `README.md` — thêm **Functional requirements** catalog (FR → tên → link `FR-{nn}.md`).

---

## harness/00-agent-ritual.md

Thứ tự: AGENTS.md → README → slice-roadmap → US/FR → domain-model → skills → verify.

Link [docs/architecture/README.md](../../architecture/README.md) — không duplicate CQRS.

---

## harness/04-slice-roadmap.md — lane columns

Mỗi slice track 4 lane + parallel group. **Prerequisite chỉ bind lane E2E**, không block FE fake / BE handler test.

```markdown
| # | Slice | Type | Contract | BE | FE | E2E | Parallel group | E2E blocked by |
```

Status mỗi lane: `todo` | `in_progress` | `done` | `blocked` | `n/a`

**Slice done** = Contract + BE + FE + E2E đều `done` (hoặc `n/a`).

---

## harness/05-traceability.md

```markdown
<!-- exemplar-complete: deferred | e01/u02 -->
| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
```

Role: `CONTRACT` | `BE` | `FE` | `E2E`

Test id: `scn_e01_u02_fr06_01` (handler/BE), `wgt_e02_u01_fr03_01` (widget/FE), `e2e_e01_u02_fr06_01` (integration)

---

## harness/07-api-contracts.md

Source of truth giữa BE và FE. Mỗi US một section:

```markdown
## Epic-{nn} / US-{nn} — {title}

### Commands / Queries
| Symbol | Input | Success | Errors |
| RegisterPartnerCommand | ... | RegisterPartnerResult | Validation, PermissionDenied |

### RPC mapping (BE)
Link [03-architecture-and-flows.md](03-architecture-and-flows.md) — không duplicate RPC chi tiết.

### Fake scenarios (FE)
| scenario_id | trigger | fake response |
| save_ok | valid form submit | RegisterPartnerResult with partnerId |

### Parallel notes
- FE có thể fake: yes/no
- E2E prerequisite: US-xx (data only)
```

Contract types live in `modules/<owner>/application/` — doc links symbols, không copy field list dài nếu đã có trong code.

---

## FR-{nn}.md / Epic·US README — UI artifacts (khi FR có UI)

```markdown
## UI artifacts

| Widget | Package path |
| ------ | ------------ |
| PartnerDetailPage | apps/erp/lib/features/partner/presentation/pages/partner_detail_page.dart |
| DeactivatePartnerDialog | modules/partner/presentation/lib/src/widgets/deactivate_partner_dialog.dart |
```

Agent tạo widget manifest từ bảng này **trước** khi implement.

---

## Trạng thái deliver

| Status | Yêu cầu |
| ------ | ------- |
| `planned` | README optional; Epic tree khi có SRS |
| `in_progress` | README + harness/00..07 + Epic/US/FR |
| `mvp` / `done` | Giống `in_progress` + traceability exemplar |

---

## Verify

```bash
./scripts/ci/guard_theme_structure.sh
./scripts/ci/verify_harness.sh
```
