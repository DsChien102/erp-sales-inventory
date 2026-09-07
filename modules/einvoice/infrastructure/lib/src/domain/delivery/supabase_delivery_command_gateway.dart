import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'delivery_rpc_mapper.dart';

final class SupabaseDeliveryCommandGateway implements IDeliveryCommandGateway {
  SupabaseDeliveryCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
    ILogger? logger,
  }) : _rpcClient = rpcClient,
       _logger = logger;

  final ILogger? _logger;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<AutoDeliveryResultDto> startAuto(
    AutoDeliveryStartRequest request,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'start_auto_delivery',
        params: DeliveryRpcMapper.startAutoParams(request),
      );
      if (rows.isEmpty) {
        throw RpcException('start_auto_delivery returned no rows');
      }
      return DeliveryRpcMapper.autoDeliveryResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<SendInvoiceResultDto> startManual(
    ManualDeliveryStartRequest request,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'send_electronic_invoice',
        params: DeliveryRpcMapper.startManualParams(request),
      );
      if (rows.isEmpty) {
        throw RpcException('send_electronic_invoice returned no rows');
      }
      return DeliveryRpcMapper.sendInvoiceResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<DeliveryAttemptContextDto?> loadAttemptContext({
    required String tenantId,
    required String deliveryId,
    required String attemptId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'load_delivery_attempt_context',
        params: DeliveryRpcMapper.loadAttemptContextParams(
          tenantId: tenantId,
          deliveryId: deliveryId,
          attemptId: attemptId,
        ),
      );
      if (rows.isEmpty) {
        return null;
      }
      return DeliveryRpcMapper.attemptContextFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<PrepareDeliveryProviderCallResult> prepareProviderCall({
    required String tenantId,
    required String deliveryId,
    required String attemptId,
    required int expectedDeliveryVersion,
    required int expectedAttemptVersion,
    required String requestReference,
  }) async {
    _logger?.info({
      'event': 'einvoice.delivery.prepare',
      'deliveryId': deliveryId,
      'attemptId': attemptId,
      'requestReference': requestReference,
    });
    try {
      final rows = await _rpcClient.callList(
        'prepare_delivery_provider_call',
        params: DeliveryRpcMapper.prepareProviderCallParams(
          tenantId: tenantId,
          deliveryId: deliveryId,
          attemptId: attemptId,
          expectedDeliveryVersion: expectedDeliveryVersion,
          expectedAttemptVersion: expectedAttemptVersion,
          requestReference: requestReference,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('prepare_delivery_provider_call returned no rows');
      }
      return DeliveryRpcMapper.prepareResultFromRowWithTenant(
        row: Map<String, dynamic>.from(rows.first),
        tenantId: tenantId,
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<RecordDeliveryResultDto> recordResult(
    DeliveryResultRecord record,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'record_delivery_result',
        params: DeliveryRpcMapper.recordResultParams(record),
      );
      if (rows.isEmpty) {
        throw RpcException('record_delivery_result returned no rows');
      }
      return DeliveryRpcMapper.recordResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<void> recordCommandDeadLetter({
    required String tenantId,
    required String deliveryId,
    required String attemptId,
    required String safeFailureCode,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'record_delivery_command_dead_letter',
        params: DeliveryRpcMapper.recordCommandDeadLetterParams(
          tenantId: tenantId,
          deliveryId: deliveryId,
          attemptId: attemptId,
          safeFailureCode: safeFailureCode,
        ),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
