import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_domain/domain.dart';

/// Shared interaction rule for E-Invoice surfaces that show a status badge.
///
/// Any control whose **active** status maps to [VBadgeStatus.processing]
/// must be non-interactive (no onTap / click). Visual badge treatment is
/// unchanged — only interaction is gated.
abstract final class EInvoiceStatusInteraction {
  /// Whether a control presenting [status] may accept taps.
  static bool allowsTap(VBadgeStatus status) => status != VBadgeStatus.processing;

  static VBadgeStatus forIssuance(IssuanceDisplayState state) => switch (state) {
    IssuanceDisplayState.notIssued => VBadgeStatus.draft,
    IssuanceDisplayState.processing => VBadgeStatus.processing,
    IssuanceDisplayState.issued => VBadgeStatus.success,
    IssuanceDisplayState.failed => VBadgeStatus.danger,
  };

  static VBadgeStatus forDelivery(DeliveryDisplayState state) => switch (state) {
    DeliveryDisplayState.notSent => VBadgeStatus.draft,
    DeliveryDisplayState.sending => VBadgeStatus.processing,
    DeliveryDisplayState.sent => VBadgeStatus.success,
    DeliveryDisplayState.failed => VBadgeStatus.danger,
    DeliveryDisplayState.unknown => VBadgeStatus.warning,
  };

  static bool allowsTapForIssuance(IssuanceDisplayState state) => allowsTap(forIssuance(state));

  static bool allowsTapForDelivery(DeliveryDisplayState state) => allowsTap(forDelivery(state));
}
