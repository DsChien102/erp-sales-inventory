# Work Slice: SL-NNN — tiêu đề ngắn (fe)

```yaml
id: SL-NNN
role: fe
family: <family-slug>
sources: []
theme: # theme-xx
```

**design_status** trên [`CATALOG.md`](CATALOG.md). Contracts: link `.be-contract` — UI gọi qua mediator + fake, không invent DTO.

---

## 1. Objective

Một câu: màn hình / interaction thỏa Screen + UC trong phạm vi family.

---

## 2. Blocked by

- Link tới `SL-….be-contract.md` (và Screen/UC phụ thuộc nếu có)

---

## 3. UI & presentation

### Screens / states / actions

| Screen | State / action | Nguồn |
| --- | --- | --- |
| … | … | SCR-… / UC-… |

### Design system

- Widget / pattern DS dùng lại — không invent token ngoài DS

### Mediator & fakes

- Gọi Command/Query qua `IModuleMediator`
- Dev/test: fake khớp `.be-contract`
- Presentation thuộc `apps/erp|admin` — không `modules/*/presentation`

### Navigation / feedback / a11y

- …

### Out of Scope

- RPC / persistence — `.be-impl`
- E2E xuyên tầng — `.e2e`

---

## 4. Contracts

Link: [`SL-….be-contract.md`](SL-….be-contract.md)

---

## 5. Verification

- [ ] **AC-01** Happy path UI theo Screen/UC
- [ ] **AC-02** Feedback lỗi / empty / loading theo contract

| Test id | Given / When / Then | Layer |
| --- | --- | --- |
| `scn_…_fe` | … | widget / golden |

---

## 6. Delivery

### Definition of Done

- [ ] UI AC xanh; changelog ship unit nếu ảnh hưởng user-facing
- [ ] Catalog → `VERIFIED` sau code-review

### Next Action

- [ ] Unblock `.e2e` khi `.be-impl` cũng xong
