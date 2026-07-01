import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import '../bloc/partner_list_state.dart';
import '../models/partner_filter_counts.dart';

abstract final class PartnerUiMapper {
  static PartnerSearchCriteria toSearchCriteria({
    required String searchQuery,
    String? filterRole,
    String? filterProfileType,
    String? filterStatus,
  }) {
    final roleFilter = switch (filterRole) {
      'Khách hàng' => PartnerRoleFilter.customer,
      'Nhà cung cấp' => PartnerRoleFilter.supplier,
      'Khách hàng & NCC' => PartnerRoleFilter.both,
      _ => null,
    };

    final statuses = switch (filterStatus) {
      'Đang hoạt động' => {PartnerStatus.active},
      'Ngừng hoạt động' => {PartnerStatus.inactive},
      _ => null,
    };

    final entityType = switch (filterProfileType) {
      'Cá nhân' => EntityType.individual,
      'Công ty' => EntityType.company,
      'Hộ kinh doanh' => EntityType.householdBusiness,
      _ => null,
    };

    return PartnerSearchCriteria(
      keyword: searchQuery.trim().isEmpty ? null : searchQuery.trim(),
      statuses: statuses,
      roleFilter: roleFilter,
      entityType: entityType,
    );
  }

  static PartnerFilterCounts toFilterCounts(List<PartnerListItemDto> items) {
    var customer = 0;
    var supplier = 0;
    var both = 0;
    var individual = 0;
    var company = 0;
    var household = 0;
    var active = 0;
    var inactive = 0;

    for (final item in items) {
      final hasCustomer = item.roles.contains(PartnerRole.customer);
      final hasSupplier = item.roles.contains(PartnerRole.supplier);

      if (hasCustomer) {
        customer++;
      }
      if (hasSupplier) {
        supplier++;
      }
      if (hasCustomer && hasSupplier) {
        both++;
      }

      switch (item.entityType) {
        case EntityType.individual:
          individual++;
        case EntityType.company:
          company++;
        case EntityType.householdBusiness:
          household++;
      }

      switch (item.status) {
        case PartnerStatus.active:
          active++;
        case PartnerStatus.inactive:
          inactive++;
      }
    }

    return PartnerFilterCounts(
      total: items.length,
      customer: customer,
      supplier: supplier,
      both: both,
      individual: individual,
      company: company,
      household: household,
      active: active,
      inactive: inactive,
    );
  }

  static PartnerItemModel toListItem(PartnerListItemDto dto) {
    return PartnerItemModel(
      id: dto.id,
      avatarText: _avatarText(dto.displayName),
      name: dto.displayName,
      role: _roleLabel(dto.roles),
      status: _statusLabel(dto.status),
      phone: dto.phone,
      email: dto.email ?? '',
      taxId: dto.taxCode ?? '',
      updatedAt: _formatDateTime(dto.updatedAt),
      profileType: _entityTypeLabel(dto.entityType),
    );
  }

  static Set<PartnerRole> toRoles(String role) {
    return switch (role) {
      'supplier' => {PartnerRole.supplier},
      'both' => {PartnerRole.customer, PartnerRole.supplier},
      _ => {PartnerRole.customer},
    };
  }

  static EntityType toEntityType(String profileType) {
    return switch (profileType) {
      'company' => EntityType.company,
      'household' => EntityType.householdBusiness,
      _ => EntityType.individual,
    };
  }

  static String toUiProfileType(EntityType entityType) {
    return switch (entityType) {
      EntityType.company => 'company',
      EntityType.householdBusiness => 'household',
      EntityType.individual => 'individual',
    };
  }

  static String toUiRole(Set<PartnerRole> roles) {
    final hasCustomer = roles.contains(PartnerRole.customer);
    final hasSupplier = roles.contains(PartnerRole.supplier);
    if (hasCustomer && hasSupplier) {
      return 'both';
    }
    if (hasSupplier) {
      return 'supplier';
    }
    return 'customer';
  }

  static RegisterPartnerCommand toRegisterCommand({
    required String tenantId,
    required String actorId,
    required String role,
    required String profileType,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String taxId,
    required String note,
    required bool confirmDuplicate,
    String? commandId,
  }) {
    final entityType = toEntityType(profileType);
    final trimmedName = name.trim();

    return RegisterPartnerCommand(
      id: commandId,
      tenantId: tenantId,
      actorId: actorId,
      entityType: entityType,
      displayName: trimmedName,
      phone: phone.trim(),
      roles: toRoles(role),
      confirmDuplicate: confirmDuplicate,
      individualName:
          entityType == EntityType.individual ? trimmedName : null,
      businessName: entityType == EntityType.householdBusiness
          ? trimmedName
          : null,
      companyName: entityType == EntityType.company ? trimmedName : null,
      email: email.trim().isEmpty ? null : email.trim(),
      taxCode: taxId.trim().isEmpty ? null : taxId.trim(),
      address: address.trim().isEmpty ? null : address.trim(),
      note: note.trim().isEmpty ? null : note.trim(),
    );
  }

  static String duplicateWarning(PartnerDuplicateMatchDto match) {
    final fieldLabel = switch (match.field) {
      PartnerDuplicateField.phone => 'Số điện thoại',
      PartnerDuplicateField.email => 'Email',
      PartnerDuplicateField.taxCode => 'Mã số thuế',
    };
    return '$fieldLabel đã tồn tại (${match.displayName}).';
  }

  static String _avatarText(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    final lastTwo = parts.sublist(parts.length - 2);
    return lastTwo.map((part) => part.substring(0, 1)).join().toUpperCase();
  }

  static String _roleLabel(Set<PartnerRole> roles) {
    final hasCustomer = roles.contains(PartnerRole.customer);
    final hasSupplier = roles.contains(PartnerRole.supplier);

    if (hasCustomer && hasSupplier) {
      return 'Khách hàng & NCC';
    }
    if (hasCustomer) {
      return 'Khách hàng';
    }
    if (hasSupplier) {
      return 'Nhà cung cấp';
    }
    return '';
  }

  static String _statusLabel(PartnerStatus status) {
    return switch (status) {
      PartnerStatus.active => 'Đang hoạt động',
      PartnerStatus.inactive => 'Ngừng hoạt động',
    };
  }

  static String _entityTypeLabel(EntityType entityType) {
    return switch (entityType) {
      EntityType.individual => 'Cá nhân',
      EntityType.company => 'Công ty',
      EntityType.householdBusiness => 'Hộ kinh doanh',
    };
  }

  static String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;

    return '$hour:$minute $day/$month/$year';
  }
}
