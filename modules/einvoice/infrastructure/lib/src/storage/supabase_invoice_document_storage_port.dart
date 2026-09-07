import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Stores invoice document bytes in the private `einvoice-documents` bucket.
final class SupabaseInvoiceDocumentStoragePort
    implements IInvoiceDocumentStoragePort {
  SupabaseInvoiceDocumentStoragePort({
    required SupabaseClient supabase,
    this.bucketName = 'einvoice-documents',
  }) : _supabase = supabase;

  final SupabaseClient _supabase;
  final String bucketName;

  @override
  Future<StoredInvoiceDocumentDto> store({
    required String tenantId,
    required String electronicInvoiceId,
    required InvoiceDocumentType documentType,
    required int documentVersion,
    required List<int> bytes,
  }) async {
    final validationError = InvoiceDocumentContentPolicy.validate(
      type: documentType,
      bytes: bytes,
    );
    if (validationError != null) {
      throw RpcException('DOCUMENT_CONTENT_INVALID: $validationError');
    }

    final checksum = sha256.convert(bytes).toString();
    final isZip = InvoiceDocumentContentPolicy.isZip(bytes);
    final extension = documentType == InvoiceDocumentType.pdf
        ? 'pdf'
        : (isZip ? 'zip' : 'xml');
    final contentType = _contentTypeFor(documentType, isZip: isZip);
    final fileName = '$checksum.$extension';
    final path =
        '$tenantId/$electronicInvoiceId/${documentType.name}/v$documentVersion/$fileName';

    final bucket = _supabase.storage.from(bucketName);
    try {
      await bucket.uploadBinary(
        path,
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );
    } on StorageException catch (error) {
      if (!_isDuplicateObjectError(error)) {
        throw RpcException('SYSTEM_ERROR: storage upload failed');
      }
      await _verifyExistingObject(
        bucket: bucket,
        path: path,
        expectedChecksum: checksum,
      );
    }

    return StoredInvoiceDocumentDto(
      storageReference: path,
      checksum: checksum,
      contentType: contentType,
      fileName: fileName,
      fileSize: bytes.length,
    );
  }

  static String _contentTypeFor(
    InvoiceDocumentType documentType, {
    bool isZip = false,
  }) {
    return switch (documentType) {
      InvoiceDocumentType.pdf => 'application/pdf',
      InvoiceDocumentType.xml => isZip ? 'application/zip' : 'application/xml',
    };
  }

  static bool _isDuplicateObjectError(StorageException error) {
    final status = error.statusCode?.toString();
    return status == '409' || status == '400';
  }

  Future<void> _verifyExistingObject({
    required StorageFileApi bucket,
    required String path,
    required String expectedChecksum,
  }) async {
    final existingBytes = await bucket.download(path);
    final existingChecksum = sha256.convert(existingBytes).toString();
    if (existingChecksum != expectedChecksum) {
      throw RpcException(
        'SYSTEM_ERROR: storage object checksum mismatch for $path',
      );
    }
  }
}
