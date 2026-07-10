import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import '../widgets/partner_contact_empty_illustration.dart';

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
        message: isEdit
            ? 'Cập nhật người liên hệ thành công'
            : 'Thêm người liên hệ thành công',
        type: VToastType.success,
      );
    }
  }

  void _showAddMethodSheet(BuildContext context) {
    showModalBottomSheet<AddContactMethod>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const PartnerContactAddMethodSheet(),
    ).then((method) {
      if (!context.mounted || method == null) return;
      
      switch (method) {
        case AddContactMethod.createNew:
          _openContactForm(
            path: '/partner/${widget.partnerId}/contacts/new',
            isEdit: false,
          );
          break;
        case AddContactMethod.selectExisting:
          final excludeIds = _cubit.state is PartnerContactsLoaded
              ? (_cubit.state as PartnerContactsLoaded).organization.contacts.map((c) => c.personPartnerId).toList()
              : <String>[];
          context.push('/partner/${widget.partnerId}/contacts/select', extra: excludeIds).then((result) {
            if (!context.mounted || result == null) return;
            if (result is List) {
              final ids = result.map((e) {
                final map = e as Map;
                return map['personPartnerId'] as String;
              }).toList();
              _cubit.addExistingContacts(ids).then((_) {
                if (!mounted) return;
                VToast.show(
                  context,
                  title: 'Thành công',
                  message: 'Thêm người liên hệ thành công',
                  type: VToastType.success,
                );
              });
            }
          });
          break;
      }
    });
  }

  void _showActionSheet(BuildContext context, PartnerContactDto contact) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PartnerContactActionSheet(
        contact: contact,
        onActionSelected: (action) {
          switch (action) {
            case PartnerContactAction.edit:
              _openContactForm(
                path:
                    '/partner/${widget.partnerId}/contacts/${contact.personPartnerId}/edit',
                extra: contact,
                isEdit: true,
              );
              break;
            case PartnerContactAction.setPrimary:
              _confirmChangePrimary(context, contact);
              break;
            case PartnerContactAction.remove:
              _confirmRemove(context, contact);
              break;
          }
        },
      ),
    );
  }

  void _confirmChangePrimary(BuildContext context, PartnerContactDto contact) {
    final state = _cubit.state;
    if (state is! PartnerContactsLoaded) return;

    final currentPrimary = state.organization.contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => contact,
    );

    showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PartnerContactChangePrimaryDialog(
        currentPrimaryName: currentPrimary.displayName,
        newPrimaryName: contact.displayName,
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        await _cubit.setPrimaryContact(contact.personPartnerId);
        if (!mounted) return;
        VToast.show(
          context,
          title: 'Thành công',
          message: 'Đã đặt người liên hệ chính',
          type: VToastType.success,
        );
      }
    });
  }

  void _confirmRemove(BuildContext context, PartnerContactDto contact) {
    showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PartnerContactRemoveDialog(),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        await _cubit.removeContact(contact.personPartnerId);
        if (!mounted) return;
        VToast.show(
          context,
          title: 'Thành công',
          message: 'Đã gỡ người liên hệ',
          type: VToastType.success,
        );
      }
    });
  }

  Color _getAvatarColor(String displayName) {
    final palette = [
      VColors.success,
      VColors.warning,
      VColors.info,
      VColors.primary,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    int sum = 0;
    for (int i = 0; i < displayName.length; i++) {
      sum += displayName.codeUnitAt(i);
    }
    return palette[sum % palette.length];
  }

  String _getInitials(String displayName) {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }
    final first = words.first[0].toUpperCase();
    final last = words.last[0].toUpperCase();
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: VAppBar(
          title: 'Người liên hệ',
          centerTitle: true,
          showBackButton: true,
          actions: [
            IconButton(
              icon: Icon(Icons.more_horiz, color: colors.textPrimary),
              onPressed: () {},
            ),
          ],
        ),
        floatingActionButton: BlocBuilder<PartnerContactsCubit, PartnerContactsState>(
          builder: (context, state) {
            if (state is PartnerContactsLoaded) {
              return VFloatingActionButton(
                key: const Key('btn_add_contact_fab'),
                onTap: () => _showAddMethodSheet(context),
                iconData: Icons.add,
              );
            }
            return const SizedBox();
          },
        ),
        body: BlocBuilder<PartnerContactsCubit, PartnerContactsState>(
          builder: (context, state) {
            if (state is PartnerContactsLoading || state is PartnerContactsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PartnerContactsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, color: colors.danger, size: 48),
                      const SizedBox(height: VSpacing.space3),
                      Text(
                        state.isNoPermission
                            ? 'Không có quyền quản lý người liên hệ'
                            : 'Đã xảy ra lỗi',
                        style: VTypography.headingH3.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: VSpacing.space2),
                      Text(
                        state.isNoPermission
                            ? 'Bạn không có quyền xem hoặc thay đổi người liên hệ của tổ chức này.'
                            : state.message,
                        style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: VSpacing.space4),
                      VButton(
                        label: 'Quay lại',
                        variant: VButtonVariant.outline,
                        foregroundColor: colors.success,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is PartnerContactsLoaded) {
              final org = state.organization;
              final filtered = state.filteredContacts;
              final roles = org.roles.contains(PartnerRoleType.customer) && org.roles.contains(PartnerRoleType.supplier)
                  ? 'KH & NCC'
                  : (org.roles.contains(PartnerRoleType.customer) ? 'Khách hàng' : 'Nhà cung cấp');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Org Context Header Banner Card (UI-02)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VSpacing.space4,
                      VSpacing.space4,
                      VSpacing.space4,
                      VSpacing.space2,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(VSpacing.space4),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(VRadius.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            org.displayName,
                            style: VTypography.headingH3.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tổ chức • $roles',
                            style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (org.contacts.isEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(VSpacing.space4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const PartnerContactEmptyIllustration(),
                            const SizedBox(height: VSpacing.space6),
                            Text(
                              'Chưa có người liên hệ',
                              style: VTypography.headingH3.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: VSpacing.space2),
                            Text(
                              'Thêm người liên hệ để liên kết làm việc\nvới tổ chức này.',
                              style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: VSpacing.space5),
                            VButton(
                              label: 'Gợi ý thêm người liên hệ',
                              variant: VButtonVariant.outline,
                              foregroundColor: colors.success,
                              onPressed: () => _showAddMethodSheet(context),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(VSpacing.space4),
                      child: VSearchBar(
                        key: const Key('input_contact_search'),
                        hintText: 'Tìm kiếm người liên hệ',
                        onChanged: _cubit.searchContacts,
                      ),
                    ),
                    
                    // Contacts Count Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                      child: Text(
                        '${filtered.length} người liên hệ',
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: VSpacing.space2),

                    // List
                    Expanded(
                      child: ListView.separated(
                        key: const Key('list_contacts_view'),
                        padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(color: colors.borderDefault, height: 1),
                        itemBuilder: (context, index) {
                          final contact = filtered[index];
                          return InkWell(
                            onTap: () => _showActionSheet(context, contact),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: _getAvatarColor(contact.displayName),
                                    child: Text(
                                      _getInitials(contact.displayName),
                                      style: VTypography.bodyDefault.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: VSpacing.space3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                contact.displayName,
                                                style: VTypography.bodyDefault.copyWith(
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (contact.isPrimary) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: colors.success.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Chính',
                                                  style: VTypography.bodySmall.copyWith(
                                                    color: colors.success,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (contact.contactRole != null && contact.contactRole!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            contact.contactRole!,
                                            style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                                          ),
                                        ],
                                        if (contact.phone != null && contact.phone!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            contact.phone!,
                                            style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                                          ),
                                        ],
                                        if (contact.email != null && contact.email!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            contact.email!,
                                            style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
