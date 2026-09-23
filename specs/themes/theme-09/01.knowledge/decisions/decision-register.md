# Theme 09 — Decision Register

## 1. Control

| Thuộc tính | Giá trị |
|---|---|
| Theme | Theme 09 — Kế toán |
| Version | `v0.1.0` |
| Baseline | `T09-BASELINE-v0.1.0` |
| Freeze | `NOT_FROZEN` |
| Quy tắc | Mỗi câu hỏi nghiệp vụ có một decision ID ổn định; quyết định tự đề xuất không được nâng thành `CONFIRMED` nếu chưa có authority |

## 2. Status

- `CONFIRMED`: có căn cứ hiện hành đủ mạnh từ người dùng hoặc boundary upstream.
- `PROPOSED`: tự đề xuất trong baseline để review.
- `DEFERRED`: định hướng tương lai, không thuộc Phase 1.
- `OUT_OF_SCOPE`: loại khỏi phạm vi hiện tại.
- `SUPERSEDED`: đã bị thay thế, chỉ giữ lineage.

## 3. Nhóm A — Phạm vi & ownership

### DEC-T09-001 — Tên canonical của Theme
**Status:** `CONFIRMED`  
Tên hiện hành: **Theme 09 — Kế toán**. “Kế toán thuế” là cách gọi lịch sử/phạm vi capability, không dùng làm tên canonical mới.

### DEC-T09-002 — Theme 09 sở hữu sổ kế toán và kỳ kế toán
**Status:** `CONFIRMED`  
Theme 09 là owner của accounting posting/entry, accounting period và accounting books. Upstream Theme không tự sửa ledger của Theme 09.

### DEC-T09-003 — Công nợ không thuộc Theme 09
**Status:** `CONFIRMED`  
Phải thu, phải trả, thu/chi và phân bổ thanh toán thuộc Theme 6. Theme 09 chỉ ghi accounting effect; không giảm/tăng receivable/payable balance trực tiếp.

### DEC-T09-004 — Tồn kho và giá vốn không thuộc Theme 09
**Status:** `CONFIRMED`  
Theme 7 sở hữu stock movement, valuation và official cost/COGS. Theme 09 tiêu thụ output authoritative để ghi sổ.

### DEC-T09-005 — Hóa đơn điện tử không thuộc Theme 09
**Status:** `CONFIRMED`  
Theme 8 sở hữu issuance, electronic invoice record và tài liệu. Theme 09 sử dụng hóa đơn đã phát hành/dữ liệu truy vết cho kế toán/thuế.

### DEC-T09-006 — Mua hàng/chiết khấu mua không thuộc Theme 09
**Status:** `CONFIRMED`  
Theme 10 xác lập giao dịch mua và quyền lợi thương mại; Theme 09 chỉ ghi nhận kế toán khi owner phát ra sự thật đủ điều kiện. Forecast discount không vào official ledger.

## 4. Nhóm B — Mô hình kế toán canonical

### DEC-T09-007 — Tách Accounting Fact khỏi Accounting Entry
**Status:** `PROPOSED`  
Một **Sự thật kế toán** mô tả điều đã xảy ra ở source domain; một **Bút toán/Bản ghi kế toán** là cách biểu diễn sự thật đó theo scheme/policy version. Hai lớp có identity và lifecycle riêng.

### DEC-T09-008 — Source fact phải bất biến theo version
**Status:** `PROPOSED`  
Sau khi một source version đã được dùng để post, snapshot canonical không bị overwrite. Source correction tạo version/fact mới và dẫn đến adjustment.

### DEC-T09-009 — Policy ghi sổ phải version hóa theo hiệu lực
**Status:** `PROPOSED`  
Mỗi entry lưu scheme/policy version đã áp dụng; policy mới không rewrite lịch sử.

### DEC-T09-010 — Không ép mọi chế độ dùng hệ thống tài khoản
**Status:** `PROPOSED`  
Data model hỗ trợ scheme không yêu cầu account code/debit-credit, phù hợp các chế độ kế toán đơn giản. Account/side chỉ bắt buộc khi scheme quy định.

### DEC-T09-011 — Một source version/purpose chỉ post official một lần
**Status:** `PROPOSED`  
Idempotency business key dựa trên tenant + source identity/version + posting purpose; technical retry không tạo double posting.

### DEC-T09-012 — Một source fact có thể sinh 0..N entry theo purpose
**Status:** `PROPOSED`  
Ví dụ một giao dịch có thể có revenue/tax/cost effects khác nhau; decomposition do policy định nghĩa nhưng mỗi purpose phải truy nguyên source.

### DEC-T09-013 — Official ledger không nhận forecast chưa realized
**Status:** `PROPOSED`  
Estimate, dự báo đạt chiết khấu, giá vốn dự kiến hoặc management simulation không được post official ledger. Nếu cần, tạo management projection riêng ở tương lai.

