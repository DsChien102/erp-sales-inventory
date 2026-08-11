import 'package:test/test.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  group('AuditPayloadRedactor secret denylist', () {
    test('removes top-level and nested secret keys', () {
      final result = AuditPayloadRedactor.redact({
        'password': 'p@ss',
        'user': {
          'token': 'abc',
          'nested': {'refresh_token': 'r', 'safe': 'keep'},
        },
        'items': [
          {'otp': '123456', 'label': 'first'},
        ],
      });

      expect(result.payload['password'], '***');
      final user = result.payload['user'] as Map<String, Object?>;
      expect(user['token'], '***');
      final nested = user['nested'] as Map<String, Object?>;
      expect(nested['refresh_token'], '***');
      expect(nested['safe'], 'keep');
      final items = result.payload['items'] as List;
      expect((items.first as Map)['otp'], '***');
      expect((items.first as Map)['label'], 'first');
      expect(result.flags, contains(AuditPayloadRedactor.flagSecretRemoved));
    });

    test('masks session and token_hash keys', () {
      final result = AuditPayloadRedactor.redact({
        'session': 'sess-1',
        'token_hash': 'deadbeef',
      });
      expect(result.payload['session'], '***');
      expect(result.payload['token_hash'], '***');
    });
  });

  group('AuditPayloadRedactor PII masking', () {
    test('masks email deterministically', () {
      expect(AuditPayloadRedactor.maskEmail('lan@gmail.com'), 'l***@gmail.com');
    });

    test('masks phone keeping last two digits', () {
      expect(AuditPayloadRedactor.maskPhone('+84901234567'), endsWith('67'));
      expect(AuditPayloadRedactor.maskPhone('+84901234567'), startsWith('*'));
    });

    test('masks tax code keeping last three chars', () {
      expect(AuditPayloadRedactor.maskTaxCode('0312345678'), endsWith('678'));
    });

    test('applies masking flags for PII fields', () {
      final result = AuditPayloadRedactor.redact({
        'contact_email': 'lan@gmail.com',
        'phone_number': '+84901234567',
        'tax_code': '0312345678',
      });
      expect(result.payload['contact_email'], 'l***@gmail.com');
      expect(result.flags, contains(AuditPayloadRedactor.flagEmailMasked));
      expect(result.flags, contains(AuditPayloadRedactor.flagPhoneMasked));
      expect(result.flags, contains(AuditPayloadRedactor.flagTaxCodeMasked));
    });
  });
}
