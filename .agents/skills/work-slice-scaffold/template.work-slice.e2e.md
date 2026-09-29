# Work Slice: SL-NNN — tiêu đề ngắn (e2e)

```yaml
id: SL-NNN
role: e2e
family: <family-slug>
sources: []
theme: # theme-xx
```

**design_status** trên [`CATALOG.md`](CATALOG.md). Design/Contracts: **link** các file cùng family — không nhân bản.

---

## 1. Objective

Một câu: kịch bản xuyên tầng chứng minh family đạt AC nghiệp vụ end-to-end.

---

## 2. Blocked by

- Link `.be-impl` và `.fe` cùng family (và phụ thuộc ngoài nếu có)

---

## 3. Scenarios & evidence

### Design / Contracts

- Design: link `.be-impl` (+ Screen từ `.fe` nếu cần)
- Contracts: link `.be-contract`

### Scenarios

| Scenario | Actor | Across | Expect |
| --- | --- | --- | --- |
| … | … | UI → mediator → RPC → DB | … |

### Evidence

- Path dưới `06.evidence/` (hoặc link MR/CI) — điền khi chạy

### Out of Scope

- Thiết kế contract/UI mới — thuộc role trước

---

## 4. Verification

- [ ] **AC-01** Happy path E2E
- [ ] **AC-02** Failure / idempotency có ý nghĩa nghiệp vụ (nếu mutation)

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_…_e2e` | … | e2e / integration |

---

## 5. Delivery

### Definition of Done

- [ ] Scenarios xanh + evidence link
- [ ] Catalog row family `e2e` → `VERIFIED`

### Next Action

- [ ] …
