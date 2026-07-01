import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class _FakeDuplicateChecker implements IPartnerDuplicateChecker {
  BusinessPartnerId? lastExcludePartnerId;

  @override
  Future<List<PartnerDuplicateMatch>> findMatches({
    required TenantId tenantId,
    PhoneNumber? phone,
    EmailAddress? email,
    TaxCode? taxCode,
    BusinessPartnerId? excludePartnerId,
  }) async {
    lastExcludePartnerId = excludePartnerId;
    return [
      PartnerDuplicateMatch(
        field: PartnerDuplicateField.phone,
        businessPartnerId: const BusinessPartnerId('existing-1'),
        displayName: 'Existing Partner',
        matchedValue: phone?.value ?? '',
      ),
    ];
  }
}

void main() {
  test('CheckDuplicatePartnersQueryHandler maps duplicate matches to DTOs', () async {
    final handler = CheckDuplicatePartnersQueryHandler(
      duplicateChecker: _FakeDuplicateChecker(),
    );

    final result = await handler.handle(
      CheckDuplicatePartnersQuery(
        tenantId: 'tenant-1',
        phone: '0987654321',
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.field, PartnerDuplicateField.phone);
    expect(result.first.businessPartnerId, 'existing-1');
    expect(result.first.displayName, 'Existing Partner');
  });

  test('CheckDuplicatePartnersForUpdateQueryHandler passes exclude partner id', () async {
    final duplicateChecker = _FakeDuplicateChecker();
    final handler = CheckDuplicatePartnersForUpdateQueryHandler(
      duplicateChecker: duplicateChecker,
    );

    await handler.handle(
      CheckDuplicatePartnersForUpdateQuery(
        tenantId: 'tenant-1',
        excludePartnerId: 'partner-1',
        phone: '0987654321',
      ),
    );

    expect(duplicateChecker.lastExcludePartnerId, const BusinessPartnerId('partner-1'));
  });
}
