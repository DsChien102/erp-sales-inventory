import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../services/file_invoice_document_exporter.dart';
import '../services/i_invoice_document_exporter.dart';
import '../services/i_invoice_viewer_launcher.dart';
import '../services/url_invoice_viewer_launcher.dart';
import '../support/order_einvoice_idempotency_key_factory.dart';
import 'order_einvoice_state.dart';

class OrderEInvoiceCubit extends Cubit<OrderEInvoiceState> {
  OrderEInvoiceCubit({
    required String salesOrderId,
    required int orderVersion,
    required OrderInvoiceProjectionDto initialProjection,
    IssuanceReadinessDto? initialReadiness,
    bool isBuyerNotReady = false,
    required IExecutionContext executionContext,
    required IModuleMediator mediator,
    IInvoiceViewerLauncher? viewerLauncher,
    IInvoiceDocumentExporter? documentExporter,
    OrderEInvoiceIdempotencyKeyFactory idempotencyKeyFactory =
        const OrderEInvoiceIdempotencyKeyFactory(),
  }) : _executionContext = executionContext,
       _mediator = mediator,
       _viewerLauncher = viewerLauncher ?? const UrlInvoiceViewerLauncher(),
       _documentExporter = documentExporter ?? const FileInvoiceDocumentExporter(),
       _idempotencyKeys = idempotencyKeyFactory,
       super(
         OrderEInvoiceState(
           salesOrderId: salesOrderId,
           orderVersion: orderVersion,
           projection: initialProjection,
           readiness: initialReadiness,
           isBuyerNotReady: isBuyerNotReady,
         ),
       );

  final IExecutionContext _executionContext;
  final IModuleMediator _mediator;
  final IInvoiceViewerLauncher _viewerLauncher;
  final IInvoiceDocumentExporter _documentExporter;
  final OrderEInvoiceIdempotencyKeyFactory _idempotencyKeys;

