import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/partner_error_mapper.dart';
import 'partner_rpc_mapper.dart';

final class SupabasePartnerCommandGateway implements IPartnerCommandGateway {
  SupabasePartnerCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<String> register({
    required BusinessPartner partner,
    required bool confirmDuplicate,
    required String idempotencyKey,
  }) async {
    try {
      final partnerId = await _rpcClient.callScalar<String>(
        'register_partner',
        params: PartnerRpcMapper.registerPartnerParams(
          partner: partner,
          confirmDuplicate: confirmDuplicate,
          idempotencyKey: idempotencyKey,
        ),
      );

      if (partnerId == null || partnerId.isEmpty) {
        throw ApplicationException(
          'Partner registration did not return an id.',
        );
      }

      return partnerId;
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<int> update({
    required BusinessPartner partner,
    required Set<PartnerRole> roles,
    required bool confirmDuplicate,
    required int expectedVersion,
    required String actorId,
  }) async {
    try {
      final version = await _rpcClient.callScalar<num>(
        'update_partner',
        params: PartnerRpcMapper.updatePartnerParams(
          partner: partner,
          roles: roles,
          confirmDuplicate: confirmDuplicate,
          expectedVersion: expectedVersion,
          actorId: actorId,
        ),
      );

      if (version == null) {
        throw ApplicationException(
          'Partner update did not return a version.',
        );
      }

      return version.toInt();
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<int> deactivate({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
    String? statusNote,
  }) async {
    try {
      final version = await _rpcClient.callScalar<num>(
        'deactivate_partner',
        params: PartnerRpcMapper.deactivatePartnerParams(
          partner: partner,
          expectedVersion: expectedVersion,
          actorId: actorId,
          statusNote: statusNote,
        ),
      );

      if (version == null) {
        throw ApplicationException(
          'Partner deactivate did not return a version.',
        );
      }

      return version.toInt();
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<int> reactivate({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
  }) async {
    try {
      final version = await _rpcClient.callScalar<num>(
        'reactivate_partner',
        params: PartnerRpcMapper.reactivatePartnerParams(
          partner: partner,
          expectedVersion: expectedVersion,
          actorId: actorId,
        ),
      );

      if (version == null) {
        throw ApplicationException(
          'Partner reactivate did not return a version.',
        );
      }

      return version.toInt();
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }

  @override
  Future<void> delete({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
  }) async {
    try {
      await _rpcClient.callScalar<bool>(
        'delete_partner',
        params: PartnerRpcMapper.deletePartnerParams(
          partner: partner,
          expectedVersion: expectedVersion,
          actorId: actorId,
        ),
      );
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }
}
