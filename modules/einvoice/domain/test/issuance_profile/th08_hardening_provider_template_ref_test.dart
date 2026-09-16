import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('th08_hardening_capability — InvoiceSeriesClassification', () {
    test('classifies có mã, không mã và MTT from InvSeries', () {
      expect(
        InvoiceSeriesClassification.tryParse('1C26TYY'),
        const InvoiceSeriesClassification(invoiceWithCode: true, isMtt: false),
      );
      expect(
        InvoiceSeriesClassification.tryParse('1K26TYY'),
        const InvoiceSeriesClassification(invoiceWithCode: false, isMtt: false),
      );
      expect(
        InvoiceSeriesClassification.tryParse('2C26MYY'),
        const InvoiceSeriesClassification(invoiceWithCode: true, isMtt: true),
      );
    });

    test('rejects malformed InvSeries at each classified position', () {
      for (final invSeries in <String>[
        '',
        '1C2',
        '3C26TYY',
        '1X26TYY',
        '1C26XYY',
      ]) {
        expect(
          InvoiceSeriesClassification.tryParse(invSeries),
          isNull,
          reason: 'expected malformed InvSeries: $invSeries',
        );
      }
    });
  });

  group('th08_hardening_capability — ProviderTemplateRef', () {
    test('create derives invoiceWithCode/isMtt and keeps isSendSummary', () {
      final ref = ProviderTemplateRef.create(
        templateId: 'tpl-mtt',
        name: 'MTT',
        invoiceSeries: '2C26MYY',
        isSendSummary: true,
        serial: '1',
      );

      expect(ref.invoiceSeries, '2C26MYY');
      expect(ref.symbol, '2C26MYY');
      expect(ref.invoiceWithCode, isTrue);
      expect(ref.isMtt, isTrue);
      expect(ref.isSendSummary, isTrue);
    });

    test('create throws on malformed InvSeries', () {
      expect(
        () => ProviderTemplateRef.create(
          templateId: 'bad',
          name: 'Bad',
          invoiceSeries: 'BAD',
          isSendSummary: false,
        ),
        throwsArgumentError,
      );
    });

    test('mergeAndDedupe keeps both code modes and drops duplicate series', () {
      final withCode = ProviderTemplateRef.create(
        templateId: 'tpl-c',
        name: 'Có mã',
        invoiceSeries: '1C26TYY',
        isSendSummary: false,
      );
      final noCode = ProviderTemplateRef.create(
        templateId: 'tpl-k',
        name: 'Không mã',
        invoiceSeries: '1K26TYY',
        isSendSummary: true,
      );
      final duplicate = ProviderTemplateRef.create(
        templateId: 'tpl-c-dup',
        name: 'Dup series',
        invoiceSeries: '1C26TYY',
        isSendSummary: false,
      );

      final merged = ProviderTemplateRef.mergeAndDedupe([
        withCode,
        noCode,
        duplicate,
      ]);

      expect(merged, hasLength(2));
      expect(
        merged.map((t) => t.invoiceSeries).toSet(),
        {'1C26TYY', '1K26TYY'},
      );
      expect(
        merged.singleWhere((t) => t.invoiceSeries == '1K26TYY').isSendSummary,
        isTrue,
      );
    });
  });
}
