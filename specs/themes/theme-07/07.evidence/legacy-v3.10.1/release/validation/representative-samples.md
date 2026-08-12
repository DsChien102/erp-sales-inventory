# Mẫu đại diện — Theme 7 v4.3.1

## Quyết định và điều hướng

`T7-DR-020` thuộc G03 và trỏ tới full heading permalink `#33-g03-nh%E1%BA%ADn-h%C3%A0ng-v%C3%A0-x%C3%A1c-nh%E1%BA%ADn-gi%C3%A1-tr%E1%BB%8B`; không còn phụ thuộc `#g13` sai hoặc custom anchor.

## Trace UI hiện hành

`BJ-02 → UC-02-04 → SCR-012 → BC-IO-02 → TST-AS-UC-02-04-*`. Screen Group cũ chỉ là alias migration; `UC-02-04` vẫn là owner của mutation ghi tồn vật lý.

## Safe failure

Test `UNKNOWN` giữ cùng operation identity và đối soát trước retry. UI trace mới không tạo owner, finality, state nghiệp vụ hoặc mutation path mới.

## Ví dụ bị chặn

Các test repository giữ `BLOCKED_BY_REPO_ADAPTER`; đường phục hồi là gắn adapter vào checkout nhánh `srs`, chạy test bằng đúng ID và lưu raw command/exit evidence.
