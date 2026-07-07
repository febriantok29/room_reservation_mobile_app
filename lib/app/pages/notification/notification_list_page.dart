import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/notification_model.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/services/notification_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/app_snackbar.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';
import 'package:rapa_track_mobile_app/app/utils/notification_handler.dart';

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
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          _loadNotifications();
          _loadUnreadCount();
          await _notificationsFuture;
        },
        child: FutureBuilder<List<NotificationModel>>(
          future: _notificationsFuture,
          builder: (_, snapshot) {
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
            if (notifications.isEmpty) return _buildEmptyFilteredState();

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              itemCount: notifications.length,
              itemBuilder: (_, index) =>
                  _buildNotificationCard(notifications[index]),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notifikasi'),
          if (_unreadCount > 0)
            Text(
              '$_unreadCount belum dibaca',
              style: const TextStyle(fontSize: AppSizes.fontXs),
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
          onSelected: (value) => setState(() {
            _filterUnread = value;
            _loadNotifications();
          }),
          itemBuilder: (_) => [
            _buildFilterMenuItem(null, 'Semua', null),
            const PopupMenuDivider(),
            _buildFilterMenuItem(true, 'Belum Dibaca', AppColors.primary),
            _buildFilterMenuItem(false, 'Sudah Dibaca', AppColors.textDisabled),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<bool?> _buildFilterMenuItem(
    bool? value,
    String label,
    Color? color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            _filterUnread == value ? Icons.check_circle : Icons.circle_outlined,
            size: AppSizes.iconSm,
            color: color,
          ),
          const SizedBox(width: AppSizes.md),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id ?? 'notif_${notification.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.lg),
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
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
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.md,
          ),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.white
                : AppColors.primary.withAlpha(15),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeIcon(notification),
              const SizedBox(width: AppSizes.md),
              Expanded(child: _buildCardContent(notification)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(NotificationModel notification) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: notification.type.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        notification.type.icon,
        color: notification.type.color,
        size: AppSizes.iconMd,
      ),
    );
  }

  Widget _buildCardContent(NotificationModel notification) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!notification.isRead)
              Container(
                width: AppSizes.sm,
                height: AppSizes.sm,
                margin: const EdgeInsets.only(right: AppSizes.sm),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                notification.title ?? notification.type.displayName,
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: notification.isRead
                      ? FontWeight.w500
                      : FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (notification.body != null) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            notification.body!,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: AppSizes.sm),
        Text(
          notification.createdAt != null
              ? DateFormatter.timeAgo(notification.createdAt!)
              : '-',
          style: const TextStyle(
            fontSize: AppSizes.fontXs,
            color: AppColors.textDisabled,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: AppSizes.iconXl,
            color: AppColors.lightGrey,
          ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'Tidak Ada Notifikasi',
            style: TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'Notifikasi akan muncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textDisabled,
            ),
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
          Icon(
            Icons.filter_list_off,
            size: AppSizes.iconXl,
            color: AppColors.lightGrey,
          ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'Tidak Ada Hasil',
            style: TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            _filterUnread == true
                ? 'Tidak ada notifikasi yang belum dibaca'
                : 'Tidak ada notifikasi yang sudah dibaca',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _filterUnread = null;
              _loadNotifications();
            }),
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
          Icon(
            Icons.error_outline,
            size: AppSizes.iconXl,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
            child: Text(
              error,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
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
    if (notification.id != null && !notification.isRead) {
      try {
        await _notificationService.markAsRead(notification.id!);
        _loadNotifications();
        _loadUnreadCount();
      } catch (_) {}
    }
    NotificationHandlerUtil.navigate(notification.toPayload());
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
