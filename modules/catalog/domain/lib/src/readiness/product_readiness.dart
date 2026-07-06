import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'readiness_blocker.dart';
import 'readiness_status.dart';

final class ProductReadiness extends ValueObject {
  const ProductReadiness({
    required this.status,
    this.blockers = const [],
  });

  final ReadinessStatus status;
  final List<ReadinessBlocker> blockers;

  /// Seeds readiness after guided minimal create.
  factory ProductReadiness.seedFromCreate({
    required bool hasBaseUnit,
    required bool hasImages,
  }) {
    final blockers = <ReadinessBlocker>[
      if (!hasBaseUnit) ReadinessBlocker.missingBaseUnit(),
      if (!hasImages) ReadinessBlocker.missingImage(),
      ReadinessBlocker.missingPrice(),
      ReadinessBlocker.missingPriceBand(),
      ReadinessBlocker.missingStock(),
    ];

    return ProductReadiness(
      status: blockers.isEmpty
          ? ReadinessStatus.readyToSell
          : ReadinessStatus.incomplete,
      blockers: List.unmodifiable(blockers),
    );
  }

  bool hasBlocker(String code) => blockers.any((b) => b.code == code);

  ProductReadiness removeBlocker(String code) {
    if (!hasBlocker(code)) return this;
    final newBlockers = blockers.where((b) => b.code != code).toList();
    return ProductReadiness(
      status: newBlockers.isEmpty
          ? ReadinessStatus.readyToSell
          : ReadinessStatus.incomplete,
      blockers: List.unmodifiable(newBlockers),
    );
  }

  ProductReadiness addBlocker(ReadinessBlocker blocker) {
    if (hasBlocker(blocker.code)) return this;
    final newBlockers = [...blockers, blocker];
    return ProductReadiness(
      status: ReadinessStatus.incomplete,
      blockers: List.unmodifiable(newBlockers),
    );
  }

  @override
  List<Object?> get props => [status, blockers];
}

