import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

/// Thin Composition Page cho Màn hình Nhật ký nền tảng trong Admin App (PA-D-02).
class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final TextEditingController _searchController = TextEditingController();
  AuditLogFilterCriteria _filterCriteria = const AuditLogFilterCriteria();
  String _searchQuery = '';
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {});
    }
  }

  void _openFilterBottomSheet() {
    showVBottomSheet(
      context: context,
      child: AuditLogFilterBottomSheet(
        initialCriteria: _filterCriteria,
        onApply: (newCriteria) {
          setState(() {
            _filterCriteria = newCriteria;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<AuditLogItemUiModel> get _filteredLogs {
    return FakeAuditLogData.sampleLogs.where((log) {
      // Lọc theo trạng thái (Status)
      if (_filterCriteria.status != null && log.status != _filterCriteria.status) {
        return false;
      }
      // Lọc theo loại chủ thể (Actor Type)
      if (_filterCriteria.actorType != 'Tất cả') {
        if (_filterCriteria.actorType == 'Người dùng' && log.actorRole.contains('Hệ thống')) {
          return false;
        }
        if (_filterCriteria.actorType == 'Hệ thống' && !log.actorRole.contains('Hệ thống')) {
          return false;
        }
      }
      // Lọc theo từ khóa tìm kiếm
      if (_searchQuery.isNotEmpty) {
        final titleMatch = log.title.toLowerCase().contains(_searchQuery);
        final actorMatch = log.actorName.toLowerCase().contains(_searchQuery);
        final orgMatch = log.targetOrg.toLowerCase().contains(_searchQuery);
        final codeMatch = log.actionCode.toLowerCase().contains(_searchQuery);
        return titleMatch || actorMatch || orgMatch || codeMatch;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filteredLogs;

    return Column(
      children: [
        // Thanh tìm kiếm + Nút bộ lọc (Mở AuditLogFilterBottomSheet)
        OrganizationSearchBar(
          controller: _searchController,
          isFilterActive: _filterCriteria.isFilterActive,
          onFilterTap: _openFilterBottomSheet,
        ),

        // Thanh chip lọc trạng thái nhanh dùng VChip
        AuditLogFilterChips(
          selectedStatus: _filterCriteria.status,
          onStatusSelected: (status) {
            setState(() {
              _filterCriteria = _filterCriteria.copyWith(
                status: status,
                clearStatus: status == null,
              );
            });
          },
        ),

        // Danh sách nhật ký thao tác cuộn độc lập
        Expanded(
          child: AuditLogListContent(
            logs: filteredLogs,
            onRefresh: _handleRefresh,
            onItemTap: (log) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AuditLogDetailPage(log: log),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
