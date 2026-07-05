import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/complaint.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/pages/base_list_page.dart';
import 'package:rapa_track_mobile_app/app/pages/complaint/create_complaint_page.dart';
import 'package:rapa_track_mobile_app/app/repositories/complaint_list_repository.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';
import 'package:rapa_track_mobile_app/app/widgets/filter_bottom_sheet.dart';

class ComplaintListPage extends StatefulWidget {
  final Profile user;

  const ComplaintListPage({super.key, required this.user});

  @override
  State<ComplaintListPage> createState() => _ComplaintListPageState();
}

class _ComplaintListPageState extends State<ComplaintListPage> {
  late final ComplaintListRepository _repository;
  ComplaintStatus? _filterStatus;
  Key _listKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _repository = ComplaintListRepository();
  }

  @override
  Widget build(BuildContext context) {
    return BaseListPage<Complaint>(
      key: _listKey,
      pageTitle: 'Keluhan & Laporan',
      repository: _repository,
      emptyIcon: Icons.feedback_outlined,
      emptyTitle: 'Belum Ada Keluhan',
      emptySubtitle: 'Ada masalah dengan fasilitas ruangan?\nLaporkan di sini!',
      itemBuilder: _buildComplaintCard,
      onFilterPressed: _showFilterSheet,
      activeFilterCount: _filterStatus != null ? 1 : 0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Buat Keluhan',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _showFilterSheet(
    void Function(Map<String, dynamic>?) onApplyFilter,
  ) async {
    ComplaintStatus? tempStatus = _filterStatus;

    await FilterBottomSheet.show(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => FilterBottomSheet(
          title: 'Filter Keluhan',
          onReset: () => setSheetState(() => tempStatus = null),
          onApply: () {
            setState(() => _filterStatus = tempStatus);
            onApplyFilter(
              tempStatus == null ? null : {'status': tempStatus!.name},
            );
            Navigator.of(sheetContext).pop();
          },
          children: [
            FilterSection(
              label: 'Status',
              child: Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: [
                  FilterPill(
                    label: 'Semua',
                    isSelected: tempStatus == null,
                    onTap: () => setSheetState(() => tempStatus = null),
                  ),
                  ...ComplaintStatus.values.map(
                    (s) => FilterPill(
                      label: s.displayName,
                      isSelected: tempStatus == s,
                      onTap: () => setSheetState(() => tempStatus = s),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final statusColor = complaint.status.color;
    return Card(
      elevation: AppSizes.elevationSm,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Builder(
        builder: (ctx) => InkWell(
          onTap: () => _showComplaintDetail(ctx, complaint),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: statusColor),
                Expanded(child: _buildCardContent(complaint, statusColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(Complaint complaint, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(complaint, statusColor),
          const SizedBox(height: AppSizes.xs),
          Text(
            complaint.room?.name ?? '-',
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            complaint.description ?? '',
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.sm),
          _buildCardFooter(complaint),
        ],
      ),
    );
  }

  Widget _buildCardHeader(Complaint complaint, Color statusColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            complaint.title ?? 'Keluhan',
            style: const TextStyle(
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xs,
          ),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
            border: Border.all(color: statusColor.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(complaint.status.icon, size: 13, color: statusColor),
              const SizedBox(width: AppSizes.xxs),
              Text(
                complaint.status.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter(Complaint complaint) {
    return Row(
      children: [
        const Icon(
          Icons.access_time,
          size: AppSizes.iconXs,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.xxs),
        Text(
          complaint.createdAt != null
              ? DateFormatter.timeAgo(complaint.createdAt!)
              : '-',
          style: const TextStyle(
            fontSize: AppSizes.fontXs,
            color: AppColors.textSecondary,
          ),
        ),
        if (complaint.facility != null) ...[
          const SizedBox(width: AppSizes.md),
          Icon(
            complaint.facility!.icon ?? Icons.build_outlined,
            size: AppSizes.iconXs,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizes.xxs),
          Expanded(
            child: Text(
              complaint.facility!.name,
              style: const TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else if (widget.user.isAdmin && complaint.reporter != null) ...[
          const SizedBox(width: AppSizes.md),
          const Icon(
            Icons.person,
            size: AppSizes.iconXs,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizes.xxs),
          Expanded(
            child: Text(
              complaint.reporter!.name,
              style: const TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  void _showComplaintDetail(BuildContext ctx, Complaint complaint) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) =>
            _buildDetailSheet(complaint, scrollController),
      ),
    );
  }

  Widget _buildDetailSheet(
    Complaint complaint,
    ScrollController scrollController,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.xl,
              AppSizes.sm,
              AppSizes.xl,
              AppSizes.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSheetHeader(complaint),
                const SizedBox(height: AppSizes.xl),
                if (complaint.room != null)
                  _buildSheetRow(
                    Icons.meeting_room,
                    'Ruangan',
                    complaint.room!.name ?? '-',
                  ),
                if (complaint.reservation != null)
                  _buildSheetRow(
                    Icons.event,
                    'Jadwal Reservasi',
                    complaint.reservation!.formattedRange,
                  ),
                if (complaint.facility != null)
                  _buildSheetRow(
                    complaint.facility!.icon ?? Icons.build_outlined,
                    'Fasilitas',
                    complaint.facility!.name,
                  ),
                _buildSheetRow(
                  Icons.person,
                  'Pelapor',
                  complaint.reporter?.name ?? '-',
                ),
                _buildSheetRow(
                  Icons.access_time,
                  'Tanggal Laporan',
                  complaint.createdAt != null
                      ? DateFormatter.shortDateTime(complaint.createdAt!)
                      : '-',
                ),
                const SizedBox(height: AppSizes.md),
                _buildSectionLabel('Deskripsi Keluhan:'),
                const SizedBox(height: AppSizes.xs),
                Text(
                  complaint.description ?? '-',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (complaint.photoPath != null &&
                    complaint.photoPath!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.lg),
                  _buildSectionLabel('Foto:'),
                  const SizedBox(height: AppSizes.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    child: Image.network(
                      complaint.photoPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: AppColors.border,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: AppColors.textDisabled),
                        ),
                      ),
                    ),
                  ),
                ],
                if (complaint.resolutionNotes != null &&
                    complaint.resolutionNotes!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.xl),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: AppSizes.md),
                  _buildSectionLabel('Catatan Penyelesaian:'),
                  const SizedBox(height: AppSizes.xs),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Text(
                      complaint.resolutionNotes!,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (complaint.resolvedAt != null) ...[
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Diselesaikan: ${DateFormatter.shortDateTime(complaint.resolvedAt!)}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (complaint.resolver != null) ...[
                    const SizedBox(height: AppSizes.xxs),
                    Text(
                      'Oleh: ${complaint.resolver!.name}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader(Complaint complaint) {
    final statusColor = complaint.status.color;
    return Row(
      children: [
        Expanded(
          child: Text(
            complaint.title ?? 'Detail Keluhan',
            style: const TextStyle(
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xs,
          ),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
            border: Border.all(color: statusColor.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(complaint.status.icon, size: 14, color: statusColor),
              const SizedBox(width: AppSizes.xxs),
              Text(
                complaint.status.displayName,
                style: TextStyle(
                  fontSize: AppSizes.fontXs,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSheetRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.textSecondary),
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
                const SizedBox(height: AppSizes.xxs),
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: AppSizes.fontSm,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateComplaintPage(user: widget.user),
      ),
    );
    if (result == true && mounted) {
      setState(() => _listKey = UniqueKey());
    }
  }
}
