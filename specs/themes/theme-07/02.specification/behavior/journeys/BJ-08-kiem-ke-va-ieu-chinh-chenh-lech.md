---
id: BJ-08
type: business-journey
theme: theme-07
title: "Kiểm kê và điều chỉnh chênh lệch"
owner: BA
status: IN_REVIEW
aligned_to: BJ.template.md
source_baseline: v3.12.0
---
# BJ-08 — Kiểm kê và điều chỉnh chênh lệch

## 1. Tổng quan nghiệp vụ & Bối cảnh

So sánh hàng thực tế với **book snapshot tại đúng cut-off đã khóa**, dùng đếm mù và các vòng recount bất biến; chỉ tạo điều chỉnh số lượng/giá trị khi final variance còn khác 0 và được người duyệt độc lập phê duyệt trên đúng risk/value basis hiện hành.

**Bắt đầu khi:** Người có quyền yêu cầu kiểm kê một warehouse/phạm vi hợp lệ.

**Kết thúc khi:** Session `COMPLETED` và lock đã release; hoặc `CANCELLED`; hoặc vẫn `BLOCKED` chờ căn cứ mà chưa ghi adjustment. Mutation `UNKNOWN` được bàn giao BJ17.

**Không bao gồm:** Điều tra nguyên nhân nhân sự; sửa Product master; tự nhập giá cho hàng thừa; sửa operation nguồn khi scope đang khóa.

## 2. Tác nhân và trách nhiệm

| Tác nhân | Trách nhiệm | Phạm vi thẩm quyền |
|---|---|---|
| Người có quyền mở kiểm kê | Chọn phạm vi/lý do và khởi tạo phiên | Không được mở nếu scope conflict hoặc còn valuation chưa giải quyết |
| Người đếm được phân công | Ghi FIRST/RECOUNT theo đếm mù và bằng chứng vật lý | Không xem book/variance trước FIRST submit; không nhập giá trị hàng thừa |
| Người duyệt độc lập | Duyệt exact final variance snapshot hoặc yêu cầu recount | Không được là actor đã góp count evidence của snapshot đang xét; không sửa số đếm |
| Hệ thống | Khóa scope/cutoff, tính variance/risk, ghi adjustment và giải phóng lock | Không tự hợp thức hóa surplus thiếu value basis |

## 3. Sơ đồ hành trình nghiệp vụ

```mermaid
flowchart TD
  Begin([Bắt đầu: yêu cầu kiểm kê]) --> U1["UC-08-01 — Mở và khóa phạm vi"]
  U1 --> U2["UC-08-02 — Ghi nhận lần đếm mù"]
  U2 --> V{"Chênh lệch lần đếm đầu?"}
  V -->|Bằng 0| Done0["Hoàn tất, không điều chỉnh"]
  V -->|Khác 0| U3["UC-08-03 — Đếm lại và hoàn thiện căn cứ"]
  U3 --> R{"Chênh lệch cuối?"}
  R -->|Bằng 0| Done0
  R -->|Khác 0, đủ căn cứ| U4["UC-08-04 — Duyệt và điều chỉnh"]
  R -->|Thiếu căn cứ| Block["Giữ phiên bị chặn và giữ lock"]
  Block --> End([Kết thúc: hoàn tất, hủy hoặc còn bị chặn có lý do])
  U4 -->|Yêu cầu đếm lại| U3
  U4 -->|Duyệt| Done1["Ghi điều chỉnh và hoàn tất"]
  U2 -->|Hủy hợp lệ| U5["UC-08-05 — Hủy phiên kiểm kê"]
  U3 -->|Hủy hợp lệ| U5
  U5 --> Cancelled["Hủy phiên, không điều chỉnh"]
  Done0 --> End
  Done1 --> End
  Cancelled --> End
```

## 4. Bản đồ Use Case

