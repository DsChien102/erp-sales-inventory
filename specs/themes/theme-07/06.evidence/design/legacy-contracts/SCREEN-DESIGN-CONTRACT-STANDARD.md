# VET45 Theme 7 — Screen Design Contract Standard v3

> Scope pilot: `BJ-02 / UIF-02`.
> Mục tiêu: biến mỗi Screen file thành đầu vào trực tiếp cho UX/UI design và HTML prototype, đồng thời khóa chính xác cách screen dùng Flutter Design System mà không tạo một HTML Design System thứ hai.

## Nguyên tắc nguồn

1. **BJ/UC/BC/API** sở hữu nghiệp vụ, rule, lifecycle, permission và transaction effect.
2. **UIF** sở hữu luồng giữa các screen, actor handoff và transition.
3. **Screen Design Contract** sở hữu trải nghiệm trên một surface: người dùng cần hiểu gì, thấy gì, làm gì, phản hồi gì và đi đâu tiếp.
4. **Flutter Design System** là nguồn duy nhất cho token/component/public props/variant/state/default implementation.
5. **UIF Component Usage Profile** chỉ pin cách dùng DS cho pilot; không định nghĩa token hoặc component mới.
6. **HTML prototype** là renderer để kiểm chứng Screen Contract + Flutter DS, không phải source of truth mới.

## Cấu trúc chuẩn của một Screen file

### 1. Identity & trace
Metadata ổn định: Screen ID, surface type, BJ/UC/UIF, actor, primary object.

### 2. Experience contract
Trả lời:
- Người dùng đang cố hoàn thành việc gì?
- Họ phải hiểu điều gì ngay?
- Hệ thống phải tự quyết định/prefill điều gì?
- Khi nào screen hoàn thành?
- Điều gì tuyệt đối không được xảy ra?

### 3. Navigation & continuity
Entry, primary path, alternate path, Back/Cancel, resume, actor handoff. Đây là nơi duy nhất mô tả screen-to-screen behavior.

### 4. Information & interaction model
Information hierarchy, ownership của dữ liệu và direct interaction. Chỉ giữ dữ liệu phục vụ task; technical evidence để on-demand.

### 5. Action contract
Mỗi user action có: label, role, trigger, visibility/precondition, input/confirmation, processing, success destination, failure/recovery.

### 6. State & feedback contract
Chỉ state làm thay đổi trải nghiệm. Không expose polling/retry/internal step thành business state.

### 7. Screen scenarios
UX/screen-flow fixtures: entry context → user sees → user action → expected next surface/feedback.

### 8. Component Composition Contract
Đây là phần **render contract**.

Không dùng danh sách mơ hồ kiểu “screen có VCard, VButton...”. Thay vào đó phải xác định:

- **slot** nào trên screen;
- public Flutter **component** nào;
- named **usage profile** nào;
- public **props/variant** nào được pin;
- content lấy từ đâu;
- visibility theo state/context;
- interaction/action nào;
- Theme composition nào được tạo từ các DS components.

#### Precedence

`Screen props` → `UIF usage profile` → `Flutter DS public default`.

#### Quy tắc

- Dùng đúng tên prop Flutter (`centerTitle`, `actions`, `showBackButton`...), không dùng alias tưởng tượng.
- Prop ảnh hưởng trực tiếp visual/interaction mà screen cần khóa phải được ghi tường minh.
- Prop không cần override được phép inherit từ Flutter DS default.
- `null` có ý nghĩa. Ví dụ `actions: null` = không có trailing AppBar action.
- Không ghi token value/pixel/style mà component đã sở hữu.
- Icon phải map tới `VIcons`.
- Theme composition phải liệt kê `composedFrom`.
- Structural primitives (`Column`, `Row`, scroll/list container hoặc HTML wrapper) chỉ làm layout, không sở hữu visual semantics.

Ví dụ:

```yaml
shell:
  profile: screen.shell.standard
  component: VPageScaffold
  resolvesToAppBar: VAppBar
  props:
    title: "Nhận hàng"
    subtitle: null
    showBackButton: false
    centerTitle: false
    actions: null
```

Kết quả: renderer **không có quyền** căn giữa title hoặc tự thêm icon/action bên phải.

### 9. Design gate
Open question/blocker. HTML high-fidelity chỉ bắt đầu khi không còn `BUSINESS_BLOCKER` ảnh hưởng interaction và Component Composition Contract không còn slot visual chưa map.

## “Don't make me think” guardrails cho Theme 7

- Một screen = một user task chính.
- Một primary action tại một thời điểm.
- Card/row có hành vi click thì click toàn vùng; không thêm CTA “Mở” dư thừa.
- Hệ thống tự routing/policy khi đã đủ dữ liệu.
- Prefill dữ liệu có thể suy ra an toàn.
- Form dài dùng progressive disclosure.
- Validation đặt sát lỗi, giữ input, focus lỗi đầu tiên.
- Review ưu tiên khác biệt/rủi ro/điểm quyết định.
- Approval chỉ hiển thị evidence cần để quyết định.
- `UNKNOWN` không phải “Thất bại”; chủ động query/reconcile.
- Multi-actor flow phải thể hiện handoff.
- Back phải dự đoán được và giữ draft khi an toàn.

## Component contract gate

Một screen chỉ `READY_FOR_HTML` khi:

1. shell/app bar được khóa;
2. mọi visible block có component/profile;
3. mọi CTA/action có component + variant/tone/placement;
4. mọi overlay có launcher + component + input/actions;
5. every state-specific substitution được xác định;
6. không có visual component “custom CSS only”.
