import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fax_notification_model.dart';
import '../services/fax_api_service.dart';

class FaxNotificationsScreen extends StatefulWidget {
  const FaxNotificationsScreen({super.key});

  @override
  State<FaxNotificationsScreen> createState() => _FaxNotificationsScreenState();
}

class _FaxNotificationsScreenState extends State<FaxNotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<FaxNotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await FaxApiService.getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = result;
      });
    } on FaxApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load notifications.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _markRead(FaxNotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await FaxApiService.markNotificationAsRead(notification.id);

      await _loadNotifications();
    } catch (_) {}
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fax Notifications')),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 150),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 150),
          Icon(Icons.notifications_none, size: 55, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No fax notifications.')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _notifications[index];

        return Card(
          child: ListTile(
            onTap: () => _markRead(item),
            leading: Icon(
              item.isRead
                  ? Icons.notifications_none
                  : Icons.notifications_active,
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(item.message),
                ],
                const SizedBox(height: 5),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            trailing: item.isRead ? null : const Icon(Icons.circle, size: 10),
          ),
        );
      },
    );
  }
}
