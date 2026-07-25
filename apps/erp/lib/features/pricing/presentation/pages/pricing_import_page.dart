import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../services/pricing_import_file_service.dart';
import '../widgets/pricing_import_cancel_dialog.dart';

/// S8 — Import giá riêng bằng Excel (US-05 — SG-04).
///
/// SG-04: Bước 3 (Xác nhận) bỏ section "Hiệu lực mặc định cho rule mới".
class PricingImportPage extends StatefulWidget {
  const PricingImportPage({
    super.key,
    this.fileService = const DevicePricingImportFileService(),
  });

  final PricingImportFileService fileService;

  @override
  State<PricingImportPage> createState() => _PricingImportPageState();
}

class _PricingImportPageState extends State<PricingImportPage> {
  late final PriceRuleImportCubit _cubit;
  bool _isDownloadingTemplate = false;
  bool _isDownloadingLog = false;
  bool _isCanceling = false;
  bool _allowPop = false;
  bool _isDragOver = false;
  String? _invalidDroppedFileName;

  @override
  void initState() {
    super.initState();
    _cubit = PriceRuleImportCubit(
      pricingModule: GetIt.instance<IPricingModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    );
    _cubit.checkAccess();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  bool _canAcceptDrop(PriceRuleImportState state) =>
      state is PriceRuleImportInitial || state is PriceRuleImportFileSelected;

  Future<void> _pickFile() async {
    try {
      final file = await widget.fileService.pickXlsx();
      if (file == null) return;
      setState(() => _invalidDroppedFileName = null);
      _cubit.selectFile(fileName: file.name, fileBytes: file.bytes);
    } catch (_) {
      if (!mounted) return;
      VToast.show(
        context,
        title: 'Không thể đọc file',
        message: 'Hệ thống không thể truy cập file đã chọn. Vui lòng thử lại.',
        type: VToastType.danger,
      );
    }
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    if (!_canAcceptDrop(_cubit.state) || files.isEmpty) return;

    final file = files.first;
    final name = file.name;
    if (!name.toLowerCase().endsWith('.xlsx')) {
      if (!mounted) return;
      setState(() => _invalidDroppedFileName = name);
      VToast.show(
        context,
        title: 'File không hợp lệ',
        message: 'Chỉ chấp nhận file Excel định dạng .xlsx.',
        type: VToastType.danger,
      );
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _invalidDroppedFileName = null);
      _cubit.selectFile(fileName: name, fileBytes: bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _invalidDroppedFileName = name);
      VToast.show(
        context,
        title: 'Không thể đọc file',
        message: 'Hệ thống không thể đọc file đã thả. Vui lòng thử lại.',
        type: VToastType.danger,
      );
    }
  }

  void _clearFile() {
    setState(() => _invalidDroppedFileName = null);
    _cubit.clearSelectedFile();
  }

  Future<void> _continueWithFile() async {
    await _cubit.continueWithSelectedFile();
  }

  Future<void> _downloadImportLog() async {
    if (_isDownloadingLog) return;

    setState(() => _isDownloadingLog = true);
    try {
      final rows = await _cubit.loadRowsForImportLog();
      if (rows.isEmpty) {
        if (!mounted) return;
        VToast.show(
          context,
          title: 'Không có nhật ký để tải',
          message: 'Không tìm thấy dữ liệu dòng nhập để xuất file.',
          type: VToastType.warning,
        );
        return;
      }
      final bytes = widget.fileService.buildImportLogXlsx(rows: rows);
      final batchId = _cubit.currentImportId ?? 'import';
      final saved = await widget.fileService.saveImportLog(
        fileName: 'import_log_$batchId.xlsx',
        bytes: bytes,
      );
      if (!mounted || !saved) return;
      VToast.show(
        context,
        title: 'Đã tải nhật ký nhập',
        message: 'import_log_$batchId.xlsx',
        type: VToastType.success,
      );
    } catch (_) {
      if (!mounted) return;
      VToast.show(
        context,
        title: 'Không thể tải nhật ký',
        message: 'Vui lòng thử lại.',
        type: VToastType.danger,
      );
    } finally {
      if (mounted) setState(() => _isDownloadingLog = false);
    }
  }

