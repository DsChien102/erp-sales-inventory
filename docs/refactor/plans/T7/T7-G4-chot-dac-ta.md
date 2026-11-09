# T7-G4 — Chốt đặc tả Theme 7 (FROZEN v5.27.0)

> Theme 7 · mục T7-G4 của PLAN.md (sau T7-P GĐ3, trước T7-G5)
> Trạng thái: Plan ✅ (viết + người dùng duyệt 2026-11-09) | Làm ⬜ | Review ⬜
> Tài liệu: [T7-P](T7-P-thiet-ke-lai-luong.md) mục 2, 5, 6, 7.3, 13; `specs/themes/theme-07/03.design/screens/_TEMPLATE.md`, `flows/_TEMPLATE.md`, `INDEX.md`, `RETIRED.md`; prototype `03.design/prototype/html` v5.26.1 (đã đóng — **không sửa giao diện**).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bộ đặc tả Theme 7 khớp hoàn toàn prototype v5.26.1 cộng 5 đề xuất vừa duyệt, rồi chốt `FROZEN` đồng loạt ở mốc **v5.27.0**, để T7-G5 (Flutter) chỉ đọc một nguồn.

**Architecture:** Chỉ sửa Markdown / JSON trong `specs/themes/theme-07` và tài liệu refactor. Task 0 thêm script kiểm `tools/check-spec.py` (mốc đo trước khi sửa). Task 1–6 sửa nội dung, mỗi task kết thúc bằng script kiểm giảm đúng số lỗi đã ghi. Task 7 đổi trạng thái + phiên bản, `check-spec.py --freeze` phải ra 0 lỗi. Task 8 cập nhật T7-P / PLAN.md.

**Tech Stack:** Markdown, Python 3 (script kiểm + `sync-registry.py` có sẵn), `git`.

**Spec:** Quyết định của người dùng 2026-11-09 (mục 2) + T7-P mục 13 (các dòng ⬜).

## Global Constraints

- **Không đổi nghiệp vụ, không sửa giao diện prototype.** Không sửa `app/*.js`, `styles/*`. Prototype chỉ đổi 3 chỗ ghi phiên bản (Task 7). Không chạy lại golden.
- Chuỗi chữ trên màn lấy **nguyên văn** từ prototype (`app/*.js`) hoặc từ plan này. Không tự đặt chữ mới.
- Thư mục gốc theme: `specs/themes/theme-07` (gọi tắt `T7/`). Script kiểm chạy được từ bất kỳ đâu: `python3 specs/themes/theme-07/03.design/prototype/html/tools/check-spec.py`.
- `04.harness/` và `09.generated/registries/design*`, `09.generated/matrices/design` là tài liệu cũ (trước refactor): **không sửa**, script kiểm bỏ qua (như 7-C Q5).
- Chỉ đổi `IN_REVIEW` → `FROZEN` (175 tệp). **`DRAFT` giữ nguyên** (35 domain + 1 knowledge, rà ở plan backend T7-B).
- Không có symbol code ⇒ không chạy `impact`. Trước mỗi commit vẫn chạy `node .gitnexus/run.cjs detect-changes` (CLAUDE.md); kết quả mong đợi: 0 symbol, 0 process.
- `AGENTS.md`, `CLAUDE.md` đang có thay đổi chưa commit của người dùng: không `git add` hai tệp này.
- Ghi Kết quả (mục 7) ngay sau mỗi task: commit, tệp:dòng, lệch plan, số lỗi script trước / sau. Phiên làm không tự chấm ĐẠT, không ghi mục Review.

## Review Focus

1. **Xoá file màn còn được link** (Task 1) ⇒ link chết trong UC / UIF. Kiểm: C3 + C5 của `check-spec.py` = 0 sau Task 1 (trừ dòng PAT-NAV ghi rõ).
2. **Đổi chữ trên màn lệch prototype** khi viết lại Hub (Task 5) ⇒ Flutter làm theo chữ sai. Kiểm: Task 5 Step 3 so từng chuỗi trong bảng "Chữ trên màn" với `grep -F` trong `app/hub.js`.
3. **Ghi quy tắc duyệt K2 sai một BJ** (Task 3) — ví dụ để chủ cửa hàng ghi nhận thẳng không qua duyệt ⇒ backend T7-B làm sai. Kiểm: Task 3 Step 2 `grep` đủ 6 BJ / UC, mỗi dòng có cụm "gửi duyệt rồi tự duyệt".
4. **Đề xuất 1a–1e ghi mơ hồ** ⇒ Flutter phải đoán. Kiểm: mỗi đề xuất có chữ cụ thể + trạng thái áp dụng trong Screen Contract (Task 4 Step 2).
5. **Bỏ sót tệp `IN_REVIEW`** hoặc đổi nhầm `DRAFT` ⇒ chốt không trọn. Kiểm: Task 7 `--freeze` = 0 lỗi và đếm `DRAFT` vẫn = 36.

---

## 1. Mục tiêu

- `python3 …/tools/check-spec.py --freeze` ⇒ in `Lỗi theo nhóm: 0`, thoát 0.
- `grep -rl "status: IN_REVIEW" T7/02.specification T7/03.design/flows T7/03.design/screens T7/03.design/patterns` ⇒ rỗng. `grep -rc "status: DRAFT"` tổng = 36 (không đổi).
- README theme, `manifest.json`, `harness/workbench.js`, badge `index.html`, `03.design/prototype/README.md` cùng ghi **5.27.0**; `CHANGELOG.md` có mục `[5.27.0]`.
- 9 màn chưa dựng nằm trong `RETIRED.md`. Mọi dòng ⬜ của T7-P mục 13 thành ✅ (hoặc "bỏ" với 1f).

## 2. Quyết định (người dùng chốt 2026-11-09)

