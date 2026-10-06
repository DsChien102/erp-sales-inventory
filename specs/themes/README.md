# VET45 Harness Doctrine

> **Phiên bản:** Draft v0.11
>
> **Ngày:** 2026-09-24
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

# 2. Mô hình nguồn và đơn vị thay đổi

BA tổ chức tri thức, hành vi và trải nghiệm; BA/SA cùng xây Domain; SA bảo vệ kiến trúc dùng chung; SE hiện thực; QA kiểm chứng. Các vai trò cùng đóng góp vào **một loại Slice**, không tạo dòng công việc riêng theo vai trò.

## 2.1 Các nguồn chuẩn

Knowledge cung cấp căn cứ cho Specification. Specification gồm hai vùng:

- **Behavior:** Business Journey, Use Case và Behavioral Contract.
- **Domain:** Domain Foundation, Entity/Value Object, Aggregate, Read Model và Integration.

Design hiện thực hóa hành vi bằng Screen Contract, Pattern, Design System và Prototype. UI Flow cấp hành trình tiếp tục nằm trong BJ, không tạo một nhánh tài liệu riêng.

Specification và Design cùng là nguồn cho Slice; Slice dẫn tới implementation và evidence. Slice không thay thế các nguồn chuẩn này.

## 2.2 Kiến trúc nằm ở đâu?

| Loại nội dung | Nơi sở hữu |
|---|---|
| Trách nhiệm Domain, nghĩa nghiệp vụ, bất biến và lifecycle | Domain Foundation |
| Đối tượng, identity, thuộc tính, quan hệ, hành vi nghiệp vụ | Entity / Value Object |
| Root, thành viên và ranh giới nhất quán khi thay đổi | Aggregate |
| Câu hỏi nghiệp vụ, dữ liệu đọc, projection, freshness/consistency, rebuild | Read Model |
| Ownership, producer/consumer, nghĩa dữ liệu, versioning, failure và reconciliation giữa các Domain/Theme | Integration |
| Idempotency, concurrency, event delivery, security, observability dùng chung | `docs/architecture`. Slice ghi cách outcome này áp dụng |
| Endpoint, orchestration, transaction, lỗi hoặc FE state của một outcome | Work slice, lúc review để implement |
| Ngưỡng NFR cần đo cho một outcome | Verification của work slice đó |

Không còn top-level Architecture và không còn nguồn Technical Contract. Tư duy kiến trúc vẫn tồn tại tại nguồn có trách nhiệm tương ứng. Entity không tự quyết định ranh giới transaction; Aggregate không được gom mọi đối tượng có quan hệ vào một cụm. Read Model thuộc Domain và mô tả mặt đọc của mô hình nghiệp vụ.

Contract của một outcome được viết trong work slice lúc review để implement. Quy tắc nền tảng đã có trong `docs/architecture` (idempotency, outbox, event delivery) thì slice dẫn tới đó và chỉ ghi cách outcome này áp dụng. Ngưỡng NFR chỉ xuất hiện trong Verification của slice khi slice đó cần đo.

## 2.3 Từ nghiệp vụ đến Slice

BJ mô tả hành trình đầu–cuối và bàn giao giữa các UC. UC xác định mục tiêu, ranh giới, tác nhân, dữ liệu, quy tắc, luồng chính/thay thế/ngoại lệ và kịch bản nghiệm thu. UC giữ nghĩa nghiệp vụ độc lập với màn hình hoặc API.

BJ dùng Journey Acceptance cho điều kiện xuyên UC. UC dùng Acceptance Scenario và dẫn về BF/AF/EF/BR. Một UC có thể được triển khai qua nhiều Slice theo tập Flow/Scenario; không mặc định quan hệ 1–1. Khi dẫn mã Flow từ Slice phải kèm UC ID vì mã bước chỉ có phạm vi nội bộ UC.

Một Slice có thể đồng thời thay đổi Domain, Application, backend, frontend và tests. Cũng có thể có Slice chỉ cung cấp năng lực dùng chung nếu đó là một phạm vi thay đổi độc lập. Không chia thêm Slice chỉ vì nhiều vai trò tham gia; không gộp các công việc khác mục tiêu chỉ để giảm số file.

## 2.4 Application và Domain

