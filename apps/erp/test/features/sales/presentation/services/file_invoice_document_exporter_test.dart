import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:erp/features/sales/presentation/services/file_invoice_document_exporter.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileInvoiceDocumentExporter', () {
    test('fetches bytes from url and executes successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('signed-invoice.xml')) {
          return http.Response(
            '<HDon><DLHDon Id="123"></DLHDon></HDon>',
            200,
            headers: {'content-type': 'application/xml; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      var shareCalled = false;
      String? sharedFilename;

      final exporter = FileInvoiceDocumentExporter(
        httpClient: mockClient,
        getTempDirFn: () async => Directory.systemTemp,
        shareFilesFn: (files, {subject}) async {
          shareCalled = true;
          sharedFilename = files.first.name;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await exporter.exportDocument(
        filename: 'HD_C26TYY_00000036.xml',
        type: InvoiceDocumentType.xml,
        url: 'https://storage.supabase.co/object/sign/signed-invoice.xml?token=abc',
      );

      expect(result, isTrue);
      expect(shareCalled, isTrue);
      expect(sharedFilename, 'HD_C26TYY_00000036.xml');
    });

    test('falls back to launchUrl with download parameter on fetch failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      Uri? launchedUri;
      final exporter = FileInvoiceDocumentExporter(
        httpClient: mockClient,
        launchUrlFn: (uri, {mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          return true;
        },
      );

      final result = await exporter.exportDocument(
        filename: 'HD_C26TYY_00000036.xml',
        type: InvoiceDocumentType.xml,
        url: 'https://storage.supabase.co/object/sign/invoice.xml?token=abc',
      );

      expect(result, isTrue);
      expect(launchedUri, isNotNull);
      expect(launchedUri!.queryParameters['download'], 'HD_C26TYY_00000036.xml');
      expect(launchedUri!.queryParameters['token'], 'abc');
    });
  });
}
