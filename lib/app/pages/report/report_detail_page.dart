import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/pages/report/report_definitions.dart';
import 'package:rapa_track_mobile_app/app/services/report_service.dart';
import 'package:rapa_track_mobile_app/app/services/room_service.dart';
import 'package:rapa_track_mobile_app/app/services/user_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/app_button.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';
import 'package:rapa_track_mobile_app/app/widgets/form_items.dart';

class ReportDetailPage extends StatefulWidget {
  final ReportDefinition definition;

  const ReportDetailPage({super.key, required this.definition});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final _service = ReportService();
  final _roomService = RoomService();
  final _userService = UserService();

  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _status;
  Room? _selectedRoom;
  Profile? _selectedUser;
  String _period = 'monthly';
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  List<Room> _rooms = [];
  List<Profile> _users = [];

  Map<String, dynamic>? _reportData;
  bool _isLoadingPreview = false;
  bool _isDownloadingPdf = false;
  bool _isDownloadingExcel = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.definition.hasRoomFilter) _loadRooms();
    if (widget.definition.hasUserFilter) _loadUsers();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await _roomService.getRoomList(perPage: 100);
      if (mounted) setState(() => _rooms = rooms);
    } catch (_) {}
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getUsers(perPage: 100);
      if (mounted) setState(() => _users = users);
    } catch (_) {}
  }

  Map<String, dynamic> _buildFilters() {
    final def = widget.definition;
    return {
      if (def.hasDateRange && _dateFrom != null)
        'date_from': DateFormatter.apiDate(_dateFrom!),
      if (def.hasDateRange && _dateTo != null)
        'date_to': DateFormatter.apiDate(_dateTo!),
      if (def.statusOptions != null && _status != null) 'status': _status,
      if (def.hasRoomFilter && _selectedRoom != null)
        'room_id': _selectedRoom!.id,
      if (def.hasUserFilter && _selectedUser != null)
        'user_id': _selectedUser!.id,
      if (def.hasPeriod) 'period': _period,
      if (def.hasPeriod) 'year': _year,
      if (def.hasPeriod && _period == 'daily') 'month': _month,
    };
  }

  Future<void> _preview() async {
    setState(() {
      _isLoadingPreview = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.fetchReport(
        widget.definition.routeKey,
        _buildFilters(),
      );
      if (mounted) setState(() => _reportData = data);
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
      await OpenFilex.open(file.path);
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
          const SectionLabel('Filter'),
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
            const SectionLabel('Hasil'),
            _buildReportPreview(_reportData!),
          ],
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
        ],
        if (def.statusOptions != null) ...[
          _buildDropdown<String>(
            label: 'Status',
            value: _status,
            items: def.statusOptions!
                .map((s) => DropdownMenuItem(value: s.value, child: Text(s.label)))
                .toList(),
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
        if (def.hasRoomFilter) ...[
          _buildDropdown<Room>(
            label: 'Ruangan',
            value: _selectedRoom,
            items: _rooms
                .map((r) => DropdownMenuItem(value: r, child: Text(r.name ?? '-')))
                .toList(),
            onChanged: (v) => setState(() => _selectedRoom = v),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
        if (def.hasUserFilter) ...[
          _buildDropdown<Profile>(
            label: 'Karyawan',
            value: _selectedUser,
            items: _users
                .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedUser = v),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
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
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
      } else {
        _dateTo = picked;
      }
    });
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
          ...summary.entries.map(
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
      ),
    );
  }

  Widget _buildTableSection(String key, List items) {
    final rows = items.whereType<Map>().toList();

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
                columns: rows.first.keys
                    .map(
                      (k) => DataColumn(
                        label: Text(
                          _humanizeKey('$k'),
                          style: const TextStyle(
                            fontSize: AppSizes.fontXs,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: rows
                    .map(
                      (row) => DataRow(
                        cells: row.values
                            .map(
                              (v) => DataCell(
                                Text(
                                  _formatCellValue(v),
                                  style: const TextStyle(
                                    fontSize: AppSizes.fontXs,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _humanizeKey(String key) {
    final words = key.replaceAll('_', ' ').split(' ');
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Ya' : 'Tidak';
    if (value is Map) {
      return value['name']?.toString() ?? value.values.first?.toString() ?? '-';
    }
    if (value is List) return '${value.length} item';
    return '$value';
  }
}
