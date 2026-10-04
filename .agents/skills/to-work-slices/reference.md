# Work Slice — một outcome, một file

SSOT trạng thái design: **`CATALOG.md`** trong harness theo BJ.
`design_status` chỉ trên catalog.

**Skills:** `/to-work-slices` (publish `IN_REVIEW`) → `/review-work-slices` (làm kín bar B → user OK → `READY`) → `/implement-work-slice`.
**READY** chỉ do `/review-work-slices` ghi.

**Bar B:** agent implement xong cả outcome từ slice mà không bịa field và không hỏi thêm. Hành vi khớp SRS. Technical contract nằm đủ trong slice. Surface, AC, layout của mọi mục có mặt đều kín, kèm link nguồn đọc được.
**Golden:** [examples/golden-family/](examples/golden-family/) (`EXAMPLE_ONLY`).
**Skeleton:** `specs/themes/theme-template/04.harness/BJ-xx-harness/`.

**Spacing:** tối đa một dòng trống giữa block.
**Fence:** source, directory tree, hoặc ASCII hiếm. Diagram dùng Mermaid.
**Trace:** key đúng loại (`BJ`/`CAP`, `UC`/`OP`, `BC`/`API`). YAML không có User Story.

---

## File

```text
BJ-<id>-harness/
    CATALOG.md
    SL-001-<slug>.md
    SL-002-<slug>.md
```

- Flat. Một file = một outcome = một `SL-id`.
- Tên: `SL-NNN-<slug>.md`.
- Có UI: file gồm Contracts và Presentation. Không UI: không có mục Presentation; Out of Scope ghi `Presentation`.
- Path harness suy từ theme. Theme-07 dùng `04.harness/`.

---

## Heading

Không đánh số. Thứ tự H2:

1. Objective
2. Blocked by
3. Scope & Rules
4. Flow
5. Design
6. Contracts
7. Presentation
8. Verification
9. Open Questions

Bốn mục luôn có: Objective, Blocked by, Scope & Rules, Verification.
Năm mục kia chỉ có khi đúng cò. Ngoài menu này không thêm H2.

| H2 | Có mặt khi |
| --- | --- |
| Flow | Outcome nhiều bước, hoặc có nhánh lỗi nghiệp vụ |
| Design | Đổi domain, persistence, transaction, hoặc file code |
| Contracts | Publish hoặc consume Command, Query, DTO, hoặc integration |
| Presentation | Có màn hình hoặc tương tác trên app |
| Open Questions | Còn việc chưa chốt. Đứng cuối file, sau Verification. Câu còn chặn thì chưa `READY` |

Mục không có mặt: xóa hẳn heading. Out of Scope gọi tên từng H2 optional đã xóa, trừ Open Questions. Hết câu thì xóa H2 đó, không ghi vào Out of Scope.

### Scope & Rules

Luôn đủ H3: In Scope, Out of Scope, Boundary, Rules.
Rules là bảng ID | quy tắc. Slice không thêm rule mới thì một dòng trỏ rule nguồn.

### Objective và Blocked by

Objective: một câu outcome.
Blocked by: `None`, hoặc link file slice cùng harness, và/hoặc GitLab `#N` / URL. Khớp `depends_on` trên catalog.

### Flow

Có mục thì có Main Flow: Mermaid khi diễn được, happy path tối đa 5 bước.
Failure Flow chỉ khi có nhánh lỗi nghiệp vụ. Mỗi dòng: condition, outcome, side-effect không xảy ra.

### Design

H3 đóng, chỉ H3 nào slice đụng:

| H3 | Khi có | Tối thiểu |
| --- | --- | --- |
| Domain | Đổi state | Before / After hoặc state |
| Persistence | Đổi bảng hoặc RPC | Mỗi bảng vật lý một table cột. Có FK thì một `erDiagram`. Đường `_drafts/`, field và RPC đủ để implement. Body SQL không bắt buộc |
| Transaction / Idempotency | Mutation | `idempotencyKey` khác `command.id`. UK `(tenant_id, command_scope, idempotency_key)` cùng transaction với business và outbox |
| Code Layout | Tạo hoặc sửa file | Một cây `modules/` và `apps/` nếu cả hai đổi. Mỗi segment một dòng, indent 4 space. Mọi file slice đụng |

Mỗi bảng vật lý: dòng «Bảng `schema.bảng`», rồi table `Cột | Kiểu | Null | Ràng buộc`. Unique cấp bảng và index, kể cả `WHERE`, một dòng dưới table. Có FK thì một `erDiagram` đứng trước các table đó. Thực thể gồm bảng slice tạo hoặc sửa và bảng đầu kia của FK. Nhãn quan hệ là cột FK. Unique từng phần ghi trên nhãn. Bảng dùng chung: link file SQL nguồn trên dòng tên, copy đủ cột, kiểu, null, ràng buộc. RPC và mã lỗi giữ một dòng một mục.

Query xóa Transaction / Idempotency.
Design không đụng concern nào ở bảng thì xóa cả mục Design.

