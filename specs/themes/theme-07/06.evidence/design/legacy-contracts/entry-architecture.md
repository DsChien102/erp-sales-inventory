# Product Entry Architecture — Theme 7 Inventory

> Baseline **v1.7.0**. Đây là architecture/QA artifact. **Không mặc định render nội dung giải thích entry point, nguồn flow, actor handoff hoặc orchestration trong Product UI.** UI chỉ hiển thị context khi fact đó cần cho quyết định/thao tác hiện tại.

## 1. Entry classes

| Class | Ý nghĩa | Product UI implication |
|---|---|---|
| `MODULE_ENTRY` | Điểm vào chủ động từ module | Có thể global-discoverable |
| `CONTEXTUAL_DEEP_LINK` | Mở từ object/task đã biết | Parent context được truyền, không cần card giải thích entry |
| `CONTEXTUAL_ONLY` | Chỉ hợp lệ trong parent object | Không có menu riêng |
| `ACTOR_HANDOFF_TASK` | Task thuộc actor/session khác | Maker không auto-navigate sang approver |
| `IN_FLOW_SURFACE` | Bước trong một task | Không có global entry |
| `CONTEXTUAL_OVERLAY` | Sheet/detail phụ cho object hiện tại | Đóng overlay quay về đúng surface; không tạo loop navigation |
| `SYSTEM_RECOVERY` | Chỉ từ finality/state | Không discoverable |
| `RESULT` | Kết quả mutation | Không back về commit đã consume |

Workbench `UIF selector` là review tooling, không phải Product navigation.

## 2. Inventory Valuation — canonical entry/continuity

| BJ | Actor | Module/context entry | Active Product chain |
|---|---|---|---|
| BJ03 | Inventory Valuation | `SCR-014` module; assigned receipt có thể mở `SCR-015` | `SCR-014 → SCR-015 → SCR-017 → SCR-019`; provenance/conflict = contextual `VBottomSheet`, **SCR-016 retired active route** |
| BJ13 | Inventory Valuation | `SCR-085` module; assigned source component có thể mở `SCR-086` | `SCR-085 → SCR-086 → SCR-087 → SCR-088 → SCR-089` |
| BJ14 | Inventory Valuation | `SCR-072` module; dirty Product/Period scope có thể mở `SCR-073` | `SCR-072 → SCR-073 → SCR-074 → SCR-076 → SCR-077`; CALCULATING/BLOCKED/READY là state của SCR-074, **SCR-075 retired active route** |

## 3. Inventory Audit & Control — canonical entry/continuity

| BJ | Actor | Module/context entry | Active Product continuity |
|---|---|---|---|
| BJ08 | Stock-count maker / assigned counter / eligible approver | `SCR-042` module; assigned count may open `SCR-044`; approver task opens `SCR-046` | Maker: `SCR-042 → SCR-043 → SCR-044 → SCR-045 → pending`; approver is a **separate task** at `SCR-046`; result `SCR-047`. Cancellation originates from maker/session context, never as approver decision. |
| BJ09 | Inventory controller / eligible approver | `SCR-036` module; Product/Lot deep link may open `SCR-037`; approver task opens `SCR-038` in approval mode | `SCR-036 → SCR-037 → SCR-038`; maker and approver modes are mutually exclusive. System state movement resolves to `SCR-041`; `SCR-056` is read-only history. |
| BJ10 | Disposal maker / eligible approver / completion operator | `SCR-036` module; eligible non-sellable item may open `SCR-037`; approver/completion tasks re-enter `SCR-040` in their own mode | Maker request → separate approval → approved waiting state → separate physical completion task. Only completion assertion can route to decrement result `SCR-041`. |

### Group hard rules

- BJ08 book/system quantity is absent from blind-count DOM until first count submit.
- BJ09 expiry is derived from business date + expiry date; it is not a user-selected generic state transition.
- BJ09 generic state destination never includes valuation/return/RTV process states.
- BJ10 approval has **zero physical decrement**; completion assertion is required.
- UNKNOWN in all three is recovery for the same operation identity, not permission to create a new operation.

