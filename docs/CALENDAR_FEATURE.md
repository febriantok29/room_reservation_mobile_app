# Calendar Page - Fitur Kalender Reservasi

## Overview

Halaman kalender yang menampilkan visualisasi jadwal reservasi ruangan menggunakan **Syncfusion Flutter Calendar**. Fitur ini memberikan tampilan yang lebih intuitif dan interaktif untuk melihat jadwal booking.

## Fitur Utama

### 1. **Multiple View Modes**

- **Day View** - Tampilan per hari dengan time slot
- **Week View** - Tampilan per minggu
- **Month View** - Tampilan per bulan dengan agenda
- **Schedule View** - Tampilan list jadwal

### 2. **Color Coding by Status**

Setiap reservasi ditampilkan dengan warna berbeda berdasarkan status:

- 🟢 **Hijau** - APPROVED (disetujui)
- 🟠 **Orange** - PENDING (menunggu approval)
- 🔴 **Merah** - REJECTED (ditolak)
- ⚫ **Abu-abu** - CANCELLED (dibatalkan)
- 🔵 **Biru** - COMPLETED (selesai)

### 3. **Interactive Features**

- **Tap on appointment** - Melihat detail reservasi dalam bottom sheet
- **Pull to refresh** - Update data terbaru dari Firestore
- **Navigation arrows** - Navigasi antar periode
- **Date picker button** - Jump ke tanggal tertentu

### 4. **Info Panel**

Panel statistik di atas kalender menampilkan:

- Total reservasi
- Jumlah reservasi disetujui
- Jumlah reservasi pending

### 5. **Detail View**

Bottom sheet detail menampilkan:

- Nama ruangan & status
- Informasi pemesan
- Lokasi ruangan
- Waktu mulai & selesai
- Jumlah tamu
- Keperluan/purpose
- Info approval (jika sudah disetujui)

## Struktur File

```
lib/app/
├── models/
│   └── reservation_appointment.dart    # Model untuk calendar appointment
└── pages/
    └── calendar/
        └── calendar_page.dart          # Halaman kalender
```

## Model Classes

### ReservationAppointment

Extends `Appointment` dari Syncfusion, menambahkan:

- Reference ke objek `Reservation`
- Factory method `fromReservation()`
- Static methods untuk warna dan icon berdasarkan status

### ReservationDataSource

Extends `CalendarDataSource`, menyediakan:

- Data source untuk Syncfusion Calendar
- Method getter untuk appointment properties
- Method `getReservation()` untuk akses objek Reservation

## Usage

### Navigasi ke Calendar Page

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => CalendarPage(user: user),
  ),
);
```

### Integration di Home Page

Sudah terintegrasi di Home Page sebagai Quick Action dengan icon kalender ungu.

## Dependencies

```yaml
dependencies:
  syncfusion_flutter_calendar: ^28.1.38
```

## Time Slot Settings

```dart
TimeSlotViewSettings(
  startHour: 7,      // Mulai jam 7 pagi
  endHour: 20,       // Sampai jam 8 malam
  timeFormat: 'HH:mm',
  timeInterval: Duration(minutes: 30), // Interval 30 menit
)
```

## Month View Settings

```dart
MonthViewSettings(
  appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
  showAgenda: true,
  agendaViewHeight: 150,
  navigationDirection: MonthNavigationDirection.vertical,
)
```

## Future Enhancements

Potensial fitur yang bisa ditambahkan:

1. **Filter by room** - Filter reservasi berdasarkan ruangan tertentu
2. **Filter by status** - Tampilkan hanya status tertentu
3. **Export to PDF/Image** - Export kalender
4. **Conflict detection** - Highlight bentrok jadwal
5. **Reminder notifications** - Notifikasi reminder
6. **Recurring events** - Support reservasi berulang
7. **Custom working hours** - Sesuaikan jam kerja per ruangan
8. **Holiday marking** - Tandai hari libur

## Performance Notes

- Data di-cache di service layer untuk mengurangi fetch
- Pull-to-refresh memaksa fetch data fresh dengan `forceRefresh: true`
- Appointment conversion dilakukan saat build, bukan per item

## Best Practices

1. **Always handle null dates** - Reservasi bisa memiliki null startTime/endTime
2. **Use factory constructors** - `fromReservation()` untuk konsistensi
3. **Color consistency** - Gunakan `_getColorByStatus()` untuk warna yang sama di semua view
4. **Error handling** - Tampilkan error state yang informatif
5. **Loading states** - Berikan feedback visual saat loading

## Screenshots

### Month View

Tampilan kalender bulanan dengan appointments dan agenda di bawah.

### Day View

Tampilan detail per hari dengan time slots (7:00 - 20:00).

### Detail Bottom Sheet

Detail lengkap reservasi saat tap pada appointment.

## Troubleshooting

### Issue: Appointments tidak muncul

**Solution**: Pastikan `startTime` dan `endTime` tidak null, dan format DateTime benar.

### Issue: Warna tidak sesuai

**Solution**: Periksa method `_getColorByStatus()` dan pastikan status string match.

### Issue: Bottom sheet tidak muncul

**Solution**: Pastikan event `onTap` ter-handle dan `targetElement == CalendarElement.appointment`.

## License

Part of Room Reservation Mobile App - Kerja Praktek Project
