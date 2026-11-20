import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
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

/// Trang Chỉnh thông tin tổ chức (TA-D-02 / S12).
class OrganizationEditProfilePage extends StatelessWidget {
  const OrganizationEditProfilePage({
    super.key,
    this.organizationRepository,
    this.cubit,
  });

  final OrganizationRepository? organizationRepository;
  final OrganizationProfileCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _EditProfileView(),
      );
    }
    assert(
      organizationRepository != null,
      'OrganizationEditProfilePage requires organizationRepository or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationProfileCubit(
        organizationRepository: organizationRepository!,
      )..load(),
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final Future<List<VnAdministrativeUnit>> _unitsFuture = VnAdministrativeUnitsLoader.load();

  String? _selectedProvinceCode;
  String? _selectedCommuneCode;
  bool _seeded = false;
  bool _seeding = false;
  String? _baselineName;
  String? _baselinePhone;
  String? _baselineEmail;
  String? _baselineAddress;
  String? _baselineProvinceCode;
  String? _baselineCommuneCode;

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    for (final controller in [
      _nameController,
      _phoneController,
      _emailController,
      _addressController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _phoneController,
      _emailController,
      _addressController,
    ]) {
      controller.removeListener(_onFieldChanged);
    }
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _seedFromState(OrganizationProfileState state) {
    if (_seeded || state.tenant == null) return;
    _seeding = true;
    final profile = OrganizationProfileUiMapper.fromTenant(state.tenant!);
    _nameController.text = profile.name;
    final rawPhone = profile.phone;
    _phoneController.text = rawPhone.startsWith('+84') ? '0${rawPhone.substring(3)}' : rawPhone;
    _emailController.text = profile.email;
    _addressController.text = profile.address;
    _selectedProvinceCode = profile.provinceCode;
    _selectedCommuneCode = profile.communeCode;
    _baselineName = profile.name;
    _baselinePhone = _phoneController.text;
    _baselineEmail = profile.email;
    _baselineAddress = profile.address;
    _baselineProvinceCode = profile.provinceCode;
    _baselineCommuneCode = profile.communeCode;
    _seeded = true;
    _seeding = false;
  }

  bool get _hasChanges {
    if (!_seeded) return false;
    return _nameController.text.trim() != _baselineName?.trim() ||
        _phoneController.text.trim() != _baselinePhone?.trim() ||
        _emailController.text.trim() != _baselineEmail?.trim() ||
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

  /// Client-side validation — chỉ chạy khi bấm "Lưu thay đổi".
  bool _validate() {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    final nameError = name.isEmpty ? 'Vui lòng nhập tên tổ chức' : null;
    final phoneError = VPhoneValidator.validate(
      _phoneController.text,
      isRequired: true,
    );
    final emailError = VEmailValidator.validate(
      _emailController.text,
      isRequired: true,
      requiredEmailMessage: 'Vui lòng nhập email liên hệ',
    );
    final addressError = address.isEmpty ? 'Vui lòng nhập địa chỉ liên hệ' : null;

    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _emailError = emailError;
      _addressError = addressError;
    });

    return nameError == null && phoneError == null && emailError == null && addressError == null;
  }

  Future<void> _save(BuildContext context) async {
    if (!_validate()) return;
    final cubit = context.read<OrganizationProfileCubit>();
    final ok = await cubit.updateProfile(
      TenantProfileFormInput(
        displayName: _nameController.text,
        contactEmail: _emailController.text,
        contactPhone: _phoneController.text,
        contactAddressText: _addressController.text,
        provinceCode: _selectedProvinceCode,
        communeCode: _selectedCommuneCode,
      ),
    );
    if (!context.mounted) return;
    final state = cubit.state;
    if (state.failure != null) {
      VToast.show(
        context,
        title: state.failure!.requiresReload ? 'Dữ liệu đã thay đổi' : 'Không lưu được',
        message: state.failure!.message,
        type: state.failure!.requiresReload ? VToastType.warning : VToastType.danger,
      );
      cubit.clearFeedback();
      // Keep user in form after STATE_CHANGED / validation.
      return;
    }
    if (!ok) return;
    VToast.show(
      context,
      title: state.successMessage ?? 'Đã lưu thay đổi',
      message: 'Thông tin tổ chức đã được cập nhật thành công.',
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

        if (state.status == IamLoadStatus.loading || state.status == IamLoadStatus.initial) {
          return const VPageScaffold(
            title: 'Chỉnh thông tin tổ chức',
            body: Center(child: VLoading(size: 40)),
          );
        }

        if (state.status == IamLoadStatus.failure && state.tenant == null) {
          if (state.failure?.code == IamBlockedCodes.permissionDenied) {
            return VPageScaffold(
              title: 'Chỉnh thông tin tổ chức',
              body: OrganizationEmptyView(
                type: OrganizationEmptyStateType.unauthorized,
                onAction: () => Navigator.of(context).pop(),
              ),
            );
          }
        }

        final colors = context.vColors;
        return PopScope(
          canPop: !_hasChanges || state.isSubmittingProfile,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _hasChanges) _confirmDiscard();
          },
          child: VPageScaffold(
            title: 'Chỉnh thông tin tổ chức',
            bottomBar: Padding(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              child: Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Hủy',
                      variant: VButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: state.isSubmittingProfile
                          ? null
                          : () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const VGap.horizontalSm(),
                  Expanded(
                    child: VButton(
                      label: 'Lưu thay đổi',
                      variant: VButtonVariant.primary,
                      tone: VComponentTone.success,
                      fullWidth: true,
                      isLoading: state.isSubmittingProfile,
                      onPressed: state.isSubmittingProfile ? null : () => _save(context),
                    ),
                  ),
                ],
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              children: [
                VText(
                  'Thông tin liên hệ này độc lập với hồ sơ pháp lý và chứng từ đã phát hành.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.md(),
                VField(
                  invalid: _nameError != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Tên tổ chức', isRequired: true),
                      VTextField(
                        controller: _nameController,
                        onChanged: (_) {
                          if (_nameError != null) setState(() => _nameError = null);
                        },
                      ),
                      if (_nameError != null)
                        VFieldError(_nameError!)
                      else
                        const VFieldDescription('Tên hiển thị.'),
                    ],
                  ),
                ),
                const VGap.md(),
                VField(
                  invalid: _phoneError != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Số điện thoại', isRequired: true),
                      VPhoneField(
                        isRequired: true,
                        controller: _phoneController,
                        validateOnChanged: false,
                        onChanged: (_) {
                          if (_phoneError != null) setState(() => _phoneError = null);
                        },
                      ),
                      if (_phoneError != null) VFieldError(_phoneError!),
                    ],
                  ),
                ),
                const VGap.md(),
                VField(
                  invalid: _emailError != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Email liên hệ', isRequired: true),
                      VEmailField(
                        controller: _emailController,
                        validateOnChanged: false,
                        onChanged: (_) {
                          if (_emailError != null) setState(() => _emailError = null);
                        },
                      ),
                      if (_emailError != null) VFieldError(_emailError!),
                    ],
                  ),
                ),
                const VGap.md(),
                VField(
                  invalid: _addressError != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Địa chỉ liên hệ', isRequired: true),
                      VTextField(
                        controller: _addressController,
                        onChanged: (_) {
                          if (_addressError != null) setState(() => _addressError = null);
                        },
                      ),
                      if (_addressError != null) VFieldError(_addressError!),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
