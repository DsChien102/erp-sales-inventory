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
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    final nameError = name.isEmpty ? 'Vui lòng nhập tên tổ chức' : null;
    String? phoneError;
    // Đếm theo chữ số để chấp nhận cả định dạng nội địa (0xxx) lẫn quốc tế (+84xxx).
    final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      phoneError = 'Vui lòng nhập số điện thoại';
    } else if (phoneDigits.length < 8 || phoneDigits.length > 15) {
      phoneError = 'Số điện thoại không hợp lệ';
    }
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

    return nameError == null &&
        phoneError == null &&
        emailError == null &&
        addressError == null;
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
                    variant: VButtonVariant.outline,
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
              VTextField(
                label: 'Tên tổ chức',
                isRequired: true,
                controller: _nameController,
                helperText: 'Tên hiển thị.',
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const VGap.md(),
              VTextField(
                label: 'Số điện thoại',
                isRequired: true,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                // Chỉ cho nhập chữ số và dấu '+' (đầu số quốc gia) — chặn chữ cái.
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  LengthLimitingTextInputFormatter(16),
                ],
                errorText: _phoneError,
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
              ),
              const VGap.md(),
              VEmailField(
                label: 'Email liên hệ',
                isRequired: true,
                controller: _emailController,
                validateOnChanged: false,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const VGap.md(),
              VTextField(
                label: 'Địa chỉ liên hệ',
                isRequired: true,
                controller: _addressController,
                errorText: _addressError,
                onChanged: (_) {
                  if (_addressError != null) setState(() => _addressError = null);
                },
              ),
              const VGap.md(),
              FutureBuilder<List<VnAdministrativeUnit>>(
                future: _unitsFuture,
                builder: (context, snapshot) {
                  final units = snapshot.data ?? const [];
                  final selectedProvince = _findProvinceByCode(units, _selectedProvinceCode);
                  final provinceItems = units
                      .map(
                        (u) => DropdownMenuEntry<String>(
                          value: u.code,
                          label: u.fullName,
                        ),
                      )
                      .toList(growable: false);
                  final wardList = selectedProvince?.wards ?? const <VnWard>[];
                  final wardItems = wardList
                      .map(
                        (w) => DropdownMenuEntry<String>(
                          value: w.code,
                          label: w.fullName,
                        ),
                      )
                      .toList(growable: false);

                  return Column(
                    children: [
                      _SearchDropdownField(
                        label: 'Tỉnh / thành phố',
                        child: VCompactSearchableDropdown<String>(
                          value: selectedProvince?.code,
                          hintText: 'Chọn tỉnh / thành phố',
                          collapsedWhenUnfocused: false,
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
                        child: VCompactSearchableDropdown<String>(
                          value: wardItems.any((i) => i.value == _selectedCommuneCode)
                              ? _selectedCommuneCode
                              : null,
                          hintText: 'Chọn xã / phường',
                          collapsedWhenUnfocused: false,
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
