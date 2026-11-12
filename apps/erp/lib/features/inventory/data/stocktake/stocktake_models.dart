import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/core/inventory_command_result.dart';

DateTime? _tryParseDate(Object? raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

DateTime _parseDate(Object? raw) => DateTime.parse(raw as String);

num? _tryParseNum(Object? raw) => raw == null ? null : raw as num;

T _enumFromWire<T>(List<T> values, String Function(T) wireOf, String wire) {
  for (final v in values) {
    if (wireOf(v) == wire) return v;
  }
  throw FormatException('Giá trị không hợp lệ: $wire');
}

T? _tryEnumFromWire<T>(
  List<T> values,
  String Function(T) wireOf,
  Object? wire,
) {
  if (wire == null) return null;
  return _enumFromWire<T>(values, wireOf, wire as String);
}

enum StocktakeStatus {
  counting('COUNTING'),
  recount('RECOUNT'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const StocktakeStatus(this.wire);
  final String wire;

  static StocktakeStatus fromWire(String wire) =>
      _enumFromWire(values, (v) => v.wire, wire);

  static StocktakeStatus? tryFromWire(Object? wire) =>
      _tryEnumFromWire(values, (v) => v.wire, wire);
}

enum StocktakeResultKind {
  matched('MATCHED'),
  adjusted('ADJUSTED');

  const StocktakeResultKind(this.wire);
  final String wire;

  static StocktakeResultKind fromWire(String wire) =>
      _enumFromWire(values, (v) => v.wire, wire);

  static StocktakeResultKind? tryFromWire(Object? wire) =>
      _tryEnumFromWire(values, (v) => v.wire, wire);
}

enum StocktakeScopeKind {
  all('ALL'),
  product('PRODUCT'),
  lot('LOT');

  const StocktakeScopeKind(this.wire);
  final String wire;

  static StocktakeScopeKind fromWire(String wire) =>
      _enumFromWire(values, (v) => v.wire, wire);
}

enum StocktakeLossReason {
  loss('LOSS'),
  damaged('DAMAGED'),
  expired('EXPIRED');

  const StocktakeLossReason(this.wire);
  final String wire;

  static StocktakeLossReason fromWire(String wire) =>
      _enumFromWire(values, (v) => v.wire, wire);

  static StocktakeLossReason? tryFromWire(Object? wire) =>
      _tryEnumFromWire(values, (v) => v.wire, wire);
}

/// Dòng tóm tắt phiên kiểm kê cho danh sách SCR-042.
class StocktakeListRow extends Equatable {
  const StocktakeListRow({
    required this.id,
    required this.code,
    required this.scopeLabel,
    required this.counterName,
    required this.status,
    required this.openedAt,
    required this.lineCount,
    required this.countedCount,
    required this.varianceCount,
  });

  factory StocktakeListRow.fromJson(Map<String, dynamic> json) {
    return StocktakeListRow(
      id: json['id'] as String,
      code: json['code'] as String,
      scopeLabel: json['scope_label'] as String,
      counterName: json['counter_name'] as String,
      status: StocktakeStatus.fromWire(json['status'] as String),
      openedAt: _parseDate(json['opened_at']),
      lineCount: (json['line_count'] as num).toInt(),
      countedCount: (json['counted_count'] as num).toInt(),
      varianceCount: (json['variance_count'] as num).toInt(),
    );
  }

  final String id;
  final String code;
  final String scopeLabel;
  final String counterName;
  final StocktakeStatus status;
  final DateTime openedAt;
  final int lineCount;
  final int countedCount;
  final int varianceCount;

  @override
  List<Object?> get props => [
    id,
    code,
    scopeLabel,
    counterName,
    status,
    openedAt,
    lineCount,
    countedCount,
    varianceCount,
  ];
}

/// Tùy chọn mặt hàng trong form mở phiên kiểm kê.
class StocktakeProductOption extends Equatable {
  const StocktakeProductOption({
    required this.id,
    required this.name,
    required this.code,
    required this.uom,
    required this.lineCount,
  });

  factory StocktakeProductOption.fromJson(Map<String, dynamic> json) {
    return StocktakeProductOption(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      lineCount: (json['line_count'] as num).toInt(),
    );
  }

  final String id;
  final String name;
  final String code;
  final String uom;
  final int lineCount;

  @override
  List<Object?> get props => [id, name, code, uom, lineCount];
}

/// Tùy chọn lô trong form mở phiên kiểm kê.
class StocktakeLotOption extends Equatable {
  const StocktakeLotOption({
    required this.id,
    required this.productId,
    required this.productName,
    required this.code,
    required this.lotCode,
    this.expiryDate,
    this.expiryPrecision,
    required this.isExpired,
    required this.uom,
  });

  factory StocktakeLotOption.fromJson(Map<String, dynamic> json) {
    return StocktakeLotOption(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      code: json['code'] as String? ?? '',
      lotCode: json['lot_code'] as String,
      expiryDate: _tryParseDate(json['expiry_date']),
      expiryPrecision: json['expiry_precision'] as String?,
      isExpired: json['is_expired'] as bool? ?? false,
      uom: json['uom'] as String? ?? '',
    );
  }

  final String id;
  final String productId;
  final String productName;
  final String code;
  final String lotCode;
  final DateTime? expiryDate;
  final String? expiryPrecision;
  final bool isExpired;
  final String uom;

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    code,
    lotCode,
    expiryDate,
    expiryPrecision,
    isExpired,
    uom,
  ];
}

/// Thành viên kho có thể được gán làm người đếm.
class StocktakeMember extends Equatable {
  const StocktakeMember({required this.userId, required this.name});

  factory StocktakeMember.fromJson(Map<String, dynamic> json) {
    return StocktakeMember(
      userId: json['user_id'] as String,
      name: json['name'] as String,
    );
  }

  final String userId;
  final String name;

  @override
  List<Object?> get props => [userId, name];
}

/// Toàn bộ dữ liệu khởi tạo form mở phiên kiểm kê SCR-043.
class StocktakeFormOptions extends Equatable {
  const StocktakeFormOptions({
    required this.allCount,
    required this.products,
    required this.lots,
    required this.members,
    required this.me,
  });

  factory StocktakeFormOptions.fromJson(Map<String, dynamic> json) {
    return StocktakeFormOptions(
      allCount: (json['all_count'] as num).toInt(),
      products: (json['products'] as List<dynamic>? ?? const [])
          .map((e) => StocktakeProductOption.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      lots: (json['lots'] as List<dynamic>? ?? const [])
          .map((e) => StocktakeLotOption.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      members: (json['members'] as List<dynamic>? ?? const [])
          .map((e) => StocktakeMember.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      me: json['me'] as String,
    );
  }

  final int allCount;
  final List<StocktakeProductOption> products;
  final List<StocktakeLotOption> lots;
  final List<StocktakeMember> members;
  final String me;

  @override
  List<Object?> get props => [allCount, products, lots, members, me];
}

/// Thông tin phiên kiểm kê đang mở gây xung đột phạm vi.
class StocktakeConflict extends Equatable {
  const StocktakeConflict({
    required this.sessionId,
    required this.code,
    required this.scopeLabel,
  });

  factory StocktakeConflict.fromJson(Map<String, dynamic> json) {
    return StocktakeConflict(
      sessionId: json['session_id'] as String,
      code: json['code'] as String,
      scopeLabel: json['scope_label'] as String,
    );
  }

  final String sessionId;
  final String code;
  final String scopeLabel;

  @override
  List<Object?> get props => [sessionId, code, scopeLabel];
}

/// Kết quả trả về của `open_stocktake`: thành công hoặc xung đột phiên mở.
class OpenStocktakeResult extends Equatable {
  const OpenStocktakeResult({this.sessionId, this.code, this.conflict});

  factory OpenStocktakeResult.fromJson(Map<String, dynamic> json) {
    final conflictJson = json['conflict'] as Map<String, dynamic>?;
    return OpenStocktakeResult(
      sessionId: json['session_id'] as String?,
      code: json['code'] as String?,
      conflict: conflictJson == null
          ? null
          : StocktakeConflict.fromJson(conflictJson),
    );
  }

  final String? sessionId;
  final String? code;
  final StocktakeConflict? conflict;

  bool get hasConflict => conflict != null;

  @override
  List<Object?> get props => [sessionId, code, conflict];
}

/// Một dòng mặt hàng trong phiên kiểm kê; giữ null các trường blind hoặc tiền của chủ kho khi không có.
class StocktakeLine extends Equatable {
  const StocktakeLine({
    required this.lineId,
    required this.productId,
    required this.productName,
    required this.productCode,
    this.lotId,
    this.lotCode,
    this.expiryDate,
    required this.isExpired,
    required this.uom,
    required this.isUnexpected,
    this.draftQty,
    required this.needsRecount,
    this.lossReason,
    this.firstQty,
    this.recountQty,
    this.bookQty,
    this.variance,
    this.adjustQty,
    this.adjustValueVnd,
  });

  factory StocktakeLine.fromJson(Map<String, dynamic> json) {
    return StocktakeLine(
      lineId: json['line_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productCode: json['product_code'] as String? ?? '',
      lotId: json['lot_id'] as String?,
      lotCode: json['lot_code'] as String?,
      expiryDate: _tryParseDate(json['expiry_date']),
      isExpired: json['is_expired'] as bool? ?? false,
      uom: json['uom'] as String? ?? '',
      isUnexpected: json['is_unexpected'] as bool? ?? false,
      draftQty: _tryParseNum(json['draft_qty']),
      needsRecount: json['needs_recount'] as bool? ?? false,
      lossReason: StocktakeLossReason.tryFromWire(json['loss_reason']),
      firstQty: _tryParseNum(json['first_qty']),
      recountQty: _tryParseNum(json['recount_qty']),
      bookQty: _tryParseNum(json['book_qty']),
      variance: _tryParseNum(json['variance']),
      adjustQty: _tryParseNum(json['adjust_qty']),
      adjustValueVnd: (json['adjust_value_vnd'] as num?)?.toInt(),
    );
  }

  final String lineId;
  final String productId;
  final String productName;
  final String productCode;
  final String? lotId;
  final String? lotCode;
  final DateTime? expiryDate;
  final bool isExpired;
  final String uom;
  final bool isUnexpected;
  final num? draftQty;
  final bool needsRecount;
  final StocktakeLossReason? lossReason;
  final num? firstQty;
  final num? recountQty;
  final num? bookQty;
  final num? variance;
  final num? adjustQty;
  final int? adjustValueVnd;

  @override
  List<Object?> get props => [
    lineId,
    productId,
    productName,
    productCode,
    lotId,
    lotCode,
    expiryDate,
    isExpired,
    uom,
    isUnexpected,
    draftQty,
    needsRecount,
    lossReason,
    firstQty,
    recountQty,
    bookQty,
    variance,
    adjustQty,
    adjustValueVnd,
  ];
}

/// Chi tiết phiên kiểm kê trả về từ `get_stocktake_session`.
class StocktakeSession extends Equatable {
  const StocktakeSession({
    required this.id,
    required this.code,
    required this.scopeKind,
    required this.scopeLabel,
    required this.counterName,
    required this.reason,
    required this.status,
    this.resultKind,
    required this.openedAt,
    this.firstSubmittedAt,
    this.completedAt,
    this.completedByName,
    this.cancelledAt,
    this.cancelReason,
    this.adjustmentValueVnd,
    this.stockChanges = const [],
    required this.lines,
  });

  factory StocktakeSession.fromJson(Map<String, dynamic> json) {
    return StocktakeSession(
      id: json['id'] as String,
      code: json['code'] as String,
      scopeKind: StocktakeScopeKind.fromWire(json['scope_kind'] as String),
      scopeLabel: json['scope_label'] as String,
      counterName: json['counter_name'] as String,
      reason: json['reason'] as String,
      status: StocktakeStatus.fromWire(json['status'] as String),
      resultKind: StocktakeResultKind.tryFromWire(json['result_kind']),
      openedAt: _parseDate(json['opened_at']),
      firstSubmittedAt: _tryParseDate(json['first_submitted_at']),
      completedAt: _tryParseDate(json['completed_at']),
      completedByName: json['completed_by_name'] as String?,
      cancelledAt: _tryParseDate(json['cancelled_at']),
      cancelReason: json['cancel_reason'] as String?,
      adjustmentValueVnd: (json['adjustment_value_vnd'] as num?)?.toInt(),
      stockChanges: (json['stock_changes'] as List<dynamic>? ?? const [])
          .map((e) => InventoryStockChange.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      lines: (json['lines'] as List<dynamic>? ?? const [])
          .map((e) => StocktakeLine.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String id;
  final String code;
  final StocktakeScopeKind scopeKind;
  final String scopeLabel;
  final String counterName;
  final String reason;
  final StocktakeStatus status;
  final StocktakeResultKind? resultKind;
  final DateTime openedAt;
  final DateTime? firstSubmittedAt;
  final DateTime? completedAt;
  final String? completedByName;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final int? adjustmentValueVnd;
  final List<InventoryStockChange> stockChanges;
  final List<StocktakeLine> lines;

  @override
  List<Object?> get props => [
    id,
    code,
    scopeKind,
    scopeLabel,
    counterName,
    reason,
    status,
    resultKind,
    openedAt,
    firstSubmittedAt,
    completedAt,
    completedByName,
    cancelledAt,
    cancelReason,
    adjustmentValueVnd,
    stockChanges,
    lines,
  ];
}

/// Lô sẵn có chưa nằm trong phiên của một sản phẩm thêm ngoài dự kiến.
class StocktakeUnexpectedLot extends Equatable {
  const StocktakeUnexpectedLot({
    required this.id,
    required this.lotCode,
    this.expiryDate,
    this.expiryPrecision,
  });

  factory StocktakeUnexpectedLot.fromJson(Map<String, dynamic> json) {
    return StocktakeUnexpectedLot(
      id: json['id'] as String,
      lotCode: json['lot_code'] as String,
      expiryDate: _tryParseDate(json['expiry_date']),
      expiryPrecision: json['expiry_precision'] as String?,
    );
  }

  final String id;
  final String lotCode;
  final DateTime? expiryDate;
  final String? expiryPrecision;

  @override
  List<Object?> get props => [id, lotCode, expiryDate, expiryPrecision];
}

/// Mặt hàng hợp lệ cho hành động thêm mặt hàng ngoài dự kiến.
class StocktakeUnexpectedProduct extends Equatable {
  const StocktakeUnexpectedProduct({
    required this.id,
    required this.name,
    required this.code,
    required this.uom,
    required this.trackingMode,
    required this.lots,
  });

  factory StocktakeUnexpectedProduct.fromJson(Map<String, dynamic> json) {
    return StocktakeUnexpectedProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      trackingMode: json['tracking_mode'] as String? ?? 'none',
      lots: (json['lots'] as List<dynamic>? ?? const [])
          .map(
            (e) => StocktakeUnexpectedLot.fromJson(e as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String id;
  final String name;
  final String code;
  final String uom;
  final String trackingMode;
  final List<StocktakeUnexpectedLot> lots;

  bool get isLotTracked => trackingMode == 'lot';

  @override
  List<Object?> get props => [id, name, code, uom, trackingMode, lots];
}

/// Danh sách mặt hàng ngoài dự kiến hợp lệ trong phiên đang đếm đầu.
class StocktakeUnexpectedOptions extends Equatable {
  const StocktakeUnexpectedOptions({required this.products});

  factory StocktakeUnexpectedOptions.fromJson(Map<String, dynamic> json) {
    return StocktakeUnexpectedOptions(
      products: (json['products'] as List<dynamic>? ?? const [])
          .map(
            (e) =>
                StocktakeUnexpectedProduct.fromJson(e as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final List<StocktakeUnexpectedProduct> products;

  @override
  List<Object?> get props => [products];
}

/// Dữ liệu đếm một dòng gửi lên RPC nộp đếm đầu / đếm lại.
class StocktakeCountInput extends Equatable {
  const StocktakeCountInput({
    required this.lineId,
    required this.quantity,
    this.lossReason,
  });

  final String lineId;
  final num quantity;
  final StocktakeLossReason? lossReason;

  Map<String, dynamic> toJson() => {
    'line_id': lineId,
    'quantity': quantity,
    if (lossReason != null) 'loss_reason': lossReason!.wire,
  };

  @override
  List<Object?> get props => [lineId, quantity, lossReason];
}

/// Trạng thái mới trả về sau khi nộp đếm đầu hoặc nộp đếm lại.
class StocktakeSubmitResult extends Equatable {
  const StocktakeSubmitResult({required this.status, this.resultKind});

  factory StocktakeSubmitResult.fromJson(Map<String, dynamic> json) {
    return StocktakeSubmitResult(
      status: StocktakeStatus.fromWire(json['status'] as String),
      resultKind: StocktakeResultKind.tryFromWire(json['result_kind']),
    );
  }

  final StocktakeStatus status;
  final StocktakeResultKind? resultKind;

  @override
  List<Object?> get props => [status, resultKind];
}
