// harness:allow-design-system-bypass — invitation shell mirrors login (branded form)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import '../../../../core/di/injection.dart';
import '../bloc/invitation_acceptance_cubit.dart';
import '../bloc/invitation_acceptance_state.dart';
import '../widgets/invitation_existing_account_form.dart';
import '../widgets/invitation_outcome_view.dart';
import '../widgets/invitation_token_entry_form.dart';
import 'invitation_registration_page.dart';

class InvitationTokenPage extends StatelessWidget {
  const InvitationTokenPage({
    super.key,
    this.iamModule,
    this.keyFactory,
    this.cubit,
  });

  final IIamModule? iamModule;
  final IdempotencyKeyFactory? keyFactory;
  final InvitationAcceptanceCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _InvitationTokenView(),
      );
    }
    return BlocProvider(
      create: (_) => InvitationAcceptanceCubit(
        iamModule: iamModule ?? getIt<IIamModule>(),
        keyFactory: keyFactory ?? const UuidIdempotencyKeyFactory(),
      ),
      child: const _InvitationTokenView(),
    );
  }
}

class _InvitationTokenView extends StatelessWidget {
  const _InvitationTokenView();

  static const _mobileLayoutWidth = VResponsiveValue<double>(
    mobile: 500,
    tablet: 500,
    desktop: 500,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<InvitationAcceptanceCubit, InvitationAcceptanceState>(
      listenWhen: (prev, next) =>
          (prev.step != next.step && next.step == InvitationAcceptanceStep.accepted) ||
          (prev.failure != next.failure && next.failure != null),
      listener: (context, state) {
        if (state.step == InvitationAcceptanceStep.accepted) {
          VToast.show(
            context,
            title: 'Kích hoạt thành công',
            message: 'Tài khoản đã được kích hoạt thành công.',
            type: VToastType.success,
          );
          context.go('/login');
          return;
        }

        final failure = state.failure;
        if (failure == null) return;
        // Inspect-time failures keep the user on the entry screen and surface
        // a code-specific toast so they can fix and re-enter the code.
        if (state.step == InvitationAcceptanceStep.tokenEntry) {
          final (message, type) = _entryFailureToast(failure.code);
          VToast.show(context, title: message, message: '', type: type);
          context.read<InvitationAcceptanceCubit>().clearFeedback();
          return;
        }
        // Never toast raw token / password — mapper messages only.
        if (state.step == InvitationAcceptanceStep.existingAccountLogin ||
            state.step == InvitationAcceptanceStep.newAccountRegistration) {
          VToast.show(
            context,
            title: 'Không hoàn tất',
            message: failure.message,
            type: VToastType.danger,
          );
          context.read<InvitationAcceptanceCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        // Token entry and registration own a full page (app bar + pinned
        // bottom bar), so they must not be nested inside this shell's
        // scroll view.
        if (_isEntryStep(state) || _isRegistrationStep(state)) {
          return _body(context, state);
        }
        return Scaffold(
          backgroundColor: colors.surface,
          body: SafeArea(
            child: VContentWidth(
              maxWidth: _mobileLayoutWidth,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: _body(context, state),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Steps that render the token-entry page — including the guard paths where
  /// a later step lost its inspection and has to fall back to entry.
  static bool _isEntryStep(InvitationAcceptanceState state) {
    switch (state.step) {
      case InvitationAcceptanceStep.tokenEntry:
      case InvitationAcceptanceStep.inspecting:
        return true;
      case InvitationAcceptanceStep.existingAccountLogin:
      case InvitationAcceptanceStep.newAccountRegistration:
        return state.inspection == null;
      case InvitationAcceptanceStep.submitting:
      case InvitationAcceptanceStep.accepted:
      case InvitationAcceptanceStep.declined:
      case InvitationAcceptanceStep.blocked:
        return false;
    }
  }

  /// Code → (toast message, tone) for inspect-time failures on the entry
  /// screen. Wording mirrors the activation-code design.
  static (String, VToastType) _entryFailureToast(String code) {
    return switch (code) {
      IamBlockedCodes.invitationTokenInvalid => (
        'Mã kích hoạt không hợp lệ. Kiểm tra và nhập lại.',
        VToastType.danger,
      ),
      IamBlockedCodes.invitationExpired => (
        'Mã kích hoạt đã hết hạn. Liên hệ người gửi để nhận mã mới.',
        VToastType.warning,
      ),
      IamBlockedCodes.invitationRevoked => (
        'Lời mời đã bị thu hồi và không thể tiếp nhận.',
        VToastType.warning,
      ),
      IamBlockedCodes.invitationAlreadyUsed => (
        'Lời mời đã được sử dụng và không thể tiếp nhận.',
        VToastType.warning,
      ),
      _ => (
        'Không thể xác thực mã. Kiểm tra kết nối và thử lại.',
        VToastType.danger,
      ),
    };
  }

  static bool _isRegistrationStep(InvitationAcceptanceState state) {
    if (state.inspection == null) return false;
    return state.step == InvitationAcceptanceStep.newAccountRegistration ||
        (state.step == InvitationAcceptanceStep.submitting &&
            state.inspection!.accountExists == false);
  }

  Widget _body(BuildContext context, InvitationAcceptanceState state) {
    final cubit = context.read<InvitationAcceptanceCubit>();
    switch (state.step) {
      case InvitationAcceptanceStep.tokenEntry:
      case InvitationAcceptanceStep.inspecting:
        return InvitationTokenEntryForm(
          isSubmitting: state.step == InvitationAcceptanceStep.inspecting || state.isSubmitting,
          onInspect: cubit.inspect,
        );
      case InvitationAcceptanceStep.existingAccountLogin:
        final inspection = state.inspection;
        if (inspection == null) {
          return InvitationTokenEntryForm(
            isSubmitting: false,
            onInspect: cubit.inspect,
          );
        }
        return InvitationExistingAccountForm(
          inspection: inspection,
          isSubmitting: state.isSubmitting,
          onAccept: (password) => cubit.loginAndAccept(password: password),
          onDecline: cubit.decline,
        );
      case InvitationAcceptanceStep.newAccountRegistration:
        return const InvitationRegistrationPage();
      case InvitationAcceptanceStep.submitting:
        if (state.inspection?.accountExists == true) {
          return InvitationExistingAccountForm(
            inspection: state.inspection!,
            isSubmitting: true,
            onAccept: (password) => cubit.loginAndAccept(password: password),
            onDecline: cubit.decline,
          );
        }
        return const InvitationRegistrationPage();
      case InvitationAcceptanceStep.accepted:
      case InvitationAcceptanceStep.declined:
      case InvitationAcceptanceStep.blocked:
        final keepToken =
            state.tokenPresent && state.failure?.code == IamBlockedCodes.tenantSuspended;
        return InvitationOutcomeView(
          step: state.step,
          message: state.failure?.message,
          onEnterWorkspace: state.step == InvitationAcceptanceStep.accepted
              ? () => context.go('/')
              : null,
          onEnterOtherToken: keepToken ? null : () => cubit.reset(),
          onRetryLater: keepToken
              ? () {
                  context.go('/login');
                }
              : null,
        );
    }
  }
}
