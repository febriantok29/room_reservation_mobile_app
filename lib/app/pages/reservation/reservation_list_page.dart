import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/create_reservation_wizard_page.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/cards/reservation_card.dart';

class ReservationListPage extends StatefulWidget {
  final Profile user;

  const ReservationListPage({super.key, required this.user});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  final _reservationService = ReservationService();

  ReservationStatus? _filterStatus;
  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _error;

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
      );
      if (mounted) setState(() => _reservations = result.reservations);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setFilter(ReservationStatus? status) {
    if (_filterStatus == status) return;
    setState(() => _filterStatus = status);
    _loadReservations();
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
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.border,
              minHeight: 2,
            ),
          _buildFilterRow(),
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

  Widget _buildFilterRow() {
    final statuses = ReservationStatus.values;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(null, 'Semua', Icons.list_outlined),
            const SizedBox(width: AppSizes.xs),
            ...statuses.map(
              (s) => Padding(
                padding: const EdgeInsets.only(right: AppSizes.xs),
                child: _buildFilterChip(s, s.displayName, s.icon),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ReservationStatus? status, String label, IconData icon) {
    final isSelected = _filterStatus == status;
    final chipColor = status?.color ?? AppColors.textSecondary;

    return GestureDetector(
      onTap: () => _setFilter(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withAlpha(25) : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? chipColor : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.xxs),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontXs,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? chipColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
    final isFiltered = _filterStatus != null;

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
                  ? 'Tidak ada reservasi dengan status "${_filterStatus?.displayName}"'
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
                onPressed: () => _setFilter(null),
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
