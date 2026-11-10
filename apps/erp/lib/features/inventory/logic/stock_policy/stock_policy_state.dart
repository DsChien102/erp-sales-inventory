import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_rules.dart';

enum StockPolicyStatus {
  loading,
  ready,
  denied,
  loadError,
  conflict,
}

enum ThresholdFilter {
  all,
  unset,
}

sealed class FailedSaveAction {
  const FailedSaveAction();
}

class FailedThresholdsSave extends FailedSaveAction {
  const FailedThresholdsSave();
}

class FailedNearExpirySave extends FailedSaveAction {
  const FailedNearExpirySave();
}

class FailedSingleSave extends FailedSaveAction {
  final String productId;
  final String threshold;
  final String target;

  const FailedSingleSave({
    required this.productId,
    required this.threshold,
    required this.target,
  });
}

class ThresholdDraft {
  final String threshold;
  final String target;

  const ThresholdDraft({
    required this.threshold,
    required this.target,
  });

  ThresholdDraft copyWith({String? threshold, String? target}) {
    return ThresholdDraft(
      threshold: threshold ?? this.threshold,
      target: target ?? this.target,
    );
  }
}

class ExpiryOverrideDraft {
  final String productId;
  final String days;

  const ExpiryOverrideDraft({
    required this.productId,
    required this.days,
  });

  ExpiryOverrideDraft copyWith({String? days}) {
    return ExpiryOverrideDraft(
      productId: productId,
      days: days ?? this.days,
    );
  }
}

class ExpiryDraft {
  final String defaultDays;
  final List<ExpiryOverrideDraft> overrides;

  const ExpiryDraft({
    this.defaultDays = '',
    this.overrides = const [],
  });

  ExpiryDraft copyWith({
    String? defaultDays,
    List<ExpiryOverrideDraft>? overrides,
  }) {
    return ExpiryDraft(
      defaultDays: defaultDays ?? this.defaultDays,
      overrides: overrides ?? this.overrides,
    );
  }
}

class StockPolicyState {
  final StockPolicyStatus status;
  final StockPolicySnapshot? snapshot;
  final Map<String, ThresholdDraft> thresholdDrafts;
  final ExpiryDraft expiryDraft;
  final ThresholdFilter filter;
  final bool saving;
  final AppException? saveError;
  final int? savedRevision;
  final FailedSaveAction? lastFailedSave;

  const StockPolicyState({
    this.status = StockPolicyStatus.loading,
    this.snapshot,
    this.thresholdDrafts = const {},
    this.expiryDraft = const ExpiryDraft(),
    this.filter = ThresholdFilter.all,
    this.saving = false,
    this.saveError,
    this.savedRevision,
    this.lastFailedSave,
  });

  List<String> get dirtyProductIds => thresholdDrafts.keys.toList();

  bool get hasThresholdError {
    if (snapshot == null) return false;
    for (final entry in thresholdDrafts.entries) {
      final product = snapshot!.products.where((p) => p.productId == entry.key).firstOrNull;
      final configured = product?.configured ?? false;
      if (thresholdRowError(entry.value.threshold, entry.value.target, configured: configured) != null) {
        return true;
      }
    }
    return false;
  }

  bool get expiryDirty {
    if (snapshot == null) return false;
    final savedDefaultDays = snapshot!.nearExpiryDays?.toString() ?? '';
    if (expiryDraft.defaultDays.trim() != savedDefaultDays.trim()) return true;

    final savedOverrides = snapshot!.products
        .where((p) => p.nearExpiryDaysOverride != null)
        .map((p) => (productId: p.productId, days: p.nearExpiryDaysOverride!.toString()))
        .toList();

    if (expiryDraft.overrides.length != savedOverrides.length) return true;

    for (final o in expiryDraft.overrides) {
      final match = savedOverrides.where((s) => s.productId == o.productId).firstOrNull;
      if (match == null || match.days != o.days.trim()) return true;
    }
    return false;
  }

  bool get expiryHasError {
    if (defaultDaysError(expiryDraft.defaultDays) != null) return true;
    for (final o in expiryDraft.overrides) {
      if (overrideDaysError(o.days) != null) return true;
    }
    return false;
  }

  bool get hasUnsavedChanges => dirtyProductIds.isNotEmpty || expiryDirty;

  bool get readOnly => !(snapshot?.isOwner ?? false) || status == StockPolicyStatus.conflict;

  ThresholdDraft shownThreshold(StockPolicyProduct product) {
    return thresholdDrafts[product.productId] ??
        ThresholdDraft(
          threshold: product.threshold?.toString() ?? '',
          target: product.target?.toString() ?? '',
        );
  }

  StockPolicyProduct appliedProduct(StockPolicyProduct product) {
    final draft = thresholdDrafts[product.productId];
    if (draft == null) return product;

    if (thresholdRowError(draft.threshold, draft.target, configured: product.configured) != null) {
      return product;
    }

    final t = num.tryParse(draft.threshold.trim());
    final g = num.tryParse(draft.target.trim());
    return StockPolicyProduct(
      productId: product.productId,
      name: product.name,
      code: product.code,
      uom: product.uom,
      isLotTracked: product.isLotTracked,
      available: product.available,
      hasExpired: product.hasExpired,
      hasNearExpiry: product.hasNearExpiry,
      threshold: t,
      target: g,
      nearExpiryDaysOverride: product.nearExpiryDaysOverride,
    );
  }

  StockPolicyState copyWith({
    StockPolicyStatus? status,
    StockPolicySnapshot? snapshot,
    Map<String, ThresholdDraft>? thresholdDrafts,
    ExpiryDraft? expiryDraft,
    ThresholdFilter? filter,
    bool? saving,
    AppException? saveError,
    bool clearSaveError = false,
    int? savedRevision,
    bool clearSavedRevision = false,
    FailedSaveAction? lastFailedSave,
  }) {
    return StockPolicyState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      thresholdDrafts: thresholdDrafts ?? this.thresholdDrafts,
      expiryDraft: expiryDraft ?? this.expiryDraft,
      filter: filter ?? this.filter,
      saving: saving ?? this.saving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      savedRevision: clearSavedRevision ? null : (savedRevision ?? this.savedRevision),
      lastFailedSave: clearSaveError ? null : (lastFailedSave ?? this.lastFailedSave),
    );
  }
}

