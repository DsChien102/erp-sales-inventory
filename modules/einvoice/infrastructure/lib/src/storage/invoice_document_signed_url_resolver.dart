import 'package:supabase/supabase.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Generates short-lived signed URLs for private invoice document storage.
final class InvoiceDocumentSignedUrlResolver {
  InvoiceDocumentSignedUrlResolver({
    required SupabaseClient supabase,
    ILogger? logger,
    this.signedUrlTtlSeconds = 300,
    this.bucketName = 'einvoice-documents',
  }) : _supabase = supabase,
       _logger = logger;

  static const defaultBucketName = 'einvoice-documents';
  static const defaultSignedUrlTtlSeconds = 300;

  final SupabaseClient _supabase;
  final ILogger? _logger;
  final int signedUrlTtlSeconds;
  final String bucketName;

  Future<String?> tryCreateSignedUrl(String storageReference) async {
    try {
      return await _supabase.storage
          .from(bucketName)
          .createSignedUrl(storageReference, signedUrlTtlSeconds);
    } on StorageException catch (error) {
      _logger?.warning(
        'invoice document signed url failed for ref=$storageReference '
        'status=${error.statusCode}',
      );
      return null;
    } catch (error) {
      _logger?.warning(
        'invoice document signed url failed for ref=$storageReference',
      );
      return null;
    }
  }

  DateTime accessLeaseExpiresAt({DateTime? now}) {
    return (now ?? DateTime.now()).add(Duration(seconds: signedUrlTtlSeconds));
  }
}