| Q | Nội dung |
|---|---|
| Q1 | **Đề xuất G3-7: làm 1a–1e, bỏ 1f.** Ghi vào Screen Contract (Task 4). Flutter làm ở T7-G5. Prototype không sửa. Chi tiết từng đề xuất ở Task 4 (plan đề xuất cách ghi cụ thể; người dùng duyệt cùng plan). 1f bỏ: giữ "Đếm mù", "Căn cứ" |
| Q2 | **9 màn chưa dựng → RETIRED** (A): SCR-002, 004, 005, 020, 022, 023, 024, 060, 061. Hệ quả nghiệp vụ: app không có màn để người dùng tự giữ / thả / phân bổ lại hàng giữ. Giữ hàng do đơn bán làm (UC-04-01…04 đã ghi tác nhân là "Source system / system process"). Muốn thả hàng thì sửa / huỷ đơn bán |
| Q3 | **Mốc v5.27.0 chung** cho README theme, manifest, workbench, badge, README prototype, CHANGELOG |
| Q4 | **Chỉ `IN_REVIEW` → `FROZEN`** (175 tệp: 65 UC, 18 BJ, 18 UIF, 64 SCR, 4 BC, 6 domain). `DRAFT` giữ |
| Q5 | (plan đề xuất, duyệt cùng plan) **Hub SCR-090…096 viết lại theo `_TEMPLATE.md`** từ `app/hub.js`. Lý do: 7 tệp đang ở khuôn v4.6.7, thiếu "Chờ duyệt", "Hàng cần xử lý", "Hồ sơ cần kiểm tra", "Kho chưa kích hoạt" mà prototype đã có — T7-15 (Home Kho Flutter) cần đúng các khối này |
| Q6 | (plan đề xuất) **PAT-UI-UX, PAT-NAV viết lại gọn**: bỏ số liệu cũ (83 màn, 479 state, bảng BJ `MAPPED`, mục "Trạng thái prototype" v0.3.2), thay bằng khuôn K1–K7 + quy tắc DS mới (T7-P mục 5, 6) và cấu trúc Home Kho (T7-P mục 2). Danh sách màn trỏ `screens/INDEX.md`, không trỏ `09.generated/registries/design/*` (bản chụp v4.6.8, không ai sinh lại) |
| Q7 | (plan đề xuất) **"Giao cho"** (T7-P mục 13, dòng SCR-028 / SCR-039 "cần chốt ở 7.3"): giữ. UC-05-03 BF-03 đã ghi "người/đơn vị nhận", SCR-028 / 039 đã có chữ ⇒ chỉ đánh dấu ✅ ở Task 8, không sửa thêm |

## 3. Hiện trạng (đo 2026-11-09, HEAD `fe26f5400`)

Script kiểm (bản thử, chính là bản Task 0 thêm vào) ra:

```text
Trạng thái: … scope/DRAFT=35, scope/FROZEN=86, scope/IN_REVIEW=175
Lỗi theo nhóm: {'C2': 12, 'C5': 1, 'C4': 1, 'C7': 1}          (--freeze: thêm C1 = 175)
```

| Nhóm | Dòng lỗi |
|---|---|
| C2 (12) | `00-use-case-map.md:32, 34` (SCR-027), `:58, 59` (SCR-052); `UC-05-02:126`, `UC-05-04:120` (027); `UC-11-02:119`, `UC-11-03:128` (052); `UC-13-01:159, 169` (088); `UIF-15-BJ-15.md:121` (054); `README.md:124` (017) |
| C5 (1) | `PAT-NAV.md:26` link `../../06.evidence/design/legacy-contracts/entry-architecture.md` (tệp không còn) |
| C4 (1) | `INDEX.md` thiếu dòng SCR-006 (đã ở `RETIRED.md`) |
| C7 (1) | README theme `version: v4.6.8`, manifest `5.26.1` |

Ngoài script:
- Tham chiếu tới 9 màn sắp bỏ (Q2): `00-use-case-map.md` (004 ×2, 005), `UC-01-02:113` (004), `UC-01-03:106` (005), `UC-01-05:115` (004), `UIF-01-BJ-01.md` (002, 004, 005, 060, 061), `UIF-04-BJ-04.md` (020, 022, 023, 024), `PAT-NAV.md` (cả 9), `SCR-003.md` (004, 005).
- Quy tắc duyệt K2 (`is_owner` lập vẫn gửi duyệt rồi tự duyệt) **đã ghi** ở UC-02-03, UC-06-02 BR-06, UC-08-04 BR-01, UC-10-02 BR-03, UC-12-02, BJ-02, BJ-12. **Chưa ghi** ở UC-09-02, UC-11-04, BJ-06, BJ-08, BJ-09, BJ-10, BJ-11.
- Hub SCR-090…096: `status: FROZEN`, `source_baseline: v4.6.7`, không có `bj` / `uif`, không có "Chờ duyệt" / "Hàng cần xử lý" / "Hồ sơ cần kiểm tra" / "Kho chưa kích hoạt" (`hub.js` có).
- PAT-UI-UX `source_baseline: v3.13.0`, PAT-NAV `v3.10.1`; không nhắc K1–K7.
- `03.design/prototype/README.md` `version: v5.3.1`.

## 4. Thay đổi (tóm tắt theo tệp)

| Tệp / nhóm | Task |
|---|---|
| `T7/03.design/prototype/html/tools/check-spec.py` (mới) | 0 |
| `RETIRED.md`, `INDEX.md`, xoá 9 `SCR-*.md`, `SCR-003.md`, `UC-01-02/03/05`, `00-use-case-map.md`, `UIF-01`, `UIF-04` | 1 |
| `UC-05-02`, `UC-05-04`, `UC-11-02`, `UC-11-03`, `UC-13-01`, `00-use-case-map.md`, `UIF-15` | 2 |
| `UC-09-02`, `UC-11-04`, `UC-13-01`, `BJ-06/08/09/10/11`, `SCR-040/046/050` mục 6 | 3 |
| `SCR-010`, `012`, `015`, `029`, `037`, `046`, `047`, `048`, `074` | 4 |
| `SCR-090…096` | 5 |
| `PAT-UI-UX.md`, `PAT-NAV.md` | 6 |
| Mọi tệp `IN_REVIEW`, `README.md` theme, `manifest.json`, `workbench.js`, `index.html`, `prototype/README.md`, `CHANGELOG.md`, `09.generated` (qua `sync-registry.py`) | 7 |
| `T7-P-thiet-ke-lai-luong.md` mục 13, 7.3; `PLAN.md` | 8 |

## 5. Các task

### Task 0: Script kiểm `check-spec.py` + đo mốc

**Files:**
- Create: `T7/03.design/prototype/html/tools/check-spec.py`

**Interfaces:**
- Produces: lệnh `python3 …/check-spec.py [--freeze]`. In 2 dòng đầu `Trạng thái: …` và `Lỗi theo nhóm: {…}` (hoặc `0`), sau đó mỗi lỗi một dòng `C<n> <tệp>:<dòng>: …`. Thoát 1 khi có lỗi.

