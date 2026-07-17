import 'package:test/test.dart';
import 'package:vet45_partner_domain/domain.dart';

void main() {
  group('PartnerActionType.parse', () {
    test('accepts snake_case wire values', () {
      expect(PartnerActionType.parse('add_contact'), PartnerActionType.addContact);
      expect(PartnerActionType.parse('remove_contact'), PartnerActionType.removeContact);
      expect(PartnerActionType.parse('create'), PartnerActionType.create);
    });

    test('accepts camelCase dart names', () {
      expect(PartnerActionType.parse('addContact'), PartnerActionType.addContact);
    });
  });
}
