import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import 'i_invoice_document_exporter.dart';

/// File and native Share Sheet exporter for PDF and XML invoice documents on Mobile/Desktop/Web.
final class FileInvoiceDocumentExporter implements IInvoiceDocumentExporter {
  const FileInvoiceDocumentExporter({
    http.Client? httpClient,
    Future<bool> Function(Uri uri, {LaunchMode mode})? launchUrlFn,
    Future<ShareResult> Function(List<XFile> files, {String? subject})? shareFilesFn,
    Future<Directory> Function()? getTempDirFn,
  })  : _httpClient = httpClient,
        _launchUrlFn = launchUrlFn,
        _shareFilesFn = shareFilesFn,
        _getTempDirFn = getTempDirFn;

  final http.Client? _httpClient;
  final Future<bool> Function(Uri uri, {LaunchMode mode})? _launchUrlFn;
  final Future<ShareResult> Function(List<XFile> files, {String? subject})? _shareFilesFn;
  final Future<Directory> Function()? _getTempDirFn;

  @override
  Future<bool> exportDocument({
    required String filename,
    required InvoiceDocumentType type,
    String? url,
    List<int>? bytes,
  }) async {
    // 1. Resolve document bytes: from passed bytes or by fetching from signed URL
    Uint8List? documentBytes = bytes != null ? Uint8List.fromList(bytes) : null;
    if (documentBytes == null && url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        try {
          final client = _httpClient ?? http.Client();
          final response = await client.get(uri);
          if (response.statusCode >= 200 && response.statusCode < 300) {
            documentBytes = response.bodyBytes;
          }
        } catch (_) {
          // Network fetch failed; proceed to fallback launchUrl
        }
      }
    }

    // 2. On Mobile / Desktop with resolved bytes: invoke native Share Sheet (Save to Files / Share to App)
    if (documentBytes != null && !kIsWeb) {
      try {
        final tempDir = _getTempDirFn != null
            ? await _getTempDirFn()
            : await getTemporaryDirectory();
        final file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(documentBytes, flush: true);

        final mimeType = type == InvoiceDocumentType.pdf
            ? 'application/pdf'
            : 'application/xml';

        final result = _shareFilesFn != null
            ? await _shareFilesFn(
                [XFile(file.path, name: filename, mimeType: mimeType)],
                subject: filename,
              )
            : await Share.shareXFiles(
                [XFile(file.path, name: filename, mimeType: mimeType)],
                subject: filename,
              );

        return result.status == ShareResultStatus.success ||
            result.status == ShareResultStatus.dismissed;
      } catch (_) {
        // If native share fails, fallback to browser launcher below
      }
    }

    // 3. Fallback: launch URL with download parameter
    // Appending `download=filename` forces Supabase Storage to send
    // `Content-Disposition: attachment; filename="..."`, so mobile browsers
    // trigger a download prompt instead of rendering raw XML text.
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final queryParams = Map<String, String>.from(uri.queryParameters);
        if (!queryParams.containsKey('download')) {
          queryParams['download'] = filename;
        }
        final downloadUri = uri.replace(queryParameters: queryParams);
        if (_launchUrlFn != null) {
          return _launchUrlFn(downloadUri, mode: LaunchMode.inAppBrowserView);
        }
        return launchUrl(downloadUri, mode: LaunchMode.inAppBrowserView);
      }
    }

    return false;
  }
}