- [x] **Step 1: Viết script.** Gốc = 4 cấp trên thư mục script (`T7/`), giống `sync-registry.py`. Quét mọi `*.md` (bỏ thư mục bắt đầu bằng `.`), **bỏ qua** `03.design/prototype`, `09.generated`, `06.evidence`, `04.harness`. Hằng số chép nguyên:

```python
FREEZE_SCOPE = ('02.specification/behavior', '02.specification/domain', '03.design/flows', '03.design/screens', '03.design/patterns', 'README.md')
MARK = re.compile(r'gộp|đã bỏ|bỏ `?SCR|retire|Bỏ từ|thay bằng|thay `?SCR|hợp nhất|link cũ|trước đây|SCR-\d{3}`? cũ|không còn', re.I)
```

  Màn đã bỏ = mã ở cột 1 các dòng `| SCR-NNN |` của `RETIRED.md`. Các kiểm:
  - **C1** (chỉ khi `--freeze`): tệp trong `FREEZE_SCOPE` có `status: IN_REVIEW` trong 1.500 ký tự đầu.
  - **C2**: dòng (ngoài `RETIRED.md`, `INDEX.md`) nhắc một màn đã bỏ mà không khớp `MARK`.
  - **C3**: `SCR-NNN` được nhắc nhưng không có tệp `screens/SCR-NNN*` và không có trong `RETIRED.md`.
  - **C4**: `INDEX.md` (cột 4 = trạng thái) thiếu màn có tệp, ghi trạng thái khác `status:` của tệp, hoặc màn trong `RETIRED.md` không ghi `RETIRED`; màn trong `RETIRED.md` mà tệp vẫn còn.
  - **C5**: link `](….md)` tương đối trỏ tới tệp không có.
  - **C6**: dòng bắt đầu `### v<số>` trong `screens/`, `flows/`.
  - **C7**: `version:` của `README.md` theme (bỏ tiền tố `v`) khác `version` của `manifest.json`.
  - Dòng `Trạng thái:` đếm `(nhóm, status)`; tệp trong `FREEZE_SCOPE` gom vào nhóm `scope`.
- [x] **Step 2: Chạy mốc.** `python3 specs/themes/theme-07/03.design/prototype/html/tools/check-spec.py` ⇒ đúng như mục 3: `{'C2': 12, 'C5': 1, 'C4': 1, 'C7': 1}`, `scope/IN_REVIEW=175`, `scope/DRAFT=35`. Với `--freeze` thêm `'C1': 175`. Lệch thì sửa script cho tới khi khớp, rồi ghi số vào Kết quả.
- [x] **Step 3: Commit** `chore(spec): T7-G4 thêm tools/check-spec.py kiểm đặc tả Theme 7`

### Task 1: Bỏ 9 màn chưa dựng (Q2)

**Files:**
- Modify: `T7/03.design/screens/RETIRED.md`, `INDEX.md`, `SCR-003.md`
- Delete: `T7/03.design/screens/SCR-002.md`, `SCR-004.md`, `SCR-005.md`, `SCR-020.md`, `SCR-022.md`, `SCR-023.md`, `SCR-024.md`, `SCR-060.md`, `SCR-061.md`
- Modify: `T7/02.specification/behavior/use-cases/UC-01-02-*.md:113`, `UC-01-03-*.md:106`, `UC-01-05-*.md:115`, `00-use-case-map.md` (dòng UC-01-02, 01-03, 01-05); `T7/03.design/flows/UIF-01-BJ-01.md`, `UIF-04-BJ-04.md`

- [x] **Step 1: `RETIRED.md`** thêm 9 dòng (cột "Bỏ từ" = `v5.27.0`):

| Màn | Tên cũ | Thay bằng | Ghi chú |
|---|---|---|---|
| SCR-002 | Kết quả khả dụng | SCR-001 | Khả dụng hiện ngay trên dòng sản phẩm |
| SCR-004 | Chi tiết lô | SCR-003 | Sheet lô trong SCR-003 |
| SCR-005 | Nguồn số liệu | SCR-003 | Sheet "Nguồn và thời điểm cập nhật" trong SCR-003 |
| SCR-020 | Đơn cần giữ hàng | SCR-021 | Giữ hàng do đơn bán tạo (UC-04-01, tác nhân hệ thống); xem từ chi tiết đơn / SCR-026 |
| SCR-022 | Rà soát giữ hàng | SCR-021 | Giao đủ / từng phần là chính sách của đơn bán (Theme 5), Kho chỉ xem |
| SCR-023 | Giải phóng hoặc phân bổ lại | SCR-021 | Giải phóng / phân bổ lại do đơn bán (sửa, huỷ đơn — UC-04-02, 04-03); Kho không có nút |
| SCR-024 | Kết quả reservation | SCR-021 | Lượng giữ / thiếu hiện ngay ở SCR-021 |
| SCR-060 | Chỉ báo tồn kho | SCR-001 | Bộ lọc "Hết hàng / Tồn thấp / Cận hạn" của SCR-001 |
| SCR-061 | Chi tiết chỉ báo sản phẩm | SCR-003 | Khối cảnh báo + "Gợi ý nhập thêm" của SCR-003 |

- [x] **Step 2: `INDEX.md`** 9 dòng trên: cột Trạng thái `RETIRED`, cột Trong prototype `Đã bỏ (xem RETIRED.md)`, tên thêm `— Đã bỏ`; thêm dòng `| SCR-006 | Chọn cách nhận hàng — Đã gộp vào SCR-007 | — | RETIRED | Đã bỏ (xem RETIRED.md) |` đúng thứ tự số (sửa C4 có sẵn).
- [x] **Step 3: Xoá 9 tệp** bằng `git rm`.
- [x] **Step 4: Sửa tham chiếu.**
  - UC-01-02 / 01-05 §8: dòng `SCR-004` → `SCR-003` "Sheet lô (thay SCR-004 cũ): …" giữ nguyên câu vai trò. UC-01-03 §8: `SCR-005` → `SCR-003` "Sheet 'Nguồn và thời điểm cập nhật' (thay SCR-005 cũ): …". Trùng dòng `SCR-003` đã có thì gộp vào dòng đó.
  - `00-use-case-map.md` cột "Màn hình hiện hành": bỏ `SCR-004`, `SCR-005` (đã có `SCR-003`, nếu chưa có thì thêm).
  - `UIF-01-BJ-01.md`: mỗi dòng nhắc 002 / 004 / 005 / 060 / 061 → đổi sang màn thay theo bảng Step 1; câu mô tả có màn cũ thì viết "(thay SCR-0NN cũ)".
  - `UIF-04-BJ-04.md`: dòng nhắc 020 / 022 / 023 / 024 → xoá khỏi bảng chuyển màn; thêm một câu ở mục lối vào: "Giữ hàng do đơn bán tạo / sửa / giải phóng; Kho chỉ có SCR-021 để xem (SCR-020, 022–024 đã bỏ từ v5.27.0)".
  - `SCR-003.md`: dòng nhắc 004 / 005 thêm "(thay SCR-004 cũ)" / "(thay SCR-005 cũ)" nếu chưa có chữ đánh dấu.
  - **Không** sửa `PAT-NAV.md` ở task này (Task 6 viết lại).
