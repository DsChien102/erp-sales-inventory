# Domain Layer — Reference

Canonical mirror: [`docs/domain_layer_skill.md`](../../../docs/domain_layer_skill.md)

Design input: [ddd-domain-modeling](../ddd-domain-modeling/reference.md). Implement code: document này.

---

## 1. Folder layout

```text
modules/<module>/domain/
  pubspec.yaml
  lib/
    domain.dart
    src/
      <aggregate_name>/
        <aggregate>.dart
        <entity>.dart                    # optional child entity
        <value_object>.dart
        <aggregate>_status.dart          # enum / status VO
        policies/
          <policy_name>.dart
        services/
          <calculator>.dart              # domain service in aggregate scope
        events/
          <event_name>_domain_event.dart # one event per file
        rules/
          <rule_name>_rule.dart            # one rule per file
      shared/                            # cross-aggregate only
        <cross_aggregate_helper>.dart
  test/
    <aggregate>/
      <rule_name>_rule_test.dart
```

**Quy tắc `lib/src/`:** implementation trong `src/`; barrel `domain.dart` export public API. Package khác không import `src/`.

---

## 2. Mapping từ `01-domain-model.md`

| Harness section | Domain artifact |
|-----------------|-----------------|
| Aggregate table | `lib/src/<snake_aggregate>/` folder + `<aggregate>.dart` |
| Value objects table | `<vo_name>.dart` trong aggregate folder |
| Business rules (implicit in BR) | `rules/<name>_rule.dart` |
| Domain events table | `events/<event>_domain_event.dart` |
| Commands table | **Không** implement ở domain — application layer |
| Integration events | `integration_events` package — không domain event cross-module |

Tên folder aggregate: `BusinessPartner` → `business_partner/`.

---

## 3. Business rule template

```dart
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerMustBeActiveRule implements IBusinessRule {
  const PartnerMustBeActiveRule(this.status);

  final PartnerStatus status;

  @override
  bool isBroken() => status != PartnerStatus.active;

  @override
  String get message => 'Partner must be active';
}
```

Gọi trong aggregate:

```dart
checkRule(PartnerMustBeActiveRule(status));
// hoặc ValueObject.checkRule(...) trong VO constructor
```

Reference thật: [`modules/accounting/domain/lib/src/money.dart`](../../../modules/accounting/domain/lib/src/money.dart).

---

## 4. Value object template

```dart
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'rules/partner_name_must_not_be_empty_rule.dart';

final class PartnerName extends ValueObject {
  PartnerName(String raw) : value = raw.trim() {
    ValueObject.checkRule(PartnerNameMustNotBeEmptyRule(value));
  }

  final String value;

  @override
  List<Object?> get props => [value];
}
```

---

## 5. Aggregate template (sketch)

```dart
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'events/partner_deactivated_domain_event.dart';
import 'rules/partner_must_be_active_rule.dart';
import 'partner_status.dart';

final class BusinessPartner extends Entity<PartnerId> implements IAggregateRoot {
  BusinessPartner({
    required super.id,
    required this.status,
    // ...
  });

  PartnerStatus status;
  final List<DomainEventBase> _events = [];

  void deactivate() {
    checkRule(PartnerMustBeActiveRule(status));
    status = PartnerStatus.inactive;
    _events.add(PartnerDeactivatedDomainEvent(partnerId: id));
  }

  List<DomainEventBase> pullEvents() {
    final copy = List<DomainEventBase>.from(_events);
    _events.clear();
    return copy;
  }
}
```

Factory `create` cho register use case; mutation methods đặt tên theo **intent** (`deactivate`, `changeRole`), không `update`.

---

## 6. Domain event template

```dart
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerDeactivatedDomainEvent extends DomainEventBase {
  PartnerDeactivatedDomainEvent({required this.partnerId}) : super();

  final PartnerId partnerId;
}
```

Application/infrastructure map sang integration event + outbox — không publish cross-module từ domain.

---

## 7. Enum / status

```dart
enum PartnerStatus {
  active,
  inactive;

  bool get isActive => this == PartnerStatus.active;
}
```

Closed set — align với Postgres `CHECK` trong migration (defense in depth).

---

## 8. Permission / catalog constants (optional)

Khi module cần permission codes dùng chung:

```dart
abstract final class PartnerPermissions {
  static const read = 'partner.read';
  static const write = 'partner.write';
}
```

Application dùng trong `@RequiresPermission` — không hardcode string trong infrastructure.

---

## 9. pubspec.yaml

```yaml
name: vet45_<module>_domain
dependencies:
  vet45_shared_domain: ^1.0.0
  meta: ^1.17.0
dev_dependencies:
  vet45_lints: ^1.0.0
  test: ^1.25.0
```

---

## 10. Review checklist

```text
[ ] Input đọc từ 01-domain-model.md (không invent aggregate mới)
[ ] lib/domain.dart + lib/src/ layout
[ ] Một rule / một file trong rules/
[ ] Một event / một file trong events/
[ ] VO validate tại construction
[ ] Aggregate methods = business intent, không CRUD
[ ] Không God aggregate
[ ] Không import application/infrastructure/flutter/supabase
[ ] Không cross-module entity reference
[ ] Money = integer minor units nếu có tiền
[ ] Tests cho rule + critical aggregate methods
[ ] Barrel export tối thiểu cần thiết
```

---

## 11. Agent output (implement)

```text
1. File list (created/modified)
2. Aggregate ↔ folder map
3. Rules ↔ aggregate methods
4. Events ↔ triggers
5. Tests
6. Handoff notes cho application-layer (commands từ harness table)
```
