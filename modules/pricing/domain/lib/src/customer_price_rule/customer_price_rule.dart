import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'customer_price_rule_key.dart';
import 'customer_price_rule_review_status.dart';
import 'customer_price_rule_source_type.dart';
import 'customer_price_rule_status.dart';
import 'customer_price_rule_type.dart';
import 'effective_period.dart';
import 'events/customer_price_rule_created_domain_event.dart';
import 'events/customer_price_rule_deleted_domain_event.dart';
import 'events/customer_price_rule_disabled_domain_event.dart';
import 'events/customer_price_rule_reenabled_domain_event.dart';
import 'events/customer_price_rule_updated_domain_event.dart';
import 'rule_validation_outcome.dart';
import 'rule_validation_state.dart';
import 'rules/customer_price_rule_can_be_deleted_rule.dart';
import 'rules/customer_price_rule_can_be_disabled_rule.dart';
import 'rules/customer_price_rule_can_be_reenabled_rule.dart';
import 'rules/manual_rule_must_have_actor_rule.dart';
import 'rules/rule_candidate_must_be_committable_rule.dart';
import 'rules/rule_currency_must_not_change_rule.dart';

final class CustomerPriceRule extends Entity<String> implements IAggregateRoot {
  CustomerPriceRule._({
    required super.id,
    required this.key,
    required Money price,
    required EffectivePeriod effectivePeriod,
    required this.actorId,
    required RuleValidationOutcome validationOutcome,
    required String? note,
    required this.ruleType,
    required this.sourceType,
    required CustomerPriceRuleStatus status,
    required CustomerPriceRuleReviewStatus reviewStatus,
    required int version,
    required DateTime? deletedAt,
  }) : _price = price,
       _effectivePeriod = effectivePeriod,
       _validationOutcome = validationOutcome,
       _note = note,
       _status = status,
       _reviewStatus = reviewStatus,
       _version = version,
       _deletedAt = deletedAt;

  factory CustomerPriceRule.createManual({
    required String id,
    required CustomerPriceRuleKey key,
    required Money price,
    required EffectivePeriod effectivePeriod,
    required String actorId,
    required RuleValidationOutcome validationOutcome,
    String? note,
  }) {
    ManualRuleMustHaveActorRule(actorId).ensureValid();
    RuleCandidateMustBeCommittableRule(validationOutcome).ensureValid();
    final rule = CustomerPriceRule._(
      id: id,
      key: key,
      price: price,
      effectivePeriod: effectivePeriod,
      actorId: actorId,
      validationOutcome: validationOutcome,
      note: _normalizeNote(note),
      ruleType: CustomerPriceRuleType.specialPrice,
      sourceType: CustomerPriceRuleSourceType.manual,
      status: CustomerPriceRuleStatus.active,
      reviewStatus: validationOutcome.outcome == RuleValidationState.warning
          ? CustomerPriceRuleReviewStatus.warning
          : CustomerPriceRuleReviewStatus.clear,
      version: 1,
      deletedAt: null,
    );
    rule.addDomainEvent(CustomerPriceRuleCreatedDomainEvent(ruleId: id));
    return rule;
  }

  factory CustomerPriceRule.reconstitute({
    required String id,
    required CustomerPriceRuleKey key,
    required Money price,
    required EffectivePeriod effectivePeriod,
    required String actorId,
    required RuleValidationOutcome validationOutcome,
    required CustomerPriceRuleType ruleType,
    required CustomerPriceRuleSourceType sourceType,
    required CustomerPriceRuleStatus status,
    required CustomerPriceRuleReviewStatus reviewStatus,
    required int version,
    String? note,
    DateTime? deletedAt,
  }) {
    if (version <= 0) {
      throw ArgumentError.value(version, 'version', 'must be positive');
    }
    final isDeleted = status == CustomerPriceRuleStatus.deleted;
    if (isDeleted != (deletedAt != null)) {
      throw ArgumentError(
        'status == deleted must be equivalent to deletedAt != null',
      );
    }
    return CustomerPriceRule._(
      id: id,
      key: key,
      price: price,
      effectivePeriod: effectivePeriod,
      actorId: actorId,
      validationOutcome: validationOutcome,
      note: _normalizeNote(note),
      ruleType: ruleType,
      sourceType: sourceType,
      status: status,
      reviewStatus: reviewStatus,
      version: version,
      deletedAt: deletedAt,
    );
  }

