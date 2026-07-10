import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';

class PartnerDeliverySection extends StatelessWidget {
  const PartnerDeliverySection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    return Column(
      children: [
        VTextField(
          label: 'Tỉnh / Thành phố',
          onChanged: cubit.updateDeliveryProvince,
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          label: 'Xã / Phường',
          onChanged: cubit.updateDeliveryCommune,
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          label: 'Địa chỉ chi tiết',
          minLines: 2,
          maxLines: 3,
          onChanged: cubit.updateDeliveryAddress,
        ),
      ],
    );
  }
}
