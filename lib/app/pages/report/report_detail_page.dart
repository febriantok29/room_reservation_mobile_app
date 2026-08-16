import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/pages/image_viewer_page.dart';
import 'package:rapa_track_mobile_app/app/pages/report/report_definitions.dart';
import 'package:rapa_track_mobile_app/app/pages/report/report_filter_options_cache.dart';
import 'package:rapa_track_mobile_app/app/services/report_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/app_button.dart';
import 'package:rapa_track_mobile_app/app/ui_items/item_multi_select_page.dart';
import 'package:rapa_track_mobile_app/app/ui_items/status_filter_chips.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';
import 'package:rapa_track_mobile_app/app/widgets/form_items.dart';

class ReportDetailPage extends StatefulWidget {
  final ReportDefinition definition;
  final ReportFilterOptionsCache filterOptionsCache;

  const ReportDetailPage({
    super.key,
    required this.definition,
    required this.filterOptionsCache,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final _service = ReportService();

  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<String> _selectedStatuses = [];
  List<Room> _selectedRooms = [];
  List<Profile> _selectedUsers = [];
  String _period = 'monthly';
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  List<Room> _rooms = [];
  List<Profile> _users = [];
  bool _roomsLoadFailed = false;
  bool _usersLoadFailed = false;

  Map<String, dynamic>? _reportData;
  bool _isLoadingPreview = false;
  bool _isDownloadingPdf = false;
  bool _isDownloadingExcel = false;
  String? _errorMessage;
  final _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.definition.hasDateRange) _setDefaultDateRange();
    if (widget.definition.hasRoomFilter) _loadRooms();
    if (widget.definition.hasUserFilter) _loadUsers();
  }

  void _setDefaultDateRange() {
    final today = DateTime.now();
    final dateTo = DateTime(today.year, today.month, today.day);
    final dateFrom = dateTo.subtract(const Duration(days: 60));
    _dateFrom = dateFrom;
    _dateTo = dateTo;
  }

  Future<void> _loadRooms() async {
    setState(() => _roomsLoadFailed = false);
    try {
      final rooms = await widget.filterOptionsCache.rooms();
      if (mounted) setState(() => _rooms = rooms);
    } catch (_) {
      if (mounted) setState(() => _roomsLoadFailed = true);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _usersLoadFailed = false);
    try {
      final users = await widget.filterOptionsCache.users();
      if (mounted) setState(() => _users = users);
    } catch (_) {
      if (mounted) setState(() => _usersLoadFailed = true);
    }
  }

  Map<String, dynamic> _buildFilters() {
    final def = widget.definition;
    return {
      if (def.hasDateRange && _dateFrom != null)
        'date_from': DateFormatter.apiDate(_dateFrom!),
      if (def.hasDateRange && _dateTo != null)
        'date_to': DateFormatter.apiDate(_dateTo!),
      if (def.statusOptions != null && _selectedStatuses.isNotEmpty)
        'status': _selectedStatuses.join(','),
      if (def.hasRoomFilter && _selectedRooms.isNotEmpty)
        'room_id': _selectedRooms
            .map((room) => room.id)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .join(','),
      if (def.hasUserFilter && _selectedUsers.isNotEmpty)
        'user_id': _selectedUsers
            .map((user) => user.id)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .join(','),
      if (def.hasPeriod) 'period': _period,
      if (def.hasPeriod) 'year': _year,
      if (def.hasPeriod && _period == 'daily') 'month': _month,
    };
  }

