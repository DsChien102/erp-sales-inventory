import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_presentation/presentation.dart';

class PartnerDetailPage extends StatefulWidget {
  final PartnerItemModel partner;

  const PartnerDetailPage({
    super.key,
    required this.partner,
  });

  @override
  State<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends State<PartnerDetailPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocProvider(
      create: (_) => PartnerDetailCubit(),
      child: Scaffold(
        backgroundColor: dynamicColors.background,
        appBar: VAppBar(
          title: 'Chi tiết KH & NCC',
          actions: [
            PartnerDetailMenu(partner: widget.partner),
          ],
        ),
        body: Column(
          children: [
            PartnerDetailHeader(partner: widget.partner),
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
                  PartnerGeneralInfoTab(partner: widget.partner),
                  const PartnerTransactionHistoryTab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: widget.partner.status == 'Đã xóa' ? null : SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: VButton(
              onPressed: () {
                // TODO: Chỉnh sửa đối tác
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng chỉnh sửa đang phát triển')),
                );
              },
              label: 'Chỉnh sửa',
              leadingIcon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
              variant: VButtonVariant.primary,
            ),
          ),
        ),
      ),
    );
  }
}
