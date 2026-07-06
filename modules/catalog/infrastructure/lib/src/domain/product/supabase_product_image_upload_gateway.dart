import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';

/// Supabase Storage bucket for catalog product images.
const catalogProductImagesBucket = 'catalog-product-images';

final class SupabaseProductImageUploadGateway implements IProductImageUploadPort {
  SupabaseProductImageUploadGateway({
    required SupabaseClient supabase,
    required SupabaseSchemaRpcClient rpcClient,
  })  : _supabase = supabase,
        _rpcClient = rpcClient;

  final SupabaseClient _supabase;
  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProductImageUploadSlotDto> reserveUploadSlot(
    RequestProductImageUploadCommand command,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'request_product_image_upload',
        params: <String, dynamic>{
          'p_tenant_id': command.tenantId,
          'p_file_name': command.fileName,
          'p_content_type': command.contentType,
          'p_byte_size': command.byteSize,
          'p_actor_id': command.actorId,
        },
      );

      if (rows.isEmpty) {
        throw ApplicationException('Image upload slot was not created.');
      }

      final row = rows.first;
      final slotId = row['slot_id']?.toString();
      final storageKey = row['storage_key']?.toString();
      final expiresRaw = row['expires_at'];

      if (slotId == null ||
          slotId.isEmpty ||
          storageKey == null ||
          storageKey.isEmpty) {
        throw ApplicationException('Invalid image upload slot response.');
      }

      final expiresAt = _parseExpiresAt(expiresRaw);

      final signed = await _supabase.storage
          .from(catalogProductImagesBucket)
          .createSignedUploadUrl(storageKey);

      return ProductImageUploadSlotDto(
        slotId: slotId,
        storageKey: storageKey,
        signedUploadUrl: signed.signedUrl,
        expiresAt: expiresAt,
      );
    } on StorageException catch (error) {
      throw ApplicationException(error.message);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  DateTime _parseExpiresAt(Object? value) {
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value).toUtc();
    }
    return DateTime.now().toUtc().add(const Duration(hours: 1));
  }
}
