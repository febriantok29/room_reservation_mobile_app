import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/complaint.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/services/complaint_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

class ComplaintDetailPage extends StatefulWidget {
  final String complaintId;
  final Profile user;

  const ComplaintDetailPage({
    super.key,
    required this.complaintId,
    required this.user,
  });

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  final _service = ComplaintService();

  Complaint? _complaint;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.getComplaintDetail(widget.complaintId);
      if (mounted) setState(() => _complaint = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Keluhan'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: AppSizes.iconXl, color: AppColors.error),
            const SizedBox(height: AppSizes.lg),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.fontSm),
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_complaint == null) return const SizedBox.shrink();

    final c = _complaint!;

    return RefreshIndicator(
      onRefresh: _loadDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(c),
            const SizedBox(height: AppSizes.lg),
            _buildInfoCard(c),
            if (c.resolutionNotes != null && c.resolutionNotes!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.lg),
              _buildResolutionCard(c),
            ],
            if (widget.user.isAdmin && !c.status.isClosed) ...[
              const SizedBox(height: AppSizes.lg),
              _buildAdminActions(c),
            ],
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Complaint c) {
    final status = c.status;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keluhan',
                      style: TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    Text(
                      c.title ?? 'Tanpa judul',
                      style: const TextStyle(
                        fontSize: AppSizes.fontXl,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              _buildStatusChip(status),
            ],
          ),
          if (c.description != null && c.description!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            Text(
              c.description!,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(ComplaintStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: status.color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
        border: Border.all(color: status.color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: AppSizes.iconXs, color: status.color),
          const SizedBox(width: AppSizes.xxs),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Complaint c) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (c.room != null)
            _buildRow(Icons.meeting_room_outlined, 'Ruangan', c.room!.name ?? '-'),
          if (c.facility != null)
            _buildRow(Icons.build_outlined, 'Fasilitas', c.facility!.name),
          if (c.reservation != null)
            _buildRow(
              Icons.event_outlined,
              'Reservasi',
              c.reservation!.formattedRange,
            ),
          if (c.reporter != null)
            _buildRow(Icons.person_outline, 'Pelapor', c.reporter!.name),
          if (c.createdAt != null)
            _buildRow(
              Icons.access_time_outlined,
              'Dilaporkan',
              '${c.createdAt!.day}/${c.createdAt!.month}/${c.createdAt!.year}',
              isLast: c.photoPath == null,
            ),
          if (c.photoPath != null)
            _buildRow(
              Icons.photo_outlined,
              'Foto',
              'Tersedia',
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard(Complaint c) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(10),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.success.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.success, size: AppSizes.iconSm),
              SizedBox(width: AppSizes.sm),
              Text(
                'Catatan Penyelesaian',
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            c.resolutionNotes!,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(Complaint c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSizes.buttonHeightLg,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(c, 'in_progress'),
            icon: const Icon(Icons.sync),
            label: const Text('Tandai Diproses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: AppSizes.buttonHeightLg,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(c, 'resolved'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Tandai Selesai'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: AppSizes.buttonHeightLg,
          child: OutlinedButton.icon(
            onPressed: () => _updateStatus(c, 'rejected'),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Tolak Keluhan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.textDisabled),
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
                const SizedBox(height: 2),
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

  Future<void> _updateStatus(Complaint c, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppSizes.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline, size: AppSizes.iconXl, color: AppColors.warning),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Konfirmasi',
              style: TextStyle(fontSize: AppSizes.fontLg, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Ubah status keluhan ini?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Lanjutkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.updateComplaintStatus(
        complaintId: c.id!,
        status: newStatus,
      );
      if (!mounted) return;
      _loadDetail();
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }
}