- [x] **Step 5: Kiểm.** `check-spec.py` ⇒ C3 = 0, C4 = 0; C2 = 12 cũ + đúng các dòng của `PAT-NAV.md` nhắc 9 màn (ghi số dòng vào Kết quả); không còn dòng C2 nào ngoài PAT-NAV và 12 dòng cũ.
- [x] **Step 6: Commit** `docs(spec): T7-G4 bỏ 9 màn chưa dựng (002, 004, 005, 020, 022–024, 060, 061) sang RETIRED`

### Task 2: Tham chiếu màn đã bỏ từ trước (C2 cũ)

**Files:** `00-use-case-map.md:32, 34, 58, 59`; `UC-05-02:126`; `UC-05-04:120`; `UC-11-02:119`; `UC-11-03:128`; `UC-13-01:159, 169`; `UIF-15-BJ-15.md:121` (tất cả dưới `T7/02.specification/behavior/use-cases/` hoặc `T7/03.design/flows/`)

- [x] **Step 1: Sửa** (T7-P mục 13 dòng UC-05, UC-11, UC-13):
  - SCR-027 → **SCR-026** (UC-05-02, UC-05-04, map dòng 17, 19). Trùng dòng SCR-026 có sẵn thì gộp.
  - SCR-052 → **SCR-050** ở UC-11-03 (chọn cách sửa + số đúng); **SCR-049** ở UC-11-02 (hủy yêu cầu chưa thực hiện là sheet "Hủy yêu cầu {mã phiếu}?" trong SCR-049). Map dòng 43, 44 theo đó.
  - UC-13-01: xoá dòng bảng `SCR-088` (:169); câu :159 viết lại: "Bước rà soát vẫn bắt buộc về hành vi; rà soát là sheet xác nhận 'Ghi điều chỉnh giá trị?' ngay trên `SCR-086` (SCR-088 đã bỏ)."
  - UIF-15:121: thêm "(đã bỏ, v5.20.0)" sau `SCR-054`.
- [x] **Step 2: Kiểm.** `check-spec.py` ⇒ C2 chỉ còn `README.md:124` + các dòng PAT-NAV (Task 1 Step 5).
- [x] **Step 3: Commit** `docs(spec): T7-G4 đổi tham chiếu SCR-027, 052, 054, 088 đã bỏ sang màn hiện hành`

### Task 3: Quy tắc duyệt K2 và "Kế toán = chủ cửa hàng"

T7-P mục 13 các dòng ⬜ của BJ-08, 09, 10, 11, 13. Câu chuẩn (chép nguyên, thay `{việc}`):

> **Người duyệt** là `is_owner` hoặc vai trò `store_owner`, khác người lập. **Ngoại lệ:** cửa hàng chỉ có một chủ, nên `is_owner` lập {việc} thì vẫn gửi duyệt rồi tự duyệt ở màn duyệt (không có đường ghi nhận thẳng); lịch sử ghi người duyệt "Chủ cửa hàng".

**Files:**
- `UC-09-02-phe-duyet-thay-doi-trang-thai.md` (mục 3 "Tác nhân chính" + bảng BR mục 6: thêm `BR-K2`), `UC-11-04-phe-duyet-correction.md` (như trên) — `{việc}` = "đổi tình trạng" / "yêu cầu sửa sai".
- `BJ-06`, `BJ-08`, `BJ-09`, `BJ-10`, `BJ-11` trong `journeys/`: bảng tác nhân, dòng người duyệt — viết theo mẫu `BJ-02-nhan-hang-mua.md:33` (`Người duyệt: is_owner hoặc vai trò store_owner, khác người lập (trừ ngoại lệ is_owner tự duyệt)`). Chưa có dòng người duyệt thì thêm.
- `SCR-040.md`, `SCR-046.md`, `SCR-050.md` mục 6 "Quyền và che tài chính": thêm câu chuẩn (`{việc}` = "đề nghị tiêu hủy" / "phiên kiểm kê (kể cả khi chủ tự đếm)" / "yêu cầu sửa sai") + "Số tiền chỉ chủ cửa hàng thấy." nếu chưa có.
- `UC-13-01-ghi-nhan-dieu-chinh-gia-tri-hang-nhap.md` mục 3: thêm chú thích như UC-03-01: "\"Kế toán\" trong UC này là chủ cửa hàng khi cửa hàng không có kế toán riêng." Mục 8 không còn SCR-088 (Task 2 đã xoá); câu `:172` về SCR-087 giữ nguyên (đã ghi "đã retire").

- [x] **Step 1: Sửa** các tệp trên. Không sửa UC-02-03, UC-06-02, UC-08-04, UC-10-02, UC-12-02, BJ-02, BJ-12 (đã có).
- [x] **Step 2: Kiểm.** `grep -l "gửi duyệt rồi tự duyệt" T7/02.specification/behavior/journeys/BJ-0{2,6,8,9}*.md T7/02.specification/behavior/journeys/BJ-1{0,1,2}*.md T7/02.specification/behavior/use-cases/UC-0{2-03,6-02,8-04,9-02}*.md T7/02.specification/behavior/use-cases/UC-1{0-02,1-04,2-02}*.md` ⇒ đủ 14 tệp (7 BJ + 7 UC; mốc trước task: 7 — BJ-02, BJ-12, UC-02-03, 06-02, 08-04, 10-02, 12-02). `grep -c "chủ cửa hàng" UC-13-01*` ≥ 1. `check-spec.py` không thêm lỗi.
- [x] **Step 3: Commit** `docs(spec): T7-G4 ghi quy tắc duyệt K2 cho BJ-06/08/09/10/11 và Kế toán = chủ ở UC-13-01`

### Task 4: Năm đề xuất đã duyệt (Q1: 1a–1e)

