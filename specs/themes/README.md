# VET45 Harness Doctrine

> **Phiên bản:** Draft v0.10  
> **Ngày:** 2026-09-18  
> **Phạm vi:** VET45; có thể phát triển tiếp thành học thuyết dùng chung cho AGAPI  
> **Pilot tham chiếu:** Theme 7 — Kho & Giá vốn  
> **Trạng thái:** DRAFT_FOR_REVIEW

---

# 1. Mục đích

Harness Doctrine xác định cách VET45 tổ chức **tri thức, yêu cầu, thiết kế, kiến trúc và công việc triển khai** để con người và AI có thể làm việc trên phạm vi lớn hơn mà vẫn giữ được khả năng kiểm soát.

Doctrine giải quyết bốn vấn đề cốt lõi:

1. BA và Tech đang phân rã công việc theo những cấu trúc khác nhau, làm tăng nguy cơ **thiếu việc, chồng việc và hiểu khác nhau**.
2. Việc BA bàn giao một khối tài liệu/design rồi kỳ vọng Tech tự đọc, tự bóc tách và triển khai đúng phụ thuộc quá nhiều vào **niềm tin**.
3. AI làm tăng mạnh năng lực thực thi, nhưng cũng làm tăng rủi ro nếu AI được phép tự đọc toàn bộ yêu cầu, tự xác định phạm vi, tự lập kế hoạch và tự lấp những chỗ còn thiếu.
4. Kiến trúc, backend và frontend cần được chia thành những **đơn vị công việc nhỏ, có ranh giới, phụ thuộc và đầu ra rõ ràng**.

Harness không phải cách để AI được tự do làm nhiều việc hơn. Harness là **cách tổ chức và kiểm soát việc thực thi**.

> **Harness không thay con người bằng AI. Harness tổ chức tri thức, quyết định, thiết kế và kiến trúc thành những ranh giới đủ rõ để con người và AI có thể thực thi nhanh mà không đánh mất quyền kiểm soát.**
>
> **Mục tiêu không phải để một người hay một agent hiểu cả hệ thống. Mục tiêu là để mỗi vai trò hiểu đúng phần mình phụ trách, biết rõ phần nào được phép thay đổi và chứng minh được đầu ra của mình.**
>
> **Nguyên lý trung tâm:** AI càng có năng lực thực thi lớn, phạm vi được phép quyết định càng phải rõ, nhỏ và có thể kiểm tra.

---

# 2. Mô hình ngôi nhà và phân rã công việc

VET45 được tổ chức như **một ngôi nhà**. Phần dưới là nền móng tri thức, nghiệp vụ và kiến trúc; phần trên là hành vi và trải nghiệm mà người dùng nhìn thấy.

Vai trò trong mô hình:

- **BA**: bao gồm BA và công việc thiết kế UI/UX hiện tại.
- **SA**: chịu trách nhiệm chính về kiến trúc hệ thống.
- **SE**: bao gồm cả công việc backend và frontend; trong Harness vẫn giữ hai loại **BE Slice** và **FE Slice** để phân biệt phạm vi công việc.

## 2.1 Sơ đồ trung tâm

