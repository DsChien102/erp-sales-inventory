import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/partner_role_type.dart';
import '../enums/partner_status.dart';
import '../enums/partner_type.dart';
import 'entities/organization_contact.dart';
import 'entities/organization_profile.dart';
import 'entities/partner_role.dart';
import 'entities/person_profile.dart';
import 'events/organization_contact_added_event.dart';
import 'events/organization_contact_removed_event.dart';
import 'events/organization_contact_updated_event.dart';
import 'events/partner_created_event.dart';
import 'events/partner_deactivated_event.dart';
import 'events/partner_profile_updated_event.dart';
import 'events/partner_reactivated_event.dart';
import 'events/partner_soft_deleted_event.dart';
import 'events/partner_transformed_to_organization_event.dart';
import 'partner_id.dart';
import 'rules/deleted_partner_cannot_mutate_rule.dart';
import 'rules/organization_contact_requires_organization_partner_rule.dart';
import 'rules/organization_single_primary_contact_rule.dart';
import 'rules/partner_must_have_at_least_one_role_rule.dart';
import 'rules/partner_status_transition_allowed_rule.dart';
import 'rules/person_or_organization_profile_exclusive_rule.dart';
import 'rules/soft_delete_requires_no_transactions_rule.dart';
import 'rules/transform_only_person_to_organization_rule.dart';

/// Partner aggregate root — profile, roles, contacts, lifecycle.
final class Partner extends Entity<PartnerId> implements IAggregateRoot {
  Partner._({
    required PartnerId id,
    required TenantId tenantId,
    required PartnerType partnerType,
    required PartnerStatus status,
    required String displayName,
    required List<PartnerRole> roles,
    PersonProfile? personProfile,
    OrganizationProfile? organizationProfile,
    List<OrganizationContact> contacts = const [],
    required int version,
  })  : _tenantId = tenantId,
        _partnerType = partnerType,
        _status = status,
        _displayName = displayName,
        _roles = List.of(roles),
        _personProfile = personProfile,
        _organizationProfile = organizationProfile,
        _contacts = List.of(contacts),
        _version = version,
        super(id: id);

  final TenantId _tenantId;
  PartnerType _partnerType;
  PartnerStatus _status;
  String _displayName;
  final List<PartnerRole> _roles;
  PersonProfile? _personProfile;
  OrganizationProfile? _organizationProfile;
  final List<OrganizationContact> _contacts;
  int _version;

  TenantId get tenantId => _tenantId;
  PartnerType get partnerType => _partnerType;
  PartnerStatus get status => _status;
  String get displayName => _displayName;
  int get version => _version;
  PersonProfile? get personProfile => _personProfile;
  OrganizationProfile? get organizationProfile => _organizationProfile;
  List<PartnerRole> get roles => List.unmodifiable(_roles);
  List<OrganizationContact> get contacts => List.unmodifiable(_contacts);

  /// Rehydrate from persistence (no domain events).
  factory Partner.reconstitute({
    required PartnerId id,
    required TenantId tenantId,
    required PartnerType partnerType,
    required PartnerStatus status,
    required String displayName,
    required List<PartnerRole> roles,
    PersonProfile? personProfile,
    OrganizationProfile? organizationProfile,
    List<OrganizationContact> contacts = const [],
    required int version,
  }) {
    return Partner._(
      id: id,
      tenantId: tenantId,
      partnerType: partnerType,
      status: status,
      displayName: displayName,
      roles: roles,
      personProfile: personProfile,
      organizationProfile: organizationProfile,
      contacts: contacts,
      version: version,
    );
  }

  factory Partner.create({
    PartnerId? id,
    required TenantId tenantId,
    required PartnerType partnerType,
    required List<PartnerRoleType> roleTypes,
    PersonProfile? personProfile,
    OrganizationProfile? organizationProfile,
  }) {
    final partnerId = id ?? PartnerId(const Uuid().v4());
    final roles = roleTypes.map((r) => PartnerRole(role: r)).toList();
    _enforceRule(PartnerMustHaveAtLeastOneRoleRule(roleTypes));
    _enforceRule(
      PersonOrOrganizationProfileExclusiveRule(
        partnerType: partnerType,
        personProfile: personProfile,
        organizationProfile: organizationProfile,
      ),
    );

    final displayName = switch (partnerType) {
      PartnerType.person => personProfile!.fullName,
      PartnerType.organization => organizationProfile!.organizationName,
    };

    final partner = Partner._(
      id: partnerId,
      tenantId: tenantId,
      partnerType: partnerType,
      status: PartnerStatus.active,
      displayName: displayName,
      roles: roles,
      personProfile: personProfile,
      organizationProfile: organizationProfile,
      version: 1,
    );
    partner.addDomainEvent(PartnerCreatedEvent(partnerId: partnerId));
    return partner;
  }