Mỗi đề xuất ghi vào **mục 3 (Thứ bậc thông tin)** và **mục 8 (Chữ trên màn)** của Screen Contract, kèm một dòng cuối mục 3: "(Đề xuất G3-7 duyệt 2026-11-09, prototype v5.26.1 chưa có — Flutter làm theo đặc tả.)"

**Files:** `T7/03.design/screens/SCR-010.md`, `012`, `015`, `029`, `037`, `046`, `047`, `048`, `074`

- [x] **Step 1: Sửa.**
  - **1a — "Tồn kho đã đổi"** (SCR-012, 029, 047). Thêm một dòng vào bảng số liệu K4, **ngay sau** dòng số lượng chính ("Vào tồn" ở 012; "Người bàn giao" ở 029; "Thiếu / thừa" ở 047): nhãn `"Tồn kho đã đổi"`, giá trị `"{sản phẩm} {trước} → {sau} {ĐVT}"` của dòng hàng đầu tiên theo thứ tự danh sách; còn dòng khác thì thêm `" · +{k} mặt hàng khác"`. `{trước}` / `{sau}` là **tồn vật lý** của sản phẩm trước / sau thao tác. Chỉ hiện ở: 012 `COMPLETED` và `VALUATION_PENDING_RESULT` khi có hàng vào tồn; 029 bàn giao toàn bộ / một phần; 047 `COMPLETED` (có điều chỉnh). Không hiện ở trạng thái khác (khớp hết, hủy, `REJECTED_EXECUTION`, `UNKNOWN`).
  - **1b — Bỏ lặp "Tóm tắt"** (T7-P ghi SCR-011, nhưng prototype cho thấy chỗ lặp nằm ở **SCR-010** web: `bj02.js` khối "Thông tin lần nhận" ở cột trái và "Tóm tắt" ở cột phải cùng ghi chứng từ, NCC, kho, ngày; SCR-011 không có khối "Tóm tắt"). SCR-010 web: **bỏ** khối "Thông tin lần nhận" ở cột trái; nút "Đổi chứng từ" (nhận theo chứng từ) / "Sửa" (nhập nhanh) chuyển vào cuối khối "Tóm tắt", ngay trên nút chính. iPhone giữ nguyên. SCR-074 web: khối "Tóm tắt" bỏ hai dòng "Điều chỉnh giá vốn xuất" / "Điều chỉnh giá trị tồn" (đã có ở ③), còn Kỳ · Phạm vi · Thời điểm chốt · Phương pháp.
  - **1c — Badge dưới tiêu đề** (SCR-048 iPhone): dòng danh sách "{loại} {mã phiếu}" để tiêu đề dùng hết bề ngang; badge tình trạng nằm **dưới** tiêu đề, cùng hàng với dòng phụ "{sản phẩm} · {n} {ĐVT} · {ngày}", căn phải. Web giữ bảng.
  - **1d — SCR-037**: khối "Việc tiếp theo" chỉ có tiêu đề khi có việc đang chạy (`k2Pending`); chỉ có câu ghi chú "Trả nhà cung cấp do bộ phận Mua hàng lập yêu cầu…" thì hiện câu đó **không** tiêu đề. Thẻ lô: dải số đổi thành `"{n} {ĐVT} · Khả dụng bán {k}"` (bỏ `{tình trạng}` vì badge đã nói).
  - **1e — Số tiền kiểu mono**: SCR-015 ("Tổng giá trị", dải "Đã chọn {n} sản phẩm · {tổng}"), SCR-046 ("Giá trị điều chỉnh", cột "Giá trị"), SCR-074 (② hai thẻ, ③ hai dòng, "Tóm tắt") — mục 7 thêm: "Số tiền ở thẻ số liệu, Key-value Row và 'Tóm tắt' dùng kiểu chữ số mono (như cột số của bảng)." Quy tắc chung ghi ở PAT-UI-UX (Task 6).
- [x] **Step 2: Kiểm.** `grep -l "Đề xuất G3-7 duyệt 2026-11-09" T7/03.design/screens/*.md | wc -l` ⇒ 9. `grep -c "Tồn kho đã đổi" SCR-012.md SCR-029.md SCR-047.md` mỗi tệp ≥ 2 (mục 3 + mục 8). `check-spec.py` không thêm lỗi.
- [x] **Step 3: Commit** `docs(spec): T7-G4 ghi 5 đề xuất G3-7 đã duyệt vào Screen Contract (1a–1e)`

### Task 5: Hub SCR-090…096 theo khuôn mới (Q5)

**Files:** `T7/03.design/screens/SCR-090.md` … `SCR-096.md` (viết lại toàn bộ)

**Interfaces:**
- Consumes: `app/hub.js` (`renderHubHome`, `WORKSPACES`, `pendingSources`, `FLOW_LABELS`, nhánh `inventoryActivated`), T7-P mục 2 bảng "Vị trí trên Home Kho".

- [x] **Step 1: Viết lại** theo `screens/_TEMPLATE.md` (9 mục, bỏ phần "Quy tắc ghi"). Frontmatter: `bj: —`, `uif: —`, `status: IN_REVIEW` (Task 7 chốt), `prototype: "app/hub.js · renderHubHome"` (090) hoặc hàm dựng workspace tương ứng (091–096), `updated: <ngày làm>`; giữ `screen_class: NAVIGATION`, `authority: PAT-NAV`.
  - SCR-090: thứ tự khối tìm kiếm → 4 nút nhanh (Nhận hàng, Lấy hàng, Kiểm kê, Tra cứu tồn) → "Cần chú ý" (chỉ khi có việc: "Chờ duyệt" gom mọi nguồn `pendingSources`, "Hàng cần xử lý", "Hồ sơ cần kiểm tra"; câu đếm lấy nguyên chữ từ `hub.js`) → "Quản lý kho" 5 khu → "Thiết lập kho". Bảng trạng thái có **"Kho chưa kích hoạt"** (`inventoryActivated = false`: khối "Kho chưa kích hoạt" + "Khởi tạo tồn kho", 4 nút nhanh tắt — T7-P mục 13 dòng SCR-066) và "Cần chú ý" rỗng.
  - SCR-091…095: mỗi khu = danh sách lối vào lấy từ `WORKSPACES[...]` (tên dòng, chữ phụ, màn đích). SCR-094 "Giá trị kho" ghi rõ chỉ chủ cửa hàng thấy (T7-P mục 2). SCR-096 "Thiết lập kho": BJ-12, CAP-01.
  - Mục 2 (lối vào / ra) mỗi dòng ghi màn đích bằng mã SCR hiện hành (không dùng mã trong `RETIRED.md`).
