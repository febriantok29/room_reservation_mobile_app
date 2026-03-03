import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget untuk memilih tanggal dan waktu
class DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final Function(DateTime?)? onChanged;
  final DateTime? minDateTime;
  final DateTime? maxDateTime;
  final bool enabled;

  const DateTimeField({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.minDateTime,
    this.maxDateTime,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? () => _selectDateTime(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value != null
                        ? '${dateFormat.format(value!)} ${timeFormat.format(value!)}'
                        : 'Pilih $label',
                    style: TextStyle(
                      color: value != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (value != null && enabled)
                  GestureDetector(
                    onTap: () {
                      if (onChanged != null) onChanged!(null);
                    },
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Menampilkan dialog untuk memilih tanggal dan waktu
  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = value ?? now;

    // Pilih tanggal
    final date = await showDatePicker(
      context: context,
      initialDate: minDateTime != null && initialDate.isBefore(minDateTime!)
          ? minDateTime!
          : initialDate,
      firstDate: minDateTime ?? now,
      lastDate: maxDateTime ?? DateTime(2100),
    );

    if (date != null && onChanged != null && context.mounted) {
      // Pilih waktu
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(value ?? now),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        onChanged!(dateTime);
      }
    }
  }
}
