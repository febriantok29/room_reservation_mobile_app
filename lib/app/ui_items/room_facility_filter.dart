import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/room_facility.dart';

/// Widget untuk filter fasilitas ruangan
/// Menampilkan chips horizontal scrollable dengan multi-select
class RoomFacilityFilter extends StatefulWidget {
  final List<RoomFacility> availableFacilities;
  final List<String> selectedFacilityIds;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  const RoomFacilityFilter({
    super.key,
    required this.availableFacilities,
    required this.selectedFacilityIds,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<RoomFacilityFilter> createState() => _RoomFacilityFilterState();
}

class _RoomFacilityFilterState extends State<RoomFacilityFilter> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedFacilityIds);
  }

  @override
  void didUpdateWidget(RoomFacilityFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFacilityIds != widget.selectedFacilityIds) {
      _selectedIds = List.from(widget.selectedFacilityIds);
    }
  }

  void _toggleFacility(String facilityId) {
    if (!widget.enabled) return;

    setState(() {
      if (_selectedIds.contains(facilityId)) {
        _selectedIds.remove(facilityId);
      } else {
        _selectedIds.add(facilityId);
      }
    });

    widget.onChanged(_selectedIds);
  }

  void _clearAll() {
    if (!widget.enabled) return;

    setState(() {
      _selectedIds.clear();
    });

    widget.onChanged(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableFacilities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter Fasilitas',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_selectedIds.isNotEmpty)
              TextButton(
                onPressed: widget.enabled ? _clearAll : null,
                child: const Text('Hapus Semua'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.availableFacilities.length,
            itemBuilder: (context, index) {
              final facility = widget.availableFacilities[index];
              final isSelected = _selectedIds.contains(facility.id);

              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.availableFacilities.length - 1
                      ? 8.0
                      : 0,
                ),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (facility.icon != null) ...[
                        Icon(
                          facility.icon,
                          size: 16,
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(facility.name),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: widget.enabled
                      ? (selected) => _toggleFacility(facility.id)
                      : null,
                  showCheckmark: true,
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  checkmarkColor: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer,
                ),
              );
            },
          ),
        ),
        if (_selectedIds.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${_selectedIds.length} fasilitas dipilih (room harus punya semua)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
