# Domain Layer — Examples

## 1. Money (full VO + rule)

Package: [`modules/accounting/domain`](../../../modules/accounting/domain/lib/src/money.dart)

```dart
class AmountMustBePositiveRule implements IBusinessRule {
  final int amount;
  const AmountMustBePositiveRule(this.amount);
  @override
  bool isBroken() => amount < 0;
  @override
  String get message => 'Amount must be positive';
}

class Money extends ValueObject {
  final int amount;
  Money(this.amount) {
    ValueObject.checkRule(AmountMustBePositiveRule(amount));
  }
  // operators, zero, props...
}
```

**Takeaway:** rule class riêng; VO gọi `checkRule` trong constructor; `int` minor units.

---

## 2. IAM interim (thin domain)

Package: [`modules/iam/domain`](../../../modules/iam/domain)

Chưa có aggregate SRS — chỉ catalog + static rules:

```dart
abstract final class AssignMemberRoleRules {
  static const allowedRoleValues = {'owner', 'staff'};
  static void ensureRoleAllowed(String role) { ... }
}
```

Application validator gọi `AssignMemberRoleRules.ensureRoleAllowed` — migrate sang aggregate khi Theme 1 land.

**Takeaway:** interim được phép; ghi rõ trong `modules/iam/docs/interim-domain.md`; không mở rộng pattern cho module greenfield đủ SRS.

---

## 3. Partner — map từ TH-03 (target sketch)

Source: [`docs/themes/TH-03-partner/harness/01-domain-model.md`](../../../docs/themes/TH-03-partner/harness/01-domain-model.md)

### Folder

```text
modules/partner/domain/lib/src/business_partner/
  business_partner.dart
  partner_status.dart
  partner_name.dart
  phone_number.dart
  rules/
    partner_name_must_not_be_empty_rule.dart
    partner_must_be_active_to_deactivate_rule.dart
    partner_must_have_no_transactions_to_delete_rule.dart
  events/
    partner_registered_domain_event.dart
    partner_deactivated_domain_event.dart
```

### VO snippet

```dart
final class PartnerName extends ValueObject {
  PartnerName(String raw) : value = raw.trim() {
    ValueObject.checkRule(PartnerNameMustNotBeEmptyRule(value));
  }
  final String value;
  @override
  List<Object?> get props => [value];
}
```

### Aggregate method snippet

```dart
void deactivate() {
  checkRule(PartnerMustBeActiveToDeactivateRule(status));
  status = PartnerStatus.inactive;
  _events.add(PartnerDeactivatedDomainEvent(partnerId: id));
}
```

### Harness → application (không domain)

| Harness command | Application (sau domain) |
|-----------------|--------------------------|
| `RegisterPartnerCommand` | Handler gọi `BusinessPartner.register(...)` |
| `DeactivatePartnerCommand` | Handler load + `deactivate()` |
| `DeletePartnerCommand` | Rule `PartnerMustHaveNoTransactionsToDeleteRule` trong aggregate |

---

## 4. Test pattern

```dart
test('PartnerName rejects blank', () {
  expect(() => PartnerName('   '), throwsA(isA<BusinessRuleValidationException>()));
});

test('deactivate fails when already inactive', () {
  final partner = BusinessPartner.create(/* inactive seed */);
  expect(() => partner.deactivate(), throwsA(isA<BusinessRuleValidationException>()));
});
```

Dùng exception từ `vet45_shared_domain` khi `checkRule` fail.