  void updateProfile({
    PersonProfile? personProfile,
    OrganizationProfile? organizationProfile,
    List<PartnerRoleType>? roleTypes,
  }) {
    _ensureMutable();
    if (personProfile != null) {
      _personProfile = personProfile;
      _displayName = personProfile.fullName;
    }
    if (organizationProfile != null) {
      _organizationProfile = organizationProfile;
      _displayName = organizationProfile.organizationName;
    }
    if (roleTypes != null) {
      checkRule(PartnerMustHaveAtLeastOneRoleRule(roleTypes));
      _roles
        ..clear()
        ..addAll(roleTypes.map((r) => PartnerRole(role: r)));
    }
    checkRule(
      PersonOrOrganizationProfileExclusiveRule(
        partnerType: _partnerType,
        personProfile: _personProfile,
        organizationProfile: _organizationProfile,
      ),
    );
    addDomainEvent(PartnerProfileUpdatedEvent(partnerId: id));
  }

  void addContact(OrganizationContact contact) {
    _ensureMutable();
    checkRule(OrganizationContactRequiresOrganizationPartnerRule(_partnerType));
    if (contact.isPrimary) {
      for (var i = 0; i < _contacts.length; i++) {
        if (_contacts[i].isPrimary) {
          _contacts[i] = _contacts[i].copyWith(isPrimary: false);
        }
      }
    }
    _contacts.add(contact);
    checkRule(OrganizationSinglePrimaryContactRule(_contacts));
    addDomainEvent(
      OrganizationContactAddedEvent(
        organizationPartnerId: id,
        personPartnerId: contact.personPartnerId,
      ),
    );
  }

  void updateContact({
    required PartnerId personPartnerId,
    String? contactRole,
    bool? isPrimary,
    String? note,
  }) {
    _ensureMutable();
    checkRule(OrganizationContactRequiresOrganizationPartnerRule(_partnerType));
    final index = _contacts.indexWhere(
      (c) => c.personPartnerId == personPartnerId,
    );
    if (index < 0) {
      throw StateError('Contact not found');
    }
    if (isPrimary == true) {
      for (var i = 0; i < _contacts.length; i++) {
        if (i != index && _contacts[i].isPrimary) {
          _contacts[i] = _contacts[i].copyWith(isPrimary: false);
        }
      }
    }
    _contacts[index] = _contacts[index].copyWith(
      contactRole: contactRole,
      isPrimary: isPrimary,
      note: note,
    );
    checkRule(OrganizationSinglePrimaryContactRule(_contacts));
    addDomainEvent(
      OrganizationContactUpdatedEvent(
        organizationPartnerId: id,
        personPartnerId: personPartnerId,
      ),
    );
  }

  void removeContact(PartnerId personPartnerId) {
    _ensureMutable();
    checkRule(OrganizationContactRequiresOrganizationPartnerRule(_partnerType));
    final before = _contacts.length;
    _contacts.removeWhere((c) => c.personPartnerId == personPartnerId);
    if (_contacts.length == before) {
      throw StateError('Contact not found');
    }
    addDomainEvent(
      OrganizationContactRemovedEvent(
        organizationPartnerId: id,
        personPartnerId: personPartnerId,
      ),
    );
  }

  void transformToOrganization({
    required OrganizationProfile organizationProfile,
    required PartnerId formerPersonPartnerId,
  }) {
    _ensureMutable();
    checkRule(TransformOnlyPersonToOrganizationRule(_partnerType));
    final formerPerson = _personProfile;
    if (formerPerson == null) {
      throw StateError('Person profile required for transform');
    }

    _partnerType = PartnerType.organization;
    _organizationProfile = organizationProfile;
    _personProfile = null;
    _displayName = organizationProfile.organizationName;
    _contacts.add(
      OrganizationContact(
        personPartnerId: formerPersonPartnerId,
        isPrimary: true,
        contactRole: 'primary',
      ),
    );
    checkRule(OrganizationSinglePrimaryContactRule(_contacts));
    addDomainEvent(PartnerTransformedToOrganizationEvent(partnerId: id));
  }

  void deactivate() {
    _transitionStatus(PartnerStatus.inactive);
    addDomainEvent(PartnerDeactivatedEvent(partnerId: id));
  }

  void reactivate() {
    _transitionStatus(PartnerStatus.active);
    addDomainEvent(PartnerReactivatedEvent(partnerId: id));
  }

  void softDelete({required bool hasTransactions}) {
    _ensureMutable();
    checkRule(SoftDeleteRequiresNoTransactionsRule(hasTransactions));
    _transitionStatus(PartnerStatus.deleted);
    addDomainEvent(PartnerSoftDeletedEvent(partnerId: id));
  }

  @visibleForTesting
  void bumpVersion() => _version++;

  void _transitionStatus(PartnerStatus to) {
    _ensureMutable();
    checkRule(PartnerStatusTransitionAllowedRule(from: _status, to: to));
    _status = to;
  }

  void _ensureMutable() {
    checkRule(DeletedPartnerCannotMutateRule(_status));
  }
}

void _enforceRule(IBusinessRule rule) {
  if (rule.isBroken()) {
    throw BusinessRuleValidationException(rule);
  }
}
