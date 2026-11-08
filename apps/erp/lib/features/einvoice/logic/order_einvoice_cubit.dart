import 'dart:async';

import 'package:async_query/async_query.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/sales/presentation/support/order_einvoice_error_message.dart';
import 'file_invoice_document_exporter.dart';
import 'i_invoice_document_exporter.dart';
import 'i_invoice_viewer_launcher.dart';
import 'order_einvoice_idempotency_key_factory.dart';
import 'order_einvoice_refresh_snapshot.dart';
import 'order_einvoice_state.dart';
import 'url_invoice_viewer_launcher.dart';

class OrderEInvoiceCubit extends Cubit<OrderEInvoiceState> {
  OrderEInvoiceCubit({
    required String salesOrderId,
    required int orderVersion,
    required OrderInvoiceProjectionDto initialProjection,
    IssuanceReadinessDto? initialReadiness,
    bool isBuyerNotReady = false,
    bool hasLoadedInitialProjection = true,
    required IExecutionContext executionContext,
    required IModuleMediator mediator,
    required QueryClient queryClient,
    IInvoiceViewerLauncher? viewerLauncher,
    IInvoiceDocumentExporter? documentExporter,
    OrderEInvoiceIdempotencyKeyFactory idempotencyKeyFactory =
        const OrderEInvoiceIdempotencyKeyFactory(),
  }) : _executionContext = executionContext,
       _mediator = mediator,
       _queryClient = queryClient,
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
           hasLoadedProjection: hasLoadedInitialProjection,
         ),
       );

  final IExecutionContext _executionContext;
  final IModuleMediator _mediator;
  final QueryClient _queryClient;
  final IInvoiceViewerLauncher _viewerLauncher;
  final IInvoiceDocumentExporter _documentExporter;
  final OrderEInvoiceIdempotencyKeyFactory _idempotencyKeys;

  QueryObserver<OrderEInvoiceRefreshSnapshot>? _pollObserver;
  StreamSubscription<QueryState<OrderEInvoiceRefreshSnapshot>>? _pollSubscription;
  bool _pollingRequested = false;
  bool _startingPolling = false;
  int _previewGeneration = 0;

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
      // Avoid poll-observer onListen re-applying a stale failed cache snapshot.
      _queryClient.setQueryData<OrderEInvoiceRefreshSnapshot>(
        ['einvoice', 'orderInvoice', tenantId, state.salesOrderId],
        OrderEInvoiceRefreshSnapshot(
          projection: state.projection,
          readiness: state.readiness,
        ),
      );
      await refresh();
    } catch (e) {
      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.error,
          errorMessage: OrderEInvoiceErrorMessage.of(e),
        ),
      );
    }
  }

  /// Alias for issueOrRetry for explicit issue action.
  Future<void> issueNow() => issueOrRetry();

  /// Projection, readiness, and safe attempt-status refresh.
  Future<void> refresh() async {
    if (isClosed || !state.isPageActive) {
      return;
    }

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final queryState = await _queryClient.fetchQuery<OrderEInvoiceRefreshSnapshot>(
        queryKey: ['einvoice', 'orderInvoice', tenantId, state.salesOrderId],
        queryFn: () => _loadRefreshSnapshot(
          tenantId: tenantId,
          actorId: actorId,
        ),
        staleTime: Duration.zero,
        retry: 0,
      );
      final snapshot = queryState.data;
      if (snapshot != null) _applyRefreshSnapshot(snapshot);
    } catch (_) {
      // Lỗi đọc tạm thời không được thay thế projection đáng tin cậy gần nhất.
    }
  }

  void setPollingActive(bool active) {
    _pollingRequested = active;
    if (!active) {
      _stopPolling();
      return;
    }
    unawaited(_startPolling());
  }

  Future<void> _startPolling() async {
    if (!_pollingRequested || isClosed || _pollObserver != null || _startingPolling) {
      return;
    }
    _startingPolling = true;
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      if (!_pollingRequested || isClosed) return;

      final observer = _queryClient.watchQuery<OrderEInvoiceRefreshSnapshot>(
        queryKey: ['einvoice', 'orderInvoice', tenantId, state.salesOrderId],
        queryFn: () => _loadRefreshSnapshot(
          tenantId: tenantId,
          actorId: actorId,
        ),
        staleTime: Duration.zero,
        retry: 0,
        refetchOnMount: true,
        refetchInterval: const Duration(seconds: 5),
      );
      _pollObserver = observer;
      _pollSubscription = observer.stream.listen((queryState) {
        final snapshot = queryState.data;
        if (snapshot != null) _applyRefreshSnapshot(snapshot);
      });
    } catch (_) {
      _stopPolling();
      // Keep last trusted projection; auth/network failures must not escape.
    } finally {
      _startingPolling = false;
    }
  }

  void _stopPolling() {
    unawaited(_pollSubscription?.cancel());
    _pollSubscription = null;
    _pollObserver?.dispose();
    _pollObserver = null;
  }

  @override
  Future<void> close() async {
    _pollingRequested = false;
    final subscription = _pollSubscription;
    _pollSubscription = null;
    await subscription?.cancel();
    _pollObserver?.dispose();
    _pollObserver = null;
    return super.close();
  }

  Future<OrderEInvoiceRefreshSnapshot> _loadRefreshSnapshot({
    required String tenantId,
    required String actorId,
  }) async {
    final projection = await _mediator.executeQueryAsync(
      GetOrderInvoiceProjectionQuery(
        tenantId: tenantId,
        actorId: actorId,
        salesOrderId: state.salesOrderId,
      ),
    );

    IssuanceReadinessDto? readiness;
    try {
      readiness = await _mediator.executeQueryAsync(
        GetIssuanceReadinessQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.salesOrderId,
        ),
      );
    } catch (_) {}

    IssuanceAttemptStatusDto? attemptStatus;
    if (projection.issuanceDisplayState == IssuanceDisplayState.failed) {
      try {
        attemptStatus = await _mediator.executeQueryAsync(
          GetIssuanceAttemptStatusQuery(
            tenantId: tenantId,
            actorId: actorId,
            salesOrderId: state.salesOrderId,
          ),
        );
      } catch (_) {}
    }

    return OrderEInvoiceRefreshSnapshot(
      projection: projection,
      readiness: readiness,
      attemptStatus: attemptStatus,
    );
  }

  void _applyRefreshSnapshot(OrderEInvoiceRefreshSnapshot snapshot) {
    if (isClosed || !state.isPageActive) return;
    final blockers = snapshot.readiness?.blockers ?? const [];
    final buyerNotReady = snapshot.readiness == null
        ? state.isBuyerNotReady
        : blockers.any(
            (blocker) =>
                blocker.code == 'BUYER_TAX_CODE_REQUIRED' ||
                blocker.code == 'BUYER_DATA_INCOMPLETE' ||
                blocker.code == 'BUYER_SOURCE_UNAVAILABLE',
          );
    final failure = snapshot.attemptStatus;
    emit(
      state.copyWith(
        status: state.status == OrderEInvoiceStatus.submitting ? OrderEInvoiceStatus.idle : null,
        projection: snapshot.projection,
        readiness: snapshot.readiness ?? state.readiness,
        isBuyerNotReady: buyerNotReady,
        hasLoadedProjection: true,
        failureCode: failure?.failureCode,
        lastFailureMessage: failure?.lastErrorMessage,
        clearError: true,
        clearFailure: failure == null,
      ),
    );
  }

  /// Loads the saved default template for the confirmation sheet.
  ///
  /// Returns false when the issuance profile has no template. A failed profile
  /// read returns true so a transient error does not block the sheet.
  Future<bool> ensureIssuanceTemplateDisplay() async {
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final template = await _loadIssuanceTemplateDisplay(
        tenantId: tenantId,
        actorId: actorId,
      );
      if (template.saved == false) return false;
      emit(
        state.copyWith(
          templateNumber: template.number,
          templateSymbol: template.symbol,
          authorityMode: template.authority,
        ),
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<({bool? saved, String number, String symbol, String authority})>
  _loadIssuanceTemplateDisplay({
    required String tenantId,
    required String actorId,
  }) async {
    IssuanceProfileDto? profile;
    var profileLoaded = false;
    List<ProviderTemplateDto> templates = const [];
    try {
      profile = await _mediator.executeQueryAsync(
        GetIssuanceProfileQuery(tenantId: tenantId, actorId: actorId),
      );
      profileLoaded = true;
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
    final savedTemplateId = profile?.templateId?.trim();
    return (
      saved: profileLoaded
          ? savedTemplateId != null && savedTemplateId.isNotEmpty
          : null,
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

  /// Cancels an in-flight preview (e.g. user dismisses the pre-issue sheet).
  ///
  /// Stops client-side polling / launch; does not revoke a server request that
  /// already started. No-op when not [OrderEInvoiceStatus.previewing].
  void cancelPreview() {
    _previewGeneration++;
    if (!isClosed && state.status == OrderEInvoiceStatus.previewing) {
      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.idle,
          clearError: true,
        ),
      );
    }
  }

  /// Requests preview, polls for readiness if needed, and launches viewer.
  ///
  /// Default poll window is ~45s (45 × 1s) so MISA unpublished preview can
  /// finish before the UI surfaces a false "not ready" error. Concurrent taps
  /// while [OrderEInvoiceStatus.previewing] are ignored. A previous
  /// [OrderEInvoiceState.previewViewerUrl] is kept until a new URL arrives.
  /// Call [cancelPreview] to abort after sheet dismiss.
  Future<String?> requestPreview({
    int maxPollAttempts = 45,
    Duration pollDelay = const Duration(seconds: 1),
  }) async {
    if (state.status == OrderEInvoiceStatus.previewing) {
      return null;
    }

    final generation = ++_previewGeneration;
    emit(
      state.copyWith(
        status: OrderEInvoiceStatus.previewing,
        clearError: true,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      if (!_isPreviewGenerationCurrent(generation)) return null;

      final result = await _mediator.executeCommandAsync(
        RequestInvoicePreviewCommand(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.salesOrderId,
          expectedOrderVersion: state.orderVersion,
        ),
      );
      if (!_isPreviewGenerationCurrent(generation)) return null;

      var viewerUrl = _nonEmptyViewerRef(result.viewerRef);
      if (viewerUrl == null) {
        var delay = pollDelay;
        for (var i = 0; i < maxPollAttempts; i++) {
          await Future<void>.delayed(delay);
          if (!_isPreviewGenerationCurrent(generation)) return null;
          try {
            final preview = await _mediator.executeQueryAsync(
              GetInvoicePreviewQuery(
                tenantId: tenantId,
                actorId: actorId,
                salesOrderId: state.salesOrderId,
              ),
            );
            if (!_isPreviewGenerationCurrent(generation)) return null;
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

      if (!_isPreviewGenerationCurrent(generation)) return null;

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
      if (!_isPreviewGenerationCurrent(generation)) return null;
      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.error,
          errorMessage: OrderEInvoiceErrorMessage.of(e),
        ),
      );
      return null;
    }
  }

  bool _isPreviewGenerationCurrent(int generation) => !isClosed && generation == _previewGeneration;

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
    if (state.isOpeningOfficialView) return false;
    if (state.projection.issuanceDisplayState != IssuanceDisplayState.issued) {
      return false;
    }

    emit(
      state.copyWith(
        isOpeningOfficialView: true,
        clearError: true,
        clearOfficialViewerUrl: true,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      final result = await _mediator.executeCommandAsync(
        RequestOfficialInvoiceViewCommand(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.salesOrderId,
        ),
      );
      if (isClosed) return false;

      var viewerUrl = _nonEmptyViewerRef(result.viewerUrl);
      final operationId = result.operationId?.trim();
      final commandStatus = result.status;

      if (viewerUrl == null &&
          (commandStatus == InvoiceDocumentStatus.failed ||
              commandStatus == InvoiceDocumentStatus.checkRequired)) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: _officialViewUnavailableMessage,
          ),
        );
        return false;
      }

      final shouldPoll =
          viewerUrl == null &&
          operationId != null &&
          operationId.isNotEmpty &&
          (commandStatus == InvoiceDocumentStatus.pending ||
              commandStatus == InvoiceDocumentStatus.available);

      if (shouldPoll) {
        var delay = commandStatus == InvoiceDocumentStatus.available ? Duration.zero : pollDelay;
        InvoiceDocumentStatus? matchedStatus;

        for (var i = 0; i < maxPollAttempts; i++) {
          if (isClosed) return false;
          if (delay > Duration.zero) {
            await Future<void>.delayed(delay);
          }
          if (isClosed) return false;

          try {
            final detail = await _mediator.executeQueryAsync(
              GetElectronicInvoiceDetailQuery(
                tenantId: tenantId,
                actorId: actorId,
                salesOrderId: state.salesOrderId,
              ),
            );
            if (isClosed) return false;

            if (detail.officialViewOperationId != operationId) {
              // Stale generation — keep polling without adopting URL/status.
            } else {
              matchedStatus = detail.officialViewStatus;
              viewerUrl = _nonEmptyViewerRef(detail.officialViewerUrl);
              if (viewerUrl != null ||
                  matchedStatus == InvoiceDocumentStatus.failed ||
                  matchedStatus == InvoiceDocumentStatus.checkRequired ||
                  matchedStatus == InvoiceDocumentStatus.available) {
                break;
              }
            }
          } catch (_) {
            // Transient poll failures should not abort the window.
          }

          if (delay == Duration.zero) {
            delay = pollDelay;
          } else if (delay > Duration.zero) {
            final nextMs = (delay.inMilliseconds * 1.5).clamp(1500, 5000).toInt();
            delay = Duration(milliseconds: nextMs);
          }
        }

        if (viewerUrl == null &&
            (matchedStatus == InvoiceDocumentStatus.failed ||
                matchedStatus == InvoiceDocumentStatus.checkRequired)) {
          if (!isClosed) {
            emit(
              state.copyWith(
                status: OrderEInvoiceStatus.error,
                errorMessage: _officialViewUnavailableMessage,
              ),
            );
          }
          return false;
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
            errorMessage: OrderEInvoiceErrorMessage.of(e),
          ),
        );
      }
      return false;
    } finally {
      if (!isClosed && state.isOpeningOfficialView) {
        emit(state.copyWith(isOpeningOfficialView: false));
      }
    }
  }

  static const _officialViewUnavailableMessage =
      'Không thể mở bản thể hiện hóa đơn lúc này. Vui lòng thử lại.';

  /// Downloads PDF or XML document, polling while the worker prepares it.
  Future<bool> downloadDocument(
    InvoiceDocumentType type, {
    int maxPollAttempts = 15,
    Duration pollDelay = const Duration(milliseconds: 1500),
  }) async {
    if (state.downloadingDocumentType != null) return false;
    if (state.projection.issuanceDisplayState != IssuanceDisplayState.issued) {
      return false;
    }

    emit(
      state.copyWith(
        status: OrderEInvoiceStatus.downloading,
        downloadingDocumentType: type,
        clearError: true,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      final result = await _mediator.executeCommandAsync(
        RequestInvoiceDocumentCommand(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: state.salesOrderId,
          documentType: type,
        ),
      );
      if (isClosed) return false;

      var downloadUrl = _nonEmptyViewerRef(result.downloadUrl);
      var checksum = _nonEmptyViewerRef(result.checksum);
      final operationId = result.operationId?.trim();
      final commandStatus = result.status;

      if (downloadUrl == null &&
          (commandStatus == InvoiceDocumentStatus.failed ||
              commandStatus == InvoiceDocumentStatus.checkRequired)) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: _documentUnavailableMessage,
          ),
        );
        return false;
      }

      final shouldPoll =
          downloadUrl == null &&
          operationId != null &&
          operationId.isNotEmpty &&
          (commandStatus == InvoiceDocumentStatus.pending ||
              commandStatus == InvoiceDocumentStatus.available);

      InvoiceDocumentStatus? matchedStatus;
      if (shouldPoll) {
        var delay = commandStatus == InvoiceDocumentStatus.available ? Duration.zero : pollDelay;

        for (var i = 0; i < maxPollAttempts; i++) {
          if (isClosed) return false;
          if (delay > Duration.zero) {
            await Future<void>.delayed(delay);
          }
          if (isClosed) return false;

          try {
            final documents = await _mediator.executeQueryAsync(
              GetInvoiceDocumentsQuery(
                tenantId: tenantId,
                actorId: actorId,
                salesOrderId: state.salesOrderId,
              ),
            );
            if (isClosed) return false;

            final item = type == InvoiceDocumentType.pdf ? documents.pdf : documents.xml;
            if (item == null || item.operationId != operationId) {
              // Missing or stale generation — keep polling.
            } else {
              matchedStatus = item.status;
              downloadUrl = _nonEmptyViewerRef(item.downloadUrl);
              checksum = _nonEmptyViewerRef(item.checksum) ?? checksum;
              if (downloadUrl != null ||
                  matchedStatus == InvoiceDocumentStatus.failed ||
                  matchedStatus == InvoiceDocumentStatus.checkRequired ||
                  matchedStatus == InvoiceDocumentStatus.available) {
                break;
              }
            }
          } catch (_) {
            // Transient poll failures should not abort the window.
          }

          if (delay == Duration.zero) {
            delay = pollDelay;
          } else if (delay > Duration.zero) {
            final nextMs = (delay.inMilliseconds * 1.5).clamp(1500, 5000).toInt();
            delay = Duration(milliseconds: nextMs);
          }
        }

        if (downloadUrl == null &&
            (matchedStatus == InvoiceDocumentStatus.failed ||
                matchedStatus == InvoiceDocumentStatus.checkRequired)) {
          if (!isClosed) {
            emit(
              state.copyWith(
                status: OrderEInvoiceStatus.error,
                errorMessage: _documentUnavailableMessage,
              ),
            );
          }
          return false;
        }
      }

      if (isClosed) return false;

      final isAvailable =
          matchedStatus == InvoiceDocumentStatus.available ||
          commandStatus == InvoiceDocumentStatus.available;

      if (downloadUrl != null && checksum != null) {
        final ext = type == InvoiceDocumentType.pdf ? 'pdf' : 'xml';
        final filename = 'invoice_${state.salesOrderId}.$ext';

        final success = await _documentExporter.exportDocument(
          filename: filename,
          type: type,
          url: downloadUrl,
          expectedSha256: checksum,
        );

        if (!success) {
          if (!isClosed) {
            emit(
              state.copyWith(
                status: OrderEInvoiceStatus.error,
                errorMessage: 'Không thể lưu tài liệu hóa đơn trên thiết bị. Vui lòng thử lại.',
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

      // AVAILABLE without URL/checksum, or URL without checksum — fail closed.
      if (isAvailable || downloadUrl != null) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: OrderEInvoiceStatus.error,
              errorMessage: _documentUnavailableMessage,
            ),
          );
        }
        return false;
      }

      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: 'Đang chuẩn bị tài liệu hóa đơn. Vui lòng thử lại sau giây lát.',
          ),
        );
      }
      return false;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: OrderEInvoiceErrorMessage.of(e),
          ),
        );
      }
      return false;
    } finally {
      if (!isClosed && state.downloadingDocumentType != null) {
        emit(state.copyWith(clearDownloadingDocumentType: true));
      }
    }
  }

  static const _documentUnavailableMessage =
      'Không thể tải tài liệu hóa đơn lúc này. Vui lòng thử lại.';

  /// Control whether auto-refresh is active (pauses when page inactive).
  void setPageActive(bool isActive) {
    emit(state.copyWith(isPageActive: isActive));
  }
}
