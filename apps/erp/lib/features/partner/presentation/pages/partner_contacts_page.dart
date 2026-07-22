import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../widgets/partner_contacts_error_body.dart';
import '../widgets/partner_contacts_loaded_body.dart';

class PartnerContactsPage extends StatefulWidget {
  const PartnerContactsPage({
    super.key,
    required this.partnerId,
    required this.partnerModule,
    required this.executionContext,
  });

  final String partnerId;
  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;

  @override
  State<PartnerContactsPage> createState() => _PartnerContactsPageState();
}

class _PartnerContactsPageState extends State<PartnerContactsPage> {
  late final PartnerContactsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PartnerContactsCubit(
      partnerModule: widget.partnerModule,
      executionContext: widget.executionContext,
    )..loadContacts(widget.partnerId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openContactForm({
    required String path,
    Object? extra,
    required bool isEdit,
  }) async {
    final result = await context.push<Object?>(path, extra: extra);
    if (!mounted) return;
    await _cubit.loadContacts(widget.partnerId);
    if (!mounted) return;
    if (result == true) {
      VToast.show(
        context,
        title: 'Thành công',
        message: isEdit ? 'Cập nhật người liên hệ thành công' : 'Thêm người liên hệ thành công',
        type: VToastType.success,
      );
    }
  }

  Future<void> _showAddMethodSheet() async {
    final method = await showPartnerContactAddMethodSheet(context);
    if (!mounted || method == null) return;

    switch (method) {
      case AddContactMethod.createNew:
        await _openContactForm(
          path: '/partner/${widget.partnerId}/contacts/new',
          isEdit: false,
        );
      case AddContactMethod.selectExisting:
        final excludeIds = _cubit.state is PartnerContactsLoaded
            ? (_cubit.state as PartnerContactsLoaded).organization.contacts
                  .map((c) => c.personPartnerId)
                  .toList()
            : <String>[];
        final result = await context.push<Object?>(
          '/partner/${widget.partnerId}/contacts/select',
          extra: excludeIds,
        );
        if (!mounted || result == null || result is! List) return;
        final ids = result.map((e) {
          final map = e as Map;
          return map['personPartnerId'] as String;
        }).toList();
        await _cubit.addExistingContacts(ids);
        if (!mounted) return;
        VToast.show(
          context,
          title: 'Thành công',
          message: 'Thêm người liên hệ thành công',
          type: VToastType.success,
        );
    }
  }

  Future<void> _showActionSheet(PartnerContactDto contact) async {
    final action = await showPartnerContactActionSheet(
      context,
      contact: contact,
    );
    if (!mounted || action == null) return;

    switch (action) {
      case PartnerContactAction.edit:
        await _openContactForm(
          path: '/partner/${widget.partnerId}/contacts/${contact.personPartnerId}/edit',
          extra: contact,
          isEdit: true,
        );
      case PartnerContactAction.setPrimary:
        await _confirmChangePrimary(contact);
      case PartnerContactAction.remove:
        await _confirmRemove(contact);
    }
  }

  Future<void> _confirmChangePrimary(PartnerContactDto contact) async {
    final state = _cubit.state;
    if (state is! PartnerContactsLoaded) return;

    final currentPrimary = state.organization.contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => contact,
    );

    final confirmed = await showPartnerContactChangePrimaryDialog(
      context,
      currentPrimaryName: currentPrimary.displayName,
      newPrimaryName: contact.displayName,
    );
    if (confirmed != true || !mounted) return;
    await _cubit.setPrimaryContact(contact.personPartnerId);
    if (!mounted) return;
    VToast.show(
      context,
      title: 'Thành công',
      message: 'Đã đặt người liên hệ chính',
      type: VToastType.success,
    );
  }

  Future<void> _confirmRemove(PartnerContactDto contact) async {
    final confirmed = await showPartnerContactRemoveDialog(context);
    if (confirmed != true || !mounted) return;
    await _cubit.removeContact(contact.personPartnerId);
    if (!mounted) return;
    VToast.show(
      context,
      title: 'Thành công',
      message: 'Đã gỡ người liên hệ',
      type: VToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: VPageScaffold(
        title: 'Người liên hệ',
        centerTitle: true,
        actions: [
          IconButton(
            icon: VIcon(icon: VIcons.moreHoriz, color: context.vColors.textPrimary),
            onPressed: () {},
          ),
        ],
        floatingActionButton: BlocBuilder<PartnerContactsCubit, PartnerContactsState>(
          builder: (context, state) {
            if (state is PartnerContactsLoaded) {
              return VFloatingActionButton(
                key: const Key('btn_add_contact_fab'),
                onTap: _showAddMethodSheet,
                icon: VIcons.add,
              );
            }
            return const SizedBox.shrink();
          },
        ),
        body: BlocBuilder<PartnerContactsCubit, PartnerContactsState>(
          builder: (context, state) {
            if (state is PartnerContactsLoading || state is PartnerContactsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PartnerContactsError) {
              return PartnerContactsErrorBody(
                isNoPermission: state.isNoPermission,
                message: state.message,
              );
            }

            if (state is PartnerContactsLoaded) {
              return PartnerContactsLoadedBody(
                organization: state.organization,
                filteredContacts: state.filteredContacts,
                onSearch: _cubit.searchContacts,
                onAddContact: _showAddMethodSheet,
                onContactTap: _showActionSheet,
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
