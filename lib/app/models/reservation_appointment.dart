import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
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
  }) : super(color: color ?? reservation.status.color);

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
      color: reservation.status.color,
    );
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
