import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';

class ProgramFormDraft {
  final String? supplierId;
  final ProgramKind kind;
  final String name;
  final DateTime startedOn;
  final String note;
  final List<String> productIds;
  final List<({String minQty, String percent})> tiers;
  final String buyQty;
  final String freeQty;
  final String targetQty;
  final String rebatePercent;

  const ProgramFormDraft({
    required this.supplierId,
    required this.kind,
    required this.name,
    required this.startedOn,
    required this.note,
    required this.productIds,
    required this.tiers,
    required this.buyQty,
    required this.freeQty,
    required this.targetQty,
    required this.rebatePercent,
  });

  factory ProgramFormDraft.initial({
    String? supplierId,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    return ProgramFormDraft(
      supplierId: supplierId,
      kind: ProgramKind.tierDiscount,
      name: '',
      startedOn: DateTime(now.year, now.month, now.day),
      note: '',
      productIds: const [],
      tiers: const [(minQty: '', percent: '')],
      buyQty: '',
      freeQty: '',
      targetQty: '',
      rebatePercent: '',
    );
  }

  factory ProgramFormDraft.fromDetail(ProgramDetail detail) {
    final r = detail.row;
    final tiers = r.tiers.isNotEmpty
        ? [
            for (final t in r.tiers)
              (
                minQty: _numToInput(t.minQty),
                percent: _numToInput(t.discountPercent),
              ),
          ]
        : const [(minQty: '', percent: '')];

    return ProgramFormDraft(
      supplierId: r.supplierId,
      kind: r.kind,
      name: r.name,
      startedOn: DateTime(r.startedOn.year, r.startedOn.month, r.startedOn.day),
      note: detail.note ?? '',
      productIds: List<String>.unmodifiable(r.productIds),
      tiers: tiers,
      buyQty: r.buyQty != null ? _numToInput(r.buyQty!) : '',
      freeQty: r.freeQty != null ? _numToInput(r.freeQty!) : '',
      targetQty: r.targetQty != null ? _numToInput(r.targetQty!) : '',
      rebatePercent:
          r.rebatePercent != null ? _numToInput(r.rebatePercent!) : '',
    );
  }

  static String _numToInput(num n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toString().replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static num? parseNum(String raw) {
    final s = raw.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return num.tryParse(s);
  }

  ProgramFormDraft copyWith({
    String? supplierId,
    bool clearSupplier = false,
    ProgramKind? kind,
    String? name,
    DateTime? startedOn,
    String? note,
    List<String>? productIds,
    List<({String minQty, String percent})>? tiers,
    String? buyQty,
    String? freeQty,
    String? targetQty,
    String? rebatePercent,
  }) {
    return ProgramFormDraft(
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      kind: kind ?? this.kind,
      name: name ?? this.name,
      startedOn: startedOn ?? this.startedOn,
      note: note ?? this.note,
      productIds: productIds ?? this.productIds,
      tiers: tiers ?? this.tiers,
      buyQty: buyQty ?? this.buyQty,
      freeQty: freeQty ?? this.freeQty,
      targetQty: targetQty ?? this.targetQty,
      rebatePercent: rebatePercent ?? this.rebatePercent,
    );
  }

  ProgramPayload toPayload({required bool forUpdate}) {
    return ProgramPayload(
      supplierId: forUpdate ? null : supplierId,
      kind: forUpdate ? null : kind,
      effectiveKind: kind,
      name: name,
      startedOn: startedOn,
      note: note,
      productIds: productIds,
      tiers: kind == ProgramKind.tierDiscount
          ? [
              for (final t in tiers)
                ProgramTier(
                  minQty: parseNum(t.minQty) ?? 0,
                  discountPercent: parseNum(t.percent) ?? 0,
                ),
            ]
          : const [],
      buyQty: kind == ProgramKind.buyXGetY ? parseNum(buyQty) : null,
      freeQty: kind == ProgramKind.buyXGetY ? parseNum(freeQty) : null,
      targetQty: kind == ProgramKind.volumeRebate ? parseNum(targetQty) : null,
      rebatePercent:
          kind == ProgramKind.volumeRebate ? parseNum(rebatePercent) : null,
    );
  }
}

