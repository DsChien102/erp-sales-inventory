import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';

class PartnerNoteSection extends StatelessWidget {
  const PartnerNoteSection({super.key});

  @override
  Widget build(BuildContext context) {
    return VTextField(
      key: const Key('input_note'),
      label: 'Ghi chú nội bộ',
      hintText: 'Nhập ghi chú cho nhân viên nội bộ',
      minLines: 4,
      maxLines: 5,
      onChanged: context.read<PartnerCreateCubit>().updateNote,
    );
  }
}