### Contracts

Mỗi Command, Query, DTO là một H3. Command và Query có blockquote 1–2 câu, rồi Dart fence đủ field. DTO có fence đủ field.
Integration là H3 khi có fact outbox hoặc `integration_commands`.
Không có type và không có Integration thì xóa cả mục Contracts.
Technical contract đủ field trong fence. SRS im về tên kỹ thuật thì slice ghi quyết định đó.

Fact outbox: `{context}_{entity}_{past}.v1`. Handoff: `integration_commands`. Outbox không mang yêu cầu đi làm việc (`*.requested`, apply, retry, reconcile).

### Presentation

Có mục thì đủ năm H3, theo thứ tự: Screens, Route, State × feedback, Design system, Mediator.
State × feedback có loading, empty, error, success.
Mediator: `IModuleMediator`, fake khớp Contracts, presentation trong `apps/erp` hoặc `apps/admin`.
Cây file nằm ở Design → Code Layout.

### Verification

| H3 | Khi có |
| --- | --- |
| Acceptance Criteria | Luôn. Checklist `- [ ] **AC-0n**` Given / When / Then |
| Tests | Luôn. Cột Test id, Given / When / Then, Layer |
| Scenarios | Khi có Presentation. Cột Scenario, Actor, Across, Given / When / Then, Seed / fixture, Pass / fail |

### Open Questions

H2 cuối. Chỉ khi còn câu chưa chốt. Câu còn chặn thì chưa `READY`.

---

## Nguồn

SRS khóa luồng nghiệp vụ: Objective, Flow, Rules, Acceptance Criteria.
Slice khóa technical contract trong Design và Contracts: RPC, `p_*`, bảng, DTO, mã lỗi, path module, cách gắn idempotency và outbox cho outcome này.

SRS im về tên kỹ thuật: slice ghi quyết định. SRS chưa khóa hành vi: Open Questions, chưa `READY`. SRS trái hard rule: Open Question nêu cả hai nguồn. Slice không sửa SRS.

Đụng seam đang có (bảng, RPC, file, command đã tồn tại): một dòng ngay dưới H3 liên quan. Dòng nói dùng lại cái gì, hoặc từ chối seam nào. Không có seam thì không thêm dòng. Dòng seam không vào bảng Rules.

---

## CATALOG.md

| Cột | Ý nghĩa |
| --- | --- |
| `id` | Link `[SL-NNN](SL-NNN-<slug>.md)`. Chưa có file thì ID trần |
| `title` | Tiêu đề ngắn |
| `design_status` | Bảng dưới |
| `depends_on` | `SL-id` outcome khác trong cùng catalog |
| `usecase` | Link markdown tới file UC. Nhiều UC cách nhau bằng dấu phẩy. Không UC thì để trống |
| `blocked_reason` | Có khi `BLOCKED` |

`design_status`:

| Status | Nghĩa |
| --- | --- |
| `DRAFT` | Đang viết |
| `IN_REVIEW` | Chờ review design |
| `READY_TO_IMPLEMENT` | Bar B kín. Mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`. Chỉ `/review-work-slices` ghi, sau user OK |
| `BLOCKED` | Dừng design hoặc implement. Có `blocked_reason` |
| `VERIFIED` | Code của cả outcome xong và code-review sạch. `/implement-work-slice` ghi |

YAML trên file slice: `id`, `journey`, `usecase`, `sources`, `theme`. Fixture `EXAMPLE_ONLY` được thêm `sample_status`.

---

## Blocking

- Blocked by trên file = cạnh giao việc.
- `depends_on` trên catalog = cửa `READY` và thứ tự implement.
- Hai nơi khớp nhau.
- Frontier = outcome không còn blocker chưa xong.

---

## Checklist trước READY_TO_IMPLEMENT

- [ ] Đủ Objective, Blocked by, Scope & Rules, Verification. Không H2 ngoài menu. Không mục Delivery
- [ ] Mỗi H2 optional vắng mặt được gọi tên trong Out of Scope, trừ Open Questions
- [ ] Scope & Rules đủ In Scope, Out of Scope, Boundary, Rules
- [ ] Open Questions, nếu có, là H2 cuối sau Verification. Câu còn chặn thì chưa READY. Hết câu thì không còn H2 đó
- [ ] Flow / Design / Contracts / Presentation, nếu có, đạt tối thiểu ở bảng Heading
- [ ] Bảng vật lý đúng dạng Persistence. Có FK thì có `erDiagram`
- [ ] Hành vi (Flow, Rules, Acceptance Criteria) khớp SRS. Lệch hành vi thì ghi rõ, hoặc còn Open Question
- [ ] Technical contract đủ trong Design và Contracts. Tên kỹ thuật không chờ SRS
- [ ] Seam đang có thì một dòng dưới H3 liên quan
- [ ] Blocked by khớp `depends_on`
- [ ] Mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`
- [ ] Hàng `CATALOG.md` cập nhật. `BLOCKED` thì có `blocked_reason`
