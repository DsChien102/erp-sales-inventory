// harness:allow-design-system-bypass — owner activation shell mirrors login (branded form)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/owner_activation_client.dart';
import '../bloc/owner_activation_cubit.dart';
import '../bloc/owner_activation_state.dart';

/// Owner account activation: enter the activation code + a new password.
class OwnerActivationPage extends StatelessWidget {
  const OwnerActivationPage({super.key, this.cubit, this.client});

  final OwnerActivationCubit? cubit;
  final OwnerActivationClient? client;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _OwnerActivationView(),
      );
    }
    return BlocProvider(
      create: (_) => OwnerActivationCubit(
        client:
            client ?? SupabaseOwnerActivationClient(Supabase.instance.client),
        idempotencyKey:
            'owner-activation-${DateTime.now().microsecondsSinceEpoch}',
      ),
      child: const _OwnerActivationView(),
    );
  }
}

class _OwnerActivationView extends StatefulWidget {
  const _OwnerActivationView();

  @override
  State<_OwnerActivationView> createState() => _OwnerActivationViewState();
}

class _OwnerActivationViewState extends State<_OwnerActivationView> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _mobileLayoutWidth = VResponsiveValue<double>(
    mobile: 500,
    tablet: 500,
    desktop: 500,
  );

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<OwnerActivationCubit>().submit(
      code: _codeController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<OwnerActivationCubit, OwnerActivationState>(
      listenWhen: (prev, next) => prev.step != next.step,
      listener: (context, state) {
        if (state.step == OwnerActivationStep.failed &&
            state.errorMessage != null) {
          VToast.show(
            context,
            title: 'Kích hoạt thất bại',
            message: state.errorMessage!,
            type: VToastType.danger,
          );
        }
        if (state.step == OwnerActivationStep.activated) {
          VToast.show(
            context,
            title: 'Kích hoạt thành công',
            message: 'Chào mừng bạn đến với VET45!',
            type: VToastType.success,
          );
          context.go('/');
        }
      },
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: VAppBar(title: 'Kích hoạt tài khoản', showBackButton: true),
          body: SafeArea(
            child: VContentWidth(
              maxWidth: _mobileLayoutWidth,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const VGap.lg(),
                    VText(
                      'Nhập mã kích hoạt đã gửi tới email của bạn, rồi đặt mật khẩu mới để đăng nhập.',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    const VGap.xl(),
                    VTextField(
                      controller: _codeController,
                      label: 'Mã kích hoạt',
                      hintText: 'Nhập mã trong email',
                      enabled: !isSubmitting,
                    ),
                    const VGap.md(),
                    VPasswordField(
                      controller: _passwordController,
                      label: 'Mật khẩu mới',
                      hintText: 'Tối thiểu 8 ký tự',
                      minLength: 8,
                      enabled: !isSubmitting,
                      prefixIcon: VIcon(icon: VIcons.lock),
                      onSubmitted: (_) => _submit(),
                    ),
                    const VGap.xl(),
                    VButton(
                      label: 'Kích hoạt tài khoản',
                      isLoading: isSubmitting,
                      fullWidth: true,
                      onPressed: isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