- [x] **Step 2: `INDEX.md`**: 7 dòng Hub cột Trạng thái `IN_REVIEW` (để C4 khớp tệp).
- [x] **Step 3: Kiểm chữ.** Với mỗi chuỗi trong mục 8 của 7 tệp: `grep -F "<chuỗi không có {…}>" T7/03.design/prototype/html/app/hub.js` có kết quả (chuỗi có biến thì kiểm phần chữ cố định). Ghi số chuỗi đã kiểm vào Kết quả. `check-spec.py` không thêm lỗi.
- [x] **Step 4: Commit** `docs(spec): T7-G4 viết lại Hub SCR-090…096 theo khuôn Screen Contract và hub.js`

### Task 6: PAT-UI-UX, PAT-NAV (Q6)

**Files:** `T7/03.design/patterns/PAT-UI-UX.md`, `PAT-NAV.md`

- [x] **Step 1: PAT-UI-UX** giữ frontmatter (đổi `source_baseline: v5.27.0`, `status: IN_REVIEW`), giữ mục 1–3, 8 (thuật ngữ). **Thay** mục 4.5–4.7, 4.9, 4.10, "Inventory Valuation Product-flow rule — v3.13.0" bằng:
  - "Khuôn dùng chung": bảng K1–K7 chép từ T7-P mục 5 (cột Khuôn, Dựng ở, Dùng lại ở) + quy tắc K2 (câu chuẩn của Task 3).
  - "Thành phần DS mới": bảng T7-P mục 6 (tên, mô tả), cột trạng thái ghi "prototype; Flutter ở T7-G5".
  - "Quy tắc UI chung": 7 gạch đầu dòng ở PLAN.md mục Theme 7 "Quy tắc UI chung" + quy tắc số tiền mono (1e).
  - "Danh sách màn": một câu trỏ [`screens/INDEX.md`](../screens/INDEX.md) và [`RETIRED.md`](../screens/RETIRED.md).
  - "Thiết bị": iPhone và web ngang nhau ở mọi màn (T7-P mục 2 đoạn "Cả hai là thiết bị chính"), K7 cho web.
- [x] **Step 2: PAT-NAV** giữ frontmatter (đổi `source_baseline: v5.27.0`, `status: IN_REVIEW`), mục 1–3. **Thay** mục 4 bằng: "Lối vào" (iPhone: tab "Thêm" → Kho; web: thanh bên "Thêm" → Kho — T7-P mục 2), bảng "Vị trí trên Home Kho" chép từ T7-P mục 2 (đổi tên BJ sang mã SCR đích), "Mỗi BJ bắt đầu ở nơi việc phát sinh" (đoạn T7-P mục 2). Bỏ "NAV taxonomy", "Danh mục theo khu vực" NAV-01…06 (thay bằng SCR-091…095). Xoá link hỏng dòng 26. Mục 8 "Screen tham chiếu" = SCR-090…096.
- [x] **Step 3: Kiểm.** `check-spec.py` ⇒ chỉ còn `C2 README.md:124` và `C7`. `grep -c "K[1-7]" PAT-UI-UX.md` ≥ 7.
- [x] **Step 4: Commit** `docs(spec): T7-G4 viết lại PAT-UI-UX (K1–K7, DS mới) và PAT-NAV (Home Kho candidate)`

### Task 7: Chốt FROZEN v5.27.0 (Q3, Q4)

**Files:** mọi tệp `status: IN_REVIEW` trong `FREEZE_SCOPE`; `T7/README.md`; `T7/03.design/prototype/README.md`; `T7/03.design/prototype/html/manifest.json`, `harness/workbench.js:458`, `index.html:28`, `CHANGELOG.md`; `T7/09.generated/registries/artifact-registry.{csv,json}`, `09.generated/indexes/package-checksums.sha256` (qua script)

- [x] **Step 1: README theme.** Frontmatter `version: v5.27.0`, `parent: v4.6.8`, `source_baseline: v5.26.1`, `semantic_delta: T7_G4_SPEC_FREEZE`. Đoạn liệt kê màn (khoảng dòng 120–135): viết lại theo danh sách màn hiện hành (bỏ mô tả `SCR-017` như màn đang dùng; mọi mã đã bỏ ghi "đã bỏ, xem RETIRED.md"). C2 `README.md:124` hết.
- [x] **Step 2: Phiên bản prototype.** `manifest.json` `"version": "5.27.0"`, `"parent": "5.26.1"`, `"status": "T7_G4_SPEC_FREEZE"`, `"scope"`: "T7-G4: chốt đặc tả FROZEN; không đổi giao diện", `"canonicalActiveScreens"` = số màn có tệp sau Task 1 (giữ `"screens"`) (đếm `ls T7/03.design/screens/SCR-*.md | wc -l`; ghi số vào Kết quả). `workbench.js:458` `version: "5.27.0"`. `index.html:28` badge `v5.27.0 · Chốt đặc tả (T7-G4)`. `prototype/README.md` `version: v5.27.0`, `source_baseline: v5.27.0`.
- [x] **Step 3: CHANGELOG** thêm đầu tệp mục `## [5.27.0] — T7-G4 chốt đặc tả`: không đổi giao diện; 9 màn sang RETIRED; Hub 090–096 viết lại; PAT viết lại; 5 đề xuất G3-7 ghi vào Screen Contract (1a–1e, prototype chưa có); 1f bỏ; 175 tệp `IN_REVIEW` → `FROZEN`.
- [x] **Step 4: Đổi trạng thái.** Mọi tệp trong `FREEZE_SCOPE` có dòng `status: IN_REVIEW` trong frontmatter: thay bằng `status: FROZEN`, thêm ngay dưới `frozen_at: v5.27.0`. Chỉ thay trong frontmatter (giữa hai dòng `---` đầu tệp). Không đụng tệp `DRAFT`. Đồng thời `INDEX.md` cột 4: `IN_REVIEW` → `FROZEN`.
- [x] **Step 5: Registry.** `python3 T7/03.design/prototype/html/tools/sync-registry.py`.
- [x] **Step 6: Kiểm.**
  - `check-spec.py --freeze` ⇒ `Lỗi theo nhóm: 0`, thoát 0; dòng `Trạng thái:` có `scope/DRAFT=35`, không có `IN_REVIEW`.
  - `grep -rl "status: DRAFT" T7 --include='*.md' | grep -v prototype | wc -l` ⇒ 36.
  - `grep -rn "5\.26\.1" T7/03.design/prototype/html/manifest.json T7/03.design/prototype/html/harness/workbench.js T7/03.design/prototype/html/index.html` ⇒ chỉ dòng `"parent"`.
  - `git diff --stat HEAD -- T7/03.design/prototype/html/app T7/03.design/prototype/html/styles` ⇒ rỗng.
