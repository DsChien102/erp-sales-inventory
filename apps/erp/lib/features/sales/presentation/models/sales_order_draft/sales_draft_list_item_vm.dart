import 'package:equatable/equatable.dart';
import 'package:vet45_sales_application/application.dart';

enum SalesDraftUiStatus { composing, needsCheck }

final class SalesDraftListItemVm extends Equatable {
  const SalesDraftListItemVm({
    required this.draftId,
    required this.version,
    required this.updatedAt,
    required this.customerLabel,
    required this.lineCount,
    required this.total,
    required this.uiStatus,
    this.phone,
    this.note,
    this.createdByName,
    this.isOwnedByMe = true,
    this.warningMessage,
  });

  final String draftId;
  final int version;
  final DateTime updatedAt;
  final String customerLabel;
  final int lineCount;
  final MoneyDto total;
  final SalesDraftUiStatus uiStatus;
  final String? phone;
  final String? note;
  final String? createdByName;
  final bool isOwnedByMe;
  final String? warningMessage;

  bool get needsCheck => uiStatus == SalesDraftUiStatus.needsCheck;

  String get statusLabel => switch (uiStatus) {
    SalesDraftUiStatus.composing => 'Đang soạn',
    SalesDraftUiStatus.needsCheck => 'Cần kiểm tra',
  };

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static final _phonePattern = RegExp(
    r'^\+?[0-9\s\.\-\(\)]{8,15}$',
  );

  String? get creatorLabel {
    final name = createdByName?.trim();
    if (name != null &&
        name.isNotEmpty &&
        !_uuidPattern.hasMatch(name) &&
        !_phonePattern.hasMatch(name)) {
      return name;
    }
    return null;
  }

  SalesDraftListItemVm copyWith({
    String? draftId,
    int? version,
    DateTime? updatedAt,
    String? customerLabel,
    int? lineCount,
    MoneyDto? total,
    SalesDraftUiStatus? uiStatus,
    String? phone,
    String? note,
    String? createdByName,
    bool? isOwnedByMe,
    String? warningMessage,
  }) {
    return SalesDraftListItemVm(
      draftId: draftId ?? this.draftId,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      customerLabel: customerLabel ?? this.customerLabel,
      lineCount: lineCount ?? this.lineCount,
      total: total ?? this.total,
      uiStatus: uiStatus ?? this.uiStatus,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      createdByName: createdByName ?? this.createdByName,
      isOwnedByMe: isOwnedByMe ?? this.isOwnedByMe,
      warningMessage: warningMessage ?? this.warningMessage,
    );
  }

  String get phoneLabel {
    final p = phone?.trim();
    if (p == null || p.isEmpty) return 'Không có số điện thoại';
    return p;
  }

  @override
  List<Object?> get props => [
    draftId,
    version,
    updatedAt,
    customerLabel,
    lineCount,
    total.amountMinor,
    total.currencyCode,
    uiStatus,
    phone,
    note,
    createdByName,
    isOwnedByMe,
    warningMessage,
  ];
}
