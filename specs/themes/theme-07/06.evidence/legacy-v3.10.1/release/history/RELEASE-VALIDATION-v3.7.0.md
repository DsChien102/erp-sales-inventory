# Release validation — Theme 7 Prototype Harness v3.7.0

**Verdict: PASS — FULL THEME 7 INTEGRATED NAVIGATION**

Parent: **v3.6.4**  
Date: **2026-09-15**

## Release objective

Provide two complementary ways to review the same Theme 7 implementation:

1. **Theo BJ / UIF** — preserve the existing technical/business-journey review organization.
2. **Toàn Theme 7** — allow a reviewer to use the prototype as an integrated VET45 module, starting at **Thêm → Kho**, then navigating across the complete Theme 7 scope.

The integrated mode must not fork or duplicate business screens. Both modes use the same renderer/state source so later component, UI and business-flow corrections remain synchronized.

## Product navigation added

### Thêm

- New VET45-style `Thêm` surface.
- `Kho` is the enabled Theme 7 entry.
- Seven surrounding out-of-scope module rows are true disabled Navigation rows: same List Row anatomy, chevron retained, non-interactive, disabled parent opacity.
- Bottom navigation is represented for app context; only `Thêm` is active in this Theme 7 harness.

### Kho

The new module root exposes the full Theme 7 system using canonical Navigation List Rows:

| Group | Entries |
|---|---|
| Tổng quan | Tồn kho — UIF-01 |
| Vận hành kho | Nhận hàng mua — UIF-02; Lấy hàng & bàn giao — UIF-05; Hàng khách trả — UIF-06; Trả nhà cung cấp — UIF-07 |
| Giá trị & giá vốn | Xác nhận giá nhập — UIF-03; Chi phí mua bổ sung — UIF-13; Giá vốn — UIF-14 |
| Kiểm kê & kiểm soát | Kiểm kê kho — UIF-08; Tình trạng hàng — UIF-09; Tiêu hủy hàng — UIF-10; Hủy & sửa sai nghiệp vụ — UIF-11; Khởi tạo tồn đầu kỳ — UIF-12; Đối soát sai lệch — UIF-16; Xác minh kết quả — UIF-17 |
| Báo cáo | Báo cáo tồn & thẻ kho — UIF-15 |
| Liên quan & thiết lập | Giữ hàng theo đơn bán — UIF-04; Chính sách tồn & cận hạn — CAP-01 |

Total: **17 Business Journeys + CAP-01 = 18 integrated entries**.

## Runtime architecture

- Existing active unique business screens: **77**.
- Existing canonical route occurrences: **89**.
- Existing declared route-state renders: **518**.
- Added business-screen clones: **0**.
- Added business-state-machine copies: **0**.
- Integrated root navigation calls the same `renderers`, `activeFlowId`, screen state and interaction handlers used by BJ/UIF mode.
- First-screen Back from an integrated root entry is normalized to **Kho**; internal flow navigation remains authoritative to the existing screen/flow implementation.

## Source/authority boundary

- Product documents / BJ / flow / decision / contract remain authority for business requirements, UX behavior and business semantics.
- Figma Design System remains UI authority for components, patterns, tokens, typography, spacing, states and interaction convention.
- HTML remains a design/verification medium, not a new source of business truth.
- `UIF-04` and `CAP-01` are surfaced in the full-theme review root so the whole package is operable. This does not silently replace their source-defined contextual/production entry decisions. In particular, the CAP-01 production IA issue tracked as `BG-006` remains a source-level decision outside this browser harness release.

## QA gates

| Gate | Result |
|---|---:|
| Integrated Theme 7 navigation | **16/16 PASS** |
| Integrated entries | **18/18 reachable** |
| Static consistency | **41/41 PASS** |
| Radio / Helper DS | **9/9 PASS** |
| List Navigation State | **15/15 PASS** |
| Mixed Navigation/Status peer defects | **0** |
| List/Card Rhythm | **9/9 PASS** |
| Independent-card collision pairs | **0** |
| Footer Action | **11/11 PASS** |
| Semantic flow/logic E2E | **21/21 PASS** |
| Full Theme completion | **14/14 PASS** |
| Representative coherence | **8/8 PASS** |
| Runtime UI | **14/14 PASS** |
| Declared route-state renders | **518** |
| All-flow runtime smoke | **89/89 PASS** |
| Device frame | **7/7 PASS** |
| Current package validation | **17/17 PASS** |
| Browser page errors | **0** |

## Key evidence

- `specs/themes/theme-07/prototype/html/qa/INTEGRATED-THEME-NAVIGATION-QA-v3.7.0.md`
- `specs/themes/theme-07/prototype/html/qa/STATIC-CONSISTENCY-QA-v3.7.0.md`
- `specs/themes/theme-07/prototype/html/qa/RUNTIME-UI-QA-v3.7.0.md`
- `specs/themes/theme-07/prototype/html/qa/FLOW-LOGIC-E2E-QA-v3.7.0.md`
- `specs/themes/theme-07/prototype/html/qa/FULL-THEME-COMPLETION-QA-v3.7.0.md`
- `specs/themes/theme-07/prototype/html/qa/LIST-NAVIGATION-STATE-QA-v3.7.0.md`
- `specs/themes/theme-07/prototype/html/qa/LIST-SURFACE-RHYTHM-QA-v3.7.0.md`
- `specs/themes/theme-07/prototype/html/qa/RADIO-HELPER-DS-QA-v3.7.0.md`
- `specs/themes/theme-07/prototype/html/qa/FOOTER-ACTION-QA-v3.7.0.md`
- visual captures: `specs/themes/theme-07/prototype/html/qa/v370-integrated-navigation-captures/`

## Evidence boundary

These checks validate the browser prototype, interaction topology, visual/runtime conformance and integrated navigation. They do **not** prove production backend transaction/database/outbox/network/concurrency/crash-restart atomicity; those require backend and integration QA.
