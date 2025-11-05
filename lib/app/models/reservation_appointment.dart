import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';

/// Model untuk mengkonversi Reservation menjadi Appointment untuk Syncfusion Calendar
class ReservationAppointment extends Appointment {
  final Reservation reservation;

  ReservationAppointment({
    required this.reservation,
    required super.startTime,
    required super.endTime,
    required super.subject,
    Color? color,
    super.notes,
  }) : super(color: color ?? _getColorByStatus(reservation.status));

  /// Factory constructor untuk membuat appointment dari reservation
  factory ReservationAppointment.fromReservation(Reservation reservation) {
    final room = reservation.room;
    final user = reservation.user;

    final subject = room?.name ?? 'Reservasi';
    final notes =
        '''
${reservation.purpose ?? 'Tidak ada keterangan'}
Pemesan: ${user?.name ?? 'Unknown'}
Jumlah Tamu: ${reservation.visitorCount ?? 0}
Status: ${reservation.status}
''';

    return ReservationAppointment(
      reservation: reservation,
      startTime: reservation.startTime ?? DateTime.now(),
      endTime:
          reservation.endTime ?? DateTime.now().add(const Duration(hours: 1)),
      subject: subject,
      notes: notes,
      color: _getColorByStatus(reservation.status),
    );
  }

  /// Mendapatkan warna berdasarkan status reservasi
  static Color _getColorByStatus(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Mendapatkan icon berdasarkan status reservasi
  static IconData getIconByStatus(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'PENDING':
        return Icons.pending;
      case 'REJECTED':
        return Icons.cancel;
      case 'CANCELLED':
        return Icons.block;
      case 'COMPLETED':
        return Icons.done_all;
      default:
        return Icons.event;
    }
  }
}

/// Data source untuk Syncfusion Calendar
class ReservationDataSource extends CalendarDataSource {
  ReservationDataSource(List<ReservationAppointment> appointments) {
    this.appointments = appointments;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endTime;
  }

  @override
  String getSubject(int index) {
    return appointments![index].subject;
  }

  @override
  Color getColor(int index) {
    return appointments![index].color;
  }

  @override
  String? getNotes(int index) {
    return appointments![index].notes;
  }

  /// Mendapatkan reservation dari appointment
  Reservation? getReservation(int index) {
    if (appointments != null && index < appointments!.length) {
      final appointment = appointments![index];
      if (appointment is ReservationAppointment) {
        return appointment.reservation;
      }
    }
    return null;
  }
}