  final CustomerPriceRuleKey key;
  Money _price;
  Money get price => _price;
  EffectivePeriod _effectivePeriod;
  EffectivePeriod get effectivePeriod => _effectivePeriod;
  final String actorId;
  RuleValidationOutcome _validationOutcome;
  RuleValidationOutcome get validationOutcome => _validationOutcome;
  String? _note;
  String? get note => _note;
  final CustomerPriceRuleType ruleType;
  final CustomerPriceRuleSourceType sourceType;
  CustomerPriceRuleStatus _status;
  CustomerPriceRuleStatus get status => _status;
  CustomerPriceRuleReviewStatus _reviewStatus;
  CustomerPriceRuleReviewStatus get reviewStatus => _reviewStatus;
  int _version;
  int get version => _version;
  DateTime? _deletedAt;
  DateTime? get deletedAt => _deletedAt;

  bool hasSameMutableValues({
    required Money price,
    required EffectivePeriod effectivePeriod,
    String? note,
  }) =>
      _price == price &&
      _effectivePeriod == effectivePeriod &&
      _note == _normalizeNote(note);

  bool updateMutableFields({
    required Money price,
    required EffectivePeriod effectivePeriod,
    required RuleValidationOutcome validationOutcome,
    String? note,
  }) {
    RuleCurrencyMustNotChangeRule(
      currentCurrencyCode: _price.currencyCode,
      updatedCurrencyCode: price.currencyCode,
    ).ensureValid();
    RuleCandidateMustBeCommittableRule(validationOutcome).ensureValid();
    if (hasSameMutableValues(
      price: price,
      effectivePeriod: effectivePeriod,
      note: note,
    )) {
      return false;
    }

    final previousVersion = _version;
    _price = price;
    _effectivePeriod = effectivePeriod;
    _note = _normalizeNote(note);
    _validationOutcome = validationOutcome;
    _reviewStatus = validationOutcome.outcome == RuleValidationState.warning
        ? CustomerPriceRuleReviewStatus.warning
        : CustomerPriceRuleReviewStatus.clear;
    if (_status != CustomerPriceRuleStatus.disabled) {
      _status = CustomerPriceRuleStatus.active;
    }
    _version += 1;
    addDomainEvent(
      CustomerPriceRuleUpdatedDomainEvent(
        ruleId: id,
        previousVersion: previousVersion,
        newVersion: _version,
      ),
    );
    return true;
  }

  bool disable() {
    if (_status == CustomerPriceRuleStatus.disabled) return false;
    CustomerPriceRuleCanBeDisabledRule(_status).ensureValid();
    final previousVersion = _version;
    _status = CustomerPriceRuleStatus.disabled;
    _version += 1;
    addDomainEvent(
      CustomerPriceRuleDisabledDomainEvent(
        ruleId: id,
        previousVersion: previousVersion,
        newVersion: _version,
      ),
    );
    return true;
  }

  bool reenable(RuleValidationOutcome validationOutcome) {
    CustomerPriceRuleCanBeReenabledRule(_status).ensureValid();
    RuleCandidateMustBeCommittableRule(validationOutcome).ensureValid();
    final previousVersion = _version;
    _status = CustomerPriceRuleStatus.active;
    _validationOutcome = validationOutcome;
    _reviewStatus = validationOutcome.outcome == RuleValidationState.warning
        ? CustomerPriceRuleReviewStatus.warning
        : CustomerPriceRuleReviewStatus.clear;
    _version += 1;
    addDomainEvent(
      CustomerPriceRuleReenabledDomainEvent(
        ruleId: id,
        previousVersion: previousVersion,
        newVersion: _version,
      ),
    );
    return true;
  }

  bool softDelete({required DateTime deletedAt}) {
    if (_status == CustomerPriceRuleStatus.deleted) return false;
    CustomerPriceRuleCanBeDeletedRule(_status).ensureValid();
    final previousVersion = _version;
    _status = CustomerPriceRuleStatus.deleted;
    _deletedAt = deletedAt;
    _version += 1;
    addDomainEvent(
      CustomerPriceRuleDeletedDomainEvent(
        ruleId: id,
        previousVersion: previousVersion,
        newVersion: _version,
      ),
    );
    return true;
  }

  static String? _normalizeNote(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
