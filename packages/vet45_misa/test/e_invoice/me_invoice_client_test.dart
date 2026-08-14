import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:vet45_misa/e_invoice.dart';

MeInvoicePublishRequest _samplePublishRequest({String refId = 'ref-9'}) {
  return MeInvoicePublishRequest(
    signType: MeInvoiceSignType.hsmWithCks,
    invoiceData: [
      MeInvoiceInvoiceData(
        refId: refId,
        invSeries: '1C25TYY',
        invDate: '2026-08-01',
        buyerLegalName: 'Buyer',
        buyerAddress: 'Address',
        totalSaleAmountOc: 100,
        totalSaleAmount: 100,
        totalAmountWithoutVatOc: 100,
        totalAmountWithoutVat: 100,
        totalVatAmountOc: 10,
        totalVatAmount: 10,
        totalDiscountAmountOc: 0,
        totalDiscountAmount: 0,
        totalAmountOc: 110,
        totalAmount: 110,
        totalAmountInWords: 'One hundred ten',
        originalInvoiceDetail: const [
          MeInvoiceOriginalInvoiceDetail(
            itemType: 1,
            lineNumber: 1,
            sortOrder: 1,
            itemName: 'Svc',
            quantity: 1,
            unitPrice: 100,
            amountOc: 100,
            amount: 100,
            amountWithoutVatOc: 100,
            amountWithoutVat: 100,
            vatRateName: '10%',
            vatAmountOc: 10,
            vatAmount: 10,
          ),
        ],
        taxRateInfo: const [
          MeInvoiceTaxRateInfo(
            vatRateName: '10%',
            amountWithoutVatOc: 100,
            vatAmountOc: 10,
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('MeInvoiceClient soft-fail', () {
    test('missing app id does not call network', () async {
      var calls = 0;
      final httpClient = MockClient((request) async {
        calls++;
        return http.Response('{}', 200);
      });
      final client = MeInvoiceClient(
        config: const MeInvoiceConfig(
          baseUrl: MeInvoiceConfig.testBaseUrl,
          appId: null,
          taxCode: '0123456789',
          username: 'u',
          password: 'p',
        ),
        httpClient: httpClient,
      );

      final result = await client.listInvoiceTemplates(invoiceWithCode: true);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'missing_MISA_MEINVOICE_APP_ID');
      expect(calls, 0);
    });

    test('empty password soft-fails', () async {
      final client = MeInvoiceClient(
        config: const MeInvoiceConfig(
          baseUrl: MeInvoiceConfig.testBaseUrl,
          appId: 'app',
          taxCode: '0123456789',
          username: 'u',
          password: '',
        ),
      );
      final result = await client.publish(_samplePublishRequest());
      expect(result.error, 'missing_MISA_MEINVOICE_PASSWORD');
    });
  });

  group('MeInvoiceClient HTTP', () {
    late MeInvoiceConfig config;

    setUp(() {
      config = const MeInvoiceConfig(
        baseUrl: 'https://example.test/api/integration',
        appId: 'app-id',
        taxCode: '0100000000',
        username: 'user',
        password: 'secret',
      );
    });

    test('seeded bearer skips /auth/token', () async {
      var authCalls = 0;
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          authCalls++;
          return http.Response('should not login', 500);
        }
        expect(request.headers['Authorization'], 'Bearer seeded-token');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'Success': true,
            'Data': <Object>[],
          }),
          200,
        );
      });

      final client = MeInvoiceClient(
        config: MeInvoiceConfig(
          baseUrl: 'https://example.test/api/integration',
          accessToken: 'seeded-token',
          accessTokenExpiresAt: DateTime.now().toUtc().add(
            const Duration(days: 1),
          ),
        ),
        httpClient: httpClient,
      );

      final result = await client.listInvoiceTemplates(invoiceWithCode: true);
      expect(result.isSuccess, isTrue);
      expect(authCalls, 0);
    });

    test('listInvoiceTemplates maps wire payload', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'Success': true,
              'Data': 'token-1',
            }),
            200,
          );
        }
        expect(request.method, 'GET');
        expect(request.url.path, '/api/integration/invoice/templates');
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.url.queryParameters['invoiceWithCode'], 'true');
        expect(request.url.queryParameters['ticket'], 'false');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'Success': true,
            'Data': jsonEncode([
              <String, dynamic>{
                'IPTemplateID': 'tpl-1',
                'CompanyID': 15388,
                'TemplateName': 'GTGT',
                'InvTemplateNo': '1',
                'InvSeries': '1C25TYY',
                'OrgInvSeries': '1KTYY',
                'CreatedDate': '2024-01-15T10:00:00+07:00',
                'ModifiedDate': '2024-06-01T08:30:00+07:00',
                'Inactive': false,
                'IsInheritFromOldTemplate': true,
                'IsSendSummary': false,
                'IsTemplatePetrol': false,
                'IsMoreVATRate': true,
              },
            ]),
          }),
          200,
        );
      });

      final client = MeInvoiceClient(config: config, httpClient: httpClient);
      final result = await client.listInvoiceTemplates(invoiceWithCode: true);

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
      final t = result.data!.first;
      expect(t.ipTemplateId, 'tpl-1');
      expect(t.companyId, 15388);
      expect(t.invSeries, '1C25TYY');
      expect(t.orgInvSeries, '1KTYY');
      expect(t.createdDate, isNotNull);
      expect(t.modifiedDate, isNotNull);
      expect(t.inactive, isFalse);
      expect(t.isInheritFromOldTemplate, isTrue);
      expect(t.isSendSummary, isFalse);
      expect(t.isTemplatePetrol, isFalse);
      expect(t.isMoreVatRate, isTrue);
    });

    test('publish sends SignType envelope and parses publishInvoiceResult', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return http.Response(
            jsonEncode(<String, dynamic>{'Success': true, 'Data': 'tok'}),
            200,
          );
        }
        expect(request.method, 'POST');
        expect(request.url.path, '/api/integration/invoice');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['SignType'], 2);
        expect(body['PublishInvoiceData'], isNull);
        final invoiceData = body['InvoiceData'] as List<dynamic>;
        expect(invoiceData, hasLength(1));
        expect(invoiceData.first['RefID'], 'ref-9');
        expect(invoiceData.first['BuyerLegalName'], 'Buyer');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': true,
            'publishInvoiceResult': [
              <String, dynamic>{
                'RefID': 'ref-9',
                'TransactionID': 'tx-9',
                'InvNo': '0000009',
              },
            ],
          }),
          200,
        );
      });

      final client = MeInvoiceClient(config: config, httpClient: httpClient);
      final result = await client.publish(_samplePublishRequest());

      expect(result.isSuccess, isTrue);
      expect(result.data!.single.transactionId, 'tx-9');
      expect(result.data!.single.invNo, '0000009');
    });

    test('getStatus returns failed when data list is empty', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return http.Response(
            jsonEncode(<String, dynamic>{'Success': true, 'Data': 'tok'}),
            200,
          );
        }
        if (request.url.path.endsWith('/invoice/status')) {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'success': true,
              'data': <Object>[],
            }),
            200,
          );
        }
        return http.Response('unexpected', 500);
      });

      final client = MeInvoiceClient(config: config, httpClient: httpClient);
      final result = await client.getStatus(
        ids: const ['tx-1'],
        inputType: MeInvoiceStatusInputType.transactionId,
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
      );
      expect(result.isSuccess, isFalse);
      expect(result.error, 'meinvoice_status_empty_data');
    });

    test('getStatus and download use array body and query params', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return http.Response(
            jsonEncode(<String, dynamic>{'Success': true, 'Data': 'tok'}),
            200,
          );
        }
        if (request.url.path.endsWith('/invoice/status')) {
          expect(jsonDecode(request.body), ['tx-1']);
          expect(request.url.queryParameters['inputType'], '1');
          expect(request.url.queryParameters['invoiceWithCode'], 'true');
          return http.Response(
            jsonEncode(<String, dynamic>{
              'success': true,
              'data': [
                <String, dynamic>{
                  'TransactionID': 'tx-1',
                  'PublishStatus': 2,
                  'InvNo': '0000001',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/invoice/download')) {
          expect(jsonDecode(request.body), ['tx-1']);
          expect(request.url.queryParameters['downloadDataType'], 'pdf');
          return http.Response(
            jsonEncode(<String, dynamic>{
              'success': true,
              'data': [
                <String, dynamic>{
                  'TransactionID': 'tx-1',
                  'Data': 'ZmFrZQ==',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('unexpected', 500);
      });

      final client = MeInvoiceClient(config: config, httpClient: httpClient);
      const query = MeInvoiceInvoiceQuery(invoiceWithCode: true);

      final status = await client.getStatus(
        ids: const ['tx-1'],
        inputType: MeInvoiceStatusInputType.transactionId,
        query: query,
      );
      expect(status.isSuccess, isTrue);
      expect(status.data!.single.publishStatus, 2);

      final download = await client.download(
        transactionIds: const ['tx-1'],
        query: query,
        downloadDataType: MeInvoiceDownloadDataType.pdf,
      );
      expect(download.isSuccess, isTrue);
      expect(download.data!.single.bytes, isNotEmpty);
    });

    test('download rejects more than 50 ids', () async {
      final client = MeInvoiceClient(
        config: config,
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      final ids = List<String>.generate(51, (i) => 'tx-$i');
      final result = await client.download(
        transactionIds: ids,
        query: const MeInvoiceInvoiceQuery(invoiceWithCode: true),
        downloadDataType: MeInvoiceDownloadDataType.xml,
      );
      expect(result.error, 'meinvoice_too_many_transaction_ids');
    });

    test('rate limit maps to rateLimited', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return http.Response(
            jsonEncode(<String, dynamic>{'Success': true, 'Data': 'tok'}),
            200,
          );
        }
        return http.Response('slow down', 429);
      });
      final client = MeInvoiceClient(config: config, httpClient: httpClient);
      final result = await client.listInvoiceTemplates(invoiceWithCode: false);
      expect(result.rateLimited, isTrue);
      expect(result.error, 'meinvoice_429_rate_limited');
    });

    test('token expired triggers refresh then retries', () async {
      var authCalls = 0;
      var refreshCalls = 0;
      var templateCalls = 0;

      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          authCalls++;
          return http.Response(
            jsonEncode(<String, dynamic>{
              'Success': true,
              'Data': 'token-old',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/auth/refreshtoken')) {
          refreshCalls++;
          expect(request.body, 'token-old');
          return http.Response(
            jsonEncode(<String, dynamic>{
              'Success': true,
              'Data': 'token-new',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/invoice/templates')) {
          templateCalls++;
          if (templateCalls == 1) {
            expect(request.headers['Authorization'], 'Bearer token-old');
            return http.Response(
              jsonEncode(<String, dynamic>{
                'Success': false,
                'ErrorCode': 'TokenExpiredCode',
              }),
              200,
            );
          }
          expect(request.headers['Authorization'], 'Bearer token-new');
          return http.Response(
            jsonEncode(<String, dynamic>{
              'Success': true,
              'Data': <Object>[],
            }),
            200,
          );
        }
        return http.Response('unexpected', 500);
      });

      final client = MeInvoiceClient(config: config, httpClient: httpClient);
      final result = await client.listInvoiceTemplates(invoiceWithCode: true);

      expect(result.isSuccess, isTrue);
      expect(authCalls, 1);
      expect(refreshCalls, 1);
      expect(templateCalls, 2);
    });
  });
}
