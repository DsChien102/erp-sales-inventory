import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_einvoice_repository.dart';

void main() {
  group('FakeEInvoiceRepository', () {
    test('records method calls in order', () async {
      final repo = FakeEInvoiceRepository();

      await repo.getProjection('so-1');
      await repo.getReadiness('so-1');

      expect(repo.calls, equals(['getProjection', 'getReadiness']));
    });

    test('throwOn throws expected error and records call', () async {
      final repo = FakeEInvoiceRepository(
        throwOn: {'getProjection': const AppException('NO_PERMISSION')},
      );

      expect(
        () => repo.getProjection('so-1'),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION'),
        ),
      );
      expect(repo.calls, equals(['getProjection']));
    });

    test('holdOn pauses until completer completes', () async {
      final gate = Completer<void>();
      final repo = FakeEInvoiceRepository(
        holdOn: {'getProjection': gate},
      );

      var finished = false;
      unawaited(
        repo.getProjection('so-1').then((_) {
          finished = true;
        }),
      );

      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, equals(['getProjection']));
      expect(finished, isFalse);

      gate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(finished, isTrue);
    });

    test('previewResults yields items sequentially then repeats last item', () async {
      const a = InvoicePreviewResultDto(viewerRef: 'preview-a', warnings: []);
      const b = InvoicePreviewResultDto(viewerRef: 'preview-b', warnings: []);
      final repo = FakeEInvoiceRepository(previewResults: [a, b]);

      expect(await repo.getPreview('so-1'), equals(a));
      expect(await repo.getPreview('so-1'), equals(b));
      expect(await repo.getPreview('so-1'), equals(b));
    });
  });
}
