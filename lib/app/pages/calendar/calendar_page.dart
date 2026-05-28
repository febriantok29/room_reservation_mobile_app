import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/models/reservation_appointment.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';
import 'package:room_reservation_mobile_app/app/utils/date_formatter.dart';

class CalendarPage extends StatefulWidget {
  final Profile user;

  const CalendarPage({super.key, required this.user});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarController _calendarController = CalendarController();
  final ReservationService _reservationService = ReservationService();

  CalendarView _currentView = CalendarView.month;
  DateTime _selectedDate = DateTime.now();
  
  Future<CalendarResult>? _calendarFuture;

  int get _currentYear => _selectedDate.year;
  int get _currentMonth => _selectedDate.month;

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

  void _loadCalendar() {
    setState(() {
      _calendarFuture = _reservationService.getCalendar(
        year: _currentYear,
        month: _currentMonth,
      );
    });
  }

  /// Handle pull to refresh
  Future<void> _onRefresh() async {
    _loadCalendar();
    if (_calendarFuture != null) {
      await _calendarFuture;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Reservasi'),
        actions: [
          // View mode selector
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_module),
            onSelected: (CalendarView view) {
              setState(() {
                _currentView = view;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarView.day,
                child: Row(
                  children: [
                    Icon(Icons.view_day),
                    SizedBox(width: 8),
                    Text('Hari'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.week,
                child: Row(
                  children: [
                    Icon(Icons.view_week),
                    SizedBox(width: 8),
                    Text('Minggu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('Bulan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.schedule,
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Jadwal'),
                  ],
                ),
              ),
            ],
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<CalendarResult>(
        future: _calendarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final calendarResult = snapshot.data;
          final reservations = calendarResult?.reservations ?? [];

          if (reservations.isEmpty) {
            return _buildEmptyState();
          }

          final appointments = reservations
              .map((r) => ReservationAppointment.fromReservation(r))
              .toList();

          final dataSource = ReservationDataSource(appointments);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                _buildInfoPanel(reservations),
                Expanded(
                  child: SfCalendar(
                    view: _currentView,
                    controller: _calendarController,
                    dataSource: dataSource,
                    initialSelectedDate: _selectedDate,
                    firstDayOfWeek: 1,
                    showNavigationArrow: true,
                    showDatePickerButton: true,
                    allowViewNavigation: true,
                    monthViewSettings: const MonthViewSettings(
                      appointmentDisplayMode:
                          MonthAppointmentDisplayMode.appointment,
                      showAgenda: true,
                      agendaViewHeight: 150,
                      navigationDirection: MonthNavigationDirection.vertical,
                    ),
                    timeSlotViewSettings: const TimeSlotViewSettings(
                      startHour: 7,
                      endHour: 20,
                      timeFormat: 'HH:mm',
                      timeInterval: Duration(minutes: 30),
                    ),
                    onTap: (CalendarTapDetails details) {
                      if (details.targetElement ==
                          CalendarElement.appointment) {
                        _showAppointmentDetails(
                          context,
                          details.appointments!.first as ReservationAppointment,
                        );
                      }
                    },
                    onViewChanged: (ViewChangedDetails details) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          final newDate = details
                              .visibleDates[details.visibleDates.length ~/ 2];
                          
                          if (newDate.year != _currentYear || newDate.month != _currentMonth) {
                            setState(() {
                              _selectedDate = newDate;
                              _loadCalendar();
                            });
                          } else {
                            _selectedDate = newDate;
                          }
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Info panel di atas kalender
  Widget _buildInfoPanel(List<Reservation> reservations) {
    final active = reservations.where((r) => r.status.isActive).length;
    final completed = reservations
        .where((r) => r.status == ReservationStatus.completed)
        .length;
    final cancelled = reservations
        .where((r) => r.status == ReservationStatus.cancelled)
        .length;
    final total = reservations.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            icon: Icons.event,
            label: 'Total',
            value: '$total',
            color: Colors.blue,
          ),
          _buildInfoItem(
            icon: Icons.check_circle,
            label: 'Aktif',
            value: '$active',
            color: Colors.green,
          ),
          _buildInfoItem(
            icon: Icons.done_all,
            label: 'Selesai',
            value: '$completed',
            color: Colors.grey,
          ),
          _buildInfoItem(
            icon: Icons.cancel,
            label: 'Batal',
            value: '$cancelled',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ],
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada reservasi',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tarik ke bawah untuk refresh',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Error state
  Widget _buildErrorState(String error) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tarik ke bawah untuk refresh',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show appointment details in bottom sheet
  void _showAppointmentDetails(
    BuildContext context,
    ReservationAppointment appointment,
  ) {
    final reservation = appointment.reservation;
    final currentStatus = reservation.status;
    final room = reservation.room;
    final user = reservation.user;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room?.name ?? 'Reservasi',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: currentStatus.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(currentStatus.icon, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          currentStatus.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Detail information
              _buildDetailRow(
                icon: Icons.person,
                label: 'Pemesan',
                value: user?.name ?? 'Unknown',
              ),
              _buildDetailRow(
                icon: Icons.location_on,
                label: 'Lokasi',
                value: room?.location ?? 'Tidak diketahui',
              ),
              _buildDetailRow(
                icon: Icons.access_time,
                label: 'Waktu Mulai',
                value: reservation.startTime != null
                    ? DateFormatter.shortDateTime(reservation.startTime!)
                    : '-',
              ),
              _buildDetailRow(
                icon: Icons.access_time,
                label: 'Waktu Selesai',
                value: reservation.endTime != null
                    ? DateFormatter.shortDateTime(reservation.endTime!)
                    : '-',
              ),
              _buildDetailRow(
                icon: Icons.group,
                label: 'Jumlah Tamu',
                value: '${reservation.visitorCount ?? 0} orang',
              ),
              const SizedBox(height: 16),
              // Purpose
              const Text(
                'Keperluan:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reservation.purpose ?? 'Tidak ada keterangan',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