  /// Triggered when user confirms issue/retry action on UI.
  Future<void> issueOrRetry() async {
    final currentState = state;
    emit(currentState.copyWith(status: OrderEInvoiceStatus.submitting));

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final key = _idempotencyKeys.next();

      if (currentState.projection.issuanceDisplayState == IssuanceDisplayState.failed) {
        // Retry from failed
        await _mediator.executeCommandAsync(
          RetryIssuanceCommand(
            tenantId: tenantId,
            actorId: actorId,
            salesOrderId: currentState.salesOrderId,
            expectedOrderVersion: currentState.orderVersion,
            idempotencyKey: key,
          ),
        );
      } else {
        // Normal issue
        await _mediator.executeCommandAsync(
          IssueInvoiceCommand(
            tenantId: tenantId,
            actorId: actorId,
            salesOrderId: currentState.salesOrderId,
            sourceVersion: currentState.orderVersion.toString(),
            idempotencyKey: key,
          ),
        );
      }

      emit(state.toProcessing());
      await refresh();
    } catch (e) {
      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.error,
          errorMessage: _humanFriendlyError(e),
        ),
      );
    }
  }

  /// Alias for issueOrRetry for explicit issue action.
  Future<void> issueNow() => issueOrRetry();

  /// Projection and readiness refresh.
  Future<void> refresh() async {
    if (isClosed || !state.isPageActive) {
      return;
    }

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final updatedProjection = await _mediator.executeQueryAsync(
        GetOrderInvoiceProjectionQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.salesOrderId,
        ),
      );

      IssuanceReadinessDto? updatedReadiness;
      try {
        updatedReadiness = await _mediator.executeQueryAsync(
          GetIssuanceReadinessQuery(
            tenantId: tenantId,
            actorId: actorId,
            salesOrderId: state.salesOrderId,
          ),
        );
      } catch (_) {
        // Ignore readiness query error
      }

      final template = await _loadIssuanceTemplateDisplay(
        tenantId: tenantId,
        actorId: actorId,
      );

      if (isClosed || !state.isPageActive) return;
      emit(
        state.copyWith(
          status: state.status == OrderEInvoiceStatus.submitting
              ? OrderEInvoiceStatus.idle
              : null,
          projection: updatedProjection,
          readiness: updatedReadiness ?? state.readiness,
          templateNumber: template.number,
          templateSymbol: template.symbol,
          authorityMode: template.authority,
          clearError: true,
        ),
      );
    } catch (_) {
      // Ignore poll/refresh failures silently
    }
  }

  /// Loads the configured MISA template (serial/symbol) for confirmation UI.
  /// Best-effort: missing manage_configuration simply leaves existing values.
  Future<void> ensureIssuanceTemplateDisplay() async {
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final template = await _loadIssuanceTemplateDisplay(
        tenantId: tenantId,
        actorId: actorId,
      );
      emit(
        state.copyWith(
          templateNumber: template.number,
          templateSymbol: template.symbol,
          authorityMode: template.authority,
        ),
      );
    } catch (_) {
      // Keep prior display values.
    }
  }

  Future<({String number, String symbol, String authority})> _loadIssuanceTemplateDisplay({
    required String tenantId,
    required String actorId,
  }) async {
    IssuanceProfileDto? profile;
    List<ProviderTemplateDto> templates = const [];
    try {
      profile = await _mediator.executeQueryAsync(
        GetIssuanceProfileQuery(tenantId: tenantId, actorId: actorId),
      );
    } catch (_) {}
    try {
      templates = await _mediator.executeQueryAsync(
        ListProviderTemplatesQuery(tenantId: tenantId, actorId: actorId),
      );
    } catch (_) {}

    ProviderTemplateDto? selected;
    final templateId = profile?.templateId;
    if (templateId != null && templateId.isNotEmpty) {
      for (final item in templates) {
        if (item.templateId == templateId) {
          selected = item;
          break;
        }
      }
    }
    if (selected == null) {
      for (final item in templates) {
        final hasSymbol = item.symbol != null && item.symbol!.trim().isNotEmpty;
        final hasSerial = item.serial != null && item.serial!.trim().isNotEmpty;
        if (hasSymbol || hasSerial) {
          selected = item;
          break;
        }
      }
    }
    selected ??= templates.isEmpty ? null : templates.first;

    final symbol = selected?.symbol?.trim();
    final serial = selected?.serial?.trim();
    return (
      number: (serial != null && serial.isNotEmpty) ? serial : '—',
      symbol: (symbol != null && symbol.isNotEmpty)
          ? symbol
          : ((serial != null && serial.isNotEmpty) ? serial : '—'),
      authority: _authorityModeLabel(profile?.signingMethod),
    );
  }

  static String _authorityModeLabel(SigningMethod? method) {
    return switch (method) {
      SigningMethod.hsm => 'Có mã CQT',
      SigningMethod.mtt => 'Máy tính tiền',
      SigningMethod.noSign => 'Không ký',
      null => '—',
    };
  }

  /// Requests preview, polls for readiness if needed, and launches viewer.
  ///
  /// Default poll window is ~45s (45 × 1s) so MISA unpublished preview can
  /// finish before the UI surfaces a false "not ready" error. Concurrent taps
  /// while [OrderEInvoiceStatus.previewing] are ignored. A previous
  /// [OrderEInvoiceState.previewViewerUrl] is kept until a new URL arrives.
  Future<String?> requestPreview({
    int maxPollAttempts = 45,
    Duration pollDelay = const Duration(seconds: 1),
  }) async {
    if (state.status == OrderEInvoiceStatus.previewing) {
      return null;
    }

    emit(
      state.copyWith(
        status: OrderEInvoiceStatus.previewing,
        clearError: true,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      final result = await _mediator.executeCommandAsync(
        RequestInvoicePreviewCommand(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.salesOrderId,
          expectedOrderVersion: state.orderVersion,
        ),
      );

      var viewerUrl = _nonEmptyViewerRef(result.viewerRef);
      if (viewerUrl == null) {
        var delay = pollDelay;
        for (var i = 0; i < maxPollAttempts; i++) {
          await Future<void>.delayed(delay);
          try {
            final preview = await _mediator.executeQueryAsync(
              GetInvoicePreviewQuery(
                tenantId: tenantId,
                actorId: actorId,
                salesOrderId: state.salesOrderId,
              ),
            );
            viewerUrl = _nonEmptyViewerRef(preview.viewerRef);
            if (viewerUrl != null) {
              break;
            }
          } catch (_) {
            // Transient poll failures should not abort the window.
          }
          // Mild backoff: 1s → 1.25s → … capped at 2s (skip when delay is 0 in tests).
          if (delay > Duration.zero) {
            final nextMs = (delay.inMilliseconds + 250).clamp(
              pollDelay.inMilliseconds,
              2000,
            );
            delay = Duration(milliseconds: nextMs);
          }
        }
      }

      if (viewerUrl != null) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.idle,
            previewViewerUrl: viewerUrl,
            clearError: true,
          ),
        );
        await _viewerLauncher.launch(viewerUrl);
        return viewerUrl;
      }

      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.error,
          errorMessage: 'Xem trước hóa đơn chưa sẵn sàng. Vui lòng thử lại sau ít giây.',
        ),
      );
      return null;
    } catch (e) {
      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.error,
          errorMessage: _humanFriendlyError(e),
        ),
      );
      return null;
    }
  }

  static String? _nonEmptyViewerRef(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  /// Opens the official signed invoice viewer, polling while the worker builds it.
  Future<bool> openOfficialView({
    int maxPollAttempts = 12,
    Duration pollDelay = const Duration(milliseconds: 1500),
  }) async {
    emit(state.copyWith(status: OrderEInvoiceStatus.submitting));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      var result = await _mediator.executeCommandAsync(
        RequestOfficialInvoiceViewCommand(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.salesOrderId,
        ),
      );

      var viewerUrl = _nonEmptyViewerRef(result.viewerUrl);
      if (viewerUrl == null && result.status == InvoiceDocumentStatus.pending) {
        var delay = pollDelay;
        for (var i = 0; i < maxPollAttempts; i++) {
          if (isClosed) return false;
          if (delay > Duration.zero) {
            await Future<void>.delayed(delay);
          }
          if (isClosed) return false;

          final detail = await _mediator.executeQueryAsync(
            GetElectronicInvoiceDetailQuery(
              tenantId: tenantId,
              actorId: actorId,
              salesOrderId: state.salesOrderId,
            ),
          );
          if (isClosed) return false;

          viewerUrl = _nonEmptyViewerRef(detail.officialViewerUrl);
          if (viewerUrl != null || detail.officialViewStatus != InvoiceDocumentStatus.pending) {
            break;
          }
          if (delay > Duration.zero) {
            final nextMs = (delay.inMilliseconds * 1.5).clamp(
              1500,
              5000,
            ).toInt();
            delay = Duration(milliseconds: nextMs);
          }
        }
      }

      if (isClosed) return false;

      if (viewerUrl != null) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.idle,
            officialViewerUrl: viewerUrl,
          ),
        );
        final launched = await _viewerLauncher.launch(viewerUrl);
        if (!launched && !isClosed) {
          emit(
            state.copyWith(
              status: OrderEInvoiceStatus.error,
              errorMessage: 'Không thể mở liên kết xem hóa đơn trên thiết bị.',
            ),
          );
        }
        return launched;
      }
      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.error,
          errorMessage: 'Đang tải bản thể hiện hóa đơn. Vui lòng thử lại sau giây lát.',
        ),
      );
      return false;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: _humanFriendlyError(e),
          ),
        );
      }
      return false;
    }
  }

  /// Downloads PDF or XML document, polling while the worker prepares it.
  Future<bool> downloadDocument(
    InvoiceDocumentType type, {
    int maxPollAttempts = 15,
    Duration pollDelay = const Duration(milliseconds: 1500),
  }) async {
    emit(state.copyWith(status: OrderEInvoiceStatus.downloading));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final key = _idempotencyKeys.next();

      final result = await _mediator.executeCommandAsync(
        RequestInvoiceDocumentCommand(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.salesOrderId,
          documentType: type,
          idempotencyKey: key,
        ),
      );

      var downloadUrl = _nonEmptyViewerRef(result.downloadUrl);
      InvoiceDocumentItemDto? lastItem;
      if (downloadUrl == null && result.status == InvoiceDocumentStatus.pending) {
        var delay = pollDelay;
        for (var i = 0; i < maxPollAttempts; i++) {
          if (isClosed) return false;
          if (delay > Duration.zero) {
            await Future<void>.delayed(delay);
          }
          if (isClosed) return false;

          final documents = await _mediator.executeQueryAsync(
            GetInvoiceDocumentsQuery(
              tenantId: tenantId,
              actorId: actorId,
              salesOrderId: state.salesOrderId,
            ),
          );
          if (isClosed) return false;

          final item = type == InvoiceDocumentType.pdf ? documents.pdf : documents.xml;
          lastItem = item;
          downloadUrl = _nonEmptyViewerRef(item?.downloadUrl);
          if (downloadUrl != null ||
              (item != null && item.status != InvoiceDocumentStatus.pending)) {
            break;
          }
          if (delay > Duration.zero) {
            final nextMs = (delay.inMilliseconds * 1.5).clamp(
              1500,
              5000,
            ).toInt();
            delay = Duration(milliseconds: nextMs);
          }
        }
      }

      if (isClosed) return false;

      if (downloadUrl != null) {
        final ext = type == InvoiceDocumentType.pdf ? 'pdf' : 'xml';
        final filename = 'invoice_${state.salesOrderId}.$ext';

        final success = await _documentExporter.exportDocument(
          filename: filename,
          type: type,
          url: downloadUrl,
        );

        if (!success) {
          if (!isClosed) {
            emit(
              state.copyWith(
                status: OrderEInvoiceStatus.error,
                errorMessage: 'Không thể mở liên kết tài liệu hóa đơn.',
              ),
            );
          }
          return false;
        }

        if (!isClosed) {
          emit(state.copyWith(status: OrderEInvoiceStatus.idle));
        }
        return success;
      }

      final finalStatus = lastItem?.status ?? result.status;
      final errorMsg = switch (finalStatus) {
        InvoiceDocumentStatus.checkRequired =>
          'Tài liệu hóa đơn chưa sẵn sàng (CHECK_REQUIRED). Vui lòng kiểm tra log worker hoặc thử lại sau.',
        InvoiceDocumentStatus.failed =>
          'Tải tài liệu hóa đơn thất bại (FAILED). Vui lòng thử lại.',
        _ => 'Đang chuẩn bị tài liệu hóa đơn. Vui lòng thử lại sau giây lát.',
      };

      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: errorMsg,
          ),
        );
      }
      return false;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: _humanFriendlyError(e),
          ),
        );
      }
      return false;
    }
  }

  /// Loads send invoice sheet context (suggested email, mode, etc.).
  Future<SendInvoiceSheetContextDto?> getSendSheetContext() async {
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      return await _mediator.executeQueryAsync(
        GetSendInvoiceSheetContextQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.salesOrderId,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Sends the electronic invoice to the specified recipient email.
  Future<bool> sendInvoiceEmail(String recipientEmail) async {
    final trimmed = recipientEmail.trim();
    if (trimmed.isEmpty) return false;

    emit(
      state.copyWith(
        status: OrderEInvoiceStatus.submitting,
        clearError: true,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final idempotencyKey = _idempotencyKeys.next();

      await _mediator.executeCommandAsync(
        SendElectronicInvoiceCommand(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.salesOrderId,
          recipientEmail: trimmed,
          idempotencyKey: idempotencyKey,
        ),
      );

      // Refresh to update projection with latest delivery status
      await refresh();
      if (!isClosed && state.status == OrderEInvoiceStatus.submitting) {
        emit(state.copyWith(status: OrderEInvoiceStatus.idle));
      }
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: _humanFriendlyError(e),
          ),
        );
      }
      return false;
    }
  }

  /// Control whether auto-refresh is active (pauses when page inactive).
  void setPageActive(bool isActive) {
    emit(state.copyWith(isPageActive: isActive));
  }

  static String _humanFriendlyError(Object error) {
    final str = error.toString();
    if (str.contains('NO_PERMISSION') || str.contains('permission')) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }
    if (str.contains('STATE_CHANGED') || str.contains('order_version_mismatch')) {
      return 'Trạng thái đơn hàng đã thay đổi. Vui lòng tải lại trang.';
    }
    if (str.contains('ISSUANCE_NOT_READY')) {
      return 'Đơn hàng hoặc thông tin xuất hóa đơn chưa sẵn sàng.';
    }
    if (str.contains('DELIVERY_NOT_SUPPORTED')) {
      return 'Cổng kết nối hóa đơn chưa hỗ trợ tính năng gửi email.';
    }
    if (str.contains('OPERATION_IN_PROGRESS')) {
      return 'Yêu cầu gửi hóa đơn đang được xử lý, vui lòng chờ giây lát.';
    }
    if (str.contains('PlatformException') || str.contains('Error while launching')) {
      return 'Không thể mở liên kết xem hóa đơn trên thiết bị. Vui lòng kiểm tra trình duyệt.';
    }
    return 'Đã có lỗi xảy ra: $str';
  }
}