- [x] **Step 7: Commit** `docs(spec): T7-G4 chốt đặc tả Theme 7 FROZEN v5.27.0`

### Task 8: T7-P và PLAN.md

**Files:** `docs/refactor/plans/T7/T7-P-thiet-ke-lai-luong.md`, `docs/refactor/PLAN.md`

- [x] **Step 1: T7-P mục 13.** Cột "Đã duyệt": 6 dòng "⬜ (chốt đặc tả 7.3)" (UC-13-01, UC-05-02/04, UC-10-02, UC-09-02, UC-08-04, UC-11-01…05) → `✅ 2026-11-09 (T7-G4 v5.27.0)`; dòng SCR-028 "cần chốt ở 7.3" thêm "— giữ (T7-G4 Q7)"; 5 dòng G3-7 (U5, Tóm tắt lặp, badge 048, số tiền mono, 037) → `✅ duyệt 2026-11-09 — ghi vào Screen Contract, Flutter ở T7-G5 (prototype chưa có)`; dòng "Đếm mù" / "Căn cứ" → `Bỏ (người dùng 2026-11-09)`. Mục 7.3 thêm "✅ xong ở T7-G4 (v5.27.0)". Mục 1 dòng 5 cột Kết quả thêm "FROZEN v5.27.0 (T7-G4)".
- [x] **Step 2: PLAN.md.** Dòng T7-G4 (mục Theme 7, bảng Plan): cột Plan `✅ [plan](plans/T7/T7-G4-chot-dac-ta.md)`, cột Làm `✅ 2026-11-09`; nội dung thêm "9 màn chưa dựng → RETIRED; Hub 090–096 viết lại; 5 đề xuất G3-7 vào đặc tả". Dòng Theme 7 ở "Theo dõi tiến độ": thêm "2026-11-09: T7-G4 ✅ (FROZEN v5.27.0); tiếp T7-G5". Dòng T7-G5 thêm: "backend T7-B: kết quả RPC nhận hàng / bàn giao / kiểm kê trả tồn vật lý trước / sau cho dòng 'Tồn kho đã đổi' (T7-G4 1a)". "Xong khi (UI)" của Theme 7: "73 màn active" → số màn đếm ở Task 7 Step 2 (= 70 màn active).
- [x] **Step 3: Kiểm.** `grep -c "⬜" ` trong khoảng mục 13 của T7-P (từ `## 13.` tới `## 14.`) ⇒ 0. `node .gitnexus/run.cjs detect-changes` ⇒ 0 symbol (chỉ Markdown heading).
- [x] **Step 4: Commit** `docs(refactor): T7-G4 cập nhật T7-P mục 13 và PLAN.md`

## 6. Rủi ro / lưu ý

- **`MARK` của script khá rộng** (vd "không còn", "gộp"): một dòng có thể lọt C2 dù vẫn dùng màn đã bỏ như màn hiện hành. Review đọc lại các dòng có mã trong `RETIRED.md` (`grep -rnE "SCR-0(02|04|05|06|16|17|18|20|22|23|24|27|52|54|57|58|60|61|64|69|73|75|76|80|87|88)"`).
- **1a cần dữ liệu tồn trước / sau** ở màn kết quả: backend T7-B phải trả `before` / `after` tồn vật lý trong kết quả RPC ghi nhận. Task 8 Step 2 ghi nhắc vào dòng T7-G5 của PLAN.md.
- **Số màn active** đổi (73 → số đếm sau Task 1, tính cả Hub). T7-G5 / T7-16 dùng số mới.
- `09.generated/registries/design/*` và `04.harness/` vẫn ghi màn cũ — chủ ý không sửa (tài liệu cũ); PAT không còn trỏ tới.

## 7. Kết quả

<!-- Phiên làm ghi ngay sau mỗi task: commit, tệp:dòng, lệch plan, script kiểm trước / sau. Không tự chấm ĐẠT. -->

### Task 8 (2026-11-09)
- **Commit:** `b9984ce87` (`docs(refactor): T7-G4 cập nhật T7-P mục 13 và PLAN.md`)
- **Tệp:** `docs/refactor/plans/T7/T7-P-thiet-ke-lai-luong.md`, `docs/refactor/PLAN.md`
- **Lệch plan:** Không.
- **Kết quả script kiểm:**
  - `grep -c "⬜"` trong khoảng mục 13 của T7-P = 0 (tất cả 12 dòng được cập nhật đúng: 6 dòng chốt đặc tả 7.3, dòng SCR-028, 5 dòng G3-7 ghi nhận vào Screen Contract, 1 dòng đếm mù/căn cứ bỏ).
  - GitNexus `detect-changes`: 0 symbol ứng dụng bị ảnh hưởng (chỉ có 13 Markdown heading trong docs).
  - PLAN.md: T7-G4 đánh dấu `✅ 2026-11-09`, T7-G5 ghi chú backend T7-B; số màn active cập nhật thành 70; theo dõi tiến độ cập nhật mốc hoàn thành T7-G4.

### Task 7 (2026-11-09)
- **Commit:** `c3916b577` (`docs(spec): T7-G4 chốt đặc tả Theme 7 FROZEN v5.27.0`)
- **Tệp:** 184 tệp đổi trạng thái sang `FROZEN` (`frozen_at: v5.27.0`), `README.md`, `prototype/README.md`, `manifest.json`, `workbench.js`, `index.html`, `CHANGELOG.md`, `INDEX.md`, registries/indexes qua `sync-registry.py` (tổng 194 tệp).
- **Lệch plan:** Không.
- **Kết quả script kiểm:**
  - `python3 specs/themes/theme-07/03.design/prototype/html/tools/check-spec.py --freeze`:
    `Trạng thái: other/ACTIVE=1, other/DRAFT=1, other/FROZEN=48, scope/DRAFT=35, scope/FROZEN=252`
    `Lỗi theo nhóm: 0` (thoát mã 0).
  - `canonicalActiveScreens` = 70 (`ls specs/themes/theme-07/03.design/screens/SCR-*.md | wc -l`).
  - `grep -rl "status: DRAFT" specs/themes/theme-07 --include='*.md' | grep -v prototype | wc -l` = 36.
  - `grep -rn "5\.26\.1" manifest.json workbench.js index.html`: chỉ còn dòng `"parent": "5.26.1"`.
  - `git diff --stat HEAD -- app styles` trong prototype: hoàn toàn rỗng.

