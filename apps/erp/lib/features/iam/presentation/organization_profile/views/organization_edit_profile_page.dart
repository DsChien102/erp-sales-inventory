import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../organizations/widgets/organization_empty_view.dart';
import '../../shared/iam_load_status.dart';
import '../bloc/organization_profile_cubit.dart';
import '../bloc/organization_profile_form_input.dart';
import '../bloc/organization_profile_state.dart';
import '../data/vn_administrative_units_loader.dart';
import '../mappers/organization_profile_ui_mapper.dart';

/// Trang Chỉnh thông tin tổ chức (TA-D-02 / S12).
class OrganizationEditProfilePage extends StatelessWidget {
  const OrganizationEditProfilePage({
    super.key,
    this.iamModule,
    this.executionContext,
    this.cubit,
  });

  final IIamModule? iamModule;
  final IExecutionContext? executionContext;
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
      iamModule != null && executionContext != null,
      'OrganizationEditProfilePage requires iamModule + executionContext or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationProfileCubit(
        iamModule: iamModule!,
        executionContext: executionContext!,
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _seedFromState(OrganizationProfileState state) {
    if (_seeded || state.tenant == null) return;
    final profile = OrganizationProfileUiMapper.fromTenant(state.tenant!);
    _nameController.text = profile.name;
    _phoneController.text = profile.phone;
    _emailController.text = profile.email;
    _addressController.text = profile.address;
    _selectedProvinceCode = profile.provinceCode;
    _selectedCommuneCode = profile.communeCode;
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
        return VPageScaffold(
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
                    onPressed: state.isSubmittingProfile ? null : () => Navigator.of(context).pop(),
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
              FutureBuilder<List<VnAdministrativeUnit>>(
                future: _unitsFuture,
                builder: (context, snapshot) {
                  final units = snapshot.data ?? const [];
                  final selectedProvince =
                      _findProvinceByCode(units, _selectedProvinceCode);
                  final wardList = selectedProvince?.wards ?? const <VnWard>[];
                  VnWard? selectedWard;
                  for (final ward in wardList) {
                    if (ward.code == _selectedCommuneCode) {
                      selectedWard = ward;
                      break;
                    }
                  }

                  return Column(
                    children: [
                      _SearchDropdownField(
                        label: 'Tỉnh / thành phố',
                        child: VCombobox<String>(
                          value: selectedProvince?.code,
                          displayTextForValue: (code) {
                            if (code == null) return '';
                            return _findProvinceByCode(units, code)?.fullName ??
                                '';
                          },
                          onChanged: (code) {
                            setState(() {
                              _selectedProvinceCode = code;
                              _selectedCommuneCode = null;
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VComboboxContent(
                                child: VComboboxList(
                                  children: [
                                    for (final unit in units)
                                      VComboboxItem<String>(
                                        value: unit.code,
                                        searchText: unit.fullName,
                                        child: Text(unit.fullName),
                                      ),
                                  ],
                                ),
                              ),
                              const VComboboxInput(
                                hintText: 'Chọn tỉnh / thành phố',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const VGap.md(),
                      _SearchDropdownField(
                        label: 'Xã / phường',
                        child: VCombobox<String>(
                          value: selectedWard?.code,
                          displayTextForValue: (code) {
                            if (code == null) return '';
                            for (final ward in wardList) {
                              if (ward.code == code) return ward.fullName;
                            }
                            return '';
                          },
                          onChanged: (code) {
                            setState(() => _selectedCommuneCode = code);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VComboboxContent(
                                child: VComboboxList(
                                  children: [
                                    for (final ward in wardList)
                                      VComboboxItem<String>(
                                        value: ward.code,
                                        searchText: ward.fullName,
                                        child: Text(ward.fullName),
                                      ),
                                  ],
                                ),
                              ),
                              const VComboboxInput(hintText: 'Chọn xã / phường'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
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
