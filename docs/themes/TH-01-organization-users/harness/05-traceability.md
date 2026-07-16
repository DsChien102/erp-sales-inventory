# TH-01 — Traceability

Ma trận truy vết FR → Role → contract → artifact → test.

```text
e{epic}/u{us}/fr{fr}/{TYPE}-{id}   ví dụ: e03/u02/fr01/SCN-01
Test id: scn_e03_u02_fr01_01 (BE), wgt_e03_u02_fr01_01 (FE), e2e_e03_u02_fr01_01 (E2E)
```

**Scaffold 2026-07-16:** Skeleton `todo`. Cập nhật row khi slice `in_progress`.

Contracts: [07-api-contracts.md](07-api-contracts.md)

Tổng product: **6 epic, 32 US** (2 Post-MVP) — [README.md](../README.md).

---

## Platform — IAM codegen

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-01-PLATFORM | BE | S0 | infrastructure | `registerGeneratedIamHandlers`, `IamCommandPipeline` | iam_startup_test | done |
| TH-01-PLATFORM | BE | S0 | infrastructure | `iam_access_metadata.g.dart` | iam_startup_test | done |

---

## S-NOTIFY — Resend delivery port

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| S-NOTIFY | CONTRACT | §S-NOTIFY | application | delivery request port / DTO | fake_notification_gateway_test | todo |
| S-NOTIFY | BE | §S-NOTIFY | infrastructure | Resend adapter + outbox consumer | scn_notify_01 | todo |

---

## S1 — EP-05 / US-01 — List accessible tenants

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §S1 | application | `ListAccessibleTenantsQuery` | fake_iam_module_test | todo |
| FR-01.. | BE | §S1 | application | handler | scn_e05_u01_fr01_01 | todo |
| FR-01.. | FE | §S1 | presentation | organization selector list | wgt_e05_u01_fr01_01 | todo |
| FR-01 | E2E | §S1 | integration | ERP via IIamModule | e2e_e05_u01_fr01_01 | todo |

---

## S2 — EP-05 / US-02 — Switch tenant

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §S2 | application | `SwitchTenantContextCommand` | fake_iam_module_test | todo |
| FR-01.. | BE | §S2 | application | handler (extend SwitchActiveTenant) | scn_e05_u02_fr01_01 | todo |
| FR-01.. | FE | §S2 | presentation | confirmation + loading | wgt_e05_u02_fr01_01 | todo |
| FR-01 | E2E | §S2 | integration | switch + reload | e2e_e05_u02_fr01_01 | todo |

---

## S7 — EP-03 / US-02 — Invite member

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §S7 | application | `CreateInvitationCommand` | fake_iam_module_test | todo |
| FR-01.. | BE | §S7 | application | handler + outbox delivery | scn_e03_u02_fr01_01 | todo |
| FR-01.. | FE | §S7 | presentation | invite form | wgt_e03_u02_fr01_01 | todo |
| FR-01 | E2E | §S7 | integration | invite + delivery outcome | e2e_e03_u02_fr01_01 | todo |

---

## S8 — EP-03 / US-03 — Accept / decline (App Link)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §S8 | application | `AcceptInvitationCommand` / `DeclineInvitationCommand` | fake_iam_module_test | todo |
| FR-01.. | BE | §S8 | application | accept atomic + membership | scn_e03_u03_fr01_01 | todo |
| FR-01.. | FE | §S8 | presentation | deep-link surface → POST body | wgt_e03_u03_fr01_01 | todo |
| FR-01 | E2E | §S8 | integration | App Link handoff | e2e_e03_u03_fr01_01 | todo |

---

## Các slice còn lại

Khi bắt đầu slice: copy bảng mẫu trên vào section `S{n} — EP-xx / US-yy`, điền FR rows, cập nhật Status. Post-MVP EP-02/US-04–05: **không** thêm row phase 1.
