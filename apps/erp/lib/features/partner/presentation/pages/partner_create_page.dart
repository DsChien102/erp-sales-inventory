import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// Shared create / edit page for partner profile (SG-02).
class PartnerCreatePage extends StatelessWidget {
  const PartnerCreatePage({
    super.key,
    required this.partnerType,
    required this.partnerModule,
    required this.executionContext,
    required this.onCreated,
    required this.onOpenExisting,
  }) : partnerId = null,
       onUpdated = null;

  const PartnerCreatePage.edit({
    super.key,
    required this.partnerId,
    required this.partnerModule,
    required this.executionContext,
    required this.onUpdated,
    required this.onOpenExisting,
  }) : partnerType = PartnerType.person,
       onCreated = null;

  final PartnerType partnerType;
  final String? partnerId;
  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;
  final ValueChanged<String>? onCreated;
  final ValueChanged<String>? onUpdated;
  final ValueChanged<String> onOpenExisting;

  bool get _isEdit => partnerId != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        if (_isEdit) {
          return PartnerCreateCubit.edit(
            partnerId: partnerId!,
            partnerModule: partnerModule,
            executionContext: executionContext,
          )..loadForEdit();
        }
        return PartnerCreateCubit(
          partnerType: partnerType,
          partnerModule: partnerModule,
          executionContext: executionContext,
        );
      },
      child: _PartnerFormView(
        isEdit: _isEdit,
        fallbackPartnerType: partnerType,
        onCreated: onCreated,
        onUpdated: onUpdated,
        onOpenExisting: onOpenExisting,
      ),
    );
  }
}

class _PartnerFormView extends StatefulWidget {
  const _PartnerFormView({
    required this.isEdit,
    required this.fallbackPartnerType,
    required this.onCreated,
    required this.onUpdated,
    required this.onOpenExisting,
  });

  final bool isEdit;
  final PartnerType fallbackPartnerType;
  final ValueChanged<String>? onCreated;
  final ValueChanged<String>? onUpdated;
  final ValueChanged<String> onOpenExisting;

  @override
  State<_PartnerFormView> createState() => _PartnerFormViewState();
}

class _PartnerFormViewState extends State<_PartnerFormView> {
  bool _allowPop = false;
  bool _leaveDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PartnerCreateCubit>().state;
    final titleType = state.isLoading ? widget.fallbackPartnerType : state.partnerType;
    final title = widget.isEdit
        ? (titleType == PartnerType.person ? 'Chỉnh sửa cá nhân' : 'Chỉnh sửa tổ chức')
        : (titleType == PartnerType.person ? 'Tạo cá nhân' : 'Tạo tổ chức');

    return BlocListener<PartnerCreateCubit, PartnerCreateState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && current.status == PartnerCreateStatus.success,
      listener: (context, state) {
        final partnerId = state.createdPartnerId;
        if (partnerId == null) return;
        if (widget.isEdit) {
          widget.onUpdated?.call(partnerId);
        } else {
          widget.onCreated?.call(partnerId);
        }
      },
      child: PopScope<Object?>(
        canPop: _allowPop || !state.isDirty,
        onPopInvokedWithResult: (didPop, _) {
          FocusManager.instance.primaryFocus?.unfocus();
          if (!didPop) _requestLeave();
        },
        child: VPageScaffold(
          key: Key(widget.isEdit ? 'wgt_e01_u03_fr01_01' : 'wgt_e01_u02_fr02_01'),
          title: title,
          showBackButton: false,
          // No padding: the app bar's 56pt leading slot is the tap target.
          leading: VIconBox(
            icon: VIcons.arrowBack,
            semanticLabel: 'Quay lại',
            size: 40,
            backgroundColor: Colors.transparent,
            onTap: _requestLeave,
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
