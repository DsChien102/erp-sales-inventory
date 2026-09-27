---
id: EVD-RELEASE-VALIDATION-v3.12.0
type: release-evidence
theme: theme-07
title: "Release validation — semantic/specification candidate v3.12.0"
owner: QA/HARNESS
status: CONDITIONALLY_READY
version: v3.12.0
parent: v3.11.0
---
# EVD — Release validation — v3.12.0

## 1. Verdict

**`CONDITIONALLY_READY` cho semantic/specification review.**

Không gọi bản này là `RELEASE_READY` hoặc full-package `READY_FOR_REVIEW` vì `03.design/` và HTML prototype được carry-forward nguyên vẹn từ v3.11.0, trong khi BJ03/BJ13/BJ14 và một số UC đã đổi semantic/ranh giới. UI parity được chủ động chuyển sang v3.13.0.

- BLOCKER: **0**
- HIGH: **0**
- MEDIUM: **1** — UI/HTML parity debt đã có owner và version xử lý.
- LOW: carry-forward Slice/Design registry còn giữ ID/tên lịch sử ở nơi phục vụ migration; đã có migration note và không phải semantic authority.

## 2. Gate record

| Gate | Phương pháp | Phạm vi | Trạng thái | Bằng chứng / Ghi chú |
|---|---|---|---|---|
| Baseline | So sánh parent/candidate, kiểm parent/version/impact | v3.11.0 → v3.12.0 | PASS | README + manifest + diff; `03.design` và IO được bảo toàn theo scope |
| Know-how | Review Decision/Glossary/Wiki liên quan valuation + supersession | 01.knowledge | PASS | `T7-DR-185…195`; decision cũ bootstrap được đánh `SUPERSEDED` |
| BJ/UC V5 | Validator section/flow/BR/UI/GWT/Begin-End | 17 BJ / 64 UC | PASS | `EVD-BJ-UC-V5-REWRITE-v3.12.0.md` |
| Domain/Entity | Template conformance + storage-leak scan | COM/IC/IV + Entity IC/IV | PASS | `EVD-DOMAIN-ENTITY-ALIGNMENT-v3.12.0.md` |
| Valuation semantic | Cross-layer invariant + desk simulation + red-team | BJ03/BJ13/BJ14 | PASS | `EVD-VALUATION-SEMANTIC-v3.12.0.md` |
| Trace | Decision/BC/Entity/Domain ID resolution + UC ownership | Knowledge + Specification | PASS | 195 Decision, 48 BC, 33 Entity, 4 Domain; 0 missing ref |
| Relative links | Static relative-link validation | README/01/02/04/05/09 | PASS | 1.972 links checked; 0 broken |
| UI contracts parity | Không chạy vì Design chủ động carry-forward | 03.design | NOT_RUN / DEFERRED | v3.13.0 |
| Mobile prototype parity/runtime | Không chạy như evidence của semantic mới | HTML | NOT_RUN / DEFERRED | Prototype cũ không được dùng làm semantic authority cho valuation v3.12.0 |
| Archive CRC/post-extract | Thực hiện sau khi freeze/checksum cuối | Final ZIP | PENDING_AT_RECORD_TIME | Kết quả cuối được kiểm ngoài record này trước bàn giao |

## 3. Ba review độc lập

### 3.1 Senior BA / Domain review — PASS

Có thể tái dựng một cách nhất quán:

- BJ02 sở hữu sự thật nhận hàng vật lý.
- BJ03 sở hữu initial inventory value, không sở hữu Official Cost.
- BJ13 sở hữu signed value adjustment sau initial valuation.
- BJ14 sở hữu calculation + publication của Official Cost.
- Theme 10 sở hữu commercial source khi có; Quick receipt không phụ thuộc Theme 10.
- Tax recoverability là policy input, không phải lựa chọn của user trong BJ03.
- Lỗi nhập liệu và business fact đến sau có route khác nhau: BJ11 vs BJ13.

Không phát hiện duplicate authority trong semantic canonical.

### 3.2 Delivery simulation — PASS cho specification

Đã walk-through ở mức BA/BE/FE/QA cho ba sample:

1. **Document receipt → BJ03 → BJ14:** source hợp lệ từ Theme 10, initial value commit, dirty scope, cost run, publish.
2. **Quick receipt → BJ03 → hóa đơn đến sau → BJ13 → BJ14:** không tạo PO/hóa đơn giả; fact đến sau tạo adjustment, không overwrite history.
3. **BJ08 stock count sample:** actor, blind count/recount, evidence, approval, adjustment và `UNKNOWN` có BF/AF/EF + acceptance theo V5.

Điểm phải hỏi lại Design ở sample valuation là presentation/screen parity, đã được chủ động defer; không phải gap semantic của v3.12.0.

### 3.3 Red-team review — PASS cho specification

Đã kiểm các tình huống:

- commercial conflict giữa PO/invoice;
- source revision stale ngay trước commit;
- tax-inclusive price và nguy cơ cộng thuế hai lần;
- projected discount bị ghi nhầm vào real ledger;
- duplicate value adjustment;
- user error bị route nhầm vào BJ13;
- user cố chọn costing method theo run;
- run/valuation mutation trả `UNKNOWN`;
- partial commit giữa value movement, state và dirty marking.

Các trường hợp đều có owner, reject/recovery hoặc atomicity rule rõ trong UC/BC/Decision hiện hành.

## 4. Finding còn mở

### MEDIUM — UI-PARITY-001

- **Location:** `03.design/`, design registries, HTML prototype.
- **Expected:** Screen/UI/HTML diễn đạt đúng semantic v3.12.0, đặc biệt BJ03/BJ13/BJ14 và UC consolidation.
- **Actual:** toàn bộ `03.design/` được giữ byte-identical với v3.11.0 theo scope phiên bản; vì vậy vẫn có copy/tên cũ.
- **Owner:** Design/BA/FE.
- **Fix version:** v3.13.0.
- **Release impact:** không chặn semantic/specification review; chặn full-package parity/release verdict.

## 5. Giới hạn bằng chứng

Version này chứng minh tính nhất quán của **Knowledge + Specification + canonical trace**. Nó không chứng minh production implementation, integration E2E hoặc visual parity của prototype mới. Các gate đó phải chạy lại sau v3.13.0.
