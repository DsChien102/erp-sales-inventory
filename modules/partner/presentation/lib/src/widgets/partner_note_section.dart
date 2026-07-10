import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';
import 'partner_compact_field.dart';

class PartnerNoteSection extends StatelessWidget {
  const PartnerNoteSection({super.key});

  static const int maxNoteLength = 500;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final note = context.watch<PartnerCreateCubit>().state.note;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.space4,
        0,
        VSpacing.space4,
        VSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ghi chú nội bộ',
            style: VTypography.bodySmall.copyWith(
              color: context.vColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          Stack(
            children: [
              PartnerCompactMultilineTextField(
                key: const Key('input_note'),
                initialValue: note,
                minLines: 4,
                maxLines: 6,
                maxLength: maxNoteLength,
                onChanged: cubit.updateNote,
              ),
              Positioned(
                right: 12,
                bottom: 10,
                child: IgnorePointer(
                  child: Text(
                    '${note.length}/$maxNoteLength',
                    style: VTypography.bodySmall.copyWith(
                      color: context.vColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
