import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../organizations/widgets/organization_empty_view.dart';
import '../../shared/iam_load_status.dart';
import '../bloc/organization_profile_cubit.dart';
import '../bloc/organization_profile_form_input.dart';
import '../bloc/organization_profile_state.dart';
import '../data/vn_administrative_units_loader.dart';
import '../mappers/organization_profile_ui_mapper.dart';
import '../widgets/tax_code_duplicate_warning_bottom_sheet.dart';

/// Trang Thêm / Chỉnh sửa hồ sơ pháp lý (TA-D-03 & TA-D-04 / S12).
class OrganizationLegalProfileFormPage extends StatelessWidget {
  const OrganizationLegalProfileFormPage({
    super.key,
    this.iamModule,
    this.executionContext,
    this.cubit,
    this.isEdit,
  });

  final IIamModule? iamModule;
  final IExecutionContext? executionContext;
  final OrganizationProfileCubit? cubit;
  final bool? isEdit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _LegalProfileFormView(isEditOverride: isEdit),
      );
    }
    assert(
      iamModule != null && executionContext != null,
      'OrganizationLegalProfileFormPage requires iamModule + '
      'executionContext or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationProfileCubit(
        iamModule: iamModule!,
        executionContext: executionContext!,
      )..load(),
      child: _LegalProfileFormView(isEditOverride: isEdit),
    );
  }
}

class _LegalProfileFormView extends StatefulWidget {
  const _LegalProfileFormView({this.isEditOverride});

  final bool? isEditOverride;

  @override
  State<_LegalProfileFormView> createState() => _LegalProfileFormViewState();
}

class _LegalProfileFormViewState extends State<_LegalProfileFormView> {
  late final TextEditingController _legalNameController;
  late final TextEditingController _taxCodeController;
  late final TextEditingController _addressController;
  late final Future<List<VnAdministrativeUnit>> _unitsFuture =
      VnAdministrativeUnitsLoader.load();

  String? _selectedEntityType;
  String? _selectedProvinceCode;
  String? _selectedCommuneCode;
  bool _seeded = false;
  bool _showingDuplicateSheet = false;

  String? _entityTypeError;
  String? _legalNameError;
  String? _taxCodeError;

