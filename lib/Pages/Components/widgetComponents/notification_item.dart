// notification_item.dart
import 'package:flutter/material.dart';

class NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onTap;

  const NotificationItem({
    super.key,
    required this.title,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications),
      title: Text(title),
      subtitle: Text(message),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