**Application Command/Query** biểu diễn yêu cầu đi vào Application; điều phối đọc dữ liệu, gọi Domain, áp dụng quy tắc nền tảng từ `docs/architecture` cùng contract của outcome trong Slice, rồi trả kết quả. Thiết kế cục bộ nằm trong Slice.

**Domain Operation / Aggregate behavior** thuộc mô hình Domain và bảo vệ các bất biến của Aggregate, không được thiết kế chỉ theo một màn hình hay UC.

API/Event của một outcome được viết trong work slice lúc review để implement. Ranh giới dùng chung giữa Domain/Theme nằm ở Integration. Giao diện sử dụng interface đã công bố, không tự thay thế quy tắc Domain.

## 2.5 Nội dung một Slice

Một Slice có bảy phần: Objective; Scope & Rules; Flow; Design; Dependencies & Contracts; Verification; Delivery. Metadata ghi owner, contributors, trạng thái và nguồn tham chiếu.

- Objective xác định kết quả thay đổi.
- Scope ghi owns/does-not-own, các Flow/Scenario/Screen/artifact được bao phủ và phần còn lại.
- Design/Contracts ghi thiết kế cục bộ, phụ thuộc và hợp đồng cần để triển khai.
- Verification gắn tiêu chí và kiểm tra với nguồn chuẩn.
- Delivery ghi đầu ra, evidence, câu hỏi mở và trạng thái thực tế.

Không sao chép toàn bộ nguồn vào Slice. Nếu phát hiện thiếu hoặc sai quy tắc Domain, sửa nguồn Domain rồi tham chiếu lại. Contract của outcome được viết trong Slice lúc review để implement. SE không tự suy ra mục tiêu nghiệp vụ từ Prototype hoặc tự thêm yêu cầu ngoài Slice.

# 3. Nguyên tắc phối hợp

BA, SA, SE và QA nhìn cùng một mô hình, bổ sung đúng trách nhiệm của mình và hội tụ vào Slice khi có thay đổi. Một nguồn có một nơi sở hữu; mỗi đầu ra phải lần ngược được qua Slice tới artifact và quyết định nghiệp vụ.

Scope, dependency và thiết kế phải đủ rõ trước khi triển khai. Evidence chứng minh kết quả, không tạo yêu cầu mới. Cấu trúc thư mục không phải lý do để tự thay đổi nghiệp vụ hoặc redesign giao diện.

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

`DRAFT → IN_REVIEW → READY_TO_IMPLEMENT → IMPLEMENTING → VERIFIED`.

`READY_TO_IMPLEMENT` nghĩa là phạm vi, nguồn và thiết kế đã được review, đủ để triển khai; không có nghĩa đã hoàn thành implementation. Với Slice cũ dùng `FROZEN`, chỉ chuyển sang READY_TO_IMPLEMENT sau khi kiểm tra đủ điều kiện này.

`BLOCKED` có thể xuất hiện trước VERIFIED; bắt buộc ghi lý do và điều kiện gỡ chặn. Không triển khai khi BLOCKED. VERIFIED phải có evidence tương ứng với phạm vi bao phủ.

---

# Phụ lục B — Cấu trúc thư mục và Directory Contract

Đây là cấu trúc Theme đích. Bộ [theme-template](theme-template/README.md) cung cấp mẫu và mapping chuyển đổi; không phải bản nghiệp vụ chính thức của một Theme.

## B.1 Cây thư mục

```text
theme-xx/
    README.md
    VERSION.md
    01.knowledge/
        know-how/
        decisions/
        glossary/
    02.specification/
        overview/
        behavior/
            journeys/
            use-cases/
            behavioral-contracts/
        domain/
            domain-foundation/
            entities/
            aggregates/
            read-models/
            integrations/
    03.design/
        screens/
        patterns/
        design-system/
        prototype/
    04.harness/
        slices/
        manifests/
    05.procedures/
    09.generated/
```

Các thư mục con `09.generated/registries`, `matrices`, `indexes` được tạo khi có đầu ra thực tế. Prototype HTML chạy được nằm trong 03.design/prototype/html/ nếu Theme có runtime. Không bỏ runtime vì chuyển cấu trúc.

## B.2 Directory Contract

