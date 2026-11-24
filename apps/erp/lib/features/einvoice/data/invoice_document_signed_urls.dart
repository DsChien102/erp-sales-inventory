import 'package:logging/logging.dart';
import 'package:supabase/supabase.dart';

class InvoiceDocumentSignedUrls {
  InvoiceDocumentSignedUrls({
    required SupabaseStorageClient storage,
    this.ttlSeconds = 300,
    this.bucket = 'einvoice-documents',
  }) : _storage = storage;

  final SupabaseStorageClient _storage;
  final int ttlSeconds;
  final String bucket;

  static final _log = Logger('InvoiceDocumentSignedUrls');

  Future<String?> tryCreate(String ref) async {
    try {
      return await _storage.from(bucket).createSignedUrl(ref, ttlSeconds);
    } on StorageException catch (error, st) {
      _log.warning(
        'invoice document signed url failed for ref=$ref status=${error.statusCode}',
        error,
        st,
      );
      return null;
    } catch (error, st) {
      _log.warning(
        'invoice document signed url failed for ref=$ref',
        error,
        st,
      );
      return null;
    }
  }

  DateTime leaseExpiresAt({DateTime? now}) {
    return (now ?? DateTime.now()).add(Duration(seconds: ttlSeconds));
  }
}

