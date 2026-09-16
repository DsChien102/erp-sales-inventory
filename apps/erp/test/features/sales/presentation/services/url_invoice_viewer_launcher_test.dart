import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:erp/features/sales/presentation/services/url_invoice_viewer_launcher.dart';

void main() {
  group('UrlInvoiceViewerLauncher', () {
    test('launches URL with LaunchMode.inAppBrowserView', () async {
      Uri? launchedUri;
      LaunchMode? launchedMode;

      final launcher = UrlInvoiceViewerLauncher(
        launchUrlFn: (uri, {mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          launchedMode = mode;
          return true;
        },
      );

      const testUrl =
          'https://xvebhrcoidwbvnytrhln.supabase.co/storage/v1/object/sign/einvoice-documents/invoice.pdf';
      final ok = await launcher.launch(testUrl);

      expect(ok, isTrue);
      expect(launchedUri, Uri.parse(testUrl));
      expect(launchedMode, LaunchMode.inAppBrowserView);
    });

    test('returns false for invalid URL', () async {
      final launcher = UrlInvoiceViewerLauncher(
        launchUrlFn: (uri, {mode = LaunchMode.platformDefault}) async => true,
      );

      final ok = await launcher.launch('');
      expect(ok, isFalse);
    });

    test('rejects non-http schemes and hostless urls', () async {
      var launchCount = 0;
      final launcher = UrlInvoiceViewerLauncher(
        launchUrlFn: (uri, {mode = LaunchMode.platformDefault}) async {
          launchCount++;
          return true;
        },
      );

      expect(await launcher.launch('javascript:alert(1)'), isFalse);
      expect(await launcher.launch('file:///tmp/invoice.pdf'), isFalse);
      expect(await launcher.launch('https:///no-host'), isFalse);
      expect(launchCount, 0);
    });

    test('falls back to LaunchMode.externalApplication when inAppBrowserView throws', () async {
      final modesCalled = <LaunchMode>[];

      final launcher = UrlInvoiceViewerLauncher(
        launchUrlFn: (uri, {mode = LaunchMode.platformDefault}) async {
          modesCalled.add(mode);
          if (mode == LaunchMode.inAppBrowserView) {
            throw Exception('PlatformException simulating iOS SFSafariViewController rejection');
          }
          return true;
        },
      );

      const testUrl =
          'https://test.meinvoice.vn/download/tra-cuu/downloadhandler.ashx?type=pdf&Viewer=1';
      final ok = await launcher.launch(testUrl);

      expect(ok, isTrue);
      expect(modesCalled, [
        LaunchMode.inAppBrowserView,
        LaunchMode.externalApplication,
      ]);
    });

    test(
      'falls back to LaunchMode.externalApplication when inAppBrowserView returns false',
      () async {
        final modesCalled = <LaunchMode>[];

        final launcher = UrlInvoiceViewerLauncher(
          launchUrlFn: (uri, {mode = LaunchMode.platformDefault}) async {
            modesCalled.add(mode);
            if (mode == LaunchMode.inAppBrowserView) {
              return false;
            }
            return true;
          },
        );

        const testUrl =
            'https://test.meinvoice.vn/download/tra-cuu/downloadhandler.ashx?type=pdf&Viewer=1';
        final ok = await launcher.launch(testUrl);

        expect(ok, isTrue);
        expect(modesCalled, [
          LaunchMode.inAppBrowserView,
          LaunchMode.externalApplication,
        ]);
      },
    );

    test(
      'returns false when both inAppBrowserView and externalApplication throw or fail',
      () async {
        final launcher = UrlInvoiceViewerLauncher(
          launchUrlFn: (uri, {mode = LaunchMode.platformDefault}) async {
            throw Exception('Simulated failure');
          },
        );

        const testUrl =
            'https://test.meinvoice.vn/download/tra-cuu/downloadhandler.ashx?type=pdf&Viewer=1';
        final ok = await launcher.launch(testUrl);

        expect(ok, isFalse);
      },
    );
  });
}