## 4. Correction & Recovery — canonical entry/continuity

| BJ | Actor | Module/context entry | Active Product continuity |
|---|---|---|---|
| BJ11 | Người phụ trách kho / approver độc lập | `SCR-048` module; operation context có thể mở `SCR-049`; assigned approval task mở `SCR-051` | Maker: `SCR-048 → SCR-049 → SCR-052`; cancel → `SCR-053`, correction → `SCR-050 → SCR-053:PENDING_APPROVAL`. Approver là **task riêng** `SCR-051 → system execution → SCR-053`. UNKNOWN handoff BJ17. |
| BJ16 | Người phụ trách kiểm soát kho | `SCR-078` module; discrepancy/case context có thể mở `SCR-079` | `SCR-078 → SCR-079`; route theo evidence. Projection recovery chỉ khi ledger proven correct: `SCR-080 → SCR-081 → SCR-082 → SCR-083`. Source/correction/UNKNOWN/escalation handoff owner phù hợp. |
| BJ17 | Người phụ trách kiểm soát kho | `SCR-078` worklist; UNKNOWN/source-waiting context có thể mở `SCR-079` | `SCR-078 → SCR-079 → SCR-080 → SCR-082 → SCR-083`; thiếu evidence → `SCR-083:ESCALATED`. Same identity/content; không blind retry/new operation. |

### Group hard rules

- Maker submit của BJ11 kết thúc ở trạng thái chờ; không collapse maker/approver thành một session.
- BJ16 không “sửa cho khớp”: ledger/source/projection phải được phân loại bằng evidence trước khi route.
- Nghi ngờ ledger integrity không được auto rebuild/correction.
- BJ17 `UNKNOWN ≠ FAILED`; evidence commit không được ghi movement/value/outbox lần hai; evidence no-commit chỉ tiếp tục cùng identity/content.
- Entry/handoff/recovery architecture chỉ nằm trong flow/contracts/Inspect; không render thành Product helper/banner.

## 5. Cross-BJ ownership

- BJ02 có thể tạo lượng `VALUATION_PENDING`; warehouse không bị auto-navigate sang BJ03.
- BJ03 xác nhận initial valuation. First direct valuation có thể bootstrap official cost theo decision hiện hành; đây không thay thế reconciliation/publish của cost run.
- BJ13 chỉ ghi value-only late cost sau initial valuation và đánh dấu Product+Period dirty; không đổi quantity và không tự publish official cost.
- BJ14 tạo immutable cost run, tính hai phương pháp trên cùng snapshot và publish theo method policy đã khóa. Input thay đổi sau khi run bắt đầu → successor run mới; run cũ không sửa/reuse.

Các quan hệ trên thuộc architecture/SRS/Inspect. **Không hiển thị tên BJ, flow ID hoặc lời giải thích orchestration trong app UI.**

## 6. QA gate — Journey continuity

Mỗi active screen phải có contract trả lời `ENTRY_CLASS`, `ACTOR_OWNER`, `PARENT_CONTEXT`, `BACK_TARGET`, `REENTRY`, `FINALITY` ở artifact này/flow contract. UI QA tách riêng:

- `DECISION_CONTEXT_ONLY`: UI chỉ giữ facts ảnh hưởng quyết định hiện tại.
- `NO_ARCHITECTURE_EXPLANATION_UI`: không card/banner/helper chỉ để giải thích task đến từ đâu hoặc màn này có vai trò gì.
- `NO_GHOST_NAV`: retired/recovery/result không thành menu destination.
- `NO_ACTOR_COLLAPSE`: maker/approver không bị nối thành một session.
- `NO_LOOP_FOR_READ_ONLY_DETAIL`: provenance/calculation phụ dùng contextual overlay nếu không phải mental task độc lập.
