import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/validation/tax_code_input_formatter.dart';
import 'package:erp/core/validation/tax_code.dart';
import 'package:erp/features/iam/data/models/tenant_profile.dart';
import 'package:erp/features/iam/data/organization_repository.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../organizations/widgets/organization_empty_view.dart';
import '../../shared/iam_load_status.dart';
import '../../../logic/organization_profile_cubit.dart';
import '../../../logic/organization_profile_form_input.dart';
import '../../../logic/organization_profile_state.dart';
import '../data/vn_administrative_units_loader.dart';
import '../mappers/organization_profile_ui_mapper.dart';
import '../widgets/administrative_units_form_section.dart';
import '../widgets/tax_code_duplicate_warning_bottom_sheet.dart';

/// Trang Thêm / Chỉnh sửa hồ sơ pháp lý (TA-D-03 & TA-D-04 / S12).
class OrganizationLegalProfileFormPage extends StatelessWidget {
  const OrganizationLegalProfileFormPage({
    super.key,
    this.organizationRepository,
    this.cubit,
    this.isEdit,
  });

  final OrganizationRepository? organizationRepository;
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
      organizationRepository != null,
      'OrganizationLegalProfileFormPage requires organizationRepository or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationProfileCubit(
        organizationRepository: organizationRepository!,
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
  late final Future<List<VnAdministrativeUnit>> _unitsFuture = VnAdministrativeUnitsLoader.load();

  String? _selectedEntityType;
  String? _selectedProvinceCode;
  String? _selectedCommuneCode;
  bool _seeded = false;
  bool _seeding = false;
  bool _showingDuplicateSheet = false;
  String? _baselineEntityType;
  String? _baselineLegalName;
  String? _baselineTaxCode;
  String? _baselineAddress;
  String? _baselineProvinceCode;
  String? _baselineCommuneCode;

  String? _entityTypeError;
  String? _legalNameError;
  String? _taxCodeError;

  @override
  void initState() {
    super.initState();
    _legalNameController = TextEditingController();
    _taxCodeController = TextEditingController();
    _addressController = TextEditingController();
    for (final controller in [
      _legalNameController,
      _taxCodeController,
      _addressController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _legalNameController,
      _taxCodeController,
      _addressController,
    ]) {
      controller.removeListener(_onFieldChanged);
    }
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
    _seeding = true;
    final legal = state.tenant!.legalProfile;
    if (legal != null) {
      final ui = OrganizationProfileUiMapper.fromLegal(legal);
      _selectedEntityType = ui.entityType;
      _legalNameController.text = ui.legalName;
      _taxCodeController.text = ui.taxCode;
      _addressController.text = ui.registeredAddress;
      _selectedProvinceCode = ui.provinceCode;
      _selectedCommuneCode = ui.communeCode;
      _baselineEntityType = ui.entityType;
      _baselineLegalName = ui.legalName;
      _baselineTaxCode = ui.taxCode;
      _baselineAddress = ui.registeredAddress;
      _baselineProvinceCode = ui.provinceCode;
      _baselineCommuneCode = ui.communeCode;
    }
    _seeded = true;
    _seeding = false;
  }

  bool get _hasChanges {
    if (!_seeded) return false;
    return _selectedEntityType != _baselineEntityType ||
        _legalNameController.text.trim() != _baselineLegalName?.trim() ||
        _taxCodeController.text.trim() != _baselineTaxCode?.trim() ||
        _addressController.text.trim() != _baselineAddress?.trim() ||
        _selectedProvinceCode != _baselineProvinceCode ||
        _selectedCommuneCode != _baselineCommuneCode;
  }

  void _onFieldChanged() {
    if (mounted && !_seeding) setState(() {});
  }

  void _confirmDiscard() {
    showVConfirmDialog(
      context: context,
      title: 'Bỏ thay đổi?',
      message: 'Các thay đổi chưa lưu sẽ bị mất.',
      cancelLabel: 'Tiếp tục sửa',
      actionLabel: 'Bỏ thay đổi',
      isDestructive: true,
      onAction: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
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
      if (!isValidTaxCode(tax)) {
        _taxCodeError = taxCodeFormatMessage;
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
      await showVAdaptiveSheet<void>(
        context: context,
        child: Builder(
          builder: (sheetContext) => TaxCodeDuplicateWarningBottomSheet(
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
                Navigator.of(sheetContext).pop(true);
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
        ),
      );
      _showingDuplicateSheet = false;
      return;
    }

    if (state.failure != null) {
      VToast.show(
        context,
        title: state.failure!.requiresReload ? 'Dữ liệu đã thay đổi' : 'Không lưu được',
        message: state.failure!.message,
        type: state.failure!.requiresReload ? VToastType.warning : VToastType.danger,
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

        if (state.status == IamLoadStatus.loading || state.status == IamLoadStatus.initial) {
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
        return PopScope(
          canPop: !_hasChanges || state.isSubmittingLegal,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _hasChanges) _confirmDiscard();
          },
          child: VPageScaffold(
            title: title,
            bottomBar: Padding(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              child: Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Hủy',
                      variant: VButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: state.isSubmittingLegal
                          ? null
                          : () => Navigator.of(context).maybePop(),
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
                      onPressed: state.isSubmittingLegal ? null : () => _save(context),
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
                VField(
                  invalid: _entityTypeError != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Loại chủ thể'),
                      VSelect<String>(
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
                      if (_entityTypeError != null) VFieldError(_entityTypeError!),
                    ],
                  ),
                ),
                const VGap.md(),
                VField(
                  invalid: _legalNameError != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Tên pháp lý', isRequired: true),
                      VTextField(
                        hintText: 'Nhập tên pháp lý',
                        controller: _legalNameController,
                        tone: _legalNameError != null
                            ? VComponentTone.danger
                            : VComponentTone.neutral,
                      ),
                      if (_legalNameError != null) VFieldError(_legalNameError!),
                    ],
                  ),
                ),
                const VGap.md(),
                VField(
                  invalid: _taxCodeError != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Mã số thuế', isRequired: true),
                      VTextField(
                        hintText: 'Nhập mã số thuế',
                        controller: _taxCodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [TaxCodeInputFormatter()],
                        tone: _taxCodeError != null
                            ? VComponentTone.danger
                            : VComponentTone.neutral,
                      ),
                      if (_taxCodeError != null)
                        VFieldError(_taxCodeError!)
                      else
                        const VFieldDescription(
                          '10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm.',
                        ),
                    ],
                  ),
                ),
                const VGap.md(),
                VField(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Địa chỉ đăng ký'),
                      VTextField(
                        hintText: 'Nhập địa chỉ đăng ký',
                        controller: _addressController,
                      ),
                    ],
                  ),
                ),
                const VGap.md(),
                AdministrativeUnitsFormSection(
                  unitsFuture: _unitsFuture,
                  selectedProvinceCode: _selectedProvinceCode,
                  selectedCommuneCode: _selectedCommuneCode,
                  onProvinceChanged: (code) {
                    setState(() {
                      _selectedProvinceCode = code;
                      _selectedCommuneCode = null;
                    });
                  },
                  onCommuneChanged: (code) {
                    setState(() => _selectedCommuneCode = code);
                  },
                ),
                const VGap.md(),
              ],
            ),
          ),
        );
      },
    );
  }
}
