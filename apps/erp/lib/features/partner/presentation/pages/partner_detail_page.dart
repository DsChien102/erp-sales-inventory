import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class PartnerDetailPage extends StatefulWidget {
  const PartnerDetailPage({
    super.key,
    required this.partnerId,
    required this.partnerModule,
    required this.executionContext,
    this.showCreateSuccessToast = false,
  });

  final String partnerId;
  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;
  final bool showCreateSuccessToast;

  @override
  State<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends State<PartnerDetailPage> {
  @override
  void initState() {
    super.initState();
    if (widget.showCreateSuccessToast) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPartnerCreateSuccessToast(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartnerDetailCubit(
        partnerId: widget.partnerId,
        partnerModule: widget.partnerModule,
        executionContext: widget.executionContext,
      )..load(),
      child: Scaffold(
        key: const Key('wgt_partner_detail_page'),
        backgroundColor: context.vColors.background,
        appBar: VAppBar(
          title: 'Hồ sơ KH & NCC',
          actions: [
            VIconBox(
              iconData: Icons.edit_outlined,
              size: 40,
              backgroundColor: Colors.transparent,
              onTap: () {},
            ),
            VIconBox(
              iconData: Icons.more_horiz,
              size: 40,
              backgroundColor: Colors.transparent,
              onTap: () {},
            ),
          ],
        ),
        body: const PartnerDetailView(),
      ),
    );
  }
}
