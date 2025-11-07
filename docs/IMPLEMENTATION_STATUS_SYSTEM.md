# Reservation Status System - Implementation Guide

## ✅ Completed Implementation

### 1. Core Files

#### **Enum Status** (`lib/app/enums/reservation_status.dart`)

```dart
enum ReservationStatus {
  confirmed,  // Auto-approved after CSP validation
  upcoming,   // 30 minutes before start
  ongoing,    // Currently in progress
  completed,  // Finished
  cancelled,  // Cancelled by user/admin
}
```

**Extension Methods:**

- `displayName`, `description`, `colorHex` - UI display
- `canBeCancelled`, `canBeRescheduled`, `canBeExtended` - Permission checks
- `isActive`, `isFinal` - State checks
- `fromString()`, `toFirestoreString()` - Firestore serialization

---

#### **Model Reservation** (`lib/app/models/reservation.dart`)

**New Fields:**

- `status: ReservationStatus` - Current status
- `originalEndTime: DateTime?` - Saved when extended
- `cancellationReason: String?` - Why cancelled
- `adminNotes: String?` - Admin actions log
- `confirmedAt: DateTime?` - Auto-confirm timestamp
- `cancelledAt: DateTime?` - Cancellation timestamp
- `cancelledBy: String?` - User ID who cancelled
- `wasRescheduled: bool` - Modification flag
- `wasExtended: bool` - Extension flag

**Helper Methods:**

- `getComputedStatus()` - Calculate status based on time
- `cancel(reason, userId)` - Cancel with reason
- `reschedule(newStart, newEnd, note)` - Reschedule
- `extend(newEndTime, note)` - Extend time (admin)
- `updateStatusIfNeeded()` - Auto-update if needed

**Auto-Confirm:**

```dart
prepareForCreate() {
  super.prepareForCreate();
  confirmedAt = DateTime.now();
  status = ReservationStatus.confirmed;
}
```

---

#### **Service** (`lib/app/services/reservation_service.dart`)

**New Methods:**

1. **Auto-Update Status** (in `getReservationList()`)

```dart
// Auto-update status based on time
for (final reservation in reservations) {
  final computedStatus = reservation.getComputedStatus();

  if (computedStatus != reservation.status) {
    // Update in Firestore (background)
    _updateReservationStatus(reservation.id!, computedStatus);

    // Return updated for UI
    updatedReservation = reservation.copyWith(status: computedStatus);
  }
}
```

2. **Cancel Reservation**

```dart
Future<Reservation> cancelReservation(
  String reservationId,
  String reason,  // REQUIRED
  String userId,
) async {
  // Validate: can only cancel if CONFIRMED or UPCOMING
  if (!reservation.status.canBeCancelled) {
    throw Exception('Cannot cancel');
  }

  final cancelled = reservation.cancel(reason, userId);
  await update(cancelled);

  return cancelled;
}
```

3. **Reschedule Reservation**

```dart
Future<Reservation> rescheduleReservation(
  String reservationId,
  DateTime newStartTime,
  DateTime newEndTime,
  String userId, {
  String? adminNote,
  bool isAdmin = false,
}) async {
  // Validate: can only reschedule if CONFIRMED
  if (!reservation.status.canBeRescheduled) {
    throw Exception('Cannot reschedule');
  }

  // CSP VALIDATION for new time
  final tempReservation = reservation.copyWith(...);
  final cspResult = await validateReservationWithCSP(tempReservation);

  if (!cspResult.isValid) {
    // Show errors + alternatives
    throw ValidationException(errorMessage);
  }

  final rescheduled = reservation.reschedule(newStartTime, newEndTime, note);
  await update(rescheduled);

  return rescheduled;
}
```

4. **Extend Reservation (Admin Only)**

