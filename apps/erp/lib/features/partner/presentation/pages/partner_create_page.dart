import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class PartnerCreatePage extends StatelessWidget {
  const PartnerCreatePage({
    super.key,
    required this.partnerType,
    required this.partnerModule,
    required this.executionContext,
    required this.onCreated,
    required this.onOpenExisting,
  });

  final PartnerType partnerType;
  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;
  final ValueChanged<String> onCreated;
  final ValueChanged<String> onOpenExisting;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartnerCreateCubit(
        partnerType: partnerType,
        partnerModule: partnerModule,
        executionContext: executionContext,
      ),
      child: _PartnerCreateView(
        partnerType: partnerType,
        onCreated: onCreated,
        onOpenExisting: onOpenExisting,
      ),
    );
  }
}

class _PartnerCreateView extends StatefulWidget {
  const _PartnerCreateView({
    required this.partnerType,
    required this.onCreated,
    required this.onOpenExisting,
  });

  final PartnerType partnerType;
  final ValueChanged<String> onCreated;
  final ValueChanged<String> onOpenExisting;

  @override
  State<_PartnerCreateView> createState() => _PartnerCreateViewState();
}

class _PartnerCreateViewState extends State<_PartnerCreateView> {
  bool _allowPop = false;
  bool _leaveDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PartnerCreateCubit>().state;
    return BlocListener<PartnerCreateCubit, PartnerCreateState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && current.status == PartnerCreateStatus.success,
      listener: (context, state) {
        final partnerId = state.createdPartnerId;
        if (partnerId == null) return;
        widget.onCreated(partnerId);
      },
      child: PopScope<Object?>(
        canPop: _allowPop || !state.isDirty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _requestLeave();
        },
        child: Scaffold(
          key: const Key('wgt_e01_u02_fr02_01'),
          backgroundColor: context.vColors.background,
          appBar: VAppBar(
            title: widget.partnerType == PartnerType.person ? 'Tạo cá nhân' : 'Tạo tổ chức',
            showBackButton: false,
            leading: Padding(
              padding: const EdgeInsets.all(VSpacing.space2),
              child: VIconBox(
                iconData: Icons.arrow_back,
                size: 40,
                backgroundColor: Colors.transparent,
                onTap: _requestLeave,
              ),
            ),
          ),
          body: PartnerCreateForm(
            onCancel: _requestLeave,
            onOpenExisting: widget.onOpenExisting,
          ),
        ),
      ),
    );
  }

  Future<void> _requestLeave() async {
    final state = context.read<PartnerCreateCubit>().state;
    if (!state.isDirty) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    if (_leaveDialogOpen) return;
    _leaveDialogOpen = true;
    await showPartnerLeaveFormDialog(
      context: context,
      onLeave: () {
        setState(() => _allowPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      },
    );
    if (mounted) _leaveDialogOpen = false;
  }
}
