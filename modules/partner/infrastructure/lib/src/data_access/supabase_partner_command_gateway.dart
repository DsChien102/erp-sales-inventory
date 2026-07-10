import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/partner_error_mapper.dart';
import 'partner_rpc_mapper.dart';

final class SupabasePartnerCommandGateway implements IPartnerCommandGateway {
  SupabasePartnerCommandGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<CreatePartnerResult> createPartner(CreatePartnerCommand command) async {
    try {
      final result = await _callFirstRow(
        'create_partner',
        params: PartnerRpcMapper.createPartnerParams(command),
      );
      return PartnerRpcMapper.mapCreatePartnerResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<UpdatePartnerProfileResult> updatePartnerProfile(
    UpdatePartnerProfileCommand command,
  ) async {
    try {
      final result = await _callFirstRow(
        'update_partner',
        params: PartnerRpcMapper.updatePartnerParams(command),
      );
      return PartnerRpcMapper.mapUpdatePartnerResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<TransformPartnerResult> transformPersonToOrganization(
    TransformPersonToOrganizationCommand command,
  ) async {
    try {
      final result = await _callFirstRow(
        'transform_to_organization',
        params: PartnerRpcMapper.transformPartnerParams(command),
      );
      return PartnerRpcMapper.mapTransformPartnerResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<AddOrganizationContactResult> addOrganizationContact(
    AddOrganizationContactCommand command,
  ) async {
    try {
      final result = await _callFirstRow(
        'add_organization_contact',
        params: PartnerRpcMapper.addContactParams(command),
      );
      return PartnerRpcMapper.mapAddContactResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<void> updateOrganizationContact(
    UpdateOrganizationContactCommand command,
  ) async {
    try {
      await _rpcClient.callScalar<void>(
        'update_organization_contact',
        params: PartnerRpcMapper.updateContactParams(command),
      );
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<void> removeOrganizationContact(
    RemoveOrganizationContactCommand command,
  ) async {
    try {
      await _rpcClient.callScalar<void>(
        'remove_organization_contact',
        params: PartnerRpcMapper.removeContactParams(command),
      );
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<DeactivatePartnerResult> deactivatePartner(
    DeactivatePartnerCommand command,
  ) async {
    try {
      final result = await _callFirstRow(
        'deactivate_partner',
        params: PartnerRpcMapper.deactivatePartnerParams(command),
      );
      return PartnerRpcMapper.mapDeactivatePartnerResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<ReactivatePartnerResult> reactivatePartner(
    ReactivatePartnerCommand command,
  ) async {
    try {
      final result = await _callFirstRow(
        'reactivate_partner',
        params: PartnerRpcMapper.reactivatePartnerParams(command),
      );
      return PartnerRpcMapper.mapReactivatePartnerResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<SoftDeletePartnerResult> softDeletePartner(
    SoftDeletePartnerCommand command,
  ) async {
    try {
      final result = await _callFirstRow(
        'soft_delete_partner',
        params: PartnerRpcMapper.softDeletePartnerParams(command),
      );
      return PartnerRpcMapper.mapSoftDeletePartnerResult(result);
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  /// Partner write RPCs return `table (...)`; PostgREST responds with a JSON array.
  Future<Map<String, dynamic>> _callFirstRow(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    final rows = await _rpcClient.callList(functionName, params: params);
    if (rows.isEmpty) {
      return <String, dynamic>{};
    }
    return rows.first;
  }
}
