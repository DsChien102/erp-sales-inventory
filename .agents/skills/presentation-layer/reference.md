# Presentation Layer — Reference

## Folder layout (TH-03 partner)

```text
apps/erp/lib/features/partner/presentation/
  pages/
    partner_list_page.dart
    partner_detail_page.dart
  widgets/                    # chỉ dùng trong feature partner (ERP shell)
    partner_profile_header.dart
  bloc/                       # optional
    partner_detail_cubit.dart

modules/partner/presentation/
  lib/
    presentation.dart         # barrel
    src/
      partner_presentation_module.dart
      widgets/
        deactivate_partner_dialog.dart
        reactivate_partner_dialog.dart
        delete_partner_dialog.dart
```

## Naming

| Kind | Pattern | Example |
| ---- | ------- | ------- |
| Page | `<feature>_<view>_page.dart` | `partner_detail_page.dart` |
| Dialog | `<action>_<entity>_dialog.dart` | `deactivate_partner_dialog.dart` |
| Section | `<entity>_<section>.dart` | `partner_profile_header.dart` |
| Class | PascalCase khớp file | `DeactivatePartnerDialog` |

## Import direction

```dart
// apps/erp — OK
import 'package:vet45_partner_presentation/presentation.dart';

// modules/partner/presentation — FORBIDDEN
import 'package:erp/...';  // never import apps/erp
```

## Dialog pattern

```dart
// modules/partner/presentation/lib/src/widgets/deactivate_partner_dialog.dart
class DeactivatePartnerDialog extends StatelessWidget {
  const DeactivatePartnerDialog({
    super.key,
    required this.partnerName,
    required this.onConfirm,
  });

  final String partnerName;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ngừng hoạt động đối tác'),
      // ...
    );
  }
}
```

```dart
// apps/erp page — chỉ gọi showDialog với widget import
showDialog<void>(
  context: context,
  builder: (_) => DeactivatePartnerDialog(
    partnerName: state.name,
    onConfirm: () => cubit.deactivate(),
  ),
);
```

## Page responsibility checklist

- [ ] ≤ 500 dòng
- [ ] Không inline `AlertDialog` / `Dialog` body
- [ ] Không `_buildLargeXxx()` — đã tách class/file
- [ ] Mutations qua `IModuleMediator` / Cubit gọi mediator
- [ ] UI artifacts khớp FR manifest

## Agent task prompt template

```text
Implement {FR_ID} UI for TH-03.

Bắt buộc:
1. Đọc .cursor/skills/presentation-layer/SKILL.md + UI artifacts trong FR
2. Widget manifest:
   - {list each file path}
3. Page ≤ 500 lines; dialogs in modules/partner/presentation/lib/src/widgets/
4. Copy composition pattern từ apps/erp/.../dashboard/presentation/
5. Verify:
   ./scripts/ci/verify_harness.sh
   cd apps/erp && flutter test test/features/partner/
```

## CI guards

| Guard | Script |
| ----- | ------ |
| File size ≤ 500 | `scripts/ci/guard_presentation_size.sh` |
| No inline dialogs in pages | `scripts/ci/guard_presentation_dialogs.sh` |

Legacy allowlist: `GUARD_PRESENTATION_DIALOGS_LEGACY=1` trong `verify_harness.sh` cho đến khi einvoice refactor.

File-level escape hatch: comment `// harness:allow-inline-dialog` ở đầu file (guard skip).

## Widget test id convention

```text
wgt_e{epic}_u{us}_fr{fr}_{nn}
Ví dụ: wgt_e02_u01_fr03_01
```
