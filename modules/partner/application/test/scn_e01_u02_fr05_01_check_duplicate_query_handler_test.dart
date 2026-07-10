import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('scn_e01_u02_fr05_01 CheckDuplicatePartnersQueryHandler', () {
    test('delegates duplicate check to port', () async {
      final checker = RecordingPartnerDuplicateChecker()
        ..matches = const [
          PartnerDuplicateMatchDto(
            partnerId: 'p-dup',
            displayName: 'Nguyễn Văn A',
            matchedField: PartnerDuplicateMatchField.phone,
            partnerType: PartnerType.person,
            matchedValue: '0901234567',
          ),
        ];
      final handler = CheckDuplicatePartnersQueryHandler(
        duplicateChecker: checker,
      );

      final result = await handler.handle(
        CheckDuplicatePartnersQuery(
          tenantId: 't-1',
          phone: '0901234567',
        ),
      );

      expect(result, hasLength(1));
      expect(checker.lastQuery?.phone, '0901234567');
    });
  });
}
