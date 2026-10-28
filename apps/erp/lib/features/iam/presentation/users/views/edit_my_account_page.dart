import 'package:erp/features/iam/data/account_repository.dart';
import 'package:erp/features/iam/data/models/my_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../shared/iam_load_status.dart';
import '../../../logic/my_account_edit_cubit.dart';
import '../../../logic/my_account_edit_state.dart';
import 'my_account_page.dart';

/// Trang Chỉnh sửa thông tin cá nhân (TA-D-02).
class EditMyAccountPage extends StatelessWidget {
  const EditMyAccountPage({
    super.key,
    this.data,
    this.accountRepository,
    this.cubit,
  });

  /// Test-only seed when [accountRepository]/[cubit] are null.
  final MyAccountUiModel? data;
  final AccountRepository? accountRepository;
  final MyAccountEditCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _EditMyAccountBody(),
      );
    }
    if (accountRepository != null) {
      return BlocProvider(
        create: (_) => MyAccountEditCubit(accountRepository: accountRepository!)..load(),
        child: const _EditMyAccountBody(),
      );
    }
    assert(
      data != null,
      'EditMyAccountPage requires data when accountRepository/cubit is null',
    );
    return _EditMyAccountSampleBody(data: data!);
  }
}

class _EditMyAccountSampleBody extends StatefulWidget {
  const _EditMyAccountSampleBody({required this.data});

  final MyAccountUiModel data;

  @override
  State<_EditMyAccountSampleBody> createState() => _EditMyAccountSampleBodyState();
}

