import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import '../storage/invoice_document_signed_url_resolver.dart';
import 'electronic_invoice_rpc_mapper.dart';

final class SupabaseElectronicInvoiceReadGateway
    implements IElectronicInvoiceReadGateway {
  SupabaseElectronicInvoiceReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
    required InvoiceDocumentSignedUrlResolver signedUrlResolver,
  }) : _rpcClient = rpcClient,
       _signedUrlResolver = signedUrlResolver;

  final SupabaseSchemaRpcClient _rpcClient;
  final InvoiceDocumentSignedUrlResolver _signedUrlResolver;

  @override
  Future<ElectronicInvoiceDetailDto> getDetail({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_electronic_invoice_detail',
        params: ElectronicInvoiceRpcMapper.scopedSalesOrderParams(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: salesOrderId,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('get_electronic_invoice_detail returned no rows');
      }
      return ElectronicInvoiceRpcMapper.detailFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<InvoiceDocumentsDto> getDocuments({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_invoice_documents',
        params: ElectronicInvoiceRpcMapper.scopedSalesOrderParams(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: salesOrderId,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('get_invoice_documents returned no rows');
      }
      final dto = ElectronicInvoiceRpcMapper.documentsFromRow(
        Map<String, dynamic>.from(rows.first),
      );
      return _withSignedDownloadUrls(dto);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<ProviderObservationDto?> getLatestObservation({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_latest_provider_observation',
        params: ElectronicInvoiceRpcMapper.scopedSalesOrderParams(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: salesOrderId,
        ),
      );
      if (rows.isEmpty) {
        return null;
      }
      return ElectronicInvoiceRpcMapper.observationFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  Future<InvoiceDocumentsDto> _withSignedDownloadUrls(
    InvoiceDocumentsDto dto,
  ) async {
    final pdf = await _withSignedItem(dto.pdf);
    final xml = await _withSignedItem(dto.xml);
    final retrievalStatus = _aggregateRetrievalStatus(
      dto.retrievalStatus,
      pdf?.status,
      xml?.status,
    );
    return InvoiceDocumentsDto(
      pdfAvailable: dto.pdfAvailable,
      xmlAvailable: dto.xmlAvailable,
      retrievalStatus: retrievalStatus,
      pdf: pdf,
      xml: xml,
    );
  }

  Future<InvoiceDocumentItemDto?> _withSignedItem(
    InvoiceDocumentItemDto? item,
  ) async {
    if (item == null) {
      return null;
    }
    if (item.status != InvoiceDocumentStatus.available ||
        item.fileRef == null ||
        item.fileRef!.isEmpty) {
      return item;
    }

    final downloadUrl = await _signedUrlResolver.tryCreateSignedUrl(
      item.fileRef!,
    );
    if (downloadUrl == null) {
      return InvoiceDocumentItemDto(
        documentType: item.documentType,
        status: InvoiceDocumentStatus.checkRequired,
        operationId: item.operationId,
        fileRef: item.fileRef,
        checksum: item.checksum,
      );
    }

    return InvoiceDocumentItemDto(
      documentType: item.documentType,
      status: item.status,
      operationId: item.operationId,
      downloadUrl: downloadUrl,
      fileRef: item.fileRef,
      checksum: item.checksum,
      expiresAt: _signedUrlResolver.accessLeaseExpiresAt(),
    );
  }

  InvoiceDocumentStatus _aggregateRetrievalStatus(
    InvoiceDocumentStatus base,
    InvoiceDocumentStatus? pdfStatus,
    InvoiceDocumentStatus? xmlStatus,
  ) {
    final statuses = [
      base,
      pdfStatus,
      xmlStatus,
    ].whereType<InvoiceDocumentStatus>();
    if (statuses.any(
      (status) => status == InvoiceDocumentStatus.checkRequired,
    )) {
      return InvoiceDocumentStatus.checkRequired;
    }
    if (statuses.any((status) => status == InvoiceDocumentStatus.pending)) {
      return InvoiceDocumentStatus.pending;
    }
    if (statuses.any((status) => status == InvoiceDocumentStatus.available)) {
      return InvoiceDocumentStatus.available;
    }
    if (statuses.any((status) => status == InvoiceDocumentStatus.failed)) {
      return InvoiceDocumentStatus.failed;
    }
    return base;
  }
}
