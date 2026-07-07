import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'custom_field_rpc_mapper.dart';

final class SupabaseCatalogCustomFieldConfigGateway
    implements ICatalogCustomFieldConfigGateway {
  SupabaseCatalogCustomFieldConfigGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<InitializeCustomFieldTemplateResult> initializeTemplate({
    required InitializeCustomFieldTemplateCommand command,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'initialize_custom_field_template',
        params: CustomFieldRpcMapper.initializeTemplateParams(command: command),
      );

      return CustomFieldRpcMapper.initializeTemplateResult(row);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<CustomFieldGroupConfigDto> upsertGroup({
    required UpsertCustomFieldGroupCommand command,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'upsert_custom_field_group',
        params: CustomFieldRpcMapper.upsertGroupParams(command: command),
      );

      if (row.isEmpty) {
        throw ApplicationException('Upsert custom field group did not return a result.');
      }

      return CustomFieldRpcMapper.groupFromJson(row);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<void> reorderGroups({
    required ReorderCustomFieldGroupsCommand command,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'reorder_custom_field_groups',
        params: CustomFieldRpcMapper.reorderGroupsParams(command: command),
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<CustomFieldDefinitionDto> upsertField({
    required UpsertCustomFieldCommand command,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'upsert_custom_field',
        params: CustomFieldRpcMapper.upsertFieldParams(command: command),
      );

      if (row.isEmpty) {
        throw ApplicationException('Upsert custom field did not return a result.');
      }

      return CustomFieldRpcMapper.fieldFromJson(row);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<ConfigureCustomFieldAttributesResult> configureAttributes({
    required ConfigureCustomFieldAttributesCommand command,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'configure_custom_field_attributes',
        params: CustomFieldRpcMapper.configureAttributesParams(command: command),
      );

      return CustomFieldRpcMapper.configureAttributesResult(row);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<void> reorderFields({required ReorderCustomFieldsCommand command}) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'reorder_custom_fields',
        params: CustomFieldRpcMapper.reorderFieldsParams(command: command),
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<CustomFieldConfigViewDto> listConfig({required String tenantId}) async {
    try {
      final row = await _rpcClient.callMap(
        'list_custom_field_config',
        params: CustomFieldRpcMapper.listConfigParams(tenantId: tenantId),
      );

      return CustomFieldRpcMapper.configViewFromJson(row);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