class _EditMyAccountSampleBodyState extends State<_EditMyAccountSampleBody> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _emailController;
  String? _phoneErrorText;
  String? _lastNameErrorText;
  String? _firstNameErrorText;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.data.firstName);
    _lastNameController = TextEditingController(text: widget.data.lastName);
    _phoneNumberController = TextEditingController(text: widget.data.phoneNumber);
    _emailController = TextEditingController(text: widget.data.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    return _firstNameController.text.trim() != widget.data.firstName.trim() ||
        _lastNameController.text.trim() != widget.data.lastName.trim() ||
        _phoneNumberController.text.trim() != widget.data.phoneNumber.trim();
  }

  void _handleSave() {
    final lastNameError = _lastNameController.text.trim().isEmpty
        ? 'Vui lòng nhập họ và tên đệm'
        : null;
    final firstNameError = _firstNameController.text.trim().isEmpty ? 'Vui lòng nhập tên' : null;
    final phoneError = VPhoneValidator.validate(_phoneNumberController.text, isRequired: false);
    if (phoneError != null || lastNameError != null || firstNameError != null) {
      setState(() {
        _phoneErrorText = phoneError;
        _lastNameErrorText = lastNameError;
        _firstNameErrorText = firstNameError;
      });
      return;
    }
    Navigator.of(context).pop(
      MyAccountUiModel(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: widget.data.email,
        emailStatus: widget.data.emailStatus,
        phoneNumber: _phoneNumberController.text.trim(),
        avatarUrl: widget.data.avatarUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EditFormScaffold(
      fullName: widget.data.fullName,
      firstNameController: _firstNameController,
      lastNameController: _lastNameController,
      phoneNumberController: _phoneNumberController,
      emailController: _emailController,
      phoneErrorText: _phoneErrorText,
      lastNameErrorText: _lastNameErrorText,
      firstNameErrorText: _firstNameErrorText,
      hasChanges: _hasChanges,
      isSaving: false,
      onChanged: () => setState(() {
        _phoneErrorText = null;
        if (_lastNameController.text.trim().isNotEmpty) _lastNameErrorText = null;
        if (_firstNameController.text.trim().isNotEmpty) _firstNameErrorText = null;
      }),
      onSave: _handleSave,
      onCancel: () => Navigator.of(context).maybePop(),
    );
  }
}

class _EditMyAccountBody extends StatefulWidget {
  const _EditMyAccountBody();

  @override
  State<_EditMyAccountBody> createState() => _EditMyAccountBodyState();
}

class _EditMyAccountBodyState extends State<_EditMyAccountBody> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _emailController;
  String? _baselineFirstName;
  String? _baselineLastName;
  String? _baselinePhone;
  String? _avatarUrl;
  String? _phoneErrorText;
  String? _lastNameErrorText;
  String? _firstNameErrorText;
  bool _controllersSeeded = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _seedFromProfile(MyAccount profile) {
    if (_controllersSeeded) return;
    _controllersSeeded = true;
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _phoneNumberController.text = profile.phoneNumber ?? '';
    _emailController.text = profile.email;
    _baselineFirstName = profile.firstName;
    _baselineLastName = profile.lastName;
    _baselinePhone = profile.phoneNumber ?? '';
    _avatarUrl = profile.avatarUrl;
  }

  bool get _hasChanges {
    if (_baselineFirstName == null) return false;
    return _firstNameController.text.trim() != _baselineFirstName!.trim() ||
        _lastNameController.text.trim() != _baselineLastName!.trim() ||
        _phoneNumberController.text.trim() != _baselinePhone!.trim();
  }

  Future<void> _handleSave() async {
    final lastNameError = _lastNameController.text.trim().isEmpty
        ? 'Vui lòng nhập họ và tên đệm'
        : null;
    final firstNameError = _firstNameController.text.trim().isEmpty ? 'Vui lòng nhập tên' : null;
    final phoneError = VPhoneValidator.validate(_phoneNumberController.text, isRequired: false);
    if (phoneError != null || lastNameError != null || firstNameError != null) {
      setState(() {
        _phoneErrorText = phoneError;
        _lastNameErrorText = lastNameError;
        _firstNameErrorText = firstNameError;
      });
      return;
    }
    final cubit = context.read<MyAccountEditCubit>();
    final ok = await cubit.save(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim().isEmpty
          ? null
          : _phoneNumberController.text.trim(),
      avatarUrl: _avatarUrl,
    );
    if (!mounted) return;
    if (!ok) {
      final failure = cubit.state.failure;
      VToast.show(
        context,
        title: 'Không lưu được',
        message: failure?.message ?? 'Đã xảy ra lỗi',
        type: VToastType.danger,
      );
      return;
    }
    final saved = cubit.state.savedProfile;
    if (saved == null) return;
    Navigator.of(context).pop(MyAccountUiModel.fromDto(saved));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyAccountEditCubit, MyAccountEditState>(
      listener: (context, state) {
        if (state.profile != null) {
          _seedFromProfile(state.profile!);
        }
      },
      builder: (context, state) {
        final colors = context.vColors;
        if (state.status == IamLoadStatus.loading || state.status == IamLoadStatus.initial) {
          return const VPageScaffold(
            title: 'Chỉnh sửa thông tin',
            body: Center(child: VLoading(size: 40)),
          );
        }

        if (state.status == IamLoadStatus.failure && state.profile == null) {
          return VPageScaffold(
            title: 'Chỉnh sửa thông tin',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: VText(
                        'Không tải được hồ sơ',
                        variant: VTextVariant.headingH4,
                      ),
                    ),
                    const VGap.sm(),
                    VText(
                      state.failure?.message ?? 'Đã xảy ra lỗi',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const VGap.lg(),
                    VButton(
                      label: 'Thử lại',
                      onPressed: () => context.read<MyAccountEditCubit>().load(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = state.profile;
        final fullName = profile == null ? '' : '${profile.lastName} ${profile.firstName}'.trim();

        return _EditFormScaffold(
          fullName: fullName,
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          phoneNumberController: _phoneNumberController,
          emailController: _emailController,
          phoneErrorText: _phoneErrorText,
          lastNameErrorText: _lastNameErrorText,
          firstNameErrorText: _firstNameErrorText,
          hasChanges: _hasChanges,
          isSaving: state.isSubmitting,
          onChanged: () => setState(() {
            _phoneErrorText = null;
            if (_lastNameController.text.trim().isNotEmpty) _lastNameErrorText = null;
            if (_firstNameController.text.trim().isNotEmpty) _firstNameErrorText = null;
          }),
          onSave: _handleSave,
          onCancel: () => Navigator.of(context).maybePop(),
        );
      },
    );
  }
}

class _EditFormScaffold extends StatelessWidget {
  const _EditFormScaffold({
    required this.fullName,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneNumberController,
    required this.emailController,
    this.phoneErrorText,
    required this.lastNameErrorText,
    required this.firstNameErrorText,
    required this.hasChanges,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  final String fullName;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneNumberController;
  final TextEditingController emailController;
  final String? phoneErrorText;
  final String? lastNameErrorText;
  final String? firstNameErrorText;
  final bool hasChanges;
  final bool isSaving;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return PopScope(
      canPop: !hasChanges || isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && hasChanges) {
          showVConfirmDialog(
            context: context,
            title: 'Bỏ thay đổi?',
            message: 'Các thay đổi chưa lưu sẽ bị mất.',
            cancelLabel: 'Tiếp tục sửa',
            actionLabel: 'Bỏ thay đổi',
            isDestructive: true,
            onAction: () {
              if (context.mounted) Navigator.of(context).pop();
            },
          );
        }
      },
      child: VPageScaffold(
        title: 'Chỉnh sửa thông tin',
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space4,
          ),
          children: [
            VCard(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Row(
                children: [
                  VAvatar(
                    name: fullName,
                    size: 48,
                  ),
                  const VGap.horizontalSm(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: VText(
                            'Ảnh đại diện',
                            variant: VTextVariant.headingH4,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
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
            VField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VFieldLabel('Họ và tên đệm', isRequired: true),
                  VField(
                    invalid: lastNameErrorText != null,
                    child: VTextField(
                      hintText: 'Nhập họ và tên đệm',
                      controller: lastNameController,
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  if (lastNameErrorText != null) VFieldError(lastNameErrorText!),
                ],
              ),
            ),
            const VGap.md(),
            VField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VFieldLabel('Tên', isRequired: true),
                  VField(
                    invalid: firstNameErrorText != null,
                    child: VTextField(
                      hintText: 'Nhập tên',
                      controller: firstNameController,
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  if (firstNameErrorText != null) VFieldError(firstNameErrorText!),
                ],
              ),
            ),
            const VGap.md(),
            VField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VFieldLabel('Số điện thoại'),
                  VPhoneField(
                    hintText: 'Nhập số điện thoại',
                    controller: phoneNumberController,
                    validateOnChanged: false,
                    onChanged: (_) => onChanged(),
                  ),
                  if (phoneErrorText != null) VFieldError(phoneErrorText!),
                ],
              ),
            ),
            const VGap.md(),
            VField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VFieldLabel('Email đăng nhập'),
                  VTextField(
                    controller: emailController,
                    enabled: false,
                  ),
                ],
              ),
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
                    variant: VButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: isSaving ? null : onCancel,
                  ),
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: VButton(
                    label: isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.primary,
                    fullWidth: true,
                    onPressed: hasChanges && !isSaving ? onSave : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