```dart
Future<Reservation> extendReservation(
  String reservationId,
  DateTime newEndTime,
  String reason,
) async {
  // Validate: can only extend if ONGOING
  if (!reservation.status.canBeExtended) {
    throw Exception('Cannot extend');
  }

  // CRITICAL: CSP validation for conflict check
  final tempReservation = reservation.copyWith(endDateTime: newEndTime);
  final cspResult = await validateReservationWithCSP(tempReservation);

  if (!cspResult.isValid) {
    // Ada conflict dengan reservasi lain!
    throw ValidationException(errorMessage);
  }

  final extended = reservation.extend(newEndTime, reason);
  await update(extended);

  return extended;
}
```

---

### 2. UI Components

#### **Status Badge** (`lib/app/ui_items/reservation_status_badge.dart`)

**Widgets:**

- `ReservationStatusBadge` - Full badge with optional description
- `ReservationStatusChip` - Compact chip with icon
- `ReservationStatusTimeline` - Timeline progress indicator

**Usage:**

```dart
// Simple badge
ReservationStatusBadge(status: reservation.status)

// With description
ReservationStatusBadge(
  status: reservation.status,
  showDescription: true,
)

// Compact chip
ReservationStatusChip(status: reservation.status)

// Timeline
ReservationStatusTimeline(status: reservation.status)
```

---

#### **Action Buttons** (`lib/app/ui_items/reservation_action_buttons.dart`)

**Widgets:**

- `ReservationActionButtons` - Smart buttons based on status
- `CancelReservationDialog` - Cancel with reason
- `RescheduleReservationDialog` - Reschedule with date/time picker
- `ExtendReservationDialog` - Extend (admin only)

**Usage:**

```dart
ReservationActionButtons(
  reservation: reservation,
  isAdmin: false,
  onCancel: () => _handleCancel(),
  onReschedule: () => _handleReschedule(),
  onExtend: () => _handleExtend(), // Admin only
  onView: () => _showDetail(),
)
```

**Buttons Shown:**
| Status | User Buttons | Admin Buttons |
|-----------|---------------------|-----------------------------|
| CONFIRMED | Cancel, Reschedule | Cancel, Reschedule |
| UPCOMING | Cancel (urgent) | Cancel |
| ONGOING | View only | Extend, View |
| COMPLETED | View only | View only |
| CANCELLED | View only | View only |

---

#### **Example Implementation** (`lib/app/examples/reservation_ui_example.dart`)

**Components:**

- `ReservationCard` - Complete card with all features
- `ReservationListPageExample` - List page with filters

**Features:**

- Display status badge
- Show modification flags (rescheduled, extended)
- Show cancellation reason
- Show admin notes
- Action buttons with dialogs
- Filter by status
- Pull-to-refresh

---

### 3. Integration with CSP

**Extension Validation Example:**

```dart
// Scenario:
Original: 09:00 - 12:00
Admin wants to extend to: 12:30

// CSP checks
await validateReservationWithCSP(tempReservation)

// If there's a reservation at 12:15:
Result: FAIL
Error: "Tidak dapat memperpanjang waktu:
• Ruangan sudah dipesan pada waktu tersebut

Perpanjangan yang diminta: 30 menit
Harap periksa jadwal reservasi lain di ruangan ini."

// If no conflict:
Result: PASS
Update: originalEndTime = 12:00, endTime = 12:30, wasExtended = true
```

---

## 🔧 Migration Steps

### Files yang Perlu Diupdate:

#### 1. **reservation_list_page.dart**

**Error:** `cancelReservation` now requires 3 parameters

**Fix:**

```dart
// OLD
await _service.cancelReservation(reservation.id!, userId);

// NEW
final reason = await showDialog<String>(...); // Get reason from dialog
if (reason != null) {
  await _service.cancelReservation(
    reservation.id!,
    reason,      // Add reason
    userId,
  );
}
```

**Error:** `_buildStatusBadge` expects String but got ReservationStatus

**Fix:**

```dart
// OLD
_buildStatusBadge(reservation.status) // status is now ReservationStatus enum

// NEW - Option 1: Use displayName
_buildStatusBadge(reservation.status.displayName)

// NEW - Option 2: Use new widget
ReservationStatusChip(status: reservation.status)
```

