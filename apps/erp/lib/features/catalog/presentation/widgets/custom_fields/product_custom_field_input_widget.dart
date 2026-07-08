import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductCustomFieldInputWidget extends StatefulWidget {
  const ProductCustomFieldInputWidget({
    super.key,
    required this.field,
    required this.input,
    required this.onChanged,
    this.errorText,
  });

  final ProductCustomFieldValueFieldDto field;
  final ProductCustomFieldValueInput input;
  final ValueChanged<ProductCustomFieldValueInput> onChanged;
  final String? errorText;

  @override
  State<ProductCustomFieldInputWidget> createState() => _ProductCustomFieldInputWidgetState();
}

class _ProductCustomFieldInputWidgetState extends State<ProductCustomFieldInputWidget> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    if (widget.field.fieldType == CustomFieldType.text.name) {
      _textController = TextEditingController(text: widget.input.textValue);
    } else if (widget.field.fieldType == CustomFieldType.number.name) {
      _textController = TextEditingController(text: widget.input.numberValue?.toString() ?? '');
    } else {
      _textController = TextEditingController();
    }
  }

  @override
  void didUpdateWidget(covariant ProductCustomFieldInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync external changes if needed
    if (widget.field.fieldType == CustomFieldType.text.name && widget.input.textValue != oldWidget.input.textValue) {
      if (_textController.text != widget.input.textValue) {
        _textController.text = widget.input.textValue ?? '';
      }
    } else if (widget.field.fieldType == CustomFieldType.number.name && widget.input.numberValue != oldWidget.input.numberValue) {
      final newVal = widget.input.numberValue?.toString() ?? '';
      if (_textController.text != newVal) {
        _textController.text = newVal;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: _buildInputContent(context),
    );
  }

  Widget _buildInputContent(BuildContext context) {
    if (widget.field.fieldType == CustomFieldType.text.name) {
      return VTextField(
        label: widget.field.name,
        isRequired: widget.field.isRequired,
        controller: _textController,
        errorText: widget.errorText,
        enabled: widget.field.isActive,
        onChanged: (val) {
          widget.onChanged(ProductCustomFieldValueInput(
            fieldId: widget.field.fieldId,
            textValue: val,
          ));
        },
      );
    } else if (widget.field.fieldType == CustomFieldType.number.name) {
      return VTextField(
        label: widget.field.name,
        isRequired: widget.field.isRequired,
        controller: _textController,
        errorText: widget.errorText,
        enabled: widget.field.isActive,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        onChanged: (val) {
          final parsed = double.tryParse(val);
          widget.onChanged(ProductCustomFieldValueInput(
            fieldId: widget.field.fieldId,
            numberValue: parsed,
            textValue: val.isNotEmpty && parsed == null ? val : null,
          ));
        },
      );
    } else if (widget.field.fieldType == CustomFieldType.singleSelect.name) {
      return VDropdown<String>(
        label: widget.field.name,
        value: widget.input.optionId,
        hintText: '— Chọn —',
        enabled: widget.field.isActive,
        items: widget.field.options.map((opt) {
          return DropdownMenuItem<String>(
            value: opt.optionId,
            child: Text(opt.label),
          );
        }).toList(),
        onChanged: (val) {
          widget.onChanged(ProductCustomFieldValueInput(
            fieldId: widget.field.fieldId,
            optionId: val,
          ));
        },
      );
    } else if (widget.field.fieldType == CustomFieldType.boolean.name) {
      return VSwitch(
        label: widget.field.name + (widget.field.isRequired ? ' *' : ''),
        value: widget.input.booleanValue ?? false,
        onChanged: widget.field.isActive
            ? (val) {
                widget.onChanged(ProductCustomFieldValueInput(
                  fieldId: widget.field.fieldId,
                  booleanValue: val,
                ));
              }
            : null,
      );
    } else if (widget.field.fieldType == CustomFieldType.date.name) {
      return VDatePickerField(
        label: widget.field.name,
        required: widget.field.isRequired,
        value: widget.input.dateValue,
        onTap: () async {
          if (!widget.field.isActive) return;
          final date = await showDatePicker(
            context: context,
            initialDate: widget.input.dateValue ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            widget.onChanged(ProductCustomFieldValueInput(
              fieldId: widget.field.fieldId,
              dateValue: date,
            ));
          }
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
