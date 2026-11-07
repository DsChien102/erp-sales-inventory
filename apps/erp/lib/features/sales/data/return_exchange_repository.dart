import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/return_exchange_json.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/data/return_exchange_errors.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_sales_application/application.dart';

/// Repository xử lý nghiệp vụ đổi/trả đơn hàng (`sales` schema):
/// - Tiền kiểm, lấy dòng có thể trả, xem trước giá hàng đổi
/// - Lập, cập nhật, huỷ nháp, quyết toán và hoàn tất phiếu đổi/trả
/// - Đánh giá định giá / chênh lệch thanh toán
class ReturnExchangeRepository {
  ReturnExchangeRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
    String Function()? newId,
  }) : _rpc = rpc,
       _tenantId = tenantId,
       _actorId = actorId,
       _newId = newId ?? const Uuid().v4;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;
  final Future<String> Function() _actorId;
  final String Function() _newId;

  Future<ReturnExchangePrecheckDto> precheck({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'precheck_return_exchange',
      params: ReturnExchangeJson.precheckParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return ReturnExchangeJson.precheckFromJson(_asMap(raw));
  });

  Future<ReturnableOrderLinesDto> getReturnableLines({
    required String salesOrderId,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_returnable_order_lines',
      params: ReturnExchangeJson.returnableParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
      ),
    );
    return ReturnExchangeJson.returnableFromJson(_asMap(raw));
  });

  Future<ReturnExchangePricingPreviewDto> previewPricing({
    required String salesOrderId,
    required List<ReturnExchangePricingLineInput> lines,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'preview_return_exchange_pricing',
      params: ReturnExchangeJson.previewPricingParams(
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        lines: lines,
      ),
    );
    return ReturnExchangeJson.previewPricingFromJson(_asMap(raw));
  });

  Future<ReturnExchangeDetailDto> getDetail({
    required String returnExchangeId,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_return_exchange_detail',
      params: ReturnExchangeJson.detailParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        returnExchangeId: returnExchangeId,
      ),
    );
    return ReturnExchangeJson.detailFromJson(_asMap(raw));
  });

  Future<ReturnExchangeDraftDto> start(
    ReturnExchangeStartRequest request,
  ) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'start_return_exchange',
      params: ReturnExchangeJson.startParams(
        request: request,
        tenantId: await _tenantId(),
        actorId: await _actorId(),
      ),
    );
    return ReturnExchangeJson.draftFromJson(_asMap(raw));
  });

  Future<ReturnExchangeDraftDto> update(
    ReturnExchangeUpdateRequest request,
  ) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'update_return_exchange',
      params: ReturnExchangeJson.updateParams(
        request: request,
        tenantId: await _tenantId(),
        actorId: await _actorId(),
      ),
    );
    return ReturnExchangeJson.draftFromJson(_asMap(raw));
  });

  Future<ReturnExchangeResultDto> cancel(
    ReturnExchangeMutationRequest request,
  ) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'cancel_return_exchange',
      params: ReturnExchangeJson.cancelParams(
        request: request,
        tenantId: await _tenantId(),
        actorId: await _actorId(),
      ),
    );
    return ReturnExchangeJson.resultFromJson(_asMap(raw));
  });

  Future<ReturnExchangeResultDto> confirm(
    ReturnExchangeConfirmRequest request,
  ) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'confirm_return_exchange',
      params: ReturnExchangeJson.confirmParams(
        request: request,
        tenantId: await _tenantId(),
        actorId: await _actorId(),
      ),
    );
    return ReturnExchangeJson.resultFromJson(_asMap(raw));
  });

  Future<ReturnExchangeResultDto> complete(
    ReturnExchangeMutationRequest request,
  ) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'complete_return_exchange',
      params: ReturnExchangeJson.completeParams(
        request: request,
        tenantId: await _tenantId(),
        actorId: await _actorId(),
      ),
    );
    return ReturnExchangeJson.resultFromJson(_asMap(raw));
  });

  Future<ReturnExchangeValuationDto> evaluate({
    required String returnExchangeId,
    required int expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'evaluate_return_exchange_valuation',
      params: ReturnExchangeJson.evaluateParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        returnExchangeId: returnExchangeId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return ReturnExchangeJson.valuationFromJson(_asMap(raw));
  });

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Object catch (error) {
      throw returnExchangeException(error);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    throw FormatException('Expected JSON object, got $raw.');
  }
}

