import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

/// Thin Composition Page cho Màn hình Danh sách Tổ chức trong Admin App.
class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key});

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  final TextEditingController _searchController = TextEditingController();
  OrganizationFilterCriteria _filterCriteria =
      const OrganizationFilterCriteria();
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

  void _onStatusSelected(OrganizationStatus status) {
    setState(() {
      _filterCriteria = _filterCriteria.copyWith(status: status);
    });
  }

  void _openFilterBottomSheet() {
    showVBottomSheet(
      context: context,
      child: OrganizationFilterBottomSheet(
        initialCriteria: _filterCriteria,
        onApply: (newCriteria) {
          setState(() {
            _filterCriteria = newCriteria;
          });
        },
      ),
    );
  }

  List<OrganizationUiModel> _getFilteredOrganizations() {
    return FakeOrganizationData.sampleOrganizations.where((org) {
      // Lọc theo trạng thái (Status)
      if (_filterCriteria.status != OrganizationStatus.all &&
          org.status != _filterCriteria.status) {
        return false;
      }
      // Lọc theo vòng đời (Lifecycle)
      if (_filterCriteria.lifecycle != 'Tất cả') {
        if (_filterCriteria.lifecycle == 'Tạm ngừng' &&
            org.status != OrganizationStatus.suspended) {
          return false;
        }
        if (_filterCriteria.lifecycle == 'Đã đóng' &&
            org.status != OrganizationStatus.closed) {
          return false;
        }
      }
      // Lọc theo từ khóa tìm kiếm (name hoặc code)
      if (_searchQuery.isNotEmpty) {
        final nameMatch = org.name.toLowerCase().contains(_searchQuery);
        final codeMatch = org.code.toLowerCase().contains(_searchQuery);
        return nameMatch || codeMatch;
      }
      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filterCriteria = const OrganizationFilterCriteria();
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredOrganizations();

    return Column(
      children: [
        // Thanh tìm kiếm + Nút bộ lọc
        OrganizationSearchBar(
          controller: _searchController,
          isFilterActive: _filterCriteria.isFilterActive,
          onFilterTap: _openFilterBottomSheet,
        ),

        // Thanh chip lọc trạng thái
        OrganizationFilterChips(
          selectedStatus: _filterCriteria.status,
          onStatusSelected: _onStatusSelected,
        ),

        // Danh sách tổ chức
        Expanded(
          child: OrganizationListContent(
            organizations: filteredItems,
            onRefresh: _handleRefresh,
            onEmptyAction: _clearFilters,
            onItemTap: (organization) async {
              final shouldRefresh = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) =>
                      OrganizationDetailPage(organization: organization),
                ),
              );
              if (shouldRefresh == true && mounted) {
                _handleRefresh();
              }
            },
          ),
        ),
      ],
    );
  }
}