```text
                              ┌────────────────────────────┐
                              │   BUSINESS JOURNEY [BA]    │
                              │   Trải nghiệm end-to-end   │
                              └─────────────┬──────────────┘
                                            │
                    phân rã nhu cầu         │      hiện thực / đối chiếu
                                            │
                        ┌───────────────────┴───────────────────┐
                        │                                       ▲
                        │                                       │                           
            ┌───────────▼────────────┐             ┌────────────────────────┐
            │     PROTOTYPE [BA]     │             │      USE CASE [BA]     │ ───► BE SLICE [SE]
            │      Final design      │             │    Outcome nguyên tử   │
            └────────────────────────┘             └────────────▲───────────┘
                        │ phát sinh                             │ hiện thực hóa
                        │                                       │
            ┌───────────▼────────────────────────────────────────────────────┐
            │                     SCREEN CONTRACT [BA]                       │ ───► FE SLICE [SE]
            │       Bề mặt tương tác · state · action · data · feedback      │
            └───────────────────────────────▲────────────────────────────────┘
                                            │
            ┌───────────────────────────────┴─────────────────────────────────┐
            │                        ARCHITECTURE [SA]                        │ ───► SA SLICE [SA]
            │           Aggregate · Read Model · Foundation · Integration     │
            └───────────────────────────────▲─────────────────────────────────┘
                                            │
            ┌───────────────────────────────┴─────────────────────────────────┐
            │                       DOMAIN + ENTITY [BA/SA]                   │
            │       Khái niệm · quyền sở hữu · lifecycle · Điều kiện bắt buộc │
            └───────────────────────────────▲─────────────────────────────────┘
                                            │
            ┌───────────────────────────────┴─────────────────────────────────┐
            │                    QUYẾT ĐỊNH NGHIỆP VỤ [BA]                    │
            └───────────────────────────────▲─────────────────────────────────┘
                                            │
            ┌───────────────────────────────┴─────────────────────────────────┐
            │                         KNOW-HOW [BA]                           │
            └─────────────────────────────────────────────────────────────────┘
                                         NỀN MÓNG
```


Sơ đồ giữ phần **ngôi nhà** cân đối và chỉ đặt ba loại Slice ở bên ngoài, đúng tầng phát sinh công việc. Các chi tiết như **Application Command/Query**, **Aggregate behavior**, API/Event được giải thích bên dưới thay vì đưa thêm tầng vào sơ đồ.

## 2.2 Cách đọc mô hình

Mô hình có hai chuyển động bổ sung cho nhau.

**Từ dưới lên**, Know-how và Quyết định nghiệp vụ hình thành Domain + Entity; Domain trở thành nền cho Architecture. Architecture không được tổ chức theo từng Use Case, mà theo những ranh giới bền vững như Aggregate, Read Model, Foundation và Integration.

**Ở tầng sản phẩm**, Business Journey được BA phân rã thành Use Case. Use Case làm phát sinh nhu cầu về một hoặc nhiều Screen Contract. Screen Contract được hiện thực hóa thành Prototype; Prototype quay lại **đối chiếu và hiện thực hóa Business Journey** mà người dùng thực sự trải qua.

Ba loại Slice nằm cạnh đúng nơi phát sinh công việc:

- **SA Slice** xuất phát từ Architecture.
- **BE Slice** xuất phát từ Use Case.
- **FE Slice** xuất phát từ Screen Contract.

Các quan hệ này không phải 1-1. Một Aggregate hoặc Read Model có thể phục vụ nhiều Use Case; một Use Case có thể dùng nhiều Screen và nhiều thành phần kiến trúc; một Screen cũng có thể phục vụ nhiều Use Case.

### Application Command/Query và hành vi của Domain

Cần phân biệt hai tầng thường cùng được gọi là “Command/Query”:

```text
Use Case
   │
   ▼
Application Command / Query        ← BE Slice [SE]
   │
   ▼
Application orchestration
   │
   ├── Aggregate behavior          ← SA Slice [SA]
   ├── Read Model
   └── Foundation / Integration khi cần
```

**Application Command / Application Query** biểu diễn yêu cầu đi vào tầng Application và thường thuộc **BE Slice**. Chúng được tổ chức theo Use Case và có thể phối hợp nhiều Aggregate, Read Model hoặc capability.

**Aggregate behavior / Domain Operation** là hành vi vốn có của Domain, ví dụ `addItem()`, `submit()`, `canSubmit()` hoặc một phép tính nghiệp vụ. Chúng được thiết kế từ bản chất của Domain và thuộc phạm vi **Architecture / SA Slice**, không phụ thuộc một Use Case cụ thể.

**API và Event là ranh giới kỹ thuật được công bố khi cần**, không phải một tầng riêng của “ngôi nhà”. Thông thường BE Slice hiện thực API/Event phục vụ Use Case; SA Slice tham gia khi ranh giới đó mang tính kiến trúc dùng chung, cross-domain hoặc integration nền tảng. FE Slice sử dụng các interface đã được công bố để hiện thực Screen.