  Future<void> _preview() async {
    if (_dateFrom != null && _dateTo != null && _dateFrom!.isAfter(_dateTo!)) {
      _showErrorDialog('Tanggal mulai tidak boleh melebihi tanggal akhir.');
      return;
    }

    setState(() {
      _isLoadingPreview = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.fetchReport(
        widget.definition.routeKey,
        _buildFilters(),
      );
      if (mounted) {
        setState(() => _reportData = data);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _resultsKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _download(String format) async {
    setState(() {
      if (format == 'pdf') {
        _isDownloadingPdf = true;
      } else {
        _isDownloadingExcel = true;
      }
    });
    try {
      final file = await _service.downloadReport(
        routeKey: widget.definition.routeKey,
        filters: _buildFilters(),
        format: format,
      );

      await OpenFile.open(file.path);

      // final uri = Uri.file(file.path);
      // if (await canLaunchUrl(uri)) {
      //   await launchUrl(uri);
      // } else {
      //   throw 'Tidak dapat membuka file: ${file.path}';
      // }
    } catch (e) {
      if (mounted) _showErrorDialog('Gagal mengunduh laporan: $e');
    } finally {
      if (mounted) {
        setState(() {
          if (format == 'pdf') {
            _isDownloadingPdf = false;
          } else {
            _isDownloadingExcel = false;
          }
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppSizes.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppSizes.iconXl,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Gagal',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.definition.title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          _buildFilterHeader(),
          _buildFilterSection(),
          const SizedBox(height: AppSizes.lg),
          _buildActionButtons(),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSizes.md),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.error,
              ),
            ),
          ],
          if (_reportData != null) ...[
            const SizedBox(height: AppSizes.xl),
            SectionLabel('Hasil', key: _resultsKey),
            _buildReportPreview(_reportData!),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'FILTER',
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          TextButton.icon(
            onPressed: _resetAllFilters,
            icon: const Icon(Icons.refresh, size: AppSizes.iconXs),
            label: const Text('Reset Filter'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, AppSizes.xl),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final def = widget.definition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (def.hasDateRange) ...[
          FormRowField(
            label: 'Dari Tanggal',
            valueText: _dateFrom != null
                ? DateFormatter.shortDate(_dateFrom!)
                : null,
            icon: Icons.calendar_today_outlined,
            onTap: () => _pickDate(isFrom: true),
          ),
          const SizedBox(height: AppSizes.sm),
          FormRowField(
            label: 'Sampai Tanggal',
            valueText: _dateTo != null
                ? DateFormatter.shortDate(_dateTo!)
                : null,
            icon: Icons.calendar_today_outlined,
            onTap: () => _pickDate(isFrom: false),
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            children: [
              _buildDateQuickAction(
                label: 'Bulan Ini',
                onTap: _setCurrentMonthRange,
              ),
              _buildDateQuickAction(
                label: '3 Bulan',
                onTap: () => _setQuickRange(days: 90),
              ),
              _buildDateQuickAction(
                label: '6 Bulan',
                onTap: () => _setQuickRange(days: 30 * 6),
              ),
              _buildDateQuickAction(
                label: '1 Tahun',
                onTap: () => _setQuickRange(days: 366),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
        ],
        if (def.statusOptions != null) ...[
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                StatusFilterChips(
                  options: def.statusOptions!,
                  selectedValues: _selectedStatuses,
                  onChanged: (v) => setState(() => _selectedStatuses = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
        if (def.hasRoomFilter)
          _buildEntityFilterField<Room>(
            label: 'Ruangan',
            pickerTitle: 'Pilih Ruangan',
            items: _rooms,
            selected: _selectedRooms,
            idOf: (room) => room.id ?? '',
            labelOf: (room) => room.name ?? '-',
            subtitleOf: (room) => room.location,
            leadingIcon: Icons.meeting_room_outlined,
            loadFailed: _roomsLoadFailed,
            onRetry: _loadRooms,
            loadingHint: 'Memuat data ruangan...',
            pickHint: 'Pilih satu atau lebih ruangan',
            searchHint: 'Cari ruangan...',
            emptyMessage: 'Belum ada data ruangan',
            onChanged: (v) => setState(() => _selectedRooms = v),
          ),
        if (def.hasUserFilter)
          _buildEntityFilterField<Profile>(
            label: 'Karyawan',
            pickerTitle: 'Pilih Karyawan',
            items: _users,
            selected: _selectedUsers,
            idOf: (user) => user.id ?? '',
            labelOf: (user) => user.name,
            subtitleOf: (user) => user.divisionLabel,
            leadingBuilder: _buildUserAvatar,
            loadFailed: _usersLoadFailed,
            onRetry: _loadUsers,
            loadingHint: 'Memuat data karyawan...',
            pickHint: 'Pilih satu atau lebih karyawan',
            searchHint: 'Cari karyawan...',
            emptyMessage: 'Belum ada data karyawan',
            onChanged: (v) => setState(() => _selectedUsers = v),
          ),
        if (def.hasPeriod) ...[
          _buildDropdown<String>(
            label: 'Periode',
            value: _period,
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('Harian')),
              DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
              DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
            ],
            onChanged: (v) => setState(() => _period = v ?? 'monthly'),
          ),
          const SizedBox(height: AppSizes.sm),
          _buildDropdown<int>(
            label: 'Tahun',
            value: _year,
            items: List.generate(6, (i) => DateTime.now().year - i)
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (v) => setState(() => _year = v ?? _year),
          ),
          if (_period == 'daily') ...[
            const SizedBox(height: AppSizes.sm),
            _buildDropdown<int>(
              label: 'Bulan',
              value: _month,
              items: List.generate(12, (i) => i + 1)
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(DateFormatter.getMonthName(m)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _month = v ?? _month),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMultiSelectField({
    required String label,
    required String hint,
    required int selectedCount,
    required VoidCallback? onTap,
  }) {
    final valueText = selectedCount > 0 ? '$selectedCount dipilih' : hint;

    return SoftCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      valueText,
                      style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                        color: onTap == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedChips<T>({
    required List<T> values,
    required String Function(T value) getLabel,
    required void Function(T value) onRemove,
  }) {
    return Wrap(
      spacing: AppSizes.xs,
      runSpacing: AppSizes.xs,
      children: values
          .map(
            (value) => InputChip(
              label: Text(getLabel(value)),
              onDeleted: () => onRemove(value),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEntityFilterField<T>({
    required String label,
    required String pickerTitle,
    required List<T> items,
    required List<T> selected,
    required String Function(T item) idOf,
    required String Function(T item) labelOf,
    String? Function(T item)? subtitleOf,
    Widget Function(T item, bool isSelected)? leadingBuilder,
    IconData leadingIcon = Icons.label_outline,
    required bool loadFailed,
    required VoidCallback onRetry,
    required String loadingHint,
    required String pickHint,
    required String searchHint,
    required String emptyMessage,
    required ValueChanged<List<T>> onChanged,
  }) {
    final isEmpty = items.isEmpty;
    final hint = isEmpty
        ? (loadFailed ? 'Gagal memuat, ketuk untuk coba lagi' : loadingHint)
        : pickHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMultiSelectField(
          label: label,
          hint: hint,
          selectedCount: selected.length,
          onTap: isEmpty
              ? (loadFailed ? onRetry : null)
              : () async {
                  final result = await ItemMultiSelectPage.show<T>(
                    context: context,
                    title: pickerTitle,
                    items: items,
                    initialSelected: selected,
                    idOf: idOf,
                    labelOf: labelOf,
                    subtitleOf: subtitleOf,
                    leadingBuilder: leadingBuilder,
                    leadingIcon: leadingIcon,
                    searchHint: searchHint,
                    emptyMessage: emptyMessage,
                  );
                  if (result != null && mounted) onChanged(result);
                },
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: AppSizes.xs),
          _buildSelectedChips<T>(
            values: selected,
            getLabel: labelOf,
            onRemove: (item) => onChanged(
              selected.where((e) => idOf(e) != idOf(item)).toList(),
            ),
          ),
        ],
        const SizedBox(height: AppSizes.sm),
      ],
    );
  }

  Widget _buildUserAvatar(Profile user, bool isSelected) {
    return CircleAvatar(
      backgroundColor: isSelected
          ? AppColors.primary.withAlpha(25)
          : AppColors.background,
      child: Text(
        user.initials,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: AppSizes.fontSm,
        ),
      ),
    );
  }

  void _resetAllFilters() {
    setState(() {
      _selectedStatuses = [];
      _selectedRooms = [];
      _selectedUsers = [];
      _period = 'monthly';
      _year = DateTime.now().year;
      _month = DateTime.now().month;
      _reportData = null;
      _errorMessage = null;
      if (widget.definition.hasDateRange) {
        _setDefaultDateRange();
      }
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final currentValue = isFrom ? _dateFrom : _dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
        if (_dateTo != null && picked.isAfter(_dateTo!)) {
          _dateTo = picked;
        }
      } else {
        _dateTo = picked;
        if (_dateFrom != null && picked.isBefore(_dateFrom!)) {
          _dateFrom = picked;
        }
      }
    });
  }

  void _setQuickRange({required int days}) {
    final today = DateTime.now();
    final dateTo = DateTime(today.year, today.month, today.day);
    setState(() {
      _dateTo = dateTo;
      _dateFrom = dateTo.subtract(Duration(days: days));
    });
  }

  void _setCurrentMonthRange() {
    final today = DateTime.now();
    setState(() {
      _dateFrom = DateTime(today.year, today.month, 1);
      _dateTo = DateTime(today.year, today.month, today.day);
    });
  }

  Widget _buildDateQuickAction({
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppSizes.xl),
        backgroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppSizes.fontXs,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        AppButton(
          text: 'Tampilkan',
          isFullWidth: true,
          isLoading: _isLoadingPreview,
          icon: Icons.visibility_outlined,
          onPressed: _isLoadingPreview ? null : _preview,
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Unduh PDF',
                isOutlined: true,
                isFullWidth: true,
                isLoading: _isDownloadingPdf,
                icon: Icons.picture_as_pdf_outlined,
                onPressed: _isDownloadingPdf ? null : () => _download('pdf'),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: AppButton(
                text: 'Unduh Excel',
                isOutlined: true,
                isFullWidth: true,
                isLoading: _isDownloadingExcel,
                icon: Icons.table_chart_outlined,
                onPressed: _isDownloadingExcel
                    ? null
                    : () => _download('excel'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ponytail: generic key/value + table renderer for all 8 report shapes,
  // bikin layout khusus per-report kalau nanti butuh visual lebih rapi.
  Widget _buildReportPreview(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: data.entries.map((entry) {
        if (entry.value is Map) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: _buildSummarySection(
              entry.key,
              (entry.value as Map).cast<String, dynamic>(),
            ),
          );
        }
        if (entry.value is List) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: _buildTableSection(entry.key, entry.value as List),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildSummarySection(String key, Map<String, dynamic> summary) {
    final tiles = summary.entries.where((e) => e.value is num).toList();
    final textRows = summary.entries.where((e) => e.value is! num).toList();

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _humanizeKey(key),
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          if (tiles.isNotEmpty) _buildStatTileGrid(tiles),
          if (textRows.isNotEmpty) ...[
            if (tiles.isNotEmpty) const SizedBox(height: AppSizes.sm),
            ...textRows.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _humanizeKey(e.key),
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatCellValue(e.value),
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTileGrid(List<MapEntry<String, dynamic>> tiles) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final second = i + 1 < tiles.length ? tiles[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i + 2 < tiles.length ? AppSizes.sm : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStatTile(tiles[i].key, tiles[i].value)),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: second != null
                    ? _buildStatTile(second.key, second.value)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildStatTile(String key, dynamic value) {
    final (color, icon) = _statTileStyle(key);

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          const SizedBox(height: AppSizes.xs),
          Text(
            _formatCellValue(value),
            style: TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            _humanizeKey(key),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _statTileStyle(String key) {
    switch (key) {
      case 'open':
        return (AppColors.warning, Icons.report_problem_outlined);
      case 'in_progress':
        return (AppColors.info, Icons.autorenew);
      case 'resolved':
      case 'completed':
        return (AppColors.success, Icons.check_circle_outline);
      case 'pending':
        return (AppColors.pending, Icons.hourglass_empty);
      case 'approved':
        return (AppColors.approved, Icons.thumb_up_outlined);
      case 'rejected':
        return (AppColors.rejected, Icons.cancel_outlined);
      case 'cancelled':
        return (AppColors.cancelled, Icons.block_outlined);
    }
    if (key.startsWith('total')) {
      return (AppColors.primary, Icons.summarize_outlined);
    }
    return (AppColors.textSecondary, Icons.insights_outlined);
  }

  Widget _buildTableSection(String key, List items) {
    final rows = items.whereType<Map>().toList();
    final allKeys = rows.isEmpty
        ? const <String>[]
        : rows.first.keys.map((k) => '$k').toList();
    final filteredKeys = allKeys.where((k) => !_isHiddenColumn(k)).toList();
    // Kalau semua key kebetulan tersaring (row cuma berisi field internal),
    // tampilkan apa adanya daripada bikin DataTable tanpa kolom.
    final visibleKeys = filteredKeys.isNotEmpty ? filteredKeys : allKeys;

    return SoftCard(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_humanizeKey(key)} (${rows.length})',
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          if (rows.isEmpty)
            const Text(
              'Tidak ada data',
              style: TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.textSecondary,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: AppSizes.xxl,
                dataRowMinHeight: AppSizes.xl,
                headingRowColor: WidgetStateProperty.all(
                  AppColors.background,
                ),
                columns: visibleKeys
                    .map(
                      (k) => DataColumn(
                        label: Text(
                          _humanizeKey(k),
                          style: const TextStyle(
                            fontSize: AppSizes.fontXs,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: rows.asMap().entries.map((entry) {
                  final isEven = entry.key.isEven;
                  return DataRow(
                    color: WidgetStateProperty.all(
                      isEven ? AppColors.white : AppColors.background,
                    ),
                    cells: visibleKeys
                        .map((k) => DataCell(_buildCellContent(k, entry.value[k])))
                        .toList(),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  static const _keyLabels = {
    // Top-level laporan
    'summary': 'Ringkasan',
    'complaints': 'Daftar Keluhan',
    'reservations': 'Daftar Reservasi',
    'rooms': 'Daftar Ruangan',
    'data': 'Data',
    'by_room': 'Per Ruangan',
    'by_user': 'Per Karyawan',
    'by_division': 'Per Divisi',
    'by_facility': 'Per Fasilitas',
    // Status
    'open': 'Terbuka',
    'in_progress': 'Diproses',
    'resolved': 'Selesai',
    'rejected': 'Ditolak',
    'pending': 'Menunggu',
    'approved': 'Disetujui',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
    // Agregat/statistik
    'total': 'Total',
    'total_reservations': 'Total Reservasi',
    'total_rooms_used': 'Total Ruangan Terpakai',
    'total_visitors': 'Total Pengunjung',
    'total_hours': 'Total Jam',
    'avg_hours': 'Rata-rata Jam',
    'total_facilities': 'Total Fasilitas',
    'total_users': 'Total Pengguna',
    'total_rooms': 'Total Ruangan',
    'under_maintenance': 'Sedang Maintenance',
    'total_complaints': 'Total Keluhan',
    'open_complaints': 'Keluhan Terbuka',
    'resolved_complaints': 'Keluhan Selesai',
    'reservation_count': 'Jumlah Reservasi',
    'reserved_count': 'Jumlah Pemakaian',
    'rooms_used': 'Ruangan Terpakai',
    'room_breakdown': 'Rincian Ruangan',
    'visitors': 'Pengunjung',
    'hours': 'Jam',
    'count': 'Jumlah',
    // Filter/periode
    'date_from': 'Dari Tanggal',
    'date_to': 'Sampai Tanggal',
    'period': 'Periode',
    'year': 'Tahun',
    'month': 'Bulan',
    'date': 'Tanggal',
    'week': 'Minggu',
    // Relasi & kolom model
    'room': 'Ruangan',
    'room_name': 'Nama Ruangan',
    'user': 'Karyawan',
    'reporter': 'Pelapor',
    'resolver': 'Diselesaikan Oleh',
    'facility': 'Fasilitas',
    'facility_name': 'Nama Fasilitas',
    'division': 'Divisi',
    'division_name': 'Nama Divisi',
    'division_code': 'Kode Divisi',
    'full_name': 'Nama Lengkap',
    'employee_id': 'No. Karyawan',
    'floor': 'Lantai',
    'capacity': 'Kapasitas',
    'is_maintenance': 'Maintenance',
    'title': 'Judul',
    'description': 'Deskripsi',
    'status': 'Status',
    'resolution_notes': 'Catatan Penyelesaian',
    'resolved_at': 'Waktu Selesai',
    'start_time': 'Mulai',
    'end_time': 'Selesai',
    'purpose': 'Keperluan',
    'visitor_count': 'Jumlah Pengunjung',
    'with_snack': 'Snack',
    'with_lunch': 'Makan Siang',
    'photo_url': 'Foto',
  };

  String _humanizeKey(String key) {
    final label = _keyLabels[key];
    if (label != null) return label;

    final words = key.replaceAll('_', ' ').split(' ');
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Ya' : 'Tidak';
    if (value is Map) {
      final firstName = value['first_name']?.toString();
      final fullNameFromParts = firstName != null
          ? '$firstName ${value['last_name'] ?? ''}'.trim()
          : null;
      final name = value['name']?.toString() ??
          value['full_name']?.toString() ??
          value['title']?.toString() ??
          (fullNameFromParts?.isNotEmpty == true ? fullNameFromParts : null);
      return name ?? value['id']?.toString() ?? '-';
    }
    if (value is List) return '${value.length} item';
    return '$value';
  }

  Widget _buildCellContent(String key, dynamic value) {
    if (key.endsWith('_url')) {
      final url = value is String && value.trim().isNotEmpty ? value : null;
      return InkWell(
        onTap: url == null ? null : () => _openImageViewer(url),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xs),
          child: Icon(
            Icons.photo_outlined,
            size: AppSizes.iconSm,
            color: url != null ? AppColors.primary : AppColors.textDisabled,
          ),
        ),
      );
    }
    return Text(
      _formatCellValue(value),
      style: const TextStyle(fontSize: AppSizes.fontXs),
    );
  }

  void _openImageViewer(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerPage(imageProvider: NetworkImage(url)),
      ),
    );
  }

  bool _isHiddenColumn(String key) {
    const hidden = {
      'id',
      'created_at',
      'updated_at',
      'deleted_at',
      'created_by',
      'updated_by',
      'deleted_by',
      'photo_path',
    };
    if (hidden.contains(key)) return true;
    return key.endsWith('_id') || key.endsWith('_by');
  }
}
