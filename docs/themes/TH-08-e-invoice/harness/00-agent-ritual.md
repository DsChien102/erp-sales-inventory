# TH-08 — Agent ritual

Thứ tự đọc khi implement một slice. Platform CQRS/module layout: [docs/architecture/README.md](../../../architecture/README.md).

Canonical đã ingest; US flat như TH-03 (`Epic-*/US-*.md`). Status deliver: `in_progress` — Contract toàn theme + BE S1 done; FE/E2E S1 vẫn todo.

## Trước khi code

```text
1. AGENTS.md + .cursor/rules/c45-architecture.mdc
2. docs/harness/PROGRESS.md
3. TH-08/README.md + OVERVIEWS.md
4. Theme-8-e-invoice.md — khi cần chi tiết domain/UI §3–6
5. harness/04-slice-roadmap.md — lane status + parallel group
6. harness/07-api-contracts.md — contract + fake scenarios
7. Epic-{nn}-*/US-{nn}.md — FR / BR / EC / SC
8. harness/01-domain-model.md + harness/02-module-map.md
9. harness/03-architecture-and-flows.md — MISA worker + job catalog §8 + UF flows §9
   - Lane BE/worker: đọc §8 Job catalog (idempotency, commit points) trước implement job
   - SQL: draft vào supabase/migrations/_drafts/
10. harness/05-traceability.md
11. Skill theo lane (domain / application / infrastructure / presentation)
12. harness/06-harness-notes.md
```

UI: Design Reference trong US → [APPENDICES.md](../APPENDICES.md) SG map → canonical §6.5 trước khi code widget.

## Sau khi code

```bash
melos bootstrap
melos run analyze
melos run test
melos run codegen
./scripts/ci/verify_harness.sh
```

## Reference code

| Mục đích | Path |
| -------- | ---- |
| Golden CQRS | `modules/iam/` |
| Module layout | `docs/MODULES_IMPLEMENTATION_TEMPLATE.md` |
| MISA blackbox | `packages/c45_misa/` |
| Worker jobs | `apps/messaging_worker/` + [03-architecture-and-flows.md §8](03-architecture-and-flows.md) |
| Presentation | `.cursor/skills/presentation-layer/SKILL.md` |

**Copy CQRS từ `modules/iam/`** — không copy scaffold module khác.