  @override
  void initState() {
    super.initState();
    _legalNameController = TextEditingController();
    _taxCodeController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _taxCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _isEdit(OrganizationProfileState state) {
    return widget.isEditOverride ?? state.hasLegalProfile;
  }

  void _seedFromState(OrganizationProfileState state) {
    if (_seeded || state.tenant == null) return;
    final legal = state.tenant!.legalProfile;
    if (legal != null) {
      final ui = OrganizationProfileUiMapper.fromLegal(legal);
      _selectedEntityType = ui.entityType;
      _legalNameController.text = ui.legalName;
      _taxCodeController.text = ui.taxCode;
      _addressController.text = ui.registeredAddress;
      _selectedProvinceCode = ui.provinceCode;
      _selectedCommuneCode = ui.communeCode;
    }
    _seeded = true;
  }

  VnAdministrativeUnit? _findProvinceByCode(
    List<VnAdministrativeUnit> units,
    String? code,
  ) {
    if (code == null || code.isEmpty) return null;
    for (final unit in units) {
      if (unit.code == code) return unit;
    }
    return null;
  }

  bool _validateLocal() {
    var ok = true;
    if (_selectedEntityType == null || _selectedEntityType!.isEmpty) {
      _entityTypeError = 'Vui lòng chọn loại chủ thể';
      ok = false;
    } else {
      _entityTypeError = null;
    }
    if (_legalNameController.text.trim().isEmpty) {
      _legalNameError = 'Vui lòng nhập tên pháp lý';
      ok = false;
    } else {
      _legalNameError = null;
    }
    final tax = _taxCodeController.text.trim();
    final type = LegalEntityTypeCodes.fromCode(_selectedEntityType);
    if (tax.isEmpty) {
      _taxCodeError = 'Vui lòng nhập mã số thuế';
      ok = false;
    } else if (type != null) {
      final expected = switch (type) {
        LegalEntityType.enterprise => 10,
        LegalEntityType.householdBusiness => 12,
      };
      if (tax.length != expected || !RegExp(r'^\d+$').hasMatch(tax)) {
        _taxCodeError = type == LegalEntityType.enterprise
            ? 'Mã số thuế doanh nghiệp phải đúng 10 chữ số.'
            : 'Mã số thuế hộ kinh doanh phải đúng 12 chữ số.';
        ok = false;
      } else {
        _taxCodeError = null;
      }
    } else {
      _taxCodeError = null;
    }
    setState(() {});
    return ok;
  }

  Future<void> _save(BuildContext context) async {
    if (!_validateLocal()) {
      VToast.show(
        context,
        title: 'Thiếu thông tin',
        message: 'Vui lòng điền đầy đủ các thông tin bắt buộc',
        type: VToastType.danger,
      );
      return;
    }

    final cubit = context.read<OrganizationProfileCubit>();
    final input = LegalProfileFormInput(
      legalEntityType: _selectedEntityType!,
      legalName: _legalNameController.text,
      taxCode: _taxCodeController.text,
      registeredAddressText: _addressController.text,
      provinceCode: _selectedProvinceCode,
      communeCode: _selectedCommuneCode,
    );
    final ok = await cubit.upsertLegal(input, allowDuplicateTaxCode: false);
    if (!context.mounted) return;
    await _handleUpsertResult(context, cubit, ok);
  }

  Future<void> _handleUpsertResult(
    BuildContext context,
    OrganizationProfileCubit cubit,
    bool ok,
  ) async {
    final state = cubit.state;
    if (state.duplicateWarning != null && !_showingDuplicateSheet) {
      _showingDuplicateSheet = true;
      await showVBottomSheet<void>(
        context: context,
        child: TaxCodeDuplicateWarningBottomSheet(
          message: state.duplicateWarning!.message,
          onSaveAnyway: () async {
            final confirmed = await cubit.confirmDuplicateLegal();
            if (!context.mounted) return;
            _showingDuplicateSheet = false;
            if (confirmed) {
              VToast.show(
                context,
                title: cubit.state.successMessage ?? 'Đã lưu hồ sơ pháp lý.',
                message: '',
                type: VToastType.success,
              );
              cubit.clearFeedback();
              Navigator.of(context).pop(true);
            } else if (cubit.state.failure != null) {
              VToast.show(
                context,
                title: 'Không lưu được',
                message: cubit.state.failure!.message,
                type: VToastType.danger,
              );
              cubit.clearFeedback();
            }
          },
          onReview: () {
            _showingDuplicateSheet = false;
            cubit.dismissDuplicateWarning();
          },
        ),
      );
      _showingDuplicateSheet = false;
      return;
    }

    if (state.failure != null) {
      VToast.show(
        context,
        title: state.failure!.requiresReload
            ? 'Dữ liệu đã thay đổi'
            : 'Không lưu được',
        message: state.failure!.message,
        type: state.failure!.requiresReload
            ? VToastType.warning
            : VToastType.danger,
      );
      cubit.clearFeedback();
      return;
    }

    if (!ok) return;
    VToast.show(
      context,
      title: state.successMessage ?? 'Đã lưu hồ sơ pháp lý.',
      message: '',
      type: VToastType.success,
    );
    cubit.clearFeedback();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizationProfileCubit, OrganizationProfileState>(
      listenWhen: (p, c) => p.tenant != c.tenant && !_seeded,
      listener: (context, state) => _seedFromState(state),
      builder: (context, state) {
        _seedFromState(state);
        final isEdit = _isEdit(state);
        final title = isEdit ? 'Chỉnh hồ sơ pháp lý' : 'Thêm hồ sơ pháp lý';

        if (state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial) {
          return VPageScaffold(
            title: title,
            body: const Center(child: VLoading(size: 40)),
          );
        }

        if (state.status == IamLoadStatus.failure && state.tenant == null) {
          if (state.failure?.code == IamBlockedCodes.permissionDenied) {
            return VPageScaffold(
              title: title,
              body: OrganizationEmptyView(
                type: OrganizationEmptyStateType.unauthorized,
                onAction: () => Navigator.of(context).pop(),
              ),
            );
          }
        }

        final colors = context.vColors;
        return VPageScaffold(
          title: title,
          bottomBar: Padding(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            child: Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Hủy',
                    variant: VButtonVariant.outline,
                    fullWidth: true,
                    onPressed: state.isSubmittingLegal
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: VButton(
                    label: 'Lưu hồ sơ',
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.success,
                    fullWidth: true,
                    isLoading: state.isSubmittingLegal,
                    onPressed:
                        state.isSubmittingLegal ? null : () => _save(context),
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            children: [
              VText(
                'Thay đổi hiện tại không làm thay đổi chứng từ lịch sử.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
              const VGap.md(),
              VDropdown<String>(
                label: 'Loại chủ thể',
                hintText: 'Chọn loại chủ thể',
                value: _selectedEntityType,
                tone: _entityTypeError != null
                    ? VComponentTone.danger
                    : VComponentTone.neutral,
                items: const [
                  DropdownMenuItem(
                    value: 'ENTERPRISE',
                    child: VText('Doanh nghiệp'),
                  ),
                  DropdownMenuItem(
                    value: 'HOUSEHOLD_BUSINESS',
                    child: VText('Hộ kinh doanh'),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedEntityType = val;
                    _entityTypeError = null;
                  });
                },
              ),
              if (_entityTypeError != null) ...[
                const VGap.xs(),
                VText(
                  _entityTypeError!,
                  variant: VTextVariant.bodySmall,
                  color: colors.danger,
                ),
              ],
              const VGap.md(),
              VTextField(
                label: 'Tên pháp lý',
                isRequired: true,
                hintText: 'Nhập tên pháp lý',
                controller: _legalNameController,
                errorText: _legalNameError,
                tone: _legalNameError != null
                    ? VComponentTone.danger
                    : VComponentTone.neutral,
              ),
              const VGap.md(),
              VTextField(
                label: 'Mã số thuế',
                isRequired: true,
                hintText: 'Nhập mã số thuế',
                controller: _taxCodeController,
                keyboardType: TextInputType.number,
                errorText: _taxCodeError,
                tone: _taxCodeError != null
                    ? VComponentTone.danger
                    : VComponentTone.neutral,
              ),
              const VGap.md(),
              VTextField(
                label: 'Địa chỉ đăng ký',
                hintText: 'Nhập địa chỉ đăng ký',
                controller: _addressController,
              ),
              const VGap.md(),
              FutureBuilder<List<VnAdministrativeUnit>>(
                future: _unitsFuture,
                builder: (context, snapshot) {
                  final units = snapshot.data ?? const [];
                  final selectedProvince =
                      _findProvinceByCode(units, _selectedProvinceCode);
                  final provinceItems = units
                      .map(
                        (u) => DropdownMenuEntry<String>(
                          value: u.code,
                          label: u.fullName,
                        ),
                      )
                      .toList(growable: false);
                  final wardList =
                      selectedProvince?.wards ?? const <VnWard>[];
                  final wardItems = wardList
                      .map(
                        (w) => DropdownMenuEntry<String>(
                          value: w.code,
                          label: w.fullName,
                        ),
                      )
                      .toList(growable: false);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SearchDropdownField(
                        label: 'Tỉnh / thành phố',
                        child: VCombobox<String>(
                          value: selectedProvince?.code,
                          hintText: 'Chọn tỉnh / thành phố',
                          items: provinceItems,
                          onChanged: (code) {
                            setState(() {
                              _selectedProvinceCode = code;
                              _selectedCommuneCode = null;
                            });
                          },
                        ),
                      ),
                      const VGap.md(),
                      _SearchDropdownField(
                        label: 'Xã / phường',
                        child: VCombobox<String>(
                          value: wardItems.any((i) => i.value == _selectedCommuneCode)
                              ? _selectedCommuneCode
                              : null,
                          hintText: _selectedProvinceCode != null
                              ? 'Chọn xã / phường'
                              : 'Chọn tỉnh / thành phố trước',
                          enabled: _selectedProvinceCode != null,
                          items: wardItems,
                          onChanged: (code) {
                            setState(() => _selectedCommuneCode = code);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const VGap.md(),
            ],
          ),
        );
      },
    );
  }
}

class _SearchDropdownField extends StatelessWidget {
  const _SearchDropdownField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText(
          label,
          variant: VTextVariant.bodySmall,
          color: context.vColors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.sm(),
        child,
      ],
    );
  }
}
