import 'package:flutter/material.dart';

class FaxStatusChip extends StatelessWidget {
  final String status;

  const FaxStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase().trim();

    IconData icon;
    Color color;
    String label;

    switch (normalized) {
      case 'delivered':
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Delivered';
        break;

      case 'failed':
        icon = Icons.error;
        color = Colors.red;
        label = 'Failed';
        break;

      case 'sending':
        icon = Icons.send;
        color = Colors.blue;
        label = 'Sending';
        break;

      case 'media_processed':
        icon = Icons.description;
        color = Colors.indigo;
        label = 'Processing';
        break;

      case 'queued':
        icon = Icons.schedule;
        color = Colors.orange;
        label = 'Queued';
        break;

      default:
        icon = Icons.info_outline;
        color = Colors.grey;
        label = status.isEmpty ? 'Unknown' : status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
