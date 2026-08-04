import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class PartnerTransformPage extends StatelessWidget {
  const PartnerTransformPage({
    super.key,
    required this.partner,
    required this.partnerModule,
    required this.executionContext,
    this.initialBlocked,
  });

  final PartnerDetailDto partner;
  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;
  final PartnerTransformBlockedKind? initialBlocked;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartnerTransformCubit(
        partnerModule: partnerModule,
        executionContext: executionContext,
      ),
      child: _PartnerTransformView(
        partner: partner,
        initialBlocked: initialBlocked,
      ),
    );
  }
}

class _PartnerTransformView extends StatefulWidget {
  const _PartnerTransformView({
    required this.partner,
    this.initialBlocked,
  });

  final PartnerDetailDto partner;
  final PartnerTransformBlockedKind? initialBlocked;

  @override
  State<_PartnerTransformView> createState() => _PartnerTransformViewState();
}

class _PartnerTransformViewState extends State<_PartnerTransformView> {
  OrganizationProfileInput? _draft;
  var _currentStep = 1;
  PartnerTransformBlockedKind? _blocked;
  String? _previewError;
  Map<String, String> _serverFieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _blocked = widget.initialBlocked;
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _blocked;
    return MultiBlocListener(
      listeners: [
        BlocListener<PartnerTransformCubit, PartnerTransformSubmitState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == PartnerTransformSubmitStatus.success) {
              context.pop(true);
              return;
            }
            if (state.status == PartnerTransformSubmitStatus.blocked && state.blocked != null) {
              setState(() {
                _blocked = state.blocked;
                _previewError = null;
                _serverFieldErrors = const {};
              });
              return;
            }
            if (state.status == PartnerTransformSubmitStatus.duplicate) {
              setState(() {
                _currentStep = 1;
                _previewError = null;
                _serverFieldErrors = state.fieldErrors.isNotEmpty
                    ? Map<String, String>.from(state.fieldErrors)
                    : {
                        'phone': PartnerTransformCubit.duplicatePhoneMessage,
                      };
              });
              return;
            }
            if (state.status == PartnerTransformSubmitStatus.failure) {
              setState(() {
                _currentStep = 2;
                _previewError =
                    state.generalError ?? 'Không thể chuyển đổi hồ sơ. Vui lòng thử lại.';
                _serverFieldErrors = const {};
              });
            }
          },
        ),
      ],
      child: PopScope(
        canPop: blocked != null || _currentStep == 1,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _goToStepOne();
        },
        child: VPageScaffold(
          key: const Key('wgt_e01_u06_fr01_01'),
          title: blocked != null
              ? 'Chuyển thành tổ chức'
              : (_currentStep == 1 ? 'Chuyển thành tổ chức' : 'Xem trước chuyển đổi'),
          centerTitle: true,
          leading: IconButton(
            key: const Key('transform_app_bar_back'),
            icon: VIcon(
              icon: VIcons.arrowBack,
              color: context.vColors.textPrimary,
            ),
            onPressed: _onAppBarBack,
          ),
          body: Stack(
            children: [
              blocked != null
                  ? PartnerTransformBlockedState(
                      kind: blocked,
                      onActionPressed: () => _onBlockedAction(blocked),
                    )
                  : _currentStep == 1
                  ? PartnerTransformStepOneView(
                      partner: widget.partner,
                      initialValue: _draft,
                      serverFieldErrors: _serverFieldErrors,
                      onCancel: () => context.pop(),
                      onContinue: (value) {
                        setState(() {
                          _draft = value;
                          _currentStep = 2;
                          _previewError = null;
                          _serverFieldErrors = const {};
                        });
                      },
                    )
                  : PartnerTransformPreviewView(
                      partner: widget.partner,
                      organization: _draft!,
                      errorMessage: _previewError,
                      onBack: _goToStepOne,
                      onContinue: _showConfirmation,
                    ),
              if (context.watch<PartnerTransformCubit>().state.isSubmitting)
                ColoredBox(
                  color: context.vColors.textPrimary,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToStepOne() {
    setState(() {
      _currentStep = 1;
      _previewError = null;
    });
  }

  void _onAppBarBack() {
    if (_blocked == null && _currentStep == 2) {
      _goToStepOne();
      return;
    }
    context.pop();
  }

  void _onBlockedAction(PartnerTransformBlockedKind kind) {
    switch (kind) {
      case PartnerTransformBlockedKind.noPermission:
        context.pop();
      case PartnerTransformBlockedKind.staleData:
        context.read<PartnerTransformCubit>().clearBlocked();
        setState(() {
          _blocked = null;
          _currentStep = 1;
        });
    }
  }

  Future<void> _showConfirmation() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => PartnerTransformConfirmationDialog(
        onBack: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          final draft = _draft;
          if (draft == null) return;
          setState(() {
            _previewError = null;
            _serverFieldErrors = const {};
          });
          context.read<PartnerTransformCubit>().confirmTransform(
            partnerId: widget.partner.partnerId,
            expectedVersion: widget.partner.expectedVersion,
            organizationProfile: draft,
          );
        },
      ),
    );
  }
}
