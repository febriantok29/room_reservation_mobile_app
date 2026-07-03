import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/complaint.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/pages/complaint/create_complaint_page.dart';
import 'package:rapa_track_mobile_app/app/services/complaint_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';

class ComplaintListPage extends StatefulWidget {
  final Profile user;

  const ComplaintListPage({super.key, required this.user});

  @override
  State<ComplaintListPage> createState() => _ComplaintListPageState();
}

class _ComplaintListPageState extends State<ComplaintListPage> {
  final _complaintService = ComplaintService();
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Future<List<Complaint>>? _complaintsFuture;
  ComplaintStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  void _loadComplaints() {
    setState(() {
      _complaintsFuture = _complaintService.getComplaintList(
        status: _filterStatus?.name,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keluhan & Laporan'),
        actions: [
          PopupMenuButton<ComplaintStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Status',
            onSelected: (status) {
              setState(() {
                _filterStatus = status;
                _loadComplaints();
              });
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      _filterStatus == null
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Semua Status'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              _buildFilterMenuItem(ComplaintStatus.pending),
              _buildFilterMenuItem(ComplaintStatus.inProgress),
              _buildFilterMenuItem(ComplaintStatus.resolved),
              _buildFilterMenuItem(ComplaintStatus.rejected),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          _loadComplaints();
          await _complaintsFuture;
        },
        child: FutureBuilder<List<Complaint>>(
          future: _complaintsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final complaints = snapshot.data ?? [];

            if (complaints.isEmpty && _filterStatus == null) {
              return _buildEmptyState();
            }

            if (complaints.isEmpty) {
              return _buildEmptyFilteredState();
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: complaints.length,
              itemBuilder: (_, index) {
                final complaint = complaints[index];
                final isLast = index == complaints.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 80 : 12),
                  child: _buildComplaintCard(complaint),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateComplaint,
        icon: const Icon(Icons.add),
        label: const Text('Buat Keluhan'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  PopupMenuItem<ComplaintStatus> _buildFilterMenuItem(ComplaintStatus status) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Icon(
            _filterStatus == status
                ? Icons.check_circle
                : Icons.circle_outlined,
            size: 20,
            color: status.color,
          ),
          const SizedBox(width: 12),
          Text(status.displayName),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showComplaintDetail(complaint),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.room?.name ?? 'Ruangan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.room?.location ?? '-',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: complaint.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: complaint.status.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          complaint.status.icon,
                          size: 14,
                          color: complaint.status.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          complaint.status.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: complaint.status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint.message ?? '',
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    complaint.createdAt != null
                        ? DateFormatter.timeAgo(complaint.createdAt!)
                        : '-',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (widget.user.isAdmin && complaint.user != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complaint.user!.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feedback_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Keluhan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ada masalah dengan ruangan?\nLaporkan di sini!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Hasil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada keluhan dengan status ${_filterStatus?.displayName ?? ""}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _filterStatus = null;
                _loadComplaints();
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Hapus Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadComplaints,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showComplaintDetail(Complaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detail Keluhan',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: complaint.status.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          complaint.status.icon,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          complaint.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                icon: Icons.meeting_room,
                label: 'Ruangan',
                value: complaint.room?.name ?? '-',
              ),
              _buildDetailRow(
                icon: Icons.location_on,
                label: 'Lokasi',
                value: complaint.room?.location ?? '-',
              ),
              _buildDetailRow(
                icon: Icons.person,
                label: 'Pelapor',
                value: complaint.user?.name ?? '-',
              ),
              _buildDetailRow(
                icon: Icons.access_time,
                label: 'Tanggal Laporan',
                value: complaint.createdAt != null
                    ? DateFormatter.shortDateTime(complaint.createdAt!)
                    : '-',
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluhan:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                complaint.message ?? '-',
                style: const TextStyle(fontSize: 16),
              ),
              if (complaint.adminResponse != null &&
                  complaint.adminResponse!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Tanggapan Admin:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    complaint.adminResponse!,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                if (complaint.respondedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ditanggapi: ${DateFormatter.shortDateTime(complaint.respondedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreateComplaint() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateComplaintPage(user: widget.user)),
    );

    if (result == true) {
      _loadComplaints();
    }
  }
}
