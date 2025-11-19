import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/room_facility.dart';

/// Widget untuk menampilkan chips fasilitas di room card
/// Compact display dengan icon dan text
class RoomFacilityChips extends StatelessWidget {
  final List<RoomFacility> facilities;
  final int maxDisplay;
  final double iconSize;
  final double fontSize;

  const RoomFacilityChips({
    super.key,
    required this.facilities,
    this.maxDisplay = 4,
    this.iconSize = 14,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayFacilities = facilities.take(maxDisplay).toList();
    final remainingCount = facilities.length - displayFacilities.length;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...displayFacilities.map((facility) => _buildChip(context, facility)),
        if (remainingCount > 0) _buildMoreChip(context, remainingCount),
      ],
    );
  }

  Widget _buildChip(BuildContext context, RoomFacility facility) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (facility.icon != null) ...[
            Icon(
              facility.icon,
              size: iconSize,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            facility.name,
            style: TextStyle(
              fontSize: fontSize,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreChip(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
