import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_publish_classifier.dart';
import 'package:vet45_misa/e_invoice.dart';

void main() {
  group('MeInvoicePublishClassifier', () {
    test('classifies InvalidInvSeries as definiteFailure', () {
      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-1',
        result: MeInvoiceResult.ok([
          const MeInvoicePublishInvoiceResultItem(
            refId: 'key-1',
            errorCode: 'InvalidInvSeries',
            descriptionErrorCode: 'bad series',
          ),
        ]),
        canonicalInvoice: const {'invDate': '2026-08-01'},
      );

      expect(outcome, isA<MeInvoicePublishDefiniteFailure>());
    });

    test('classifies DuplicateInvoiceRefID as undetermined', () {
      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-1',
        result: MeInvoiceResult.ok([
          MeInvoicePublishInvoiceResultItem(
            refId: 'key-1',
            transactionId: 'tx-1',
            invNo: '0000001',
            errorCode: MeInvoicePublishErrorCodes.duplicateInvoiceRefId,
          ),
        ]),
        canonicalInvoice: const {'invDate': '2026-08-01'},
      );

      expect(outcome, isA<MeInvoicePublishUndetermined>());
      expect(
        (outcome as MeInvoicePublishUndetermined).reasonCode,
        'DUPLICATE_INVOICE_REF_ID',
      );
    });

    test('classifies HTTP client InvalidInvSeries response', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return http.Response(
            jsonEncode({'Success': true, 'Data': 'tok'}),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'publishInvoiceResult': [
              {
                'RefID': 'key-1',
                'ErrorCode': 'InvalidInvSeries',
                'DescriptionErrorCode': 'bad series',
              },
            ],
          }),
          200,
        );
      });

      final client = MeInvoiceClient(
        config: const MeInvoiceConfig(
          baseUrl: 'https://meinvoice-test.misa.vn',
          appId: 'app',
          taxCode: '0100000000',
          username: 'user',
          password: 'secret',
        ),
        httpClient: httpClient,
      );

      final result = await client.publish(
        MeInvoicePublishRequest(
          signType: MeInvoiceSignType.hsmWithCks,
          invoiceData: const [
            MeInvoiceInvoiceData(refId: 'key-1', invSeries: '1C25TYY'),
          ],
        ),
      );

      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-1',
        result: result,
        canonicalInvoice: const {'invDate': '2026-08-01'},
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(outcome, isA<MeInvoicePublishDefiniteFailure>());
    });
  });

  group('MeInvoicePublishClassifier — mã từ chối theo tài liệu MISA', () {
    MeInvoicePublishOutcome classifyItem(String errorCode) {
      return MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-1',
        result: MeInvoiceResult.ok([
          MeInvoicePublishInvoiceResultItem(
            refId: 'key-1',
            errorCode: errorCode,
            descriptionErrorCode: 'desc',
          ),
        ]),
        canonicalInvoice: const {'invDate': '2026-08-01'},
      );
    }

    for (final code in const [
      'InvalidInvoiceData',
      'TaxRateInfo_VATRateName',
      'BuyerTaxCode_TaxCodeInvalid',
      'InvalidTaxCode',
      'InvalidInvoiceDate',
      'InvalidXMLContainEmoji',
      'InvoiceTemplateNotExist',
      'DeclarationNotExist',
      'InvalidDeclaration',
      'ExistDeclarationNotReceive',
      'InvoiceTemplateNotValidInDeclaration',
      'LicenseInfo_NotBuy',
      'LicenseInfo_OutOfInvoice',
      'LicenseInfo_Expired',
      'CallSignServiceFail',
    ]) {
      test('item $code là definiteFailure', () {
        final outcome = classifyItem(code);
        expect(outcome, isA<MeInvoicePublishDefiniteFailure>());
        expect((outcome as MeInvoicePublishDefiniteFailure).providerCode, code);
      });
    }

    for (final code in const [
      'InvoiceDetail_ItemName',
      'RequireError_BuyerLegalName',
      'StockInTaxCode_NotInfo_1_StockInLegalName',
      'Invalid_[Invoice.TaxRateInfo]',
    ]) {
      test('item mã theo tiền tố $code là definiteFailure', () {
        expect(classifyItem(code), isA<MeInvoicePublishDefiniteFailure>());
      });
    }

    for (final code in const [
      'Exception',
      'SignEsignHSMError',
      'SignSoftDream78Exception',
      'CreateInvoiceDataError',
      'DuplicateRefID',
      'SomeUnknownCode',
    ]) {
      test('item $code vẫn là undetermined', () {
        expect(classifyItem(code), isA<MeInvoicePublishUndetermined>());
      });
    }

    test('envelope lỗi dữ liệu theo tiền tố là definiteFailure', () {
      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-1',
        result: const MeInvoiceResult.failed(
          'InvoiceDetail_Quantity: Số lượng không hợp lệ',
        ),
        canonicalInvoice: const {'invDate': '2026-08-01'},
      );

      expect(outcome, isA<MeInvoicePublishDefiniteFailure>());
      final failure = outcome as MeInvoicePublishDefiniteFailure;
      expect(failure.providerCode, 'InvoiceDetail_Quantity');
      expect(failure.providerMessage, 'Số lượng không hợp lệ');
    });

    test('envelope LicenseInfo_Expired là definiteFailure', () {
      final outcome = MeInvoicePublishClassifier.classify(
        idempotencyKey: 'key-1',
        result: const MeInvoiceResult.failed('LicenseInfo_Expired: hết hạn'),
        canonicalInvoice: const {'invDate': '2026-08-01'},
      );

      expect(outcome, isA<MeInvoicePublishDefiniteFailure>());
    });

    test('mã từ chối phát hành không lan sang isDefiniteFailure chung', () {
      // isDefiniteFailure còn dùng cho /invoice/status: lỗi khi hỏi trạng thái
      // không chứng minh hóa đơn chưa phát hành.
      expect(
        MeInvoicePublishErrorCodes.isDefiniteFailure('LicenseInfo_Expired'),
        isFalse,
      );
      expect(
        MeInvoicePublishErrorCodes.isPublishRejection('LicenseInfo_Expired'),
        isTrue,
      );
    });
  });
}
