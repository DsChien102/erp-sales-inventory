import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/widgets/address/administrative_units_form_section.dart';
import '../../../../core/widgets/address/vn_administrative_units_loader.dart';
import '../../data/auth_repository.dart';
import '../../data/models/signup_input.dart';
import '../../logic/signup_cubit.dart';
import '../../logic/signup_state.dart';
import '../widgets/verify_email_view.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({
    super.key,
    this.auth,
    this.session,
    this.cubit,
  });

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
      create: (_) => SignupCubit(auth: repository),
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

  Future<List<VnAdministrativeUnit>> get _administrativeUnits =>
      _units ??= VnAdministrativeUnitsLoader.load();

  static const _stepLabels = ['1/3 · Tài khoản', '2/3 · Cửa hàng', '3/3 · Xác minh email'];

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
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignupCubit, SignupState>(
      listenWhen: (previous, current) => previous.step != current.step,
      listener: (context, state) {
        if (state.step == SignupStep.store && _contactEmail.text.trim().isEmpty) {
          _contactEmail.text = _email.text.trim();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.vColors.surface,
          appBar: VAppBar(
            title: 'Đăng ký cửa hàng',
            leading: IconButton(
              icon: Icon(Icons.chevron_left, color: context.vColors.textPrimary),
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
            child: ListView(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              children: [
                VText(
                  _stepLabels[state.step.index],
                  variant: VTextVariant.bodySmall,
                  color: context.vColors.textSecondary,
                ),
                const VGap.lg(),
                if (state.emailExists) _emailExists(context) else _step(context, state),
                if (state.failure != null && !state.emailExists) ...[
                  const VGap.md(),
                  VFieldError(state.failure!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _step(BuildContext context, SignupState state) {
    return switch (state.step) {
      SignupStep.account => _accountStep(),
      SignupStep.store => _storeStep(state),
      SignupStep.verify => VerifyEmailView(
        email: state.account?.email.trim() ?? '',
        auth: widget.auth,
        session: widget.session,
        onVerified: () {
          final name = state.store?.name.trim() ?? '';
          VToast.show(
            context,
            title: 'Chào mừng đến VET45!',
            message: 'Cửa hàng $name đã sẵn sàng.',
            type: VToastType.success,
          );
          context.go('/');
        },
      ),
    };
  }

  Widget _accountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          label: 'Họ và tên đệm',
          child: VTextField(
            key: const Key('signup_family_name'),
            controller: _familyName,
            hintText: 'Nguyễn Thị',
          ),
        ),
        const VGap.md(),
        _field(
          label: 'Tên',
          child: VTextField(
            key: const Key('signup_given_name'),
            controller: _givenName,
            hintText: 'Lan',
          ),
        ),
        const VGap.md(),
        _field(
          label: 'Email',
          child: VEmailField(
            key: const Key('signup_email'),
            controller: _email,
            hintText: 'lan@example.com',
            validateOnChanged: false,
          ),
        ),
        const VGap.md(),
        _field(
          label: 'Số điện thoại',
          child: VTextField(
            key: const Key('signup_phone'),
            controller: _phone,
            hintText: '0912 345 678',
            keyboardType: TextInputType.phone,
          ),
        ),
        const VGap.md(),
        _field(
          label: 'Mật khẩu',
          child: VPasswordField(
            key: const Key('signup_password'),
            controller: _password,
            hintText: 'Nhập mật khẩu',
            minLength: 1,
            validateOnChanged: false,
          ),
        ),
        const VGap.md(),
        _field(
          label: 'Nhập lại mật khẩu',
          child: VPasswordField(
            key: const Key('signup_confirm_password'),
            controller: _confirmPassword,
            hintText: 'Nhập lại mật khẩu',
            minLength: 1,
            validateOnChanged: false,
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
    );
  }

  Widget _storeStep(SignupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          label: 'Tên cửa hàng',
          child: VTextField(
            key: const Key('signup_store_name'),
            controller: _storeName,
            hintText: 'Thú y An Phát',
          ),
        ),
        const VGap.md(),
        _field(
          label: 'Số điện thoại cửa hàng',
          child: VTextField(
            key: const Key('signup_store_phone'),
            controller: _storePhone,
            hintText: '0912 345 678',
            keyboardType: TextInputType.phone,
          ),
        ),
        const VGap.md(),
        AdministrativeUnitsFormSection(
          unitsFuture: _administrativeUnits,
          selectedProvinceCode: _provinceCode,
          selectedCommuneCode: _communeCode,
          onProvinceChanged: (code) => setState(() {
            _provinceCode = code;
            _communeCode = null;
          }),
          onCommuneChanged: (code) => setState(() => _communeCode = code),
        ),
        const VGap.md(),
        _field(
          label: 'Địa chỉ chi tiết',
          child: VTextField(
            key: const Key('signup_address'),
            controller: _address,
            hintText: 'Số nhà, tên đường...',
          ),
        ),
        const VGap.md(),
        _field(
          label: 'Email liên hệ',
          child: VEmailField(
            key: const Key('signup_contact_email'),
            controller: _contactEmail,
            hintText: 'lan@example.com',
            validateOnChanged: false,
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
    );
  }

  Widget _emailExists(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VFieldError('Email đã được đăng ký'),
        const VGap.lg(),
        VButton(
          label: 'Đăng nhập',
          fullWidth: true,
          onPressed: () => context.go('/login', extra: {'prefilledEmail': _email.text.trim()}),
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

  Widget _field({required String label, required Widget child}) {
    return VField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VFieldLabel(label),
          child,
        ],
      ),
    );
  }
}