### Task 6 (2026-11-09)
- **Commit:** `35a74ab87` (`docs(spec): T7-G4 viết lại PAT-UI-UX (K1–K7, DS mới) và PAT-NAV (Home Kho candidate)`)
- **Tệp:** `specs/themes/theme-07/03.design/patterns/PAT-UI-UX.md`, `specs/themes/theme-07/03.design/patterns/PAT-NAV.md`
- **Lệch plan:** Không.
- **Kết quả script kiểm:**
  - `grep -c "K[1-7]" PAT-UI-UX.md` = 10 (≥ 7).
  - `check-spec.py`: C5 = 0, C2 chỉ còn 1 lỗi duy nhất (`README.md:124`), C7 = 1 (`README.md` version).
  - Trạng thái `check-spec.py`: `scope/IN_REVIEW=184`, `scope/FROZEN=68`.

### Task 5 (2026-11-09)
- **Commit:** `039dd75ab` (`docs(spec): T7-G4 viết lại Hub SCR-090…096 theo khuôn Screen Contract và hub.js`)
- **Tệp:** `SCR-090.md` … `SCR-096.md` (7 tệp viết lại theo khuôn mới), `INDEX.md` (đổi trạng thái 7 màn sang IN_REVIEW)
- **Lệch plan:** Không.
- **Kết quả script kiểm:**
  - Kiểm tra 64/64 chuỗi cố định ở mục 8 của 7 tệp đều khớp 100% với `app/hub.js`.
  - `check-spec.py`: không sinh lỗi mới (giữ nguyên C2: 12, C5: 3, C7: 1).
  - Trạng thái `check-spec.py`: `scope/IN_REVIEW=182`, `scope/FROZEN=70`.

### Task 4 (2026-11-09)
- **Commit:** `4cc622066` (`docs(spec): T7-G4 ghi 5 đề xuất G3-7 đã duyệt vào Screen Contract (1a–1e)`)
- **Tệp:** `SCR-010`, `SCR-012`, `SCR-015`, `SCR-029`, `SCR-037`, `SCR-046`, `SCR-047`, `SCR-048`, `SCR-074` (9 tệp)
- **Lệch plan:** Không.
- **Kết quả script kiểm:**
  - `grep` "Đề xuất G3-7 duyệt 2026-11-09" đủ 9 tệp.
  - `grep -c "Tồn kho đã đổi"`: SCR-012 (2), SCR-029 (2), SCR-047 (2).
  - `check-spec.py`: không sinh lỗi mới (giữ nguyên C2: 12, C5: 3, C7: 1).

### Task 3 (2026-11-09)
- **Commit:** `d73a83514` (`docs(spec): T7-G4 ghi quy tắc duyệt K2 cho BJ-06/08/09/10/11 và Kế toán = chủ ở UC-13-01`)
- **Tệp:** `UC-09-02`, `UC-11-04`, `UC-13-01`, `BJ-06`, `BJ-08`, `BJ-09`, `BJ-10`, `BJ-11`, `SCR-040`, `SCR-046`, `SCR-050` (11 tệp)
- **Lệch plan:** Không.
- **Kết quả script kiểm:**
  - `grep` "gửi duyệt rồi tự duyệt" đủ 14 tệp (7 BJ + 7 UC).
  - `grep -c "chủ cửa hàng" UC-13-01*` = 1.
  - `check-spec.py`: không sinh lỗi mới (giữ nguyên C2: 12, C5: 3, C7: 1).

### Task 2 (2026-11-09)
- **Commit:** `fede97526` (`docs(spec): T7-G4 đổi tham chiếu SCR-027, 052, 054, 088 đã bỏ sang màn hiện hành`)
- **Tệp:** `00-use-case-map.md`, `UC-05-02`, `UC-05-04`, `UC-11-02`, `UC-11-03`, `UC-13-01`, `UIF-15-BJ-15.md`
- **Lệch plan:** Không.
- **Kết quả script kiểm:**
  - `check-spec.py`: C2 giảm còn 12 (đúng `README.md:124` + 11 dòng trong `PAT-NAV.md`).

### Task 1 (2026-11-09)
- **Commit:** `bb49e8d42` (`docs(spec): T7-G4 bỏ 9 màn chưa dựng (002, 004, 005, 020, 022–024, 060, 061) sang RETIRED`)
- **Tệp:** `RETIRED.md`, `INDEX.md`, `SCR-003.md`, `UC-01-02`, `UC-01-03`, `UC-01-05`, `00-use-case-map.md`, `UIF-01-BJ-01.md`, `UIF-04-BJ-04.md`; git rm 9 tệp SCR-*.md
- **Lệch plan:** Không.
- **Kết quả script kiểm:**
  - `check-spec.py`: C3 = 0, C4 = 0 (đã sửa cả SCR-006 thiếu ở INDEX); C2 = 23 (12 cũ + 11 dòng trong PAT-NAV.md: 67, 68, 69, 98); C5 = 3 (PAT-NAV: 26, 67, 68); C7 = 1.
  - Số màn FROZEN giảm 9 (86 → 77).

### Task 0 (2026-11-09)
- **Commit:** `95a08b42f` (`chore(spec): T7-G4 thêm tools/check-spec.py kiểm đặc tả Theme 7`)
- **Tệp:** `specs/themes/theme-07/03.design/prototype/html/tools/check-spec.py` (220 dòng)
- **Lệch plan:** Không.
- **Kết quả script kiểm mốc:**
  - `python3 specs/themes/theme-07/03.design/prototype/html/tools/check-spec.py`:
    `Trạng thái: other/ACTIVE=1, other/DRAFT=1, other/FROZEN=48, scope/DRAFT=35, scope/FROZEN=86, scope/IN_REVIEW=175`
    `Lỗi theo nhóm: {'C2': 12, 'C4': 1, 'C5': 1, 'C7': 1}` (thoát mã 1)
  - `python3 specs/themes/theme-07/03.design/prototype/html/tools/check-spec.py --freeze`:
    `Lỗi theo nhóm: {'C1': 175, 'C2': 12, 'C4': 1, 'C5': 1, 'C7': 1}`
  - Khớp 100% số liệu baseline tại mục 3.

## 8. Review

<!-- Chỉ phiên review ghi. -->
