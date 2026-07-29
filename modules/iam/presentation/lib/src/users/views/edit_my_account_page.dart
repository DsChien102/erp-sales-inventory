import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'my_account_page.dart';

/// Trang Chỉnh sửa thông tin cá nhân (TA-D-02).
class EditMyAccountPage extends StatefulWidget {
  final MyAccountUiModel data;
  final IIamModule? iamModule;

  const EditMyAccountPage({
    super.key,
    this.data = MyAccountUiModel.sample,
    this.iamModule,
  });

  @override
  State<EditMyAccountPage> createState() => _EditMyAccountPageState();
}

class _EditMyAccountPageState extends State<EditMyAccountPage> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneNumberController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.data.firstName);
    _lastNameController = TextEditingController(text: widget.data.lastName);
    _phoneNumberController =
        TextEditingController(text: widget.data.phoneNumber);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    return _firstNameController.text.trim() != widget.data.firstName.trim() ||
        _lastNameController.text.trim() != widget.data.lastName.trim() ||
        _phoneNumberController.text.trim() != widget.data.phoneNumber.trim();
  }

  bool get _isValid {
    return _hasChanges &&
        _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;
  }

  Future<void> _handleSave() async {
    if (!_isValid || _isSaving) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();

    final module = widget.iamModule;
    if (module != null) {
      setState(() => _isSaving = true);
      try {
        final dto = await module.executeCommandAsync<MyIdentityProfileDto>(
          UpdateMyIdentityProfileCommand(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
            avatarUrl: widget.data.avatarUrl,
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(MyAccountUiModel.fromDto(dto));
      } on ApplicationException catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        VToast.show(
          context,
          title: 'Không lưu được',
          message: e.message,
          type: VToastType.danger,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        VToast.show(
          context,
          title: 'Không lưu được',
          message: e.toString(),
          type: VToastType.danger,
        );
      }
      return;
    }

    final updatedData = MyAccountUiModel(
      firstName: firstName,
      lastName: lastName,
      email: widget.data.email,
      emailStatus: widget.data.emailStatus,
      phoneNumber: phoneNumber,
      avatarUrl: widget.data.avatarUrl,
    );

    Navigator.of(context).pop(updatedData);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final data = widget.data;

    return VPageScaffold(
      title: 'Chỉnh sửa thông tin',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        children: [
          // Card Ảnh đại diện (Tạm thời không gán sự kiện click)
          VCard(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VAvatar(
                  name: data.fullName,
                  size: 48,
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        'Ảnh đại diện',
                        variant: VTextVariant.headingH4,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const VGap.xs(),
                      VText(
                        'Chạm để thay hoặc xóa ảnh',
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                VIcon(
                  icon: VIcons.chevronRight,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.lg(),

          // 1. Họ và tên đệm *
          VTextField(
            label: 'Họ và tên đệm',
            isRequired: true,
            hintText: 'Nhập họ và tên đệm',
            controller: _firstNameController,
            onChanged: (_) => setState(() {}),
          ),
          const VGap.md(),

          // 2. Tên *
          VTextField(
            label: 'Tên',
            isRequired: true,
            hintText: 'Nhập tên',
            controller: _lastNameController,
            onChanged: (_) => setState(() {}),
          ),
          const VGap.md(),

          // 3. Số điện thoại
          VTextField(
            label: 'Số điện thoại',
            hintText: 'Nhập số điện thoại',
            keyboardType: TextInputType.phone,
            controller: _phoneNumberController,
            onChanged: (_) => setState(() {}),
          ),
          const VGap.md(),

          // 4. Email đăng nhập (Read-only)
          VTextField(
            label: 'Email đăng nhập',
            controller: TextEditingController(text: data.email),
            enabled: false,
          ),
          const VGap.xl(),
        ],
      ),
      bottomBar: Container(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(color: colors.borderDefault),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Hủy',
                  variant: VButtonVariant.outline,
                  fullWidth: true,
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const VGap.horizontalSm(),
              Expanded(
                child: VButton(
                  label: _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                  variant: VButtonVariant.primary,
                  tone: VComponentTone.primary,
                  fullWidth: true,
                  onPressed: _isValid && !_isSaving ? _handleSave : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