## 2.3 Cách chia việc bám theo mô hình

| Slice | Owner | Điểm neo | Trách nhiệm chính |
|---|---|---|---|
| **SA Slice** | SA | Architecture | Xây mới hoặc thay đổi Aggregate, Read Model, Foundation, Integration và các ranh giới kiến trúc liên quan |
| **BE Slice** | SE | Use Case | Hiện thực outcome của UC bằng Application Command/Query, application orchestration, sử dụng Architecture và công bố API/Event khi cần |
| **FE Slice** | SE | Screen Contract | Hiện thực Screen thành giao diện chạy được, đủ state/action, sử dụng interface đã công bố và khớp Prototype |

Các nguyên tắc triển khai:

1. **SA đi theo nền tảng trước.** Aggregate, Read Model và Foundation được tổ chức theo ranh giới nghiệp vụ và kỹ thuật bền vững, không theo từng UC.
2. **BE Slice đi theo Use Case.** SE không tự suy ra outcome từ BJ hoặc Screen; UC là đầu vào chính để triển khai hành vi backend.
3. **FE Slice đi theo Screen Contract.** SE không tự suy ra giao diện từ Prototype; Prototype là hiện thực hóa cuối, còn Screen Contract giữ ranh giới tương tác cần triển khai.
4. **Domain + Entity là vùng phối hợp BA/SA.** BA xác định nghĩa nghiệp vụ; SA cùng tham gia để đảm bảo các ranh giới này có thể trở thành nền cho kiến trúc mà không làm sai nghĩa nghiệp vụ.
5. **Không tạo kiến trúc cục bộ trong BE/FE Slice.** Nếu triển khai phát hiện thiếu Aggregate, Read Model, Foundation hoặc Integration dùng chung, phần thiếu phải quay về Architecture và được xử lý bằng SA Slice.
6. **Slice không sao chép lại tài liệu nguồn.** Slice chỉ nêu phạm vi, nguồn đầu vào, đầu ra, phụ thuộc và cách kiểm tra.

---

# 3. Kết luận

Harness Doctrine đưa **nguồn tài liệu và cách chia việc về cùng một mô hình**. BA không còn bàn giao một khối SRS/Design để Tech tự giải nghĩa; SA và SE cũng không tạo một hệ phân rã công việc tách rời khỏi nguồn ban đầu.

Ngôi nhà tạo ra ba ranh giới rõ:

- **BA** tổ chức tri thức, quyết định, hành vi và trải nghiệm người dùng.
- **SA** xây nền kiến trúc dùng chung và bảo vệ các ranh giới hệ thống.
- **SE** hiện thực Use Case và Screen thông qua BE Slice và FE Slice.

Khi các lớp được nối trực tiếp với nhau, Harness có thể kiểm soát công việc theo phạm vi nhỏ hơn mà vẫn giữ được **tính liên tục từ Business Journey đến implementation**. AI có thể làm nhanh hơn và trên phạm vi lớn hơn, nhưng không cần — và không được — tự quyết định lại cấu trúc yêu cầu hoặc kiến trúc ngoài Slice được giao.

> **Một nguồn rõ ràng. Một ranh giới trách nhiệm rõ ràng. Một Slice đủ nhỏ để kiểm soát. Và mọi đầu ra đều phải lần ngược được về lý do nó tồn tại.**

---

# Phụ lục A — Vòng đời tài liệu và Slice

Phụ lục này chỉ quy định cách hiểu trạng thái, để tránh nhầm giữa **đã khóa nội dung** và **đã triển khai xong**.

## A.1 Tài liệu chuẩn

```text
DRAFT
  ↓
IN_REVIEW
  ↓
FROZEN
```

`FROZEN` nghĩa là tài liệu đã đủ ổn định để phần phụ thuộc sử dụng. Nếu thay đổi sau đó, các phần liên quan phải được xem lại theo phạm vi ảnh hưởng.

## A.2 Slice

```text
DRAFT
  ↓
IN_REVIEW
  ↓
FROZEN
  ↓
IMPLEMENTING
  ↓
VERIFIED
```

