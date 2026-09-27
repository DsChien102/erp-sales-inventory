# PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho

> **Loại artifact:** Technical recovery procedure; không phải Business Journey  
> **Migration:** Theme 7 `4.0.0/BJ-21` → `4.1.0/PROC-01`  
> **Owner:** Platform Operations  
> **Caller:** Chỉ BJ-16 sau khi xác nhận ledger đúng và projection sai
> **Quyết định nghiệp vụ:** `T7-BASELINE-FREEZE-v4.0.0` + `T7-DR-084`, `T7-DR-084#REQ-02`, `T7-DR-086`, `T7-DR-090`

# 1. Mục tiêu và precondition

Khôi phục projection/read model từ authoritative ledger mà không sửa ledger hoặc operation nguồn. Chỉ chạy khi BJ-16 đã phân loại `PROJECTION_MISMATCH`, chứng minh ledger toàn vẹn và cấp scope/cut-off.

# 2. Procedure

| Step | Hành động | Evidence bắt buộc |
|---|---|---|
| PROC-01-STEP-01 | Xác định projection, scope và cut-off; kiểm ledger integrity | Rebuild plan và integrity decision |
| PROC-01-STEP-02 | Khóa phạm vi rủi ro; snapshot projection cũ/control totals | Safe baseline, old version/hash |
| PROC-01-STEP-03 | Dựng candidate projection từ ledger tới cut-off | Candidate version và input hash |
| PROC-01-STEP-04 | Đối chiếu totals/counts/hash và atomic publish | Validation evidence hoặc failure evidence |

# 3. Hard controls

- Không dùng report/chứng từ nguồn để tái tạo ledger.
- Candidate không đạt totals/count/hash không được publish.
- Publish bằng atomic/versioned switch; không để người dùng thấy dữ liệu trộn phiên bản.
- Failure giữ projection cũ, scope protection và owner/escalation; không ghi đè bán phần.
- Rebuild run lưu ledger cut-off, input/output hash, actor và publish time.
- PROC-01 không giải quyết operation `UNKNOWN`; authority đó thuộc BJ-17.

# 4. Handoff

PROC-01 trả validation evidence về BJ-16. Chỉ BJ-16 có quyền close/reopen Reconciliation Case.

# 5. Step contracts chi tiết

- [PROC-01-STEP-01-chuan](PROC-01-STEP-01-chuan-bi-pham-vi-dung-lai.md)
- [PROC-01-STEP-02-bao](PROC-01-STEP-02-bao-ve-phien-ban-du-lieu-dan-xuat.md)
- [PROC-01-STEP-03-dung](PROC-01-STEP-03-dung-lai-tu-ledger.md)
- [PROC-01-STEP-04-xac](PROC-01-STEP-04-xac-minh-va-cong-bo-ket-qua.md)
