import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_create_state.dart';

final class PartnerCreateCubit extends Cubit<PartnerCreateState> {
  PartnerCreateCubit({
    required PartnerType partnerType,
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  }) : _partnerModule = partnerModule,
       _executionContext = executionContext,
       super(PartnerCreateState(partnerType: partnerType));

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  bool get canConfirmDuplicate =>
      state.status == PartnerCreateStatus.duplicate &&
      state.duplicateLevel == PartnerDuplicateMatchLevel.possible;

  void setActiveSection(PartnerCreateSection section) {
    if (!state.sections.contains(section)) return;
    if (state.activeSection == section) {
      emit(state.copyWith(clearActiveSection: true));
      return;
    }
    emit(state.copyWith(activeSection: section));
  }

  void skipActiveSection() => _advance(markCompleted: false);

  void continueActiveSection() {
    final section = state.activeSection;
    if (section == null) return;
    final errors = _validateSection(section);
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          errors: {...state.errors, ...errors},
          status: PartnerCreateStatus.failure,
        ),
      );
      return;
    }
    _advance(markCompleted: true);
  }

  void _advance({required bool markCompleted}) {
    final sections = state.sections;
    final currentSection = state.activeSection ?? sections.first;
    final currentIndex = sections.indexOf(currentSection);
    final completed = {...state.completedSections};
    if (markCompleted) completed.add(currentSection);
    final nextIndex = currentIndex < sections.length - 1 ? currentIndex + 1 : currentIndex;
    emit(
      state.copyWith(
        activeSection: sections[nextIndex],
        completedSections: completed,
        status: PartnerCreateStatus.initial,
      ),
    );
  }

  void updateRoles(List<PartnerRoleType> value) => _update(
    state.copyWith(roles: List.unmodifiable(value)),
    clearErrors: const ['roles'],
  );
  void updatePersonTitle(String value) => _update(state.copyWith(personTitle: value));
  void updateFullName(String value) =>
      _update(state.copyWith(fullName: value), clearErrors: const ['fullName']);
  void updateNickname(String value) => _update(state.copyWith(nickname: value));
  void updatePhone(String value) =>
      _update(state.copyWith(phone: value), clearErrors: const ['phone']);
  void updateSecondaryPhone(String value) => _update(state.copyWith(secondaryPhone: value));
  void updateEmail(String value) =>
      _update(state.copyWith(email: value), clearErrors: const ['email']);
  void updateOrganizationType(OrganizationType value) =>
      _update(state.copyWith(organizationType: value));
  void updateOrganizationName(String value) => _update(
    state.copyWith(organizationName: value),
    clearErrors: const ['organizationName'],
  );
  void updateShortName(String value) => _update(state.copyWith(shortName: value));
  void updateInternationalName(String value) => _update(state.copyWith(internationalName: value));
  void setPrimaryContactEnabled(bool value) =>
      _update(state.copyWith(primaryContactEnabled: value));
  void updatePrimaryContactTitle(String value) =>
      _update(state.copyWith(primaryContactTitle: value));
  void updatePrimaryContactName(String value) => _update(
    state.copyWith(primaryContactName: value),
    clearErrors: const ['primaryContactName'],
  );
  void updatePrimaryContactPhone(String value) => _update(
    state.copyWith(primaryContactPhone: value),
    clearErrors: const ['primaryContactPhone'],
  );
  void updatePrimaryContactSecondaryPhone(String value) =>
      _update(state.copyWith(primaryContactSecondaryPhone: value));
  void updatePrimaryContactEmail(String value) => _update(
    state.copyWith(primaryContactEmail: value),
    clearErrors: const ['primaryContactEmail'],
  );
  void updateTaxCode(String value) =>
      _update(state.copyWith(taxCode: value), clearErrors: const ['taxCode']);
  void updateInvoiceName(String value) => _update(state.copyWith(invoiceName: value));
  void updateInvoiceAddress(String value) => _update(state.copyWith(invoiceAddress: value));
  void updateInvoiceEmail(String value) => _update(
    state.copyWith(invoiceEmail: value),
    clearErrors: const ['invoiceEmail'],
  );
  void updateDeliveryProvince(String value) => _update(state.copyWith(deliveryProvince: value));
  void updateDeliveryCommune(String value) => _update(state.copyWith(deliveryCommune: value));
  void updateDeliveryAddress(String value) => _update(state.copyWith(deliveryAddress: value));
  void updateNote(String value) => _update(state.copyWith(note: value));

  void _update(PartnerCreateState next, {List<String> clearErrors = const []}) {
    final errors = {...next.errors};
    for (final key in clearErrors) {
      errors.remove(key);
    }
    emit(
      next.copyWith(
        errors: errors,
        isDirty: true,
        status: PartnerCreateStatus.initial,
        clearGeneralError: true,
        clearDuplicate: true,
      ),
    );
  }

  Future<void> submit() async {
    if (state.isReadOnly || state.isSubmitting) return;
    final errors = _validateAll();
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          errors: errors,
          activeSection: _firstErrorSection(errors),
          status: PartnerCreateStatus.failure,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: PartnerCreateStatus.submitting,
        errors: const {},
        clearGeneralError: true,
        clearDuplicate: true,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final matches = await _partnerModule.executeQueryAsync(
        CheckDuplicatePartnersQuery(
          tenantId: tenantId,
          phone: _nullable(_normalizePhone(state.phone)),
          email: _nullable(state.email.trim()),
          taxCode: _nullable(_digitsOnly(state.taxCode)),
          name: _nullable(_displayName),
        ),
      );
      if (matches.isNotEmpty) {
        final level =
            matches.any(
              (match) => match.matchLevel == PartnerDuplicateMatchLevel.exact,
            )
            ? PartnerDuplicateMatchLevel.exact
            : PartnerDuplicateMatchLevel.possible;
        emit(
          state.copyWith(
            status: PartnerCreateStatus.duplicate,
            duplicateMatches: matches,
            duplicateLevel: level,
          ),
        );
        return;
      }
      await _create(confirmDuplicate: false);
    } catch (error) {
      _mapFailure(error);
    }
  }

  Future<void> confirmPossibleDuplicate() async {
    if (!canConfirmDuplicate) return;
    emit(state.copyWith(status: PartnerCreateStatus.submitting));
    try {
      await _create(confirmDuplicate: true);
    } catch (error) {
      _mapFailure(error);
    }
  }

  void dismissDuplicate() {
    if (state.status == PartnerCreateStatus.duplicate) {
      emit(state.copyWith(status: PartnerCreateStatus.initial, clearDuplicate: true));
    }
  }

  Future<void> _create({required bool confirmDuplicate}) async {
    final tenantId = await _executionContext.requireTenantId();
    final actorId = await _executionContext.requireUserId();
    final result = await _partnerModule.executeCommandAsync(
      CreatePartnerCommand(
        tenantId: tenantId,
        actorId: actorId,
        partnerType: state.partnerType,
        roles: state.roles,
        personProfile: state.partnerType == PartnerType.person ? _personProfile : null,
        organizationProfile: state.partnerType == PartnerType.organization
            ? _organizationProfile
            : null,
        organizationPrimaryContact:
            state.partnerType == PartnerType.organization && state.primaryContactEnabled
            ? _primaryContactProfile
            : null,
        confirmDuplicate: confirmDuplicate,
      ),
    );
    emit(
      state.copyWith(
        status: PartnerCreateStatus.success,
        createdPartnerId: result.partnerId,
        isDirty: false,
        clearDuplicate: true,
      ),
    );
  }

  PersonProfileInput get _personProfile => PersonProfileInput(
    title: _personTitle(state.personTitle),
    fullName: state.fullName.trim(),
    nickname: _nullable(state.nickname.trim()),
    phone: _normalizePhone(state.phone),
    phone2: _nullable(_normalizePhone(state.secondaryPhone)),
    email: _nullable(state.email.trim()),
    taxCode: _nullable(_digitsOnly(state.taxCode)),
    invoice: _invoiceProfile,
    delivery: _deliveryAddress,
    note: _nullable(state.note.trim()),
  );

  OrganizationProfileInput get _organizationProfile => OrganizationProfileInput(
    organizationType: state.organizationType,
    organizationName: state.organizationName.trim(),
    shortName: _nullable(state.shortName.trim()),
    intlName: _nullable(state.internationalName.trim()),
    phone: _normalizePhone(state.phone),
    email: _nullable(state.email.trim()),
    taxCode: _nullable(_digitsOnly(state.taxCode)),
    invoice: _invoiceProfile,
    delivery: _deliveryAddress,
    note: _nullable(state.note.trim()),
  );

  PersonProfileInput get _primaryContactProfile => PersonProfileInput(
    title: _personTitle(state.primaryContactTitle),
    fullName: state.primaryContactName.trim(),
    phone: _normalizePhone(state.primaryContactPhone),
    phone2: _nullable(_normalizePhone(state.primaryContactSecondaryPhone)),
    email: _nullable(state.primaryContactEmail.trim()),
  );

  InvoiceProfileInput? get _invoiceProfile {
    final name = _nullable(state.invoiceName.trim());
    final address = _nullable(state.invoiceAddress.trim());
    final email = _nullable(state.invoiceEmail.trim());
    if (name == null && address == null && email == null) return null;
    return InvoiceProfileInput(
      invoiceName: name,
      invoiceAddress: address,
      invoiceEmail: email,
    );
  }

  DeliveryAddressInput? get _deliveryAddress {
    final province = _nullable(state.deliveryProvince.trim());
    final commune = _nullable(state.deliveryCommune.trim());
    final address = _nullable(state.deliveryAddress.trim());
    if (province == null && commune == null && address == null) return null;
    return DeliveryAddressInput(
      province: province,
      commune: commune,
      address: address,
    );
  }

  Map<String, String> _validateAll() {
    final errors = <String, String>{};
    for (final section in state.sections) {
      errors.addAll(_validateSection(section));
    }
    return errors;
  }

  Map<String, String> _validateSection(PartnerCreateSection section) {
    final errors = <String, String>{};
    switch (section) {
      case PartnerCreateSection.role:
        if (state.roles.isEmpty) {
          errors['roles'] = 'Vui lòng chọn vai trò giao dịch';
        }
      case PartnerCreateSection.main:
        if (state.partnerType == PartnerType.person && state.fullName.trim().isEmpty) {
          errors['fullName'] = 'Vui lòng nhập họ và tên';
        }
        if (state.partnerType == PartnerType.organization &&
            state.organizationName.trim().isEmpty) {
          errors['organizationName'] = 'Vui lòng nhập tên tổ chức';
        }
        _validatePhone(state.phone, 'phone', errors, required: true);
        _validateEmail(state.email, 'email', errors);
        _validatePhone(state.secondaryPhone, 'secondaryPhone', errors);
      case PartnerCreateSection.primaryContact:
        if (state.primaryContactEnabled) {
          if (state.primaryContactName.trim().isEmpty) {
            errors['primaryContactName'] = 'Vui lòng nhập họ và tên người liên hệ';
          }
          _validatePhone(
            state.primaryContactPhone,
            'primaryContactPhone',
            errors,
            required: true,
          );
          _validatePhone(
            state.primaryContactSecondaryPhone,
            'primaryContactSecondaryPhone',
            errors,
          );
          _validateEmail(state.primaryContactEmail, 'primaryContactEmail', errors);
        }
      case PartnerCreateSection.invoice:
        final taxDigits = _digitsOnly(state.taxCode);
        if (state.taxCode.trim().isNotEmpty && taxDigits.length != 10 && taxDigits.length != 13) {
          errors['taxCode'] = 'MST phải có 10 hoặc 13 chữ số';
        }
        _validateEmail(state.invoiceEmail, 'invoiceEmail', errors);
      case PartnerCreateSection.delivery:
      case PartnerCreateSection.note:
        break;
    }
    return errors;
  }

  void _validatePhone(
    String value,
    String key,
    Map<String, String> errors, {
    bool required = false,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      if (required) errors[key] = 'Vui lòng nhập số điện thoại';
      return;
    }
    final allowed = RegExp(r'^\+?[0-9\s.\-()]+$').hasMatch(trimmed);
    final digits = _digitsOnly(trimmed);
    if (!allowed || digits.length < 8 || digits.length > 15) {
      errors[key] = 'Số điện thoại phải có từ 8 đến 15 chữ số';
    }
  }

  void _validateEmail(String value, String key, Map<String, String> errors) {
    final error = VEmailValidator.validate(value, isRequired: false);
    if (error != null) errors[key] = error;
  }

  PartnerCreateSection _firstErrorSection(Map<String, String> errors) {
    const keysBySection = {
      PartnerCreateSection.role: ['roles'],
      PartnerCreateSection.main: [
        'fullName',
        'organizationName',
        'phone',
        'secondaryPhone',
        'email',
      ],
      PartnerCreateSection.primaryContact: [
        'primaryContactName',
        'primaryContactPhone',
        'primaryContactSecondaryPhone',
        'primaryContactEmail',
      ],
      PartnerCreateSection.invoice: ['taxCode', 'invoiceEmail'],
      PartnerCreateSection.delivery: <String>[],
      PartnerCreateSection.note: <String>[],
    };
    for (final section in state.sections) {
      if (keysBySection[section]!.any(errors.containsKey)) return section;
    }
    return state.activeSection ?? state.sections.first;
  }

  void _mapFailure(Object error) {
    if (error is PartnerBlockedException) {
      if (error.code == PartnerBlockedCodes.noPermission) {
        emit(
          state.copyWith(
            status: PartnerCreateStatus.blocked,
            generalError: 'Bạn chưa có quyền tạo KH & NCC.',
          ),
        );
        return;
      }
      if (error.code == PartnerBlockedCodes.duplicateWarning) {
        emit(state.copyWith(status: PartnerCreateStatus.duplicate));
        return;
      }
      emit(
        state.copyWith(
          status: PartnerCreateStatus.failure,
          generalError: error.message ?? 'Không thể lưu KH & NCC.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: PartnerCreateStatus.failure,
        generalError: 'Không thể lưu dữ liệu. Vui lòng thử lại.',
      ),
    );
  }

  String get _displayName => state.partnerType == PartnerType.person
      ? state.fullName.trim()
      : state.organizationName.trim();

  static String _normalizePhone(String value) {
    final trimmed = value.trim();
    final digits = _digitsOnly(trimmed);
    return trimmed.startsWith('+') && digits.isNotEmpty ? '+$digits' : digits;
  }

  static String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
  static String? _nullable(String value) => value.isEmpty ? null : value;
  static PersonTitle? _personTitle(String value) =>
      value.trim().isEmpty ? null : PersonTitle(value.trim());
}
