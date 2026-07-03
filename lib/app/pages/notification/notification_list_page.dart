import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/notification_model.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/services/notification_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/ui_items/app_snackbar.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';

class NotificationListPage extends StatefulWidget {
  final Profile user;

  const NotificationListPage({super.key, required this.user});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final _notificationService = NotificationService();
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Future<List<NotificationModel>>? _notificationsFuture;
  int _unreadCount = 0;
  bool? _filterUnread;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = _notificationService.getNotificationList(
        isRead: _filterUnread != null ? !_filterUnread! : null,
      );
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      debugPrint('Failed to load unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifikasi'),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount belum dibaca',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Tandai Semua Dibaca',
            ),
          PopupMenuButton<bool?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (value) {
              setState(() {
                _filterUnread = value;
                _loadNotifications();
              });
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      _filterUnread == null
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Semua'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(
                      _filterUnread == true
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    const Text('Belum Dibaca'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(
                      _filterUnread == false
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    const Text('Sudah Dibaca'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          _loadNotifications();
          _loadUnreadCount();
          await _notificationsFuture;
        },
        child: FutureBuilder<List<NotificationModel>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty && _filterUnread == null) {
              return _buildEmptyState();
            }

            if (notifications.isEmpty) {
              return _buildEmptyFilteredState();
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (_, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id ?? 'notification_$notification'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus Notifikasi'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus notifikasi ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteNotification(notification),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.blue.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notification.type.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.type.icon,
                  color: notification.type.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title ?? notification.type.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (notification.body != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      notification.createdAt != null
                          ? DateFormatter.timeAgo(notification.createdAt!)
                          : '-',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
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
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi akan muncul di sini',
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
            _filterUnread == true
                ? 'Tidak ada notifikasi yang belum dibaca'
                : 'Tidak ada notifikasi yang sudah dibaca',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _filterUnread = null;
                _loadNotifications();
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
            onPressed: () {
              _loadNotifications();
              _loadUnreadCount();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        await _notificationService.markAsRead(notification.id!);
        _loadNotifications();
        _loadUnreadCount();
      } catch (e) {
        debugPrint('Failed to mark as read: $e');
      }
    }

    // TODO: Navigate to related content based on notification type
    // e.g., if type is reservationApproved, navigate to reservation detail
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Semua notifikasi ditandai telah dibaca',
        type: SnackBarType.success,
      );

      _loadNotifications();
      _loadUnreadCount();
    } catch (e) {
      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Gagal menandai notifikasi: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _notificationService.deleteNotification(notification.id!);

      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Notifikasi dihapus',
        type: SnackBarType.success,
      );

      _loadNotifications();
      _loadUnreadCount();
    } catch (e) {
      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Gagal menghapus notifikasi: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }
}
