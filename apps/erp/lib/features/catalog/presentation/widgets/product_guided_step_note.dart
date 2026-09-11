import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'product_guided_fields.dart';

class ProductGuidedStepNote extends StatefulWidget {
  const ProductGuidedStepNote({
    super.key,
    required this.state,
  });

  final ProductGuidedCreateState state;

  @override
  State<ProductGuidedStepNote> createState() => _ProductGuidedStepNoteState();
}

class _ProductGuidedStepNoteState extends State<ProductGuidedStepNote> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.note);
  }

  @override
  void didUpdateWidget(covariant ProductGuidedStepNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.note != _controller.text &&
        widget.state.note != oldWidget.state.note) {
      _controller.text = widget.state.note;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final cubit = context.read<ProductGuidedCreateCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductGuidedFields.buildLabel(context, 'Nội dung ghi chú'),
        VTextFormField(
          key: const Key('input_guided_note'),
          controller: _controller,
          maxLines: 4,
          maxLength: 500,
          hintText: 'Ví dụ: Hàng nhập từ NCC A, khách hay hỏi tên cũ ABC...',
          onChanged: (val) {
            cubit.updateNote(val);
          },
        ),
        const VGap.sm(),
        VText(
          'Ghi chú riêng cho bạn. Không hiển thị cho khách hàng.',
          variant: VTextVariant.bodySmall,
          color: dynamicColors.textSecondary,
        ),
      ],
    );
  }
}
