import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:erp/features/sales/presentation/services/file_invoice_document_exporter.dart';
import 'package:flutter/services.dart' show Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileInvoiceDocumentExporter', () {
    for (final fixture in [
      (
        type: InvoiceDocumentType.pdf,
        filename: 'invoice.pdf',
        mime: 'application/pdf',
        body: <int>[0x25, 0x50, 0x44, 0x46, 0x2d],
      ),
      (
        type: InvoiceDocumentType.xml,
        filename: 'invoice.xml',
        mime: 'application/xml',
        body: utf8.encode('<HDon/>'),
      ),
    ]) {
      test(
        'shares ${fixture.type.name} bytes with native filename and MIME',
        () async {
          List<XFile>? sharedFiles;
          List<String>? sharedNames;
          final exporter = FileInvoiceDocumentExporter(
            shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
              sharedFiles = files;
              sharedNames = fileNameOverrides;
              return const ShareResult('success', ShareResultStatus.success);
            },
          );

          final result = await exporter.exportDocument(
            filename: fixture.filename,
            type: fixture.type,
            bytes: fixture.body,
            expectedSha256: sha256.convert(fixture.body).toString(),
          );

          expect(result, isTrue);
          expect(await sharedFiles!.single.readAsBytes(), fixture.body);
          expect(sharedFiles!.single.mimeType, fixture.mime);
          expect(sharedNames, [fixture.filename]);
        },
      );
    }

    test('fetches bytes from url and executes successfully', () async {
      final body = '<HDon><DLHDon Id="123"></DLHDon></HDon>';
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('signed-invoice.xml')) {
          return http.Response(
            body,
            200,
            headers: {'content-type': 'application/xml; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      var shareCalled = false;
      List<String>? sharedNames;

      final exporter = FileInvoiceDocumentExporter(
        httpClient: mockClient,
        shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
          shareCalled = true;
          sharedNames = fileNameOverrides;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await exporter.exportDocument(
        filename: 'HD_C26TYY_00000036.xml',
        type: InvoiceDocumentType.xml,
        url: 'https://storage.supabase.co/object/sign/signed-invoice.xml?token=abc',
        expectedSha256: sha256.convert(utf8.encode(body)).toString(),
      );

      expect(result, isTrue);
      expect(shareCalled, isTrue);
      expect(sharedNames, ['HD_C26TYY_00000036.xml']);
    });

    test('does not share fetched bytes when sha256 differs', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<HDon>actual</HDon>',
          200,
          headers: {'content-type': 'application/xml; charset=utf-8'},
        );
      });

      var shareCalled = false;

      final exporter = FileInvoiceDocumentExporter(
        httpClient: mockClient,
        shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
          shareCalled = true;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await exporter.exportDocument(
        filename: 'HD_C26TYY_00000036.xml',
        type: InvoiceDocumentType.xml,
        url: 'https://storage.supabase.co/object/sign/signed-invoice.xml?token=abc',
        expectedSha256: 'deadbeef',
      );

      expect(result, isFalse);
      expect(shareCalled, isFalse);
    });

    test(
      'native share dismissed is a successful handoff cancellation',
      () async {
        final body = utf8.encode('<HDon>ok</HDon>');
        final exporter = FileInvoiceDocumentExporter(
          shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
            return const ShareResult('dismissed', ShareResultStatus.dismissed);
          },
        );

        final result = await exporter.exportDocument(
          filename: 'invoice.xml',
          type: InvoiceDocumentType.xml,
          bytes: body,
          expectedSha256: sha256.convert(body).toString(),
        );

        expect(result, isTrue);
      },
    );

    test('http failure returns false and never reports export success', () async {
      final mockClient = MockClient((_) async => http.Response('Server error', 500));
      var shareCalled = false;

      final exporter = FileInvoiceDocumentExporter(
        httpClient: mockClient,
        shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
          shareCalled = true;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await exporter.exportDocument(
        filename: 'invoice.pdf',
        type: InvoiceDocumentType.pdf,
        url: 'https://storage.example.com/invoice.pdf',
        expectedSha256: 'not-used-after-http-failure',
      );

      expect(result, isFalse);
      expect(shareCalled, isFalse);
    });

    test('invalid URL scheme returns false without sharing', () async {
      var shareCalled = false;
      final exporter = FileInvoiceDocumentExporter(
        shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
          shareCalled = true;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await exporter.exportDocument(
        filename: 'invoice.pdf',
        type: InvoiceDocumentType.pdf,
        url: 'file:///tmp/invoice.pdf',
        expectedSha256: 'unused',
      );

      expect(result, isFalse);
      expect(shareCalled, isFalse);
    });

    test('http client throw returns false without sharing', () async {
      final mockClient = MockClient((_) async {
        throw http.ClientException('network down');
      });
      var shareCalled = false;
      final exporter = FileInvoiceDocumentExporter(
        httpClient: mockClient,
        shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
          shareCalled = true;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await exporter.exportDocument(
        filename: 'invoice.pdf',
        type: InvoiceDocumentType.pdf,
        url: 'https://storage.example.com/invoice.pdf',
        expectedSha256: 'unused',
      );

      expect(result, isFalse);
      expect(shareCalled, isFalse);
    });

    test('empty http body returns false without sharing', () async {
      final mockClient = MockClient((_) async => http.Response.bytes([], 200));
      var shareCalled = false;
      final exporter = FileInvoiceDocumentExporter(
        httpClient: mockClient,
        shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
          shareCalled = true;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await exporter.exportDocument(
        filename: 'invoice.pdf',
        type: InvoiceDocumentType.pdf,
        url: 'https://storage.example.com/invoice.pdf',
        expectedSha256: 'unused',
      );

      expect(result, isFalse);
      expect(shareCalled, isFalse);
    });

    test('missing expectedSha256 returns false without sharing', () async {
      var shareCalled = false;
      final body = utf8.encode('<HDon/>');
      final exporter = FileInvoiceDocumentExporter(
        shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
          shareCalled = true;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await exporter.exportDocument(
        filename: 'invoice.xml',
        type: InvoiceDocumentType.xml,
        bytes: body,
      );

      expect(result, isFalse);
      expect(shareCalled, isFalse);
    });

    test('native share throw returns false', () async {
      final body = utf8.encode('<HDon/>');
      final exporter = FileInvoiceDocumentExporter(
        shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
          throw StateError('share unavailable');
        },
      );

      final result = await exporter.exportDocument(
        filename: 'invoice.xml',
        type: InvoiceDocumentType.xml,
        bytes: body,
        expectedSha256: sha256.convert(body).toString(),
      );

      expect(result, isFalse);
    });

    test('ShareResultStatus.unavailable returns false', () async {
      final body = utf8.encode('<HDon/>');
      final exporter = FileInvoiceDocumentExporter(
        shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
          return const ShareResult(
            'unavailable',
            ShareResultStatus.unavailable,
          );
        },
      );

      final result = await exporter.exportDocument(
        filename: 'invoice.xml',
        type: InvoiceDocumentType.xml,
        bytes: body,
        expectedSha256: sha256.convert(body).toString(),
      );

      expect(result, isFalse);
    });

    test(
      'passes non-zero sharePositionOrigin for iOS popover compatibility',
      () async {
        final body = utf8.encode('<HDon/>');
        Rect? sharedOrigin;
        final exporter = FileInvoiceDocumentExporter(
          shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
            sharedOrigin = sharePositionOrigin;
            return const ShareResult('success', ShareResultStatus.success);
          },
        );

        final result = await exporter.exportDocument(
          filename: 'invoice.xml',
          type: InvoiceDocumentType.xml,
          bytes: body,
          expectedSha256: sha256.convert(body).toString(),
        );

        expect(result, isTrue);
        expect(sharedOrigin, isNotNull);
        expect(sharedOrigin!.width, greaterThan(0));
        expect(sharedOrigin!.height, greaterThan(0));
      },
    );

    test(
      'waits for complete verified bytes before invoking native share',
      () async {
        final body = utf8.encode('<HDon/>');
        final responseGate = Completer<http.Response>();
        var shareCalled = false;
        final exporter = FileInvoiceDocumentExporter(
          httpClient: MockClient((_) => responseGate.future),
          shareFilesFn: (files, {subject, fileNameOverrides, sharePositionOrigin}) async {
            shareCalled = true;
            return const ShareResult('success', ShareResultStatus.success);
          },
        );

        final exportFuture = exporter.exportDocument(
          filename: 'invoice.xml',
          type: InvoiceDocumentType.xml,
          url: 'https://storage.example.com/invoice.xml',
          expectedSha256: sha256.convert(body).toString(),
        );
        await Future<void>.delayed(Duration.zero);

        expect(shareCalled, isFalse);

        responseGate.complete(http.Response.bytes(body, 200));
        expect(await exportFuture, isTrue);
        expect(shareCalled, isTrue);
      },
    );
  });
}
