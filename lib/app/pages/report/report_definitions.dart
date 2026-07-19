import 'package:flutter/material.dart';

class ReportStatusOption {
  final String value;
  final String label;

  const ReportStatusOption(this.value, this.label);
}

class ReportDefinition {
  final String routeKey;
  final String title;
  final String description;
  final IconData icon;
  final bool hasDateRange;
  final bool hasRoomFilter;
  final bool hasUserFilter;
  final bool hasPeriod;
  final List<ReportStatusOption>? statusOptions;

  const ReportDefinition({
    required this.routeKey,
    required this.title,
    required this.description,
    required this.icon,
    this.hasDateRange = false,
    this.hasRoomFilter = false,
    this.hasUserFilter = false,
    this.hasPeriod = false,
    this.statusOptions,
  });
}

const complaintStatusOptions = [
  ReportStatusOption('open', 'Menunggu'),
  ReportStatusOption('in_progress', 'Diproses'),
  ReportStatusOption('resolved', 'Selesai'),
  ReportStatusOption('rejected', 'Ditolak'),
];

const reservationStatusOptions = [
  ReportStatusOption('pending', 'Menunggu Persetujuan'),
  ReportStatusOption('approved', 'Disetujui'),
  ReportStatusOption('rejected', 'Ditolak'),
  ReportStatusOption('completed', 'Selesai'),
  ReportStatusOption('cancelled', 'Dibatalkan'),
];

const reportDefinitions = [
  ReportDefinition(
    routeKey: 'Report.complaints',
    title: 'Laporan Keluhan & Kerusakan Fasilitas',
    description: 'Rekap keluhan berdasarkan status, ruangan, dan periode',
    icon: Icons.feedback_outlined,
    hasDateRange: true,
    hasRoomFilter: true,
    statusOptions: complaintStatusOptions,
  ),
  ReportDefinition(
    routeKey: 'Report.usage',
    title: 'Rekapitulasi Penggunaan Ruangan',
    description: 'Statistik pemakaian ruangan dalam suatu periode',
    icon: Icons.meeting_room_outlined,
    hasDateRange: true,
    hasRoomFilter: true,
  ),
  ReportDefinition(
    routeKey: 'Report.userActivity',
    title: 'Laporan Aktivitas Pengguna',
    description: 'Riwayat aktivitas reservasi per karyawan',
    icon: Icons.person_outline,
    hasDateRange: true,
    hasUserFilter: true,
  ),
  ReportDefinition(
    routeKey: 'Report.scheduleHistory',
    title: 'Laporan Jadwal & Histori Reservasi',
    description: 'Daftar reservasi berdasarkan status, ruangan, dan periode',
    icon: Icons.event_note_outlined,
    hasDateRange: true,
    hasRoomFilter: true,
    statusOptions: reservationStatusOptions,
  ),
  ReportDefinition(
    routeKey: 'Report.periodic',
    title: 'Laporan Ringkasan Periodik Reservasi',
    description: 'Rekap reservasi harian, mingguan, atau bulanan',
    icon: Icons.calendar_view_month_outlined,
    hasPeriod: true,
  ),
  ReportDefinition(
    routeKey: 'Report.divisionActivity',
    title: 'Laporan Aktivitas Divisi',
    description: 'Rekap aktivitas reservasi berdasarkan divisi',
    icon: Icons.apartment_outlined,
    hasDateRange: true,
  ),
  ReportDefinition(
    routeKey: 'Report.maintenance',
    title: 'Laporan Ruangan Maintenance',
    description: 'Riwayat ruangan yang berstatus maintenance',
    icon: Icons.build_outlined,
    hasDateRange: true,
    hasRoomFilter: true,
  ),
  ReportDefinition(
    routeKey: 'Report.divisionUsage',
    title: 'Laporan Penggunaan Ruangan per Divisi',
    description: 'Statistik pemakaian ruangan dikelompokkan per divisi',
    icon: Icons.pie_chart_outline,
    hasDateRange: true,
  ),
];