---

#### 2. **calendar_page.dart**

**Error:** Status comparison expects String but got ReservationStatus

**Fix:**

```dart
// OLD
if (reservation.status == 'PENDING') { ... }

// NEW
if (reservation.status == ReservationStatus.confirmed) { ... }
// or
switch (reservation.status) {
  case ReservationStatus.confirmed:
    // ...
    break;
  case ReservationStatus.upcoming:
    // ...
    break;
  // etc
}
```

---

#### 3. **reservation_appointment.dart**

**Error:** `_getColorByStatus` expects String but got ReservationStatus

**Fix:**

```dart
// OLD
static Color _getColorByStatus(String status) {
  switch (status) {
    case 'PENDING': return Colors.orange;
    case 'APPROVED': return Colors.green;
    // ...
  }
}

// NEW
static Color _getColorByStatus(ReservationStatus status) {
  switch (status) {
    case ReservationStatus.confirmed: return Colors.blue;
    case ReservationStatus.upcoming: return Colors.orange;
    case ReservationStatus.ongoing: return Colors.green;
    case ReservationStatus.completed: return Colors.grey;
    case ReservationStatus.cancelled: return Colors.red;
  }
}

// OR use built-in color
final hex = reservation.status.colorHex.substring(1);
final color = Color(int.parse(hex, radix: 16) + 0xFF000000);
```

---

## 📊 Status Flow Reference

```
┌─────────────────────────────────────────────────────────────────┐
│  USER SUBMIT → CSP VALIDATE → PASS                              │
│                                ↓                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  CONFIRMED (Blue)                                       │     │
│  │  • Auto-approved, menunggu waktu                        │     │
│  │  • Can: Cancel, Reschedule                              │     │
│  └────────────────────────────────────────────────────────┘     │
│                                ↓ (30 min before)                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  UPCOMING (Orange)                                      │     │
│  │  • Segera dimulai                                       │     │
│  │  • Can: Cancel (urgent only)                            │     │
│  └────────────────────────────────────────────────────────┘     │
│                                ↓ (start time)                    │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  ONGOING (Green)                                        │     │
│  │  • Sedang berlangsung                                   │     │
│  │  • Can: Extend (admin only, with CSP check)            │     │
│  └────────────────────────────────────────────────────────┘     │
│                                ↓ (end time)                      │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  COMPLETED (Grey)                                       │     │
│  │  • Selesai                                              │     │
│  │  • Read-only                                            │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
│                         OR                                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  CANCELLED (Red)                                        │     │
│  │  • Dibatalkan (with reason)                             │     │
│  │  • Read-only                                            │     │
│  └────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✅ Testing Checklist

### Unit Tests

- [ ] Enum extension methods (displayName, colorHex, canBe\*)
- [ ] Model helper methods (cancel, reschedule, extend)
- [ ] getComputedStatus() logic
- [ ] Service methods (cancel, reschedule, extend)
- [ ] CSP validation for extend/reschedule

### Integration Tests

- [ ] Auto-status update on getReservationList
- [ ] Cancel with reason
- [ ] Reschedule with CSP validation
- [ ] Extend with CSP conflict detection
- [ ] Status transition timeline

### UI Tests

- [ ] Status badge colors
- [ ] Action buttons visibility based on status
- [ ] Cancel dialog with reason
- [ ] Reschedule dialog with date/time picker
- [ ] Extend dialog (admin only)
- [ ] Filter by status

---

## 🎯 Next Steps

1. **Fix Compilation Errors** - Update files mentioned above
2. **Test Auto-Update** - Create reservation, wait, check status change
3. **Test Actions**:
   - Create → Cancel (with reason)
   - Create → Reschedule (with CSP)
   - Create → Wait for ONGOING → Extend (admin, with CSP)
4. **UI Polish** - Add notifications, animations
5. **Documentation** - User guide for status system

---

**Status:** ✅ Core implementation complete  
**Next:** Fix legacy code compatibility  
**Blocker:** None - ready for testing!
