// harness:allow-design-system-bypass — invitation shell mirrors login (branded form)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../../../iam/presentation/shared/idempotency_key_factory.dart';
import '../../data/auth_repository.dart';
import '../../data/invitation_acceptance_repository.dart';
import '../../logic/invitation_acceptance_cubit.dart';
import '../../logic/invitation_acceptance_state.dart';
import '../widgets/invitation_confirm_bottom_sheet.dart';
import '../widgets/invitation_outcome_view.dart';
import '../widgets/invitation_token_entry_form.dart';
import '../auth_layout.dart';
import 'invitation_registration_page.dart';

class InvitationTokenPage extends StatelessWidget {
  const InvitationTokenPage({
    super.key,
    this.invitations,
    this.auth,
    this.session,
    this.keyFactory,
    this.cubit,
  });

  final InvitationAcceptanceRepository? invitations;
  final AuthRepository? auth;
  final SessionController? session;
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
    final keys = keyFactory ?? const UuidIdempotencyKeyFactory();
    final resolvedAuth = auth ?? getIt<AuthRepository>();
    final resolvedSession = session ?? getIt<SessionController>();
    return BlocProvider(
      create: (_) => InvitationAcceptanceCubit(
        invitations: invitations ?? getIt<InvitationAcceptanceRepository>(),
        auth: resolvedAuth,
        session: resolvedSession,
        nextKey: keys.next,
      ),
      child: const _InvitationTokenView(),
    );
  }
}

class _InvitationTokenView extends StatefulWidget {
  const _InvitationTokenView();

  @override
  State<_InvitationTokenView> createState() => _InvitationTokenViewState();
}

class _InvitationTokenViewState extends State<_InvitationTokenView> {
  bool _confirmedNewAccount = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<InvitationAcceptanceCubit, InvitationAcceptanceState>(
      listenWhen: (prev, next) =>
          (prev.step != next.step && next.step == InvitationAcceptanceStep.accepted) ||
          (prev.step != next.step && next.step == InvitationAcceptanceStep.existingAccountLogin) ||
          (prev.step != next.step &&
              next.step == InvitationAcceptanceStep.newAccountRegistration) ||
          (prev.failure != next.failure && next.failure != null),
      listener: (context, state) {
        if (state.step == InvitationAcceptanceStep.tokenEntry) {
          setState(() => _confirmedNewAccount = false);
        }

        if (state.step == InvitationAcceptanceStep.accepted) {
          context.go(
            '/login',
            extra: {
              if (state.inspection?.inviteeEmail != null)
                'prefilledEmail': state.inspection!.inviteeEmail,
              'showSuccessBanner': true,
              if (state.inspection?.tenantName != null)
                'organizationName': state.inspection!.tenantName,
            },
          );
          return;
        }

        if ((state.step == InvitationAcceptanceStep.existingAccountLogin ||
                state.step == InvitationAcceptanceStep.newAccountRegistration) &&
            state.inspection != null &&
            state.failure == null) {
          final inspection = state.inspection!;
          final cubit = context.read<InvitationAcceptanceCubit>();
          () async {
            final confirmed = await showInvitationConfirmBottomSheet(
              context: context,
              inspection: inspection,
            );
            if (!context.mounted) return;
            if (confirmed == true) {
              if (inspection.accountExists) {
                await cubit.acceptExistingAccount();
              } else {
                setState(() => _confirmedNewAccount = true);
              }
            } else if (confirmed == false) {
              await cubit.decline();
            }
          }();
          return;
        }

        final failure = state.failure;
        if (failure == null) return;
        // Inspect-time failures stay on the entry screen and render inline.
        if (state.step == InvitationAcceptanceStep.tokenEntry) {
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
              maxWidth: authMaxWidth,
              alignment: Alignment.topCenter,
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
  bool _isEntryStep(InvitationAcceptanceState state) {
    switch (state.step) {
      case InvitationAcceptanceStep.tokenEntry:
      case InvitationAcceptanceStep.inspecting:
      case InvitationAcceptanceStep.existingAccountLogin:
        return true;
      case InvitationAcceptanceStep.newAccountRegistration:
        return state.inspection == null || !_confirmedNewAccount;
      case InvitationAcceptanceStep.submitting:
        return state.inspection?.accountExists == true;
      case InvitationAcceptanceStep.accepted:
      case InvitationAcceptanceStep.declined:
      case InvitationAcceptanceStep.blocked:
        return false;
    }
  }

  /// Code → inline message for inspect-time failures on the entry screen.
  static String _entryFailureMessage(String code) {
    return switch (code) {
      IamBlockedCodes.invitationTokenInvalid => 'Mã lời mời không hợp lệ. Kiểm tra và nhập lại.',
      IamBlockedCodes.invitationExpired =>
        'Mã lời mời đã hết hạn. Liên hệ người gửi để nhận mã mới.',
      IamBlockedCodes.invitationRevoked => 'Lời mời đã bị thu hồi và không thể tiếp nhận.',
      IamBlockedCodes.invitationAlreadyUsed => 'Lời mời đã được sử dụng và không thể tiếp nhận.',
      _ => 'Không thể xác thực mã. Kiểm tra kết nối và thử lại.',
    };
  }

  bool _isRegistrationStep(InvitationAcceptanceState state) {
    if (state.inspection == null) return false;
    return (state.step == InvitationAcceptanceStep.newAccountRegistration &&
            _confirmedNewAccount) ||
        (state.step == InvitationAcceptanceStep.submitting &&
            state.inspection!.accountExists == false);
  }

  Widget _body(BuildContext context, InvitationAcceptanceState state) {
    final cubit = context.read<InvitationAcceptanceCubit>();
    switch (state.step) {
      case InvitationAcceptanceStep.tokenEntry:
      case InvitationAcceptanceStep.inspecting:
      case InvitationAcceptanceStep.existingAccountLogin:
        return InvitationTokenEntryForm(
          isSubmitting: state.step == InvitationAcceptanceStep.inspecting || state.isSubmitting,
          onInspect: cubit.inspect,
          errorMessage: state.step == InvitationAcceptanceStep.tokenEntry && state.failure != null
              ? _entryFailureMessage(state.failure!.code)
              : null,
          onEditing: state.failure == null ? null : cubit.clearFeedback,
        );
      case InvitationAcceptanceStep.newAccountRegistration:
        if (!_confirmedNewAccount) {
          return InvitationTokenEntryForm(
            isSubmitting: state.isSubmitting,
            onInspect: cubit.inspect,
            onEditing: state.failure == null ? null : cubit.clearFeedback,
          );
        }
        return const InvitationRegistrationPage();
      case InvitationAcceptanceStep.submitting:
        if (state.inspection?.accountExists == true) {
          return InvitationTokenEntryForm(
            isSubmitting: true,
            onInspect: cubit.inspect,
          );
        }
        return const InvitationRegistrationPage();
      case InvitationAcceptanceStep.accepted:
        return const SizedBox.shrink();
      case InvitationAcceptanceStep.declined:
      case InvitationAcceptanceStep.blocked:
        return InvitationOutcomeView(
          step: state.step,
          message: state.failure?.message,
          onEnterWorkspace: null,
          onEnterOtherToken: () => cubit.reset(),
        );
    }
  }
}
