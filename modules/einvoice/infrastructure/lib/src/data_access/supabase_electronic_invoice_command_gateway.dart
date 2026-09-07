import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import '../storage/invoice_document_signed_url_resolver.dart';
import 'electronic_invoice_rpc_mapper.dart';

final class SupabaseElectronicInvoiceCommandGateway
    implements IElectronicInvoiceCommandGateway {
  SupabaseElectronicInvoiceCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
    required InvoiceDocumentSignedUrlResolver signedUrlResolver,
  }) : _rpcClient = rpcClient,
       _signedUrlResolver = signedUrlResolver;

  final SupabaseSchemaRpcClient _rpcClient;
  final InvoiceDocumentSignedUrlResolver _signedUrlResolver;

  @override
  Future<OfficialInvoiceViewDto> requestOfficialView({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'request_official_invoice_view',
        params: ElectronicInvoiceRpcMapper.scopedSalesOrderParams(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: salesOrderId,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('request_official_invoice_view returned no rows');
      }
      return ElectronicInvoiceRpcMapper.officialViewFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<InvoiceDocumentRetrievalDto> requestDocument({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required InvoiceDocumentType documentType,
    required String idempotencyKey,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'request_invoice_document',
        params: ElectronicInvoiceRpcMapper.requestDocumentParams(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: salesOrderId,
          documentType: documentType,
          idempotencyKey: idempotencyKey,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('request_invoice_document returned no rows');
      }
      final dto = ElectronicInvoiceRpcMapper.documentRetrievalFromRow(
        Map<String, dynamic>.from(rows.first),
      );
      return _withSignedDownloadUrl(dto);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<OfficialViewOperationContextDto?> loadOfficialViewContext({
    required String tenantId,
    required String operationId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'load_official_view_operation_context',
        params: ElectronicInvoiceRpcMapper.loadOfficialViewContextParams(
          tenantId: tenantId,
          operationId: operationId,
        ),
      );
      if (rows.isEmpty) {
        return null;
      }
      return ElectronicInvoiceRpcMapper.officialViewContextFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<InvoiceDocumentOperationContextDto?> loadDocumentContext({
    required String tenantId,
    required String operationId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'load_invoice_document_operation_context',
        params: ElectronicInvoiceRpcMapper.loadDocumentContextParams(
          tenantId: tenantId,
          operationId: operationId,
        ),
      );
      if (rows.isEmpty) {
        return null;
      }
      return ElectronicInvoiceRpcMapper.documentContextFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<ProviderObservationOperationContextDto?> loadObservationContext({
    required String tenantId,
    required String commandId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'load_provider_observation_context',
        params: ElectronicInvoiceRpcMapper.loadObservationContextParams(
          tenantId: tenantId,
          commandId: commandId,
        ),
      );
      if (rows.isEmpty) {
        return null;
      }
      return ElectronicInvoiceRpcMapper.observationContextFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<void> recordOfficialViewResult(OfficialViewResultRecord record) async {
    try {
      await _rpcClient.callList(
        'record_official_invoice_view_result',
        params: ElectronicInvoiceRpcMapper.recordOfficialViewResultParams(
          record,
        ),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<void> recordDocumentResult(InvoiceDocumentResultRecord record) async {
    try {
      await _rpcClient.callList(
        'record_invoice_document_result',
        params: ElectronicInvoiceRpcMapper.recordDocumentResultParams(record),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<ProviderObservationDto> recordProviderObservation(
    ProviderObservationRecord record,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'record_provider_observation',
        params: ElectronicInvoiceRpcMapper.recordProviderObservationParams(
          record,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('record_provider_observation returned no rows');
      }
      return ElectronicInvoiceRpcMapper.observationFromRow(
        Map<String, dynamic>.from(rows.first),
        source: record.source,
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  Future<InvoiceDocumentRetrievalDto> _withSignedDownloadUrl(
    InvoiceDocumentRetrievalDto dto,
  ) async {
    if (dto.status != InvoiceDocumentStatus.available ||
        dto.fileRef == null ||
        dto.fileRef!.isEmpty) {
      return dto;
    }

    final downloadUrl = await _signedUrlResolver.tryCreateSignedUrl(
      dto.fileRef!,
    );
    if (downloadUrl == null) {
      return InvoiceDocumentRetrievalDto(
        operationId: dto.operationId,
        status: InvoiceDocumentStatus.checkRequired,
        fileRef: dto.fileRef,
        checksum: dto.checksum,
      );
    }

    return InvoiceDocumentRetrievalDto(
      operationId: dto.operationId,
      status: dto.status,
      downloadUrl: downloadUrl,
      fileRef: dto.fileRef,
      checksum: dto.checksum,
    );
  }
}
