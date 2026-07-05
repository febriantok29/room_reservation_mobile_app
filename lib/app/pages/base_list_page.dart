import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/repositories/data_list_repository.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/filter_icon_button.dart';

/// Generic base page untuk list dengan infinite scroll dan dynamic filter
class BaseListPage<T> extends StatefulWidget {
  final String pageTitle;
  final DataListRepository<T> repository;
  final Widget Function(T item) itemBuilder;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  /// Optional FAB
  final Widget? floatingActionButton;

  /// Custom filter builder - menerima callback untuk apply filter
  /// Called saat filter diaplikasikan
  final Widget Function(
    void Function(Map<String, dynamic>? filters) onApplyFilter,
  )?
  customFilterBuilder;

  /// Callback saat icon filter di AppBar ditekan - menerima apply filter callback
  final void Function(
    void Function(Map<String, dynamic>? filters) onApplyFilter,
  )?
  onFilterPressed;

  /// Jumlah filter aktif untuk badge di icon filter
  final int activeFilterCount;

  /// Custom fetch data handler - override default fetchList
  final Future<void> Function({
    Map<String, dynamic>? filters,
    required bool isRefresh,
  })?
  onFetchData;

  const BaseListPage({
    super.key,
    required this.pageTitle,
    required this.repository,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.floatingActionButton,
    this.customFilterBuilder,
    this.onFilterPressed,
    this.activeFilterCount = 0,
    this.onFetchData,
  });

  @override
  State<BaseListPage<T>> createState() => _BaseListPageState<T>();
}

class _BaseListPageState<T> extends State<BaseListPage<T>> {
  bool _isInitialLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _currentFilters;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    widget.repository.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await _fetchData(isRefresh: true);
  }

  Future<void> _fetchData({
    Map<String, dynamic>? filters,
    required bool isRefresh,
  }) async {
    if (!mounted) return;

    // Guard: jangan fetch jika sedang fetching
    if (widget.repository.isFetching && !isRefresh) return;

    setState(() {
      _errorMessage = null;
      if (isRefresh) {
        _isInitialLoading = true;
      }
    });

    try {
      if (widget.onFetchData != null) {
        await widget.onFetchData!(filters: filters, isRefresh: isRefresh);
      } else {
        await widget.repository.fetchList(
          filters: filters,
          isRefresh: isRefresh,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  void _applyFilter(Map<String, dynamic>? filters) {
    _currentFilters = filters;
    _fetchData(filters: filters, isRefresh: true);
  }

  Widget _buildFilterSection() {
    if (widget.customFilterBuilder != null) {
      return widget.customFilterBuilder!(_applyFilter);
    }
    return const SizedBox.shrink();
  }

  int _buildListItemCount() =>
      widget.repository.data.length + (widget.repository.hasMoreData ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (widget.onFilterPressed != null)
            FilterIconButton(
              activeCount: widget.activeFilterCount,
              onPressed: () => widget.onFilterPressed!(_applyFilter),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withAlpha(26), AppColors.white],
          ),
        ),
        child: Column(
          children: [
            if (widget.customFilterBuilder != null) _buildFilterSection(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildContent() {
    // Initial loading
    if (_isInitialLoading && widget.repository.data.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state (no data)
    if (_errorMessage != null && widget.repository.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: AppSizes.iconXl, color: AppColors.textDisabled),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
              child: Text(
                _errorMessage ?? 'Gagal memuat data',
                style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: () =>
                  _fetchData(filters: _currentFilters, isRefresh: true),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (widget.repository.data.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchData(filters: _currentFilters, isRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withAlpha(13),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(widget.emptyIcon, size: AppSizes.iconXl, color: AppColors.textDisabled),
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    widget.emptyTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppSizes.fontLg,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    widget.emptySubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // List content
    return RefreshIndicator(
      onRefresh: () => _fetchData(filters: _currentFilters, isRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.lg),
        itemCount: _buildListItemCount(),
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
        itemBuilder: (context, index) {
          // Load more trigger (pada item terakhir)
          if (index == widget.repository.data.length) {
            if (_errorMessage != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                child: Column(
                  children: [
                    Text(
                      'Gagal memuat data selanjutnya',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () => _fetchData(
                        filters: _currentFilters,
                        isRefresh: false,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            // Trigger load more via callback bukan pixel checking
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  !widget.repository.isFetching &&
                  widget.repository.hasMoreData) {
                _fetchData(filters: _currentFilters, isRefresh: false);
              }
            });

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final item = widget.repository.data[index];
          return widget.itemBuilder(item);
        },
      ),
    );
  }
}
