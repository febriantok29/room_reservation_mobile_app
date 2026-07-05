import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/reservation_appointment.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/create_reservation_wizard_page.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';
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

  void _toggleFilter(ReservationStatus status) {
    setState(() {
      if (_filterStatuses.contains(status)) {
        _filterStatuses.remove(status);
      } else {
        _filterStatuses.add(status);
      }
    });
  }

  void _clearFilters() => setState(() => _filterStatuses.clear());

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
          _buildFilterRow(),
          const Divider(height: 1),
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
        PopupMenuButton<CalendarView>(
          icon: const Icon(Icons.view_module_outlined),
          tooltip: 'Tampilan',
          onSelected: _changeView,
          itemBuilder: (_) => [
            _viewMenuItem(CalendarView.month, Icons.calendar_month_outlined, 'Bulan'),
            _viewMenuItem(CalendarView.week, Icons.view_week_outlined, 'Minggu'),
            _viewMenuItem(CalendarView.day, Icons.view_day_outlined, 'Hari'),
            _viewMenuItem(CalendarView.schedule, Icons.list_alt_outlined, 'Jadwal'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<CalendarView> _viewMenuItem(
    CalendarView view,
    IconData icon,
    String label,
  ) {
    final isSelected = _currentView == view;
    return PopupMenuItem(
      value: view,
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSizes.iconSm,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizes.md),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: AppSizes.iconSm, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    const statuses = [
      ReservationStatus.pending,
      ReservationStatus.approved,
      ReservationStatus.completed,
      ReservationStatus.rejected,
      ReservationStatus.cancelled,
    ];

    final allSelected = _filterStatuses.isEmpty;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: Wrap(
        spacing: AppSizes.xs,
        runSpacing: AppSizes.xs,
        children: [
          _buildChip(
            label: 'Semua',
            icon: Icons.all_inclusive,
            isSelected: allSelected,
            color: AppColors.primary,
            onTap: _clearFilters,
          ),
          ...statuses.map(
            (s) => _buildChip(
              label: s.displayName,
              icon: s.icon,
              isSelected: _filterStatuses.contains(s),
              color: s.color,
              onTap: () => _toggleFilter(s),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(25) : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? color : AppColors.textSecondary),
            const SizedBox(width: AppSizes.xxs),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontXs,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
          setState(() => _visibleDate = mid);
          _loadCalendar();
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
              style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => _loadCalendar(invalidateCache: true),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.error),
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
              _buildSheetRow(Icons.person_outline, 'Pemesan', booker?.name ?? '-'),
              if (room?.location != null)
                _buildSheetRow(Icons.location_on_outlined, 'Lokasi', room!.location),
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
              if (reservation.purpose != null && reservation.purpose!.isNotEmpty)
                _buildSheetRow(
                  Icons.description_outlined,
                  'Keperluan',
                  reservation.purpose!,
                ),
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

  String _monthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return months[month - 1];
  }
}
