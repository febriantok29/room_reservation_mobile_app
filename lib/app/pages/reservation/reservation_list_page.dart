import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/create_reservation_wizard_page.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/cards/reservation_card.dart';
import 'package:rapa_track_mobile_app/app/ui_items/filter_icon_button.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';
import 'package:rapa_track_mobile_app/app/widgets/filter_bottom_sheet.dart';

class ReservationListPage extends StatefulWidget {
  final Profile user;

  const ReservationListPage({super.key, required this.user});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  final _reservationService = ReservationService();

  ReservationStatus? _filterStatus;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _error;

  bool get _hasActiveFilters =>
      _filterStatus != null || _dateFrom != null || _dateTo != null;

  int get _activeFilterCount =>
      (_filterStatus != null ? 1 : 0) +
      ((_dateFrom != null || _dateTo != null) ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _reservationService.getReservationList(
        status: _filterStatus?.name,
        dateFrom: _dateFrom != null ? DateFormatter.apiDate(_dateFrom!) : null,
        dateTo: _dateTo != null ? DateFormatter.apiDate(_dateTo!) : null,
      );
      if (mounted) setState(() => _reservations = result.reservations);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = null;
      _dateFrom = null;
      _dateTo = null;
    });
    _loadReservations();
  }

  Future<void> _showFilterSheet() async {
    ReservationStatus? tempStatus = _filterStatus;
    DateTime? tempFrom = _dateFrom;
    DateTime? tempTo = _dateTo;

    await FilterBottomSheet.show(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) {
          Future<void> pickDate({required bool isFrom}) async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: sheetContext,
              initialDate: isFrom
                  ? (tempFrom ?? now)
                  : (tempTo ?? tempFrom ?? now),
              firstDate: isFrom
                  ? DateTime(now.year - 1)
                  : (tempFrom ?? DateTime(now.year - 1)),
              lastDate: DateTime(now.year + 1, 12, 31),
              locale: const Locale('id', 'ID'),
              helpText: isFrom ? 'Pilih Tanggal Awal' : 'Pilih Tanggal Akhir',
              cancelText: 'Batal',
              confirmText: 'OK',
            );
            if (picked == null) return;
            setSheetState(() {
              if (isFrom) {
                tempFrom = picked;
                if (tempTo != null && tempTo!.isBefore(picked)) tempTo = null;
              } else {
                tempTo = picked;
              }
            });
          }

          return FilterBottomSheet(
            title: 'Filter Reservasi',
            onReset: () => setSheetState(() {
              tempStatus = null;
              tempFrom = null;
              tempTo = null;
            }),
            onApply: () {
              setState(() {
                _filterStatus = tempStatus;
                _dateFrom = tempFrom;
                _dateTo = tempTo;
              });
              _loadReservations();
              Navigator.of(sheetContext).pop();
            },
            children: [
              FilterSection(
                label: 'Status',
                child: Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    FilterPill(
                      label: 'Semua',
                      isSelected: tempStatus == null,
                      onTap: () => setSheetState(() => tempStatus = null),
                    ),
                    ...ReservationStatus.values.map(
                      (s) => FilterPill(
                        label: s.displayName,
                        isSelected: tempStatus == s,
                        onTap: () => setSheetState(() => tempStatus = s),
                      ),
                    ),
                  ],
                ),
              ),
              FilterSection(
                label: 'Rentang Tanggal',
                child: Row(
                  children: [
                    Expanded(
                      child: FilterDateField(
                        label: 'Dari',
                        valueText: tempFrom != null
                            ? DateFormatter.shortDate(tempFrom!)
                            : null,
                        onTap: () => pickDate(isFrom: true),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: FilterDateField(
                        label: 'Sampai',
                        valueText: tempTo != null
                            ? DateFormatter.shortDate(tempTo!)
                            : null,
                        onTap: () => pickDate(isFrom: false),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.user.isAdmin ? 'Semua Reservasi' : 'Reservasi Saya',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          FilterIconButton(
            activeCount: _activeFilterCount,
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.border,
              minHeight: 2,
            ),
          if (_error != null) _buildErrorBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReservation,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Buat Reservasi',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      color: AppColors.error.withAlpha(15),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: AppSizes.iconSm,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSizes.sm),
          const Expanded(
            child: Text(
              'Gagal memuat data. Tarik ke bawah untuk coba lagi.',
              style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: _loadReservations,
            child: const Text(
              'Coba Lagi',
              style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_isLoading && _reservations.isEmpty && _error == null) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg,
          AppSizes.md,
          AppSizes.lg,
          AppSizes.xxxl + AppSizes.xl,
        ),
        itemCount: _reservations.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: ReservationCard(
            reservation: _reservations[index],
            user: widget.user,
            onRefresh: _loadReservations,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _hasActiveFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered ? Icons.filter_list_off : Icons.event_busy_outlined,
              size: AppSizes.iconXl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              isFiltered ? 'Tidak Ada Hasil' : 'Belum Ada Reservasi',
              style: const TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              isFiltered
                  ? 'Tidak ada reservasi yang cocok dengan filter'
                  : (widget.user.isAdmin
                      ? 'Belum ada reservasi yang dibuat oleh pengguna'
                      : 'Anda belum memiliki reservasi.\nBuat reservasi pertama Anda!'),
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textDisabled,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: AppSizes.lg),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: AppSizes.iconSm),
                label: const Text('Hapus Filter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createReservation() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateReservationWizardPage(currentUser: widget.user),
      ),
    );
    if (result == true) _loadReservations();
  }
}