`BLOCKED` có thể xuất hiện trước `VERIFIED` khi dependency hoặc đầu vào chưa đủ.

`FROZEN` của Slice nghĩa là **scope và thiết kế của Slice đã được khóa để có thể triển khai**, không có nghĩa implementation đã hoàn tất.

---

# Phụ lục B — Cấu trúc thư mục và Directory Contract

Phụ lục này mô tả **cách repository được tổ chức**, không phải luồng phát triển bắt buộc.

Các nhãn `[BA]`, `[BA/SA]`, `[SA]`, `[SA/SE]`, `[SE]`, `[HARNESS]`, `[QA]`, `[SHARED]` là **owner chính**, không phải một phần của tên thư mục thật.

## B.1 Cây thư mục cơ bản

```text
theme-xx/
│
├── [SHARED] README.md
│
├── [BA] knowledge/
│   ├── know-how/
│   ├── decisions/
│   └── glossary/
│
├── [BA] specification/
│   ├── overview/
│   ├── behavior/
│   │   ├── journeys/
│   │   ├── use-cases/
│   │   └── behavioral-contracts/
│   └── [BA/SA] domain/
│       ├── domain-foundation/
│       └── entities/
│
├── [BA] design/
│   ├── screens/
│   ├── patterns/
│   ├── design-system/
│   └── prototype/
│
├── [SA] architecture/
│   ├── aggregates/
│   ├── read-models/
│   ├── foundations/
│   ├── integrations/
│   └── nfr/
│
│
├── [HARNESS] harness/
│   ├── [SA] sa-slices/
│   ├── [SE] be-slices/
│   ├── [SE] fe-slices/
│   └── manifests/
│
├── [SA/SE] procedures/
│
├── [QA/SHARED] evidence/
│   ├── specification/
│   ├── design/
│   ├── implementation/
│   └── release/
│
└── [HARNESS] generated/
    ├── registries/
    ├── matrices/
    └── indexes/
```


## B.2 Directory Contract

