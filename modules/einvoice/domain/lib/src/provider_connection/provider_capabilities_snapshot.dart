import 'package:equatable/equatable.dart';

/// Embedded capability snapshot from provider sync (replaceable on sync).
final class ProviderCapabilitiesSnapshot extends Equatable {
  const ProviderCapabilitiesSnapshot({
    required this.supportsEmailDelivery,
    required this.templateCount,
    this.syncedAt,
  });

  final bool supportsEmailDelivery;
  final int templateCount;
  final DateTime? syncedAt;

  ProviderCapabilitiesSnapshot copyWith({
    bool? supportsEmailDelivery,
    int? templateCount,
    DateTime? syncedAt,
  }) {
    return ProviderCapabilitiesSnapshot(
      supportsEmailDelivery:
          supportsEmailDelivery ?? this.supportsEmailDelivery,
      templateCount: templateCount ?? this.templateCount,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  List<Object?> get props => [
    supportsEmailDelivery,
    templateCount,
    syncedAt,
  ];
}
