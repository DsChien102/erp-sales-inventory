import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Storage bucket for catalog product images.
const catalogProductImagesBucket = 'catalog-product-images';

/// Resolves a storage key or legacy URL into a displayable read URL.
///
/// Upload signed URLs (`/object/upload/sign/`) cannot be used for GET and are
/// rejected. Private bucket images are exposed via short-lived signed read URLs.
final class ProductImageDisplayResolver {
  ProductImageDisplayResolver({SupabaseClient? client}) : _clientOverride = client;

  static final ProductImageDisplayResolver instance =
      ProductImageDisplayResolver();

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;
  final Map<String, _CachedSignedUrl> _cache = {};

  static const Duration _signedUrlTtl = Duration(hours: 1);
  static const Duration _cacheSafetyMargin = Duration(minutes: 5);

  static bool isHttpUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool isUploadSignedUrl(String value) {
    return value.contains('/object/upload/sign/');
  }

  static bool looksLikeStorageKey(String value) {
    return value.isNotEmpty && !isHttpUrl(value);
  }

  /// Extracts `{tenant}/staging/...` or `{tenant}/products/...` from Supabase
  /// storage URLs, including upload/read/public object paths.
  static String? extractStorageKeyFromSupabaseUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    const bucketSegment = '/$catalogProductImagesBucket/';
    final index = uri.path.indexOf(bucketSegment);
    if (index == -1) {
      return null;
    }

    final key = uri.path.substring(index + bucketSegment.length);
    if (key.isEmpty) {
      return null;
    }
    return Uri.decodeComponent(key);
  }

  /// Normalizes API/legacy values into a storage key when possible.
  static String? normalizeToStorageKey(String? reference) {
    if (reference == null || reference.trim().isEmpty) {
      return null;
    }

    final value = reference.trim();
    if (isUploadSignedUrl(value)) {
      return extractStorageKeyFromSupabaseUrl(value);
    }
    if (looksLikeStorageKey(value)) {
      return value;
    }
    if (isHttpUrl(value) && value.contains('supabase.co/storage')) {
      return extractStorageKeyFromSupabaseUrl(value);
    }
    return null;
  }

  /// Returns a URL suitable for [Image.network], or `null` when unavailable.
  Future<String?> resolve(String? reference) async {
    if (reference == null || reference.trim().isEmpty) {
      return null;
    }

    final value = reference.trim();
    if (isUploadSignedUrl(value)) {
      final storageKey = extractStorageKeyFromSupabaseUrl(value);
      if (storageKey == null) {
        return null;
      }
      return _signedReadUrlForKey(storageKey);
    }

    if (looksLikeStorageKey(value)) {
      return _signedReadUrlForKey(value);
    }

    if (!isHttpUrl(value)) {
      return null;
    }

    if (value.contains('supabase.co/storage')) {
      final storageKey = extractStorageKeyFromSupabaseUrl(value);
      if (storageKey != null) {
        return _signedReadUrlForKey(storageKey);
      }
    }

    // Permanent CDN / fake harness URLs.
    return value;
  }

  Future<String> _signedReadUrlForKey(String storageKey) async {
    final cached = _cache[storageKey];
    if (cached != null &&
        cached.expiresAt.isAfter(DateTime.now().add(_cacheSafetyMargin))) {
      return cached.url;
    }

    final url = await _client.storage
        .from(catalogProductImagesBucket)
        .createSignedUrl(
          storageKey,
          _signedUrlTtl.inSeconds,
        );

    _cache[storageKey] = _CachedSignedUrl(
      url: url,
      expiresAt: DateTime.now().add(_signedUrlTtl),
    );
    return url;
  }
}

final class _CachedSignedUrl {
  const _CachedSignedUrl({
    required this.url,
    required this.expiresAt,
  });

  final String url;
  final DateTime expiresAt;
}