| Khu vực | Owner chính | Mục đích | Tiêu chuẩn đầu ra |
|---|---|---|---|
| `README.md` | Shared | Điểm bắt đầu của Theme | Scope ngắn gọn; cây thư mục; owner; link tới tài liệu chính; không lặp nội dung chi tiết |
| `knowledge/know-how/` | BA | Lưu tri thức nghiệp vụ, pháp lý, vận hành và phương pháp | Bối cảnh rõ; có nguồn khi cần; phân biệt dữ kiện, diễn giải và đề xuất |
| `knowledge/decisions/` | BA | Lưu Quyết định nghiệp vụ đã chốt | ID ổn định; quyết định; lý do; phạm vi; trạng thái; link đến nội dung bị chi phối |
| `knowledge/glossary/` | BA | Chuẩn hóa ngôn ngữ của Theme | Một thuật ngữ có một nghĩa thống nhất trong phạm vi Theme |
| `specification/overview/` | BA | Xác định mục tiêu, phạm vi và ranh giới Theme | Purpose; in/out scope; actor; cross-theme boundary; high-level BJ/Domain map |
| `specification/behavior/journeys/` | BA | Mô tả Business Journey end-to-end; UI Flow nằm trong BJ | Objective; boundary; actor; main flow; UC map; exception; interaction flow; screen transition; handoff; outcome |
| `specification/behavior/use-cases/` | BA | Định nghĩa outcome nghiệp vụ nguyên tử dùng để bàn giao và nghiệm thu | Actor; trigger; outcome; precondition; behavior; exception; business effect; BC; Screen; acceptance scenario |
| `specification/behavior/behavioral-contracts/` | BA | Định nghĩa quy tắc hành vi dùng chung cho nhiều UC | Intent; precondition; business rule; Điều kiện bắt buộc; state effect; finality; result/failure semantics |
| `specification/domain/domain-foundation/` | BA/SA | Định nghĩa Domain, phạm vi sở hữu, vòng đời và Điều kiện bắt buộc ở mức nghiệp vụ | Domain map; quyền sở hữu; business rules; lifecycle; cross-domain boundary; liên kết Decision |
| `specification/domain/entities/` | BA/SA | Định nghĩa đối tượng dữ liệu nghiệp vụ và quan hệ | Ý nghĩa; identity; thuộc tính chính; quan hệ; Domain sở hữu; lifecycle/constraint nghiệp vụ |
| `design/screens/` | BA | Tài liệu chuẩn cho từng Screen | Screen ID; purpose; UC; entry/exit; data; actions; states; validation; feedback; permission; component composition; prototype reference |
| `design/patterns/` | BA | Lưu pattern tương tác/bố cục dùng chung | Phạm vi áp dụng; phần bắt buộc; phần được thay đổi; mapping Design System |
| `design/design-system/` | BA | Khai báo Design System mà Theme sử dụng | Version; component subset; extension/exception được chấp thuận |
| `design/prototype/` | BA | Lưu Final Design có thể chạy/tương tác | Current build chạy được; khớp Screen Contract; mapping Screen → route/state; không quyết định business rule |
| `architecture/aggregates/` | SA | Định nghĩa ranh giới đảm bảo tính nhất quán ở write-side | Root; boundary; child Entity/VO; Điều kiện bắt buộc; lifecycle; domain operations; concurrency; persistence; events; dependencies |
| `architecture/read-models/` | SA | Định nghĩa cấu trúc đọc/Projection phục vụ Query | Câu hỏi nghiệp vụ; nguồn dữ liệu; projection semantics; consistency/freshness; query shape; rebuild; consumers |
| `architecture/foundations/` | SA | Định nghĩa khả năng kỹ thuật dùng chung | Problem; scope; execution protocol; technical state; shared boundary; failure/recovery; consumers; verification |
| `architecture/integrations/` | SA | Định nghĩa ranh giới tích hợp bền vững giữa Domain/hệ thống | Producer/consumer boundary; ownership; consistency; transaction/message semantics; failure/recovery |
| `architecture/nfr/` | SA | Lưu yêu cầu phi chức năng ảnh hưởng kiến trúc | Security/performance/resilience/observability ở dạng đo hoặc kiểm tra được |
| `harness/sa-slices/` | SA | Đơn vị công việc kiến trúc | Objective; scope; owns/does-not-own; nguồn đầu vào; output; dependency; verification; status |
| `harness/be-slices/` | SE | Triển khai UC thành backend behavior | UC → BC → Application Command/Query → application orchestration → Architecture → API/Event khi cần → Tests khép kín |
| `harness/fe-slices/` | SE | Triển khai Screen thành giao diện chạy được | Screen → UC → action → published interface → state → Design System → Prototype → FE tests khép kín |
| `harness/manifests/` | Harness | Lưu dependency và trạng thái Slice ở dạng máy đọc được | Slice catalog; type; owner; dependency; blocker; status; coverage |
| `procedures/` | SA/SE | Quy trình kỹ thuật/vận hành không phải product behavior | Trigger; preconditions; steps; safety; rollback/recovery; owner |
| `evidence/` | QA/Shared | Lưu bằng chứng kiểm tra | Lần ngược được về tài liệu/Slice; không trở thành nguồn yêu cầu thứ hai |
| `generated/` | Harness | View tổng hợp phục vụ tra cứu và kiểm soát | 100% sinh tự động; cùng đầu vào sinh cùng kết quả; read-only; link ngược về nguồn |

## B.3 Nguyên tắc tổ chức thư mục

1. Mỗi loại nội dung chỉ có **một nơi chịu trách nhiệm chính**.
2. Không copy file để lưu lịch sử phiên bản; lịch sử thuộc Git.
3. ID đã dùng phải ổn định qua việc tái tổ chức thư mục.
4. Registry, matrix và index nên được sinh tự động khi có thể.
5. `generated/` không chứa nội dung được biên tập bằng tay.
6. Evidence không được trở thành nguồn yêu cầu thứ hai.
7. Thư mục được tổ chức để **nguồn đủ rõ cho các bước sau sử dụng trực tiếp**, không tạo thêm lớp tài liệu trung gian sao chép lại nội dung.
8. Application Command/Query mặc định thuộc BE Slice/Application.