import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import 'einvoice_rpc_mapper.dart';

final class SupabaseProviderConnectionCommandGateway
    implements IProviderConnectionCommandGateway {
  SupabaseProviderConnectionCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProviderConnectionResultDto> connect(
    ConnectProviderCommand command,
  ) async {
    return _mapConnection(
      'connect_provider',
      EinvoiceRpcMapper.connectProviderParams(command),
    );
  }

  @override
  Future<ProviderConnectionCheckResultDto> verify(
    VerifyProviderConnectionCommand command,
  ) async {
    try {
      final row = await _firstRow(
        'verify_provider_connection',
        EinvoiceRpcMapper.verifyProviderParams(command),
      );
      return EinvoiceRpcMapper.mapConnectionCheckResult(row);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<ProviderConnectionResultDto> reconnect(
    ReconnectProviderCommand command,
  ) async {
    return _mapConnection(
      'reconnect_provider',
      EinvoiceRpcMapper.reconnectProviderParams(command),
    );
  }

  @override
  Future<ProviderConnectionResultDto> disconnect(
    DisconnectProviderCommand command,
  ) async {
    return _mapConnection(
      'disconnect_provider',
      EinvoiceRpcMapper.disconnectProviderParams(command),
    );
  }

  @override
  Future<ProviderConnectionResultDto> recordConnectionVerified(
    RecordConnectionVerifiedCommand command,
  ) async {
    return _mapConnection(
      'record_connection_verified',
      EinvoiceRpcMapper.recordConnectionVerifiedParams(command),
    );
  }

  Future<ProviderConnectionResultDto> _mapConnection(
    String rpc,
    Map<String, dynamic> params,
  ) async {
    try {
      final row = await _firstRow(rpc, params);
      return EinvoiceRpcMapper.mapConnectionResult(row);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  Future<Map<String, dynamic>> _firstRow(
    String rpc,
    Map<String, dynamic> params,
  ) async {
    final rows = await _rpcClient.callList(rpc, params: params);
    if (rows.isEmpty) {
      throw RpcException('RPC $rpc returned no rows');
    }
    return Map<String, dynamic>.from(rows.first);
  }
}
