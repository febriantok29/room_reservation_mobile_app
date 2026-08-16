import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

/// Halaman full-screen untuk memilih banyak item dari daftar panjang
/// (sudah ada di memori, filter pencarian client-side, tanpa call API).
class ItemMultiSelectPage<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> initialSelected;
  final String Function(T item) idOf;
  final String Function(T item) labelOf;
  final String? Function(T item)? subtitleOf;
  final Widget Function(T item, bool isSelected)? leadingBuilder;
  final IconData leadingIcon;
  final String searchHint;
  final String emptyMessage;

  const ItemMultiSelectPage({
    super.key,
    required this.title,
    required this.items,
    required this.initialSelected,
    required this.idOf,
    required this.labelOf,
    this.subtitleOf,
    this.leadingBuilder,
    this.leadingIcon = Icons.label_outline,
    this.searchHint = 'Cari...',
    this.emptyMessage = 'Belum ada data',
  });

  static Future<List<T>?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required List<T> initialSelected,
    required String Function(T item) idOf,
    required String Function(T item) labelOf,
    String? Function(T item)? subtitleOf,
    Widget Function(T item, bool isSelected)? leadingBuilder,
    IconData leadingIcon = Icons.label_outline,
    String searchHint = 'Cari...',
    String emptyMessage = 'Belum ada data',
  }) {
    return Navigator.of(context).push<List<T>>(
      MaterialPageRoute(
        builder: (_) => ItemMultiSelectPage<T>(
          title: title,
          items: items,
          initialSelected: initialSelected,
          idOf: idOf,
          labelOf: labelOf,
          subtitleOf: subtitleOf,
          leadingBuilder: leadingBuilder,
          leadingIcon: leadingIcon,
          searchHint: searchHint,
          emptyMessage: emptyMessage,
        ),
      ),
    );
  }

  @override
  State<ItemMultiSelectPage<T>> createState() =>
      _ItemMultiSelectPageState<T>();
}

class _ItemMultiSelectPageState<T> extends State<ItemMultiSelectPage<T>> {
  final _searchController = TextEditingController();
  late final Set<String> _selectedIds = widget.initialSelected
      .map(widget.idOf)
      .toSet();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) {
      if (widget.labelOf(item).toLowerCase().contains(q)) return true;
      final subtitle = widget.subtitleOf?.call(item);
      return subtitle?.toLowerCase().contains(q) ?? false;
    }).toList();
  }

  void _toggle(T item) {
    setState(() {
      final id = widget.idOf(item);
      _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    });
  }

  bool get _allFilteredSelected {
    final filtered = _filteredItems;
    return filtered.isNotEmpty &&
        filtered.every((item) => _selectedIds.contains(widget.idOf(item)));
  }

  void _toggleSelectAllFiltered() {
    setState(() {
      final filtered = _filteredItems;
      if (_allFilteredSelected) {
        for (final item in filtered) {
          _selectedIds.remove(widget.idOf(item));
        }
      } else {
        for (final item in filtered) {
          _selectedIds.add(widget.idOf(item));
        }
      }
    });
  }

  void _finish() {
    final result = widget.items
        .where((item) => _selectedIds.contains(widget.idOf(item)))
        .toList();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selectedIds.isEmpty
              ? widget.title
              : '${widget.title} (${_selectedIds.length})',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () => setState(_selectedIds.clear),
            child: Text(
              'Reset',
              style: TextStyle(
                color: _selectedIds.isEmpty
                    ? AppColors.white.withAlpha(120)
                    : AppColors.white,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ),
          TextButton(
            onPressed: _finish,
            child: const Text(
              'Selesai',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          if (_filteredItems.isNotEmpty) _buildSelectAllRow(),
          Expanded(
            child: Container(color: AppColors.white, child: _buildContent()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: const TextStyle(
            fontSize: AppSizes.fontSm,
            color: AppColors.grey,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: AppSizes.iconSm,
            color: AppColors.grey,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: AppSizes.iconSm),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
    );
  }

  Widget _buildSelectAllRow() {
    final allSelected = _allFilteredSelected;

    return Container(
      color: AppColors.white,
      child: ListTile(
        onTap: _toggleSelectAllFiltered,
        tileColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.xs,
        ),
        leading: Icon(
          allSelected ? Icons.check_circle : Icons.circle_outlined,
          color: allSelected ? AppColors.primary : AppColors.textSecondary,
          size: AppSizes.iconSm,
        ),
        title: Text(
          'Pilih Semua (${_filteredItems.length})',
          style: const TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final items = _filteredItems;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off,
                size: AppSizes.iconXl,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                _query.isNotEmpty
                    ? 'Tidak ditemukan untuk "$_query"'
                    : widget.emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppSizes.fontMd,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: AppSizes.lg + AppSizes.iconMd + AppSizes.md,
      ),
      itemBuilder: (_, index) => _buildTile(items[index]),
    );
  }

  Widget _buildTile(T item) {
    final id = widget.idOf(item);
    final isSelected = _selectedIds.contains(id);
    final subtitle = widget.subtitleOf?.call(item);

    return ListTile(
      onTap: () => _toggle(item),
      tileColor: isSelected ? AppColors.primary.withAlpha(10) : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.xs,
      ),
      leading:
          widget.leadingBuilder?.call(item, isSelected) ??
          Container(
            padding: const EdgeInsets.all(AppSizes.xs),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withAlpha(25)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radiusXs),
            ),
            child: Icon(
              widget.leadingIcon,
              size: AppSizes.iconSm,
              color: isSelected ? AppColors.primary : AppColors.grey,
            ),
          ),
      title: Text(
        widget.labelOf(item),
        style: TextStyle(
          fontSize: AppSizes.fontSm,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      subtitle: subtitle != null && subtitle != '-'
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? AppColors.primary : AppColors.border,
        size: AppSizes.iconSm,
      ),
    );
  }
}
