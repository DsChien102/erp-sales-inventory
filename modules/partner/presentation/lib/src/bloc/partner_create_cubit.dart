import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_create_draft_mapper.dart';
import 'partner_create_form_validator.dart';
import 'partner_create_state.dart';

final class PartnerCreateCubit extends Cubit<PartnerCreateState> {
  PartnerCreateCubit({
    required PartnerType partnerType,
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  }) : _partnerModule = partnerModule,
       _executionContext = executionContext,
       super(PartnerCreateState(partnerType: partnerType));

  /// Edit mode — call [loadForEdit] after construction.
  PartnerCreateCubit.edit({
    required String partnerId,
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  }) : _partnerModule = partnerModule,
       _executionContext = executionContext,
       super(
         PartnerCreateState(
           partnerType: PartnerType.person,
           mode: PartnerFormMode.edit,
           partnerId: partnerId,
           status: PartnerCreateStatus.loading,
           activeSection: null,
         ),
       );

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  bool get canConfirmDuplicate =>
      state.status == PartnerCreateStatus.duplicate &&
      state.duplicateLevel == PartnerDuplicateMatchLevel.possible;

  Future<void> loadForEdit() async {
    final partnerId = state.partnerId;
    if (!state.isEditMode || partnerId == null) return;

    emit(state.copyWith(status: PartnerCreateStatus.loading, clearGeneralError: true));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final detail = await _partnerModule.executeQueryAsync(
        GetPartnerDetailQuery(tenantId: tenantId, partnerId: partnerId),
      );
      emit(_hydrateFromDetail(detail));
    } catch (error) {
      _mapFailure(error);
    }
  }

  PartnerCreateState _hydrateFromDetail(PartnerDetailDto detail) {
    final person = detail.personProfile;
    final org = detail.organizationProfile;
    final invoice = person?.invoice ?? org?.invoice;
    final delivery = person?.delivery ?? org?.delivery;

    return PartnerCreateState(
      partnerType: detail.partnerType,
      mode: PartnerFormMode.edit,
      partnerId: detail.partnerId,
      expectedVersion: detail.expectedVersion,
      roles: List.unmodifiable(detail.roles),
      activeSection: PartnerCreateSection.role,
      completedSections: const {},
      isDirty: false,
      status: PartnerCreateStatus.initial,
      personTitle: person?.title?.value ?? '',
      fullName: person?.fullName ?? '',
      nickname: person?.nickname ?? '',
      phone: person?.phone ?? org?.phone ?? '',
      secondaryPhone: person?.phone2 ?? '',
      email: person?.email ?? org?.email ?? '',
      organizationTypeLabel: org == null
          ? ''
          : PartnerCreateDraftMapper.organizationTypeLabel(org.organizationType),
      organizationName: org?.organizationName ?? '',
      shortName: org?.shortName ?? '',
      internationalName: org?.intlName ?? '',
      taxCode: person?.taxCode ?? org?.taxCode ?? '',
      invoiceName: invoice?.invoiceName ?? '',
      invoiceAddress: invoice?.invoiceAddress ?? '',
      invoiceEmail: invoice?.invoiceEmail ?? '',
      deliveryProvince: delivery?.province ?? '',
      deliveryCommune: delivery?.commune ?? '',
      deliveryAddress: delivery?.address ?? '',
      note: person?.note ?? org?.note ?? '',
    );
  }

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
    final errors = PartnerCreateFormValidator.validateSection(state, section);
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
  void updateOrganizationType(String value) =>
      _update(state.copyWith(organizationTypeLabel: value));
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
  void updateDeliveryProvince(String value) => _update(
    state.copyWith(deliveryProvince: value, deliveryCommune: ''),
  );
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
    if (state.isReadOnly || state.isSubmitting || state.isLoading) return;
    final errors = PartnerCreateFormValidator.validateAll(state);
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          errors: errors,
          activeSection: PartnerCreateFormValidator.firstErrorSection(
            state,
            errors,
          ),
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
      final matches = <PartnerDuplicateMatchDto>[
        ...await _partnerModule.executeQueryAsync(
          CheckDuplicatePartnersQuery(
            tenantId: tenantId,
            phone: PartnerCreateDraftMapper.nullable(
              PartnerCreateDraftMapper.normalizePhone(state.phone),
            ),
            email: PartnerCreateDraftMapper.nullable(state.email.trim()),
            taxCode: PartnerCreateDraftMapper.nullable(
              PartnerCreateFormValidator.digitsOnly(state.taxCode),
            ),
            name: PartnerCreateDraftMapper.nullable(
              PartnerCreateDraftMapper.displayName(state),
            ),
            excludePartnerId: state.isEditMode ? state.partnerId : null,
          ),
        ),
      ];
      if (!state.isEditMode &&
          state.partnerType == PartnerType.organization &&
          state.primaryContactEnabled) {
        matches.addAll(
          await _partnerModule.executeQueryAsync(
            CheckDuplicatePartnersQuery(
              tenantId: tenantId,
              phone: PartnerCreateDraftMapper.nullable(
                PartnerCreateDraftMapper.normalizePhone(
                  state.primaryContactPhone,
                ),
              ),
              email: PartnerCreateDraftMapper.nullable(
                state.primaryContactEmail.trim(),
              ),
            ),
          ),
        );
      }
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
      await _persist(confirmDuplicate: false);
    } catch (error) {
      _mapFailure(error);
    }
  }

  Future<void> confirmPossibleDuplicate() async {
    if (!canConfirmDuplicate) return;
    emit(state.copyWith(status: PartnerCreateStatus.submitting));
    try {
      await _persist(confirmDuplicate: true);
    } catch (error) {
      _mapFailure(error);
    }
  }

  void dismissDuplicate() {
    if (state.status == PartnerCreateStatus.duplicate) {
      emit(state.copyWith(status: PartnerCreateStatus.initial, clearDuplicate: true));
    }
  }

  Future<void> _persist({required bool confirmDuplicate}) async {
    if (state.isEditMode) {
      await _updateProfile(confirmDuplicate: confirmDuplicate);
    } else {
      await _create(confirmDuplicate: confirmDuplicate);
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
        personProfile: state.partnerType == PartnerType.person
            ? PartnerCreateDraftMapper.personProfile(state)
            : null,
        organizationProfile: state.partnerType == PartnerType.organization
            ? PartnerCreateDraftMapper.organizationProfile(state)
            : null,
        organizationPrimaryContact:
            state.partnerType == PartnerType.organization && state.primaryContactEnabled
            ? PartnerCreateDraftMapper.primaryContactProfile(state)
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

  Future<void> _updateProfile({required bool confirmDuplicate}) async {
    final partnerId = state.partnerId;
    final expectedVersion = state.expectedVersion;
    if (partnerId == null || expectedVersion == null) {
      emit(
        state.copyWith(
          status: PartnerCreateStatus.failure,
          generalError: 'Không tải được hồ sơ để chỉnh sửa.',
        ),
      );
      return;
    }

    final tenantId = await _executionContext.requireTenantId();
    final actorId = await _executionContext.requireUserId();
    final result = await _partnerModule.executeCommandAsync(
      UpdatePartnerProfileCommand(
        tenantId: tenantId,
        actorId: actorId,
        partnerId: partnerId,
        roles: state.roles,
        expectedVersion: expectedVersion,
        personProfile: state.partnerType == PartnerType.person
            ? PartnerCreateDraftMapper.personProfile(state)
            : null,
        organizationProfile: state.partnerType == PartnerType.organization
            ? PartnerCreateDraftMapper.organizationProfile(state)
            : null,
        confirmDuplicate: confirmDuplicate,
      ),
    );
    emit(
      state.copyWith(
        status: PartnerCreateStatus.success,
        createdPartnerId: result.partnerId,
        expectedVersion: result.expectedVersion,
        isDirty: false,
        clearDuplicate: true,
      ),
    );
  }

  void _mapFailure(Object error) {
    if (error is PartnerBlockedException) {
      if (error.code == PartnerBlockedCodes.noPermission) {
        emit(
          state.copyWith(
            status: PartnerCreateStatus.blocked,
            generalError: state.isEditMode
                ? 'Bạn chưa có quyền chỉnh sửa KH & NCC.'
                : 'Bạn chưa có quyền tạo KH & NCC.',
          ),
        );
        return;
      }
      if (error.code == PartnerBlockedCodes.duplicateWarning) {
        emit(
          state.copyWith(
            status: PartnerCreateStatus.failure,
            generalError: 'Đã tồn tại hồ sơ trùng MST/SĐT/email. Vui lòng kiểm tra lại.',
          ),
        );
        return;
      }
      if (error.code == PartnerBlockedCodes.stateChanged) {
        emit(
          state.copyWith(
            status: PartnerCreateStatus.failure,
            generalError: 'Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại rồi thử lại.',
          ),
        );
        return;
      }
      if (error.code == PartnerBlockedCodes.notFound) {
        emit(
          state.copyWith(
            status: PartnerCreateStatus.failure,
            generalError: 'Không tìm thấy hồ sơ hoặc bạn không có quyền xem.',
          ),
        );
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
}
