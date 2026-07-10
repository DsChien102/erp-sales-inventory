import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

import '../bloc/partner_create_cubit.dart';

class PartnerInvoiceSection extends StatelessWidget {
  const PartnerInvoiceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;
    return Column(
      children: [
        VTextField(
          key: const Key('input_tax_code'),
          label: state.partnerType == PartnerType.person ? 'MST cá nhân' : 'MST',
          keyboardType: TextInputType.number,
          errorText: state.errors['taxCode'],
          onChanged: cubit.updateTaxCode,
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          label: 'Tên xuất hóa đơn',
          onChanged: cubit.updateInvoiceName,
        ),
        const SizedBox(height: VSpacing.space3),
        VEmailField(
          label: 'Email nhận hóa đơn',
          errorText: state.errors['invoiceEmail'],
          onChanged: cubit.updateInvoiceEmail,
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          label: 'Địa chỉ xuất hóa đơn',
          minLines: 2,
          maxLines: 3,
          onChanged: cubit.updateInvoiceAddress,
        ),
        if (state.partnerType == PartnerType.organization && state.taxCode.trim().isEmpty) ...[
          const SizedBox(height: VSpacing.space3),
          _InvoiceWarning(),
        ],
      ],
    );
  }
}

class _InvoiceWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VIcon(
            iconData: Icons.warning_amber_rounded,
            color: VColors.warning,
          ),
          const SizedBox(width: VSpacing.space2),
          Expanded(
            child: Text(
              'Vui lòng kiểm tra lại MST và địa chỉ xuất hóa đơn trước khi lưu.',
              style: VTypography.bodySmall.copyWith(color: VColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
