import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../../core/di/injection.dart';
import 'partner_edit_page.dart';

class PartnerDetailPage extends StatefulWidget {
  final String partnerId;
  final PartnerItemModel? initialPartner;
  final WidgetBuilder? editPageBuilder;

  const PartnerDetailPage({
    super.key,
    required this.partnerId,
    this.initialPartner,
    this.editPageBuilder,
  });

  @override
  State<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends State<PartnerDetailPage> {
  int _selectedIndex = 0;
  bool _hasPartnerChanges = false;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocProvider(
      create: (_) => PartnerDetailCubit(
        partnerModule: getIt<IPartnerModule>(),
        executionContext: getIt<IExecutionContext>(),
        initialPartner: widget.initialPartner,
      )..load(widget.partnerId),
      child: BlocConsumer<PartnerDetailCubit, PartnerDetailState>(
        listenWhen: (previous, current) =>
            previous.status != current.status && current.status == PartnerDetailStatus.failure,
        listener: (context, state) {
          if (state.errorMessage != null) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: state.errorMessage!,
              type: VToastType.danger,
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state.status == PartnerDetailStatus.loading && state.partner == null) {
            return Scaffold(
              backgroundColor: dynamicColors.background,
              appBar: const VAppBar(title: 'Chi tiết KH & NCC'),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final partner = state.partner;
          if (partner == null) {
            return Scaffold(
              backgroundColor: dynamicColors.background,
              appBar: const VAppBar(title: 'Chi tiết KH & NCC'),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: dynamicColors.background,
            appBar: VAppBar(
              title: 'Chi tiết KH & NCC',
              leading: Navigator.of(context).canPop()
                  ? IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: dynamicColors.textPrimary,
                      ),
                      onPressed: () => _popWithRefreshResult(context),
                    )
                  : null,
              actions: [
                PartnerDetailMenu(partner: partner),
              ],
            ),
            body: Column(
              children: [
                PartnerDetailHeader(partner: partner),
                VTabs(
                  tabs: const ['Thông tin chung', 'Lịch sử giao dịch'],
                  selectedIndex: _selectedIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      PartnerGeneralInfoTab(partner: partner),
                      const PartnerTransactionHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: partner.status == 'Đã xóa'
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(VSpacing.space4),
                      child: VButton(
                        onPressed: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder:
                                  widget.editPageBuilder ??
                                  (_) => PartnerEditPage(
                                    partnerId: partner.id,
                                    initialPartner: partner,
                                  ),
                            ),
                          );
                          if (updated == true && context.mounted) {
                            _hasPartnerChanges = true;
                            await context.read<PartnerDetailCubit>().load(widget.partnerId);
                          }
                        },
                        label: 'Chỉnh sửa',
                        leadingIcon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                        variant: VButtonVariant.primary,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  void _popWithRefreshResult(BuildContext context) {
    Navigator.of(context).pop(_hasPartnerChanges ? true : null);
  }
}