### DEC-T09-014 — Bút toán đã post là immutable
**Status:** `PROPOSED`  
Không edit amount/date/source của entry đã post. Sửa bằng reversal/adjustment/replacement entry.

### DEC-T09-015 — Description và terminology ưu tiên tiếng Việt
**Status:** `PROPOSED`  
UI/business documentation dùng thuật Việt dễ hiểu; mã kỹ thuật có thể giữ tiếng Anh trong backtick. Nợ/Có chỉ expose khi user/regime cần.

## 5. Nhóm C — Thời gian & kỳ kế toán

### DEC-T09-016 — Phân biệt source time, accounting date và recorded time
**Status:** `PROPOSED`  
Không dùng một timestamp cho ba ý nghĩa. Entry phải truy được thời điểm nghiệp vụ gốc, ngày kế toán và thời điểm hệ thống ghi nhận.

### DEC-T09-017 — Period Phase 1 dùng hai trạng thái Mở/Đã khóa
**Status:** `PROPOSED`  
Không thêm soft-close trong MVP nếu chưa có yêu cầu rõ.

### DEC-T09-018 — Kỳ khóa chặn posting tại commit
**Status:** `PROPOSED`  
Pre-check chỉ hỗ trợ UX; authoritative check thực hiện khi commit accounting entry.

### DEC-T09-019 — Mở lại kỳ là privileged action có reason/audit
**Status:** `PROPOSED`  
Reopen không xóa lịch sử lần khóa trước; lưu actor, time, reason, reopen count.

### DEC-T09-020 — Late event không back-post im lặng
**Status:** `PROPOSED`  
Nếu ngày kế toán mục tiêu thuộc kỳ khóa, case chuyển `PERIOD_LOCKED` hoặc theo policy post kỳ mở gần nhất kèm original effective date. Mặc định cuối cùng cần OQ-06 chốt.

### DEC-T09-021 — Chế độ kế toán thay đổi có effective date
**Status:** `PROPOSED`  
Không đổi scheme hồi tố lên locked period; migration phải là decision riêng.

## 6. Nhóm D — Sổ kế toán & chế độ áp dụng

### DEC-T09-022 — Phase 1 ưu tiên TT152/2025 cho HKD/CKD
**Status:** `PROPOSED`  
Đây là baseline product proposal dựa trên Product Vision và pháp luật hiện hành từ 01/01/2026.

### DEC-T09-023 — Không mặc định dùng đồng thời 7 mẫu sổ TT152
**Status:** `PROPOSED`  
Applicable book set được xác định bởi profile/chế độ/nghĩa vụ tương ứng.

### DEC-T09-024 — Sổ là projection, entry mới là accounting write truth
**Status:** `PROPOSED`  
Không sửa trực tiếp dòng sổ. Rebuild sổ từ canonical entries/facts theo book rule version.

### DEC-T09-025 — Export sổ tạo snapshot bất biến
**Status:** `PROPOSED`  
Mỗi lần xuất sổ có run ID, watermark, scheme version, checksum. Re-export tạo run mới.

### DEC-T09-026 — TT58/2026 là evolution, không trộn Phase 1
**Status:** `DEFERRED`  
Doanh nghiệp siêu nhỏ sẽ dùng cùng abstraction scheme/policy, nhưng rule cụ thể để một baseline sau.

### DEC-T09-027 — Chart of Accounts là capability tùy scheme
**Status:** `DEFERRED`  
Chỉ model đầy đủ khi cần chế độ doanh nghiệp có hệ thống tài khoản; không ép HKD Phase 1.

### DEC-T09-028 — Phase 1 base currency VND
**Status:** `PROPOSED`  
Multi-currency/FX deferred.

## 7. Nhóm E — Thuế

### DEC-T09-029 — Tax Compliance nằm trong end-state Theme 09
**Status:** `PROPOSED`  
Theme 09 sở hữu tax profile, tax period, calculation snapshot và tax return lifecycle cho tới khi Product quyết định tách Theme.

### DEC-T09-030 — Accounting result và tax result là hai projection khác nhau
**Status:** `PROPOSED`  
Không giả định một amount/accounting category luôn bằng taxable amount/tax category.

### DEC-T09-031 — Tax rule/form catalog phải version hóa
**Status:** `PROPOSED`  
Không hard-code form code lâu dài trong entity schema; lưu `form_schema_version` và `tax_policy_version`.

### DEC-T09-032 — Tax calculation snapshot giữ source watermark
**Status:** `PROPOSED`  
Mỗi run truy được tập dữ liệu và rule version đã dùng.

### DEC-T09-033 — Filed/ready snapshot không tự đổi theo master hiện hành
**Status:** `PROPOSED`  
Nếu dữ liệu thay đổi sau snapshot, phải tạo recalculation/amendment flow chứ không mutate im lặng.

