import 'package:test/test.dart';
import 'package:vet45_partner_domain/src/search/search_keyword_normalizer.dart';

void main() {
  group('SearchKeywordNormalizer', () {
    test('returns null for blank keyword', () {
      expect(SearchKeywordNormalizer.normalizeKeyword('   '), isNull);
    });

    test('normalizes phone keyword', () {
      final value = SearchKeywordNormalizer.normalizePhoneKeyword(
        ' +84 987-654-321 ',
      );
      expect(value, '+84987654321');
    });
  });
}
