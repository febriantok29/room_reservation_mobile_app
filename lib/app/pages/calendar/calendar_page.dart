import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/models/reservation_appointment.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/create_reservation_wizard_page.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/filter_icon_button.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';
import 'package:rapa_track_mobile_app/app/widgets/filter_bottom_sheet.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  final Profile user;

  const CalendarPage({super.key, required this.user});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _calendarController = CalendarController();
  final _reservationService = ReservationService();

  CalendarView _currentView = CalendarView.month;
  DateTime _visibleDate = DateTime.now();
  final Set<ReservationStatus> _filterStatuses = {};

  List<ReservationAppointment> _appointments = [];
  bool _isLoading = false;
  String? _error;

  final Map<String, List<ReservationAppointment>> _cache = {};

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  List<ReservationAppointment> get _filteredAppointments {
    if (_filterStatuses.isEmpty) return _appointments;
    return _appointments
        .where((a) => _filterStatuses.contains(a.reservation.status))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendar({bool invalidateCache = false}) async {
    final key =
        '${_visibleDate.year}-${_visibleDate.month.toString().padLeft(2, '0')}';

    if (!invalidateCache && _cache.containsKey(key)) {
      setState(() => _appointments = _cache[key]!);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _reservationService.getCalendar(
        year: _visibleDate.year,
        month: _visibleDate.month,
      );
      final appointments = result.reservations
          .map((r) => ReservationAppointment.fromReservation(r))
          .toList();
      _cache[key] = appointments;
      if (mounted) setState(() => _appointments = appointments);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToToday() {
    final now = DateTime.now();
    _calendarController.displayDate = now;
    if (_visibleDate.year != now.year || _visibleDate.month != now.month) {
      setState(() => _visibleDate = now);
      _loadCalendar();
    }
  }

  void _changeView(CalendarView view) {
    setState(() => _currentView = view);
    _calendarController.view = view;
  }

  Future<void> _showFilterSheet() async {
    CalendarView tempView = _currentView;
    final tempStatuses = Set<ReservationStatus>.from(_filterStatuses);

    const viewOptions = <CalendarView, String>{
      CalendarView.month: 'Bulan',
      CalendarView.week: 'Minggu',
      CalendarView.day: 'Hari',
      CalendarView.schedule: 'Jadwal',
    };

    const statuses = [
      ReservationStatus.pending,
      ReservationStatus.approved,
      ReservationStatus.completed,
      ReservationStatus.rejected,
      ReservationStatus.cancelled,
    ];

    await FilterBottomSheet.show(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => FilterBottomSheet(
          title: 'Filter Kalender',
          onReset: () => setSheetState(() {
            tempView = CalendarView.month;
            tempStatuses.clear();
          }),
          onApply: () {
            setState(() {
              _filterStatuses
                ..clear()
                ..addAll(tempStatuses);
            });
            if (tempView != _currentView) _changeView(tempView);
            Navigator.of(sheetContext).pop();
          },
          children: [
            FilterSection(
              label: 'Tampilan',
              child: Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: viewOptions.entries
                    .map(
                      (entry) => FilterPill(
                        label: entry.value,
                        isSelected: tempView == entry.key,
                        onTap: () => setSheetState(() => tempView = entry.key),
                      ),
                    )
                    .toList(),
              ),
            ),
            FilterSection(
              label: 'Status Reservasi',
              child: Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: [
                  FilterPill(
                    label: 'Semua',
                    isSelected: tempStatuses.isEmpty,
                    onTap: () => setSheetState(tempStatuses.clear),
                  ),
                  ...statuses.map(
                    (s) => FilterPill(
                      label: s.displayName,
                      isSelected: tempStatuses.contains(s),
                      onTap: () => setSheetState(() {
                        if (tempStatuses.contains(s)) {
                          tempStatuses.remove(s);
                        } else {
                          tempStatuses.add(s);
                        }
                      }),
                    ),
                  ),
                ],
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
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.border,
              minHeight: 2,
            ),
          if (_error != null) _buildErrorBanner(),
          Expanded(child: _buildCalendar()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateReservationFromFab,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Buat Reservasi',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kalender Reservasi',
            style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.white),
          ),
          Text(
            '${_monthName(_visibleDate.month)} ${_visibleDate.year}',
            style: const TextStyle(
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.today_outlined),
          onPressed: _goToToday,
          tooltip: 'Hari Ini',
        ),
        FilterIconButton(
          activeCount: _filterStatuses.length,
          onPressed: _showFilterSheet,
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return SfCalendar(
      view: _currentView,
      controller: _calendarController,
      dataSource: ReservationDataSource(_filteredAppointments),
      initialDisplayDate: DateTime.now(),
      firstDayOfWeek: 1,
      showNavigationArrow: true,
      showDatePickerButton: false,
      allowViewNavigation: false,
      headerHeight: 48,
      headerStyle: const CalendarHeaderStyle(
        textAlign: TextAlign.center,
        textStyle: TextStyle(
          fontSize: AppSizes.fontMd,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      viewHeaderStyle: const ViewHeaderStyle(
        dayTextStyle: TextStyle(
          fontSize: AppSizes.fontXs,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        dateTextStyle: TextStyle(
          fontSize: AppSizes.fontSm,
          color: AppColors.textPrimary,
        ),
      ),
      todayHighlightColor: AppColors.primary,
      selectionDecoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
      ),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: true,
        agendaViewHeight: 180,
        navigationDirection: MonthNavigationDirection.horizontal,
        appointmentDisplayCount: 3,
        agendaStyle: AgendaStyle(
          dayTextStyle: TextStyle(
            fontSize: AppSizes.fontXl,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          dateTextStyle: TextStyle(
            fontSize: AppSizes.fontXs,
            color: AppColors.textSecondary,
          ),
          appointmentTextStyle: TextStyle(
            fontSize: AppSizes.fontXs,
            color: AppColors.white,
          ),
        ),
      ),
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 7,
        endHour: 20,
        timeFormat: 'HH:mm',
        timeInterval: Duration(minutes: 30),
        timeTextStyle: TextStyle(
          fontSize: AppSizes.fontXs,
          color: AppColors.textSecondary,
        ),
      ),
      onTap: _onCalendarTap,
      onViewChanged: (details) {
        final mid = details.visibleDates[details.visibleDates.length ~/ 2];
        if (mid.year != _visibleDate.year || mid.month != _visibleDate.month) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _visibleDate = mid);
            _loadCalendar();
          });
        }
      },
    );
  }

  void _onCalendarTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment &&
        details.appointments != null &&
        details.appointments!.isNotEmpty) {
      final appt = details.appointments!.first;
      if (appt is ReservationAppointment) {
        _showAppointmentDetails(appt);
      }
      return;
    }

    // cell tap only selects the date — agenda panel updates automatically
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
              'Gagal memuat data.',
              style: TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _loadCalendar(invalidateCache: true),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(ReservationAppointment appointment) {
    final reservation = appointment.reservation;
    final status = reservation.status;
    final room = reservation.room;
    final booker = reservation.user;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.md,
            AppSizes.lg,
            AppSizes.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      room?.name ?? 'Reservasi',
                      style: const TextStyle(
                        fontSize: AppSizes.fontXl,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSizes.md),
              _buildSheetRow(
                Icons.person_outline,
                'Pemesan',
                booker?.name ?? '-',
              ),
              if (room?.location != null)
                _buildSheetRow(
                  Icons.location_on_outlined,
                  'Lokasi',
                  room!.location,
                ),
              _buildSheetRow(
                Icons.schedule_outlined,
                'Waktu Mulai',
                reservation.startTime != null
                    ? DateFormatter.shortDateTime(reservation.startTime!)
                    : '-',
              ),
              _buildSheetRow(
                Icons.schedule_outlined,
                'Waktu Selesai',
                reservation.endTime != null
                    ? DateFormatter.shortDateTime(reservation.endTime!)
                    : '-',
              ),
              _buildSheetRow(
                Icons.group_outlined,
                'Jumlah Tamu',
                '${reservation.visitorCount ?? 0} orang',
              ),
              if (reservation.purpose != null &&
                  reservation.purpose!.isNotEmpty)
                _buildSheetRow(
                  Icons.description_outlined,
                  'Keperluan',
                  reservation.purpose!,
                ),
              if (_canModerate(reservation) || _canCancel(reservation)) ...[
                const SizedBox(height: AppSizes.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSizes.lg),
                if (_canModerate(reservation)) ...[
                  _buildModerationButtons(reservation),
                  if (_canCancel(reservation))
                    const SizedBox(height: AppSizes.sm),
                ],
                if (_canCancel(reservation)) _buildCancelButton(reservation),
              ],
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReservationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: status.color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
        border: Border.all(color: status.color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: AppSizes.xxs),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.textDisabled),
          const SizedBox(width: AppSizes.md),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canCancel(Reservation reservation) {
    if (reservation.id == null) return false;

    final isOwner =
        reservation.userId != null && reservation.userId == widget.user.id;
    if (!isOwner && !widget.user.isAdmin) return false;

    final statusAllowed =
        reservation.status == ReservationStatus.pending ||
        reservation.status == ReservationStatus.approved;
    if (!statusAllowed) return false;

    return reservation.startTime != null &&
        reservation.startTime!.isAfter(DateTime.now());
  }

  bool _canModerate(Reservation reservation) {
    return reservation.id != null &&
        widget.user.isAdmin &&
        reservation.status == ReservationStatus.pending;
  }

  Widget _buildCancelButton(Reservation reservation) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleReservationAction(
          action: () => _reservationService.cancelReservation(reservation.id!),
          icon: Icons.event_busy_outlined,
          color: AppColors.error,
          title: 'Batalkan Reservasi?',
          message:
              'Reservasi ${reservation.room?.name ?? 'ruangan'} pada '
              '${reservation.startTime != null ? DateFormatter.shortDateTime(reservation.startTime!) : '-'} '
              'akan dibatalkan.',
          confirmLabel: 'Ya, Batalkan',
          successMessage: 'Reservasi berhasil dibatalkan.',
        ),
        icon: const Icon(Icons.event_busy_outlined, size: AppSizes.iconSm),
        label: const Text('Batalkan Reservasi'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          minimumSize: const Size(0, AppSizes.buttonHeightLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
        ),
      ),
    );
  }

  Widget _buildModerationButtons(Reservation reservation) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleReservationAction(
              action: () =>
                  _reservationService.rejectReservation(reservation.id!),
              icon: Icons.close_outlined,
              color: AppColors.error,
              title: 'Tolak Reservasi?',
              message:
                  'Reservasi dari ${reservation.user?.name ?? 'karyawan'} akan ditolak.',
              confirmLabel: 'Ya, Tolak',
              successMessage: 'Reservasi berhasil ditolak.',
            ),
            icon: const Icon(Icons.close_outlined, size: AppSizes.iconSm),
            label: const Text('Tolak'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(0, AppSizes.buttonHeightLg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleReservationAction(
              action: () =>
                  _reservationService.approveReservation(reservation.id!),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              title: 'Setujui Reservasi?',
              message:
                  'Reservasi dari ${reservation.user?.name ?? 'karyawan'} akan disetujui.',
              confirmLabel: 'Ya, Setujui',
              successMessage: 'Reservasi berhasil disetujui.',
            ),
            icon: const Icon(Icons.check_outlined, size: AppSizes.iconSm),
            label: const Text('Setujui'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              minimumSize: const Size(0, AppSizes.buttonHeightLg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleReservationAction({
    required Future<void> Function() action,
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String confirmLabel,
    required String successMessage,
  }) async {
    final confirmed = await _showConfirmDialog(
      icon: icon,
      color: color,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    );

    if (confirmed != true || !mounted) return;

    Navigator.of(context).pop();

    setState(() => _isLoading = true);

    try {
      await action();
      if (!mounted) return;
      await _loadCalendar(invalidateCache: true);
      if (!mounted) return;
      _showResultDialog(
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        title: 'Berhasil',
        message: successMessage,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showResultDialog(
        icon: Icons.error_outline,
        color: AppColors.error,
        title: 'Gagal',
        message: e.toString(),
      );
    }
  }

  Future<bool?> _showConfirmDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        contentPadding: const EdgeInsets.all(AppSizes.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppSizes.iconXl),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontLg,
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResultDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        contentPadding: const EdgeInsets.all(AppSizes.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppSizes.iconXl),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontLg,
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
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateReservationFromFab() {
    final selected = _calendarController.selectedDate;
    DateTime initialDate = _today;
    if (selected != null) {
      final selectedDay = DateTime(selected.year, selected.month, selected.day);
      if (!selectedDay.isBefore(_today)) initialDate = selected;
    }
    _navigateToCreateReservation(initialDate: initialDate);
  }

  Future<void> _navigateToCreateReservation({DateTime? initialDate}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateReservationWizardPage(
          currentUser: widget.user,
          initialDate: initialDate,
        ),
      ),
    );
    if (result == true) _loadCalendar(invalidateCache: true);
  }

  String _monthName(int month) => DateFormatter.getMonthName(month);
}