### DEC-T09-034 — Tax e-submission deferred Phase 1
**Status:** `DEFERRED`  
Baseline chuẩn bị data/form; submission/acknowledgement chỉ triển khai khi integration contract được chốt.

## 8. Nhóm F — Điều chỉnh, đối chiếu & số dư đầu kỳ

### DEC-T09-035 — Cho phép manual accounting document có kiểm soát
**Status:** `PROPOSED`  
Bắt buộc reason; evidence theo policy; permission riêng.

### DEC-T09-036 — Manual accounting không được sửa subledger owner khác
**Status:** `PROPOSED`  
Nếu nguyên nhân là sai công nợ/kho, phải quay lại owner hoặc mở reconciliation; không “vá” authoritative source bằng một bút toán kế toán giả.

### DEC-T09-037 — Adjustment phải link entry/source gốc khi có
**Status:** `PROPOSED`  
Không tạo correction mất lineage.

### DEC-T09-038 — ReconciliationCase chỉ sở hữu process state
**Status:** `PROPOSED`  
Case không tự tuyên bố source business result nếu owner chưa final.

### DEC-T09-039 — Source correction tạo accounting adjustment, không delete history
**Status:** `PROPOSED`.

### DEC-T09-040 — Có accounting opening position nhưng không chiếm opening subledger
**Status:** `PROPOSED`  
Theme 6/7 vẫn sở hữu opening balance/stock thuộc domain của họ. Theme 09 nhận opening facts hoặc nhập phần kế toán độc lập theo scope.

### DEC-T09-041 — Opening entry mang type riêng
**Status:** `PROPOSED`  
`entry_type=OPENING`, có migration source/evidence và không giả là giao dịch kỳ hiện tại.

## 9. Nhóm G — Tích hợp & finality

### DEC-T09-042 — Selective preflight + asynchronous posting
**Status:** `CONFIRMED`  
Với cross-theme integration đã thảo luận, chỉ preflight khi thật sự cần; business event/outbox là đường chính để ghi sổ, không synchronous mọi giao dịch.

### DEC-T09-043 — Cross-theme posting result codes chuẩn
**Status:** `CONFIRMED`  
Tối thiểu hỗ trợ `POSTED`, `REJECTED`, `PERIOD_LOCKED`, `RECONCILIATION_NEEDED` ở business result layer.

### DEC-T09-044 — Technical delivery status tách business result
**Status:** `PROPOSED`  
`queued/sent/ack/failed/unknown` không được dùng thay trạng thái kế toán.

### DEC-T09-045 — Downstream accounting failure không rollback source transaction final
**Status:** `PROPOSED`  
Source Theme hiển thị side-effect pending/error riêng; không biến đơn hàng/thu chi đã hoàn tất thành chưa hoàn tất.

### DEC-T09-046 — UNKNOWN phải reconcile trước retry mù
**Status:** `PROPOSED`  
Nếu không biết Theme 09 đã post hay chưa, query/reconcile bằng idempotency key trước khi resend.

### DEC-T09-047 — Theme 09 lưu source reference + semantic checksum
**Status:** `PROPOSED`  
Mục tiêu là audit/dedup, không lưu duplicate source aggregate.

### DEC-T09-048 — Integration payload chi tiết chưa canonical ở v0.1.0
**Status:** `PROPOSED`  
Payload/schema thuộc `04.architecture/integrations`, chỉ viết sau khi BA semantics đủ review.

## 10. Nhóm H — Quyền, audit, retention & evolution

### DEC-T09-049 — Permission kế toán tách theo hành động nhạy cảm
**Status:** `PROPOSED`  
Tối thiểu phân biệt xem, điều chỉnh thủ công, khóa kỳ, mở lại kỳ, xuất sổ, chuẩn bị hồ sơ thuế.

### DEC-T09-050 — Mọi mutation trọng yếu phải audit
**Status:** `PROPOSED`  
Bao gồm profile/scheme change, manual document, posting/reversal, period lock/reopen, tax snapshot/amendment.

### DEC-T09-051 — Retention theo data class và legal policy version
**Status:** `PROPOSED`  
Không hard-code “10 năm cho mọi thứ”; entity lưu retention class/policy reference khi cần.

### DEC-T09-052 — Multi-currency, consolidation, fixed asset, payroll subledger ngoài Phase 1
**Status:** `DEFERRED`.

## 11. Decision dependency map

```text
001-006 Ownership
   ↓
007-015 Canonical accounting model
   ↓
016-021 Time & Period
   ├────────→ 022-028 Books/Schemes
   ├────────→ 029-034 Tax
   └────────→ 035-041 Adjustment/Reconciliation
                    ↓
              042-048 Integration
                    ↓
              049-052 Control/Evolution
```

## 12. Review priority

Ưu tiên chốt trước: `022`, `029`, `035`, `020`, `030`, `042-043`. Đây là các decision có khả năng làm thay đổi mạnh BJ/UC/API/UI downstream.
