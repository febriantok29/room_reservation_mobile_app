import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/room_selector_section.dart';
import 'package:rapa_track_mobile_app/app/services/complaint_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/ui_items/app_snackbar.dart';

class CreateComplaintPage extends StatefulWidget {
  final Profile user;
  final Room? initialRoom;

  const CreateComplaintPage({super.key, required this.user, this.initialRoom});

  @override
  State<CreateComplaintPage> createState() => _CreateComplaintPageState();
}

class _CreateComplaintPageState extends State<CreateComplaintPage> {
  final _complaintService = ComplaintService();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Room? _selectedRoom;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.initialRoom;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Keluhan'), elevation: 0),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Laporkan masalah atau kendala yang Anda temui di ruangan rapat',
                        style: TextStyle(fontSize: 13, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Room Selector
              const Text(
                'Pilih Ruangan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isSubmitting ? null : _showRoomSelector,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedRoom != null
                          ? AppColors.primary
                          : Colors.grey.shade400,
                      width: _selectedRoom != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.meeting_room,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedRoom != null
                                  ? _selectedRoom!.name ?? 'Ruangan'
                                  : 'Pilih Ruangan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _selectedRoom != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _selectedRoom != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                            if (_selectedRoom != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _selectedRoom!.location,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Message Field
              const Text(
                'Keluhan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText:
                      'Contoh: AC di ruangan tidak dingin, proyektor mati, dll...',
                  border: const OutlineInputBorder(),
                  helperText: 'Jelaskan masalah yang Anda temui secara detail',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, top: 12),
                    child: Icon(Icons.description),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Keluhan tidak boleh kosong';
                  }
                  if (value.trim().length < 10) {
                    return 'Keluhan minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Mengirim...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text('Kirim Keluhan'),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRoomSelector() async {
    final selectedRoom = await RoomSelectorSection.showBottomSheet(
      context: context,
      selectedRoomId: _selectedRoom?.id,
    );

    if (selectedRoom != null) {
      setState(() {
        _selectedRoom = selectedRoom;
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoom == null) {
      AppSnackBar.show(
        context,
        'Silakan pilih ruangan terlebih dahulu',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _complaintService.createComplaint(
        roomId: _selectedRoom!.id!,
        message: _messageController.text.trim(),
      );

      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Keluhan berhasil dikirim. Tim kami akan segera menanggapi.',
        type: SnackBarType.success,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Gagal mengirim keluhan: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
