import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../testing/fake_audit_logs_data.dart';
import '../models/audit_log_filter_criteria.dart';
import '../models/audit_log_ui_model.dart';
import '../widgets/audit_log_empty_view.dart';
import '../widgets/audit_log_filter_bottom_sheet.dart';
import '../widgets/audit_log_item_card.dart';
import 'audit_log_detail_page.dart';

/// Trang Lịch sử quản trị tổ chức (TA-D-01 — Lịch sử quản trị).
class OrganizationAuditLogsPage extends StatefulWidget {
  final List<AuditLogItemUiModel>? initialLogs;
  final bool hasError;
  final bool isUnauthorized;
  final VoidCallback? onRetry;

  const OrganizationAuditLogsPage({
    super.key,
    this.initialLogs,
    this.hasError = false,
    this.isUnauthorized = false,
    this.onRetry,
  });

  @override
  State<OrganizationAuditLogsPage> createState() => _OrganizationAuditLogsPageState();
}

class _OrganizationAuditLogsPageState extends State<OrganizationAuditLogsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  String _selectedCategory = 'Tất cả';
  AuditLogFilterCriteria _filterCriteria = const AuditLogFilterCriteria(timeRange: '30 ngày');

  static const List<String> _categoryOptions = [
    'Tất cả',
    'Thành viên',
    'Vai trò',
    'Tổ chức',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isFilterActive =>
      _selectedCategory != 'Tất cả' ||
      _filterCriteria.timeRange != '30 ngày' ||
      _filterCriteria.status != null ||
      _filterCriteria.actorType != 'Tất cả';

  List<AuditLogItemUiModel> get _filteredLogs {
    final baseLogs = widget.initialLogs ?? FakeAuditLogsData.sampleAuditLogs;
    return baseLogs.where((log) {
      // 1. Quick filter category chip
      if (_selectedCategory != 'Tất cả' && log.category != _selectedCategory) {
        return false;
      }

      // 2. Bottom Sheet Criteria - Status
      if (_filterCriteria.status != null && log.status != _filterCriteria.status) {
        return false;
      }

      // 3. Bottom Sheet Criteria - Actor Type
      if (_filterCriteria.actorType != 'Tất cả') {
        if (_filterCriteria.actorType == 'Người dùng' && log.actorRole.contains('Hệ thống')) {
          return false;
        }
        if (_filterCriteria.actorType == 'Hệ thống' && !log.actorRole.contains('Hệ thống')) {
          return false;
        }
      }

      // 4. Search query (actorName or title)
      if (_searchQuery.isNotEmpty) {
        final titleMatch = log.title.toLowerCase().contains(_searchQuery);
        final actorMatch = log.actorName.toLowerCase().contains(_searchQuery);
        final actionMatch = log.actionCode.toLowerCase().contains(_searchQuery);
        return titleMatch || actorMatch || actionMatch;
      }

      return true;
    }).toList();
  }

  Future<void> _openFilterBottomSheet() async {
    final newCriteria = await showVBottomSheet<AuditLogFilterCriteria>(
      context: context,
      child: AuditLogFilterBottomSheet(
        initialCriteria: _filterCriteria,
      ),
    );
    if (newCriteria != null && mounted) {
      setState(() {
        _filterCriteria = newCriteria;
      });
    }
  }

  Future<void> _navigateToDetail(AuditLogItemUiModel log) async {
    try {
      await context.push('/more/audit-logs/detail', extra: log);
    } catch (_) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AuditLogDetailPage(log: log),
        ),
      );
    }
  }

  void _clearSearchAndFilter() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'Tất cả';
      _filterCriteria = const AuditLogFilterCriteria(timeRange: '30 ngày');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final filteredList = _filteredLogs;
    final totalCount = filteredList.length;

    final String subtitleText = widget.isUnauthorized
        ? 'Chưa được cấp quyền'
        : widget.hasError
        ? 'Không tải được dữ liệu'
        : '$totalCount hoạt động trong ${_filterCriteria.timeRange}';

    return Scaffold(
      backgroundColor: colors.surfaceAlt,
      appBar: VAppBar(
        title: 'Lịch sử quản trị',
        subtitle: subtitleText,
        showBackButton: true,
        leading: IconButton(
          icon: VIcon(
            icon: VIcons.chevronLeft,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh Tìm kiếm & Nút Lọc
            Container(
              color: colors.surfaceAlt,
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.screenMobile,
                vertical: VSpacing.space2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: VSearchBar(
                      hintText: 'Tìm người thực hiện hoặc hoạt động',
                      controller: _searchController,
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            setState(() {
                              _searchQuery = value.trim().toLowerCase();
                            });
                          }
                        });
                      },
                    ),
                  ),
                  const VGap.horizontalSm(),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: _isFilterActive ? colors.successBg : colors.surface,
                      border: Border.all(
                        color: _isFilterActive ? colors.success : colors.borderDefault,
                      ),
                      borderRadius: BorderRadius.circular(VRadius.button),
                    ),
                    child: IconButton(
                      icon: VIcon(
                        icon: VIcons.tune,
                        size: 20,
                        color: _isFilterActive ? colors.success : colors.textPrimary,
                      ),
                      onPressed: _openFilterBottomSheet,
                    ),
                  ),
                ],
              ),
            ),

            // Quick Filter Chips Category Row
            Padding(
              padding: const EdgeInsets.only(
                left: VSpacing.screenMobile,
                right: VSpacing.screenMobile,
                bottom: VSpacing.space2,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categoryOptions.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: VSpacing.space2),
                      child: VChip(
                        label: cat,
                        emphasis: isSelected
                            ? VComponentEmphasis.strong
                            : VComponentEmphasis.medium,
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Subtitle Meta text
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.screenMobile,
                vertical: VSpacing.space2,
              ),
              child: VText(
                'Thời gian: ${_filterCriteria.timeRange} gần đây · Mới nhất trước',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ),

            // Main List Content
            Expanded(
              child: _buildListContent(colors, filteredList),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(dynamic colors, List<AuditLogItemUiModel> logs) {
    if (widget.isUnauthorized) {
      return AuditLogEmptyView(
        type: AuditLogEmptyStateType.unauthorized,
        onAction: () => Navigator.of(context).maybePop(),
      );
    }

    if (widget.hasError) {
      return AuditLogEmptyView(
        type: AuditLogEmptyStateType.loadError,
        onAction: widget.onRetry ?? () {},
      );
    }

    if (logs.isEmpty) {
      final isFiltered =
          _searchQuery.isNotEmpty || _isFilterActive || _selectedCategory != 'Tất cả';

      if (isFiltered) {
        return AuditLogEmptyView(
          type: AuditLogEmptyStateType.noResults,
          onAction: _clearSearchAndFilter,
        );
      }

      return AuditLogEmptyView(
        type: AuditLogEmptyStateType.noAuditLogs,
        onAction: widget.onRetry ?? () {},
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(
        left: VSpacing.screenMobile,
        right: VSpacing.screenMobile,
        bottom: VSpacing.space6,
      ),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const VGap.sm(),
      itemBuilder: (context, index) {
        final log = logs[index];
        return AuditLogItemCard(
          log: log,
          onTap: () => _navigateToDetail(log),
        );
      },
    );
  }
}
