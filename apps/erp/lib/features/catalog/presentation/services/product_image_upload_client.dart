import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Uploads image bytes to a Supabase signed upload URL.
abstract final class ProductImageUploadClient {
  static Future<void> uploadFile({
    required String signedUploadUrl,
    required String localPath,
    required String contentType,
  }) async {
    final bytes = kIsWeb
        ? throw UnsupportedError('Use uploadBytes on web.')
        : await File(localPath).readAsBytes();
    await uploadBytes(
      signedUploadUrl: signedUploadUrl,
      bytes: bytes,
      contentType: contentType,
    );
  }

  static Future<void> uploadBytes({
    required String signedUploadUrl,
    required List<int> bytes,
    required String contentType,
  }) async {
    final response = await http.put(
      Uri.parse(signedUploadUrl),
      headers: <String, String>{
        'Content-Type': contentType,
      },
      body: bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Upload failed with status ${response.statusCode}',
        uri: Uri.parse(signedUploadUrl),
      );
    }
  }

  static String contentTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
