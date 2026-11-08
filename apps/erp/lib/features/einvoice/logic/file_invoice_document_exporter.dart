import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import 'i_invoice_document_exporter.dart';

/// Injectable native Share Sheet callback used by [FileInvoiceDocumentExporter].
typedef ShareInvoiceFiles =
    Future<ShareResult> Function(
      List<XFile> files, {
      String? subject,
      List<String>? fileNameOverrides,
      Rect? sharePositionOrigin,
    });

/// Native Share Sheet exporter for PDF and XML invoice documents.
///
/// Fail-closed: never opens signed URLs in a browser. Platforms without
/// native file share (e.g. web) return false.
final class FileInvoiceDocumentExporter implements IInvoiceDocumentExporter {
  const FileInvoiceDocumentExporter({
    http.Client? httpClient,
    ShareInvoiceFiles? shareFilesFn,
  }) : _httpClient = httpClient,
       _shareFilesFn = shareFilesFn;

  final http.Client? _httpClient;
  final ShareInvoiceFiles? _shareFilesFn;

  /// Non-zero origin required by iOS UIActivityViewController popover
  /// (iPad and some iPhone/Xcode runtimes that require sharePositionOrigin).
  static const Rect _defaultShareOrigin = Rect.fromLTWH(0, 0, 1, 1);

  @override
  Future<bool> exportDocument({
    required String filename,
    required InvoiceDocumentType type,
    String? url,
    List<int>? bytes,
    String? expectedSha256,
  }) async {
    Uint8List? documentBytes = bytes != null ? Uint8List.fromList(bytes) : null;

    if (documentBytes == null && url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }

      final ownsClient = _httpClient == null;
      final client = _httpClient ?? http.Client();
      try {
        final response = await client.get(uri);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint(
            'FileInvoiceDocumentExporter stage=http_fetch '
            'status=${response.statusCode}',
          );
          return false;
        }
        documentBytes = response.bodyBytes;
      } catch (error) {
        debugPrint(
          'FileInvoiceDocumentExporter stage=http_fetch '
          'errorType=${error.runtimeType}',
        );
        return false;
      } finally {
        if (ownsClient) {
          client.close();
        }
      }
    }

    if (documentBytes == null || documentBytes.isEmpty) {
      return false;
    }

    final expected = expectedSha256?.trim();
    if (expected == null || expected.isEmpty) {
      return false;
    }

    final actual = sha256.convert(documentBytes).toString();
    if (actual.toLowerCase() != expected.toLowerCase()) {
      return false;
    }

    if (kIsWeb) {
      return false;
    }

    final mimeType = type == InvoiceDocumentType.pdf ? 'application/pdf' : 'application/xml';

    try {
      final file = XFile.fromData(documentBytes, mimeType: mimeType);
      final shareFiles =
          _shareFilesFn ??
          (
            List<XFile> files, {
            String? subject,
            List<String>? fileNameOverrides,
            Rect? sharePositionOrigin,
          }) => Share.shareXFiles(
            files,
            subject: subject,
            fileNameOverrides: fileNameOverrides,
            sharePositionOrigin: sharePositionOrigin ?? _defaultShareOrigin,
          );
      final result = await shareFiles(
        [file],
        subject: filename,
        fileNameOverrides: [filename],
        sharePositionOrigin: _defaultShareOrigin,
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (error) {
      if (error is PlatformException) {
        debugPrint(
          'FileInvoiceDocumentExporter stage=native_share '
          'errorType=PlatformException code=${error.code}',
        );
      } else {
        debugPrint(
          'FileInvoiceDocumentExporter stage=native_share '
          'errorType=${error.runtimeType}',
        );
      }
      return false;
    }
  }
}