| UC | Mục tiêu | Tác nhân | Bắt đầu khi | Kết quả |
|---|---|---|---|---|
| [UC-08-01](../use-cases/UC-08-01-mo-va-khoa-pham-vi.md) | Khóa exact scope + cut-off trước đếm | Người mở kiểm kê | Có yêu cầu kiểm kê hợp lệ | Session OPEN/LOCKED + CountScopeSnapshot + InventoryLock |
| [UC-08-02](../use-cases/UC-08-02-ghi-nhan-lan-dem-mu.md) | Ghi FIRST count không bị book quantity chi phối | Assigned counter | Session OPEN/LOCKED | Immutable FIRST submission; zero variance hoặc RECOUNT_REQUIRED |
| [UC-08-03](../use-cases/UC-08-03-dem-lai-va-hoan-thien-bang-chung.md) | Tạo recount bất biến và final count hiện hành | Assigned counter | Có variance/REQUEST_RECOUNT | Zero variance complete hoặc non-zero basis ready/blocked |
| [UC-08-04](../use-cases/UC-08-04-duyet-va-dieu-chinh.md) | Duyệt exact variance snapshot hoặc yêu cầu recount | Independent approver | Non-zero final variance + current basis/case | Adjustment + complete/unlock hoặc recount requirement |
| [UC-08-05](../use-cases/UC-08-05-huy-phien-kiem-ke.md) | Dừng session an toàn | Người có quyền hủy | Session chưa final và policy cho phép | CANCELLED, no adjustment, lock released |

## 5. Bàn giao và ranh giới liên quan

| Nơi cung cấp/nhận | Dữ kiện | Điều kiện |
|---|---|---|
| BJ01 / ledger | Book snapshot tại cutoff | Scope barrier đã khóa |
| BJ03 | Valuation readiness | Scope có mixed/VALUATION_PENDING thì BJ08 chưa mở session |
| BJ11/BJ16 | Correction/reconciliation nguồn | Chỉ sau khi count session kết thúc; không sửa nguồn trong lock |
| BJ14 | Value facts từ approved adjustment | Sau adjustment commit |
| BJ17 | Same command/session identity khi mutation `UNKNOWN` | Không blind retry |

## 6. Luồng giao diện cấp hành trình

| UC | Screen | Mental task |
|---|---|---|
| UC-08-01 | `SCR-042`, `SCR-043` | Chọn/mở phạm vi kiểm kê và thấy lock/cutoff result |
| UC-08-02 | `SCR-044` | Đếm mù FIRST round |
| UC-08-03 | `SCR-045` | Recount các dòng chênh và theo dõi basis readiness |
| UC-08-04 | `SCR-046`, `SCR-047` | Duyệt độc lập và xem result authoritative |
| UC-08-05 | `SCR-044`, `SCR-045`, `SCR-047` | Hủy trong session context, xem no-adjustment result |

## 7. Nghiệm thu hành trình (Journey Acceptance)

| ID | Điều kiện | Kết quả cần bảo đảm | Trace |
|---|---|---|---|
| JA-01 | Mở phiên thành công | Scope membership, cutoff, book snapshot và lock cùng atomic boundary | UC-08-01 / BC-IC-01 |
| JA-02 | FIRST/recount | Evidence round cũ bất biến; người đếm không thấy book trước FIRST submit | UC-08-02/03 |
| JA-03 | Final variance = 0 | Complete + unlock, không ApprovalCase/adjustment | UC-08-02/03 |
| JA-04 | Final variance ≠ 0 | Chỉ current independent approval + current risk/value basis mới được commit | UC-08-04 |
| JA-05 | Hủy | Giữ evidence, không adjustment, release lock | UC-08-05 |
| JA-06 | UNKNOWN | Không ghi lần hai; handoff BJ17 cùng identity | UC-08-01/02/03/04/05 |

## 8. Truy vết

- **Decision:** `T7-DR-035…039`, `T7-DR-171…177`.
- **Domain:** `DOM-IC`, `DOM-IO`, valuation reference `DOM-IV`.
- **BC:** `BC-IC-01/02/03/08`.
- **UI:** `SCR-042…047`.
