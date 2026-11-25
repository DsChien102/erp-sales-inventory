import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/validation/password_policy.dart';
import '../../../../core/widgets/address/administrative_units_form_section.dart';
import '../../../../core/widgets/address/vn_administrative_units_loader.dart';
import '../../data/auth_repository.dart';
import '../../data/models/signup_input.dart';
import '../../logic/signup_cubit.dart';
import '../../logic/signup_state.dart';
import '../widgets/verify_email_view.dart';
import '../auth_layout.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key, this.auth, this.session, this.cubit});

  final AuthRepository? auth;
  final SessionController? session;
  final SignupCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final repository = auth ?? getIt<AuthRepository>();
    final sessionController = session ?? getIt<SessionController>();
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _SignupView(auth: repository, session: sessionController),
      );
    }
    return BlocProvider(
      create: (_) => SignupCubit(auth: repository, session: sessionController),
      child: _SignupView(auth: repository, session: sessionController),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView({required this.auth, required this.session});

  final AuthRepository auth;
  final SessionController session;

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _familyName = TextEditingController();
  final _givenName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _storeName = TextEditingController();
  final _storePhone = TextEditingController();
  final _address = TextEditingController();
  final _contactEmail = TextEditingController();

  String? _provinceCode;
  String? _communeCode;
  Future<List<VnAdministrativeUnit>>? _units;
  final _bannerKey = GlobalKey();
  final _fieldKeys = {
    for (final field in SignupField.values) field: GlobalKey(),
  };

  Future<List<VnAdministrativeUnit>> get _administrativeUnits =>
      _units ??= VnAdministrativeUnitsLoader.load();

  static const _stepLabels = [
    '1/3 · Tài khoản',
    '2/3 · Cửa hàng',
    '3/3 · Xác minh email',
  ];

  @override
  void dispose() {
    _familyName.dispose();
    _givenName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _storeName.dispose();
    _storePhone.dispose();
    _address.dispose();
    _contactEmail.dispose();
    super.dispose();
  }

  void _continue() {
    context.read<SignupCubit>().continueToStore(
      SignupAccountInput(
        familyName: _familyName.text,
        givenName: _givenName.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        confirmPassword: _confirmPassword.text,
      ),
    );
    _scheduleScrollToFirstError();
  }

  void _createStore() {
    final accountEmail = _email.text.trim();
    if (_contactEmail.text.trim().isEmpty) {
      _contactEmail.text = accountEmail;
    }
    context.read<SignupCubit>().createStore(
      SignupStoreInput(
        name: _storeName.text,
        contactPhone: _storePhone.text,
        provinceCode: _provinceCode ?? '',
        communeCode: _communeCode ?? '',
        addressText: _address.text,
        contactEmail: _contactEmail.text,
      ),
    );
    _scheduleScrollToFirstError();
  }

  void _scheduleScrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final errors = context.read<SignupCubit>().state.fieldErrors;
      if (errors.isEmpty) return;
      final firstField = SignupField.values.firstWhere(
        errors.containsKey,
      );
      final targetContext = _fieldKeys[firstField]?.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 200),
          alignment: 0.1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignupCubit, SignupState>(
      listenWhen: (previous, current) =>
          previous.step != current.step ||
          (previous.failure != current.failure && current.failure != null) ||
          (!previous.completed && current.completed),
      listener: (context, state) {
        if (state.failure != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final targetContext = _bannerKey.currentContext;
            if (targetContext != null) {
              Scrollable.ensureVisible(
                targetContext,
                duration: const Duration(milliseconds: 200),
                alignment: 0.1,
              );
            }
          });
        }
        if (state.step == SignupStep.store && _contactEmail.text.trim().isEmpty) {
          _contactEmail.text = _email.text.trim();
        }
        if (state.completed) {
          final name = state.tenantName?.trim();
          final label = (name == null || name.isEmpty) ? 'cửa hàng' : name;
          VToast.show(
            context,
            title: 'Chào mừng đến Mosaic Retail!',
            message: 'Cửa hàng $label đã sẵn sàng.',
            type: VToastType.success,
          );
          if (state.nameDiffers) {
            VToast.show(
              context,
              title: 'Thông báo',
              message:
                  'Cửa hàng được tạo theo thông tin lần đăng ký trước. Bạn có thể sửa trong Hồ sơ tổ chức.',
              type: VToastType.info,
            );
          }
          context.go('/');
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.vColors.surface,
          appBar: VAppBar(
            title: 'Đăng ký cửa hàng',
            leading: IconButton(
              tooltip: 'Quay lại',
              icon: VIcon(
                icon: VIcons.chevronLeft,
                color: context.vColors.textPrimary,
              ),
              onPressed: () {
                if (state.step == SignupStep.store) {
                  context.read<SignupCubit>().back();
                  return;
                }
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/login');
                }
              },
            ),
          ),
          body: SafeArea(
            child: VContentWidth(
              maxWidth: authMaxWidth,
              alignment: Alignment.topCenter,
              child: ListView(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                children: [
                  VSteps(
                    steps: const [
                      VStepItem(title: 'Tài khoản'),
                      VStepItem(title: 'Cửa hàng'),
                      VStepItem(title: 'Xác minh email'),
                    ],
                    currentStep: state.step.index,
                    semanticLabel: _stepLabels[state.step.index],
                  ),
                  const VGap.lg(),
                  if (state.failure != null && !state.emailExists) ...[
                    VBanner(
                      key: _bannerKey,
                      status: VBannerStatus.error,
                      title: state.failure!,
                    ),
                    const VGap.md(),
                  ],
                  if (state.emailExists) _emailExists(context) else _step(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _step(BuildContext context, SignupState state) {
    return switch (state.step) {
      SignupStep.account => _accountStep(state),
      SignupStep.store => _storeStep(state),
      SignupStep.verify => VerifyEmailView(
        email: state.account?.email.trim() ?? '',
        auth: widget.auth,
        session: widget.session,
        deferSignedIn: true,
        initialResendCooldown: state.verifyCooldownSeconds == null
            ? null
            : Duration(seconds: state.verifyCooldownSeconds!),
        onVerified: (userId) {
          context.read<SignupCubit>().completeAfterVerification(userId);
        },
      ),
    };
  }

  Widget _accountStep(SignupState state) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            label: 'Họ và tên đệm',
            field: SignupField.familyName,
            state: state,
            child: VTextField(
              key: const Key('signup_family_name'),
              controller: _familyName,
              hintText: 'Nguyễn Thị',
              autofillHints: const [AutofillHints.familyName],
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<SignupCubit>().clearFieldError(
                SignupField.familyName,
              ),
            ),
          ),
          const VGap.md(),
          _field(
            label: 'Tên',
            field: SignupField.givenName,
            state: state,
            child: VTextField(
              key: const Key('signup_given_name'),
              controller: _givenName,
              hintText: 'Lan',
              autofillHints: const [AutofillHints.givenName],
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<SignupCubit>().clearFieldError(
                SignupField.givenName,
              ),
            ),
          ),
          const VGap.md(),
          _field(
            label: 'Email',
            field: SignupField.email,
            state: state,
            child: VEmailField(
              key: const Key('signup_email'),
              controller: _email,
              hintText: 'lan@example.com',
              validateOnChanged: false,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<SignupCubit>().clearFieldError(
                SignupField.email,
              ),
            ),
          ),
          const VGap.md(),
          _field(
            label: 'Số điện thoại',
            field: SignupField.phone,
            state: state,
            child: VPhoneField(
              key: const Key('signup_phone'),
              controller: _phone,
              hintText: '0912 345 678',
              validateOnChanged: false,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<SignupCubit>().clearFieldError(
                SignupField.phone,
              ),
            ),
          ),
          const VGap.md(),
          _field(
            label: 'Mật khẩu',
            field: SignupField.password,
            state: state,
            child: VPasswordField(
              key: const Key('signup_password'),
              controller: _password,
              hintText: 'Nhập mật khẩu',
              minLength: 1,
              validateOnChanged: false,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<SignupCubit>().clearFieldError(
                SignupField.password,
              ),
            ),
            description: PasswordPolicy.requirementText,
          ),
          const VGap.md(),
          _field(
            label: 'Nhập lại mật khẩu',
            field: SignupField.confirmPassword,
            state: state,
            child: VPasswordField(
              key: const Key('signup_confirm_password'),
              controller: _confirmPassword,
              hintText: 'Nhập lại mật khẩu',
              minLength: 1,
              validateOnChanged: false,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onChanged: (_) => context.read<SignupCubit>().clearFieldError(
                SignupField.confirmPassword,
              ),
              onSubmitted: (_) => _continue(),
            ),
          ),
          const VGap.lg(),
          VButton(
            key: const Key('signup_continue'),
            label: 'Tiếp tục',
            fullWidth: true,
            onPressed: _continue,
          ),
          const VGap.md(),
          Center(
            child: VButton(
              label: 'Đã có tài khoản? Đăng nhập',
              variant: VButtonVariant.link,
              onPressed: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeStep(SignupState state) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            label: 'Tên cửa hàng',
            field: SignupField.storeName,
            state: state,
            child: VTextField(
              key: const Key('signup_store_name'),
              controller: _storeName,
              hintText: 'Thú y An Phát',
              autofillHints: const [AutofillHints.organizationName],
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<SignupCubit>().clearFieldError(
                SignupField.storeName,
              ),
            ),
          ),
          const VGap.md(),
          _field(
            label: 'Số điện thoại cửa hàng',
            field: SignupField.storePhone,
            state: state,
            child: VPhoneField(
              key: const Key('signup_store_phone'),
              controller: _storePhone,
              hintText: '0912 345 678',
              validateOnChanged: false,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<SignupCubit>().clearFieldError(
                SignupField.storePhone,
              ),
            ),
          ),
          const VGap.md(),
          AdministrativeUnitsFormSection(
            unitsFuture: _administrativeUnits,
            selectedProvinceCode: _provinceCode,
            selectedCommuneCode: _communeCode,
            isRequired: true,
            provinceError: state.fieldErrors[SignupField.province],
            communeError: state.fieldErrors[SignupField.commune],
            provinceKey: _fieldKeys[SignupField.province],
            communeKey: _fieldKeys[SignupField.commune],
            onProvinceChanged: (code) => setState(() {
              _provinceCode = code;
              _communeCode = null;
              context.read<SignupCubit>().clearFieldError(SignupField.province);
              context.read<SignupCubit>().clearFieldError(SignupField.commune);
            }),
            onCommuneChanged: (code) => setState(() {
              _communeCode = code;
              context.read<SignupCubit>().clearFieldError(SignupField.commune);
            }),
          ),
          const VGap.md(),
          _field(
            label: 'Địa chỉ chi tiết',
            field: SignupField.address,
            state: state,
            child: VTextField(
              key: const Key('signup_address'),
              controller: _address,
              hintText: 'Số nhà, tên đường...',
              autofillHints: const [AutofillHints.fullStreetAddress],
              textInputAction: TextInputAction.next,
              onChanged: (_) => context.read<SignupCubit>().clearFieldError(
                SignupField.address,
              ),
            ),
          ),
          const VGap.md(),
          _field(
            label: 'Email liên hệ',
            field: SignupField.contactEmail,
            state: state,
            child: VEmailField(
              key: const Key('signup_contact_email'),
              controller: _contactEmail,
              hintText: 'lan@example.com',
              validateOnChanged: false,
              textInputAction: TextInputAction.done,
              onChanged: (_) => context.read<SignupCubit>().clearFieldError(
                SignupField.contactEmail,
              ),
              onSubmitted: (_) {
                if (!state.submitting) _createStore();
              },
            ),
          ),
          const VGap.md(),
          VText(
            'Thông tin pháp lý (mã số thuế) có thể bổ sung sau trong Hồ sơ tổ chức.',
            variant: VTextVariant.bodySmall,
            color: context.vColors.textSecondary,
          ),
          const VGap.lg(),
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Quay lại',
                  variant: VButtonVariant.secondary,
                  onPressed: state.submitting ? null : () => context.read<SignupCubit>().back(),
                ),
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: VButton(
                  key: const Key('signup_create'),
                  label: state.submitting ? 'Đang tạo...' : 'Tạo cửa hàng',
                  isLoading: state.submitting,
                  onPressed: state.submitting ? null : _createStore,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emailExists(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VField(invalid: true, child: VFieldError('Email đã được đăng ký')),
        const VGap.lg(),
        VButton(
          label: 'Đăng nhập',
          fullWidth: true,
          onPressed: () => context.go(
            '/login',
            extra: {'prefilledEmail': _email.text.trim()},
          ),
        ),
        const VGap.md(),
        VButton(
          label: 'Quên mật khẩu',
          variant: VButtonVariant.link,
          onPressed: () => context.push('/login/reset-password', extra: _email.text.trim()),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required SignupField field,
    required SignupState state,
    required Widget child,
    String? description,
  }) {
    return KeyedSubtree(
      key: _fieldKeys[field],
      child: VField(
        invalid: state.fieldErrors[field] != null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VFieldLabel(
              label,
              isRequired: field != SignupField.phone && field != SignupField.contactEmail,
            ),
            child,
            if (state.fieldErrors[field] case final error?) VFieldError(error),
            if (state.fieldErrors[field] == null && description != null)
              VFieldDescription(description),
          ],
        ),
      ),
    );
  }
}