| Khu vực | Owner chính | Mục đích và tiêu chuẩn đầu ra |
|---|---|---|
| README.md | Shared | Scope, cấu trúc, vai trò, trạng thái và link tới nguồn |
| VERSION.md | Harness | Phiên bản hiện hành, cumulative parent thực tế, thay đổi và evidence |
| 01.knowledge/know-how/ | BA | Tri thức có nguồn; phân biệt dữ kiện, diễn giải và đề xuất |
| 01.knowledge/decisions/ | BA | Quyết định, lý do, phạm vi, trạng thái, ID ổn định |
| 01.knowledge/glossary/ | BA | Thuật ngữ có nghĩa thống nhất trong phạm vi Theme |
| 02.specification/overview/ | BA | Mục tiêu, phạm vi, tác nhân, boundary và bản đồ BJ/Domain |
| 02.specification/behavior/journeys/ | BA | Hành trình đầu–cuối, sơ đồ, UC map, bàn giao, UI Flow và Journey Acceptance |
| 02.specification/behavior/use-cases/ | BA | Mục tiêu, ranh giới, tác nhân, dữ liệu, BF/AF/EF, BR/BC, kết quả và Acceptance Scenario |
| 02.specification/behavior/behavioral-contracts/ | BA | Quy tắc hành vi dùng chung, điều kiện, tác động và nghĩa kết quả/thất bại |
| 02.specification/domain/domain-foundation/ | BA/SA | Trách nhiệm, ownership, bất biến, lifecycle và ranh giới Domain |
| 02.specification/domain/entities/ | BA/SA | Entity/VO, identity, thuộc tính, quan hệ, lifecycle và ràng buộc nghiệp vụ |
| 02.specification/domain/aggregates/ | BA/SA | Root, thành viên, consistency boundary, invariant, hành vi và concurrency |
| 02.specification/domain/read-models/ | BA/SA | Mô hình đọc, projection, nguồn, freshness/consistency, rebuild và consumers |
| 02.specification/domain/integrations/ | BA/SA | Nghĩa trao đổi, owner, producer/consumer, versioning, consistency, failure và reconciliation |
| 03.design/screens/ | BA | Screen, UC, entry/exit, data, action, state, validation, feedback, permission và component |
| 03.design/patterns/ | BA | Tương tác/bố cục dùng chung và phạm vi biến thể |
| 03.design/design-system/ | BA | Version, component và ngoại lệ được chấp thuận |
| 03.design/prototype/ | BA | Thiết kế tương tác chạy được, mapping Screen/route/state, khớp Screen Contract |
| 04.harness/slices/ | Owner theo thay đổi; BA/SA/SE/QA phối hợp | Một đơn vị thay đổi có nguồn, phạm vi, thiết kế cục bộ, phụ thuộc, đầu ra và kiểm chứng |
| 04.harness/manifests/ | Harness | Danh mục Slice, artifact, path, dependency, coverage, trạng thái và blocker |
| 05.procedures/ | SA/SE | Trigger, điều kiện, các bước, an toàn, rollback/recovery và owner |
| 09.generated/ | Harness | Registry/matrix/index sinh tự động, có thể tạo lại, dẫn về nguồn |

## B.3 Nguyên tắc chuyển đổi

1. Xác định cumulative parent đang được chấp nhận, không mặc định một version cũ.
2. Giữ ID nguồn nghiệp vụ, Domain, BC và Screen. Đổi ID Slice khi cần phải có mapping.
3. Di chuyển/phân loại trước; không nhân bản tài liệu để giữ path cũ. Lịch sử thuộc Git.
4. Đưa Aggregate/Read Model/Integration vào Domain. Contract của outcome và ngưỡng đo nằm trong work slice.
5. Dùng một thư mục slices; ranh giới theo mục tiêu thay đổi, không theo vai trò.
6. Cập nhật link, manifest, README và kiểm tra orphan/dependency sau di chuyển.
7. Giữ số 09 cho Generated; không cần lấp số 07/08 khi chưa có lý do.
8. Giữ nguyên prototype, Design System, quyết định và traceability khi migrate Theme thật.
9. Generated là kết quả sinh từ nguồn; không biên tập tay và không trở thành nguồn thay thế.
