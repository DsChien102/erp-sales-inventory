import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// S8 — Import giá riêng bằng Excel (US-05 — SG-04).
///
/// SG-04: Bước 3 (Xác nhận) bỏ section "Hiệu lực mặc định cho rule mới".
class PricingImportPage extends StatefulWidget {
  const PricingImportPage({super.key});

  @override
  State<PricingImportPage> createState() => _PricingImportPageState();
}

class _PricingImportPageState extends State<PricingImportPage> {
  late final PriceRuleImportCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PriceRuleImportCubit(
      pricingModule: GetIt.instance<IPricingModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    await _cubit.startImport(fileName: file.name, fileBytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PriceRuleImportCubit, PriceRuleImportState>(
        builder: (context, state) {
          return VPageScaffold(
            key: const Key('wgt_e02_u05_fr01_01'),
            title: 'Nhập từ Excel',
            showBackButton: true,
            body: Column(
              children: [
                PriceRuleImportStepIndicator(step: state.step),
                Expanded(
                  child: PriceRuleImportWizard(
                    cubit: _cubit,
                    state: state,
                    onPickFile: _pickFile,
                    onDownloadTemplate: () => VToast.show(
                      context,
                      title: 'File mẫu',
                      message:
                          'Tải file mẫu sẽ khả dụng khi backend pricing sẵn sàng.',
                      type: VToastType.info,
                    ),
                    onFinish: () => context.pop(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