  Future<void> _downloadTemplate() async {
    if (_isDownloadingTemplate) return;
    setState(() => _isDownloadingTemplate = true);
    try {
      final template = await _cubit.loadTemplate();
      final saved = await widget.fileService.saveTemplate(template);
      if (!mounted || !saved) return;
      VToast.show(
        context,
        title: 'Đã tải file mẫu',
        message: template.fileName,
        type: VToastType.success,
      );
    } on PricingBlockedException catch (error) {
      if (!mounted) return;
      final denied = error.code == PricingBlockedCodes.noPermission;
      VToast.show(
        context,
        title: denied ? 'Không có quyền tải file mẫu' : 'Không thể tải file mẫu',
        message: denied
            ? 'Bạn không có quyền nhập giá riêng.'
            : 'Máy chủ từ chối yêu cầu. Vui lòng thử lại.',
        type: VToastType.danger,
      );
    } catch (_) {
      if (!mounted) return;
      VToast.show(
        context,
        title: 'Không thể lưu file mẫu',
        message: 'Vui lòng kiểm tra quyền truy cập tệp và thử lại.',
        type: VToastType.danger,
      );
    } finally {
      if (mounted) setState(() => _isDownloadingTemplate = false);
    }
  }

  Future<void> _requestCancel({required bool popAfterCancel}) async {
    if (_isCanceling) return;
    if (!_cubit.hasCancelableBatch) {
      if (popAfterCancel) {
        if (context.canPop()) context.pop();
      } else {
        _cubit.backToChooseFile();
      }
      return;
    }

    final confirmed = await showPricingImportCancelDialog(context);
    if (!mounted || !confirmed) return;
    setState(() => _isCanceling = true);
    final errorCode = await _cubit.cancelCurrentImport();
    if (!mounted) return;
    setState(() => _isCanceling = false);
    if (errorCode != null) {
      VToast.show(
        context,
        title: 'Không thể hủy lần nhập',
        message: errorCode == PricingBlockedCodes.stateChanged
            ? 'Lô dữ liệu đã thay đổi. Vui lòng tải lại và thử lại.'
            : 'Lô dữ liệu vẫn được giữ nguyên. Vui lòng thử lại.',
        type: VToastType.danger,
      );
      return;
    }
    if (popAfterCancel && context.canPop()) {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.canPop()) context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PriceRuleImportCubit, PriceRuleImportState>(
        builder: (context, state) {
          final hideSteps = switch (state) {
            PriceRuleImportNoPermission() => true,
            // Kết quả + xem lại từ kết quả: ẩn VSteps.
            PriceRuleImportResult() => true,
            PriceRuleImportPreview(:final readOnly) => readOnly,
            PriceRuleImportLoading(:final step) =>
              step == PriceRuleImportStep.chooseFile ||
                  step == PriceRuleImportStep.result,
            _ => false,
          };
          final acceptDrop = _canAcceptDrop(state);

          return PopScope<Object?>(
            canPop: _allowPop || !_cubit.hasCancelableBatch,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _requestCancel(popAfterCancel: true);
            },
            child: VPageScaffold(
              key: const Key('wgt_e02_u05_fr01_01'),
              title: 'Nhập giá nhớ',
              showBackButton: true,
              body: DropTarget(
                enable: acceptDrop,
                onDragEntered: (_) {
                  if (acceptDrop) setState(() => _isDragOver = true);
                },
                onDragExited: (_) {
                  if (_isDragOver) setState(() => _isDragOver = false);
                },
                onDragDone: (detail) async {
                  if (_isDragOver) setState(() => _isDragOver = false);
                  await _handleDroppedFiles(detail.files);
                },
                child: Column(
                  children: [
                    if (!hideSteps)
                      PriceRuleImportStepIndicator(step: state.step),
                    Expanded(
                      child: PriceRuleImportWizard(
                        cubit: _cubit,
                        state: state,
                        onPickFile: _pickFile,
                        onContinue: _continueWithFile,
                        onClearFile: _clearFile,
                        onDownloadTemplate: _downloadTemplate,
                        isDownloadingTemplate: _isDownloadingTemplate,
                        isDragOver: acceptDrop && _isDragOver,
                        isFileInvalid: _invalidDroppedFileName != null,
                        invalidFileName: _invalidDroppedFileName,
                        onDownloadLog: _downloadImportLog,
                        isDownloadingLog: _isDownloadingLog,
                        onBackToChooseFile: () =>
                            _requestCancel(popAfterCancel: false),
                        onFinish: () => context.pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
