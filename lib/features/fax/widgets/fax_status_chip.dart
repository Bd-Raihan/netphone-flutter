import 'package:flutter/material.dart';

class FaxStatusChip extends StatelessWidget {
  final String status;

  const FaxStatusChip({super.key, required this.status});

  static String normalize(String value) =>
      value.trim().toLowerCase().replaceAll('.', '_');

  static bool isSuccessful(String value) =>
      normalize(value) == 'delivered' || normalize(value) == 'received';

  static bool isPending(String value) => const {
    'queued',
    'media_processed',
    'originated',
    'sending',
    'sending_started',
    'initiated',
    'receiving',
    'receiving_started',
    'media_processing',
    'media_processing_started',
  }.contains(normalize(value));

  static String failureMessage(String? reason) {
    switch (reason?.trim().toLowerCase()) {
      case 'destination_invalid':
      case 'receiver_invalid_number_format':
        return 'Invalid fax number.';
      case 'receiver_unallocated_number':
        return 'Fax number is not in service.';
      case 'destination_unreachable':
        return 'Receiver is unreachable.';
      case 'receiver_no_answer':
        return 'Receiver did not answer.';
      case 'receiver_no_response':
        return 'No response from the receiver.';
      case 'user_busy':
        return 'Receiver is busy.';
      case 'receiver_decline':
        return 'Receiver declined the fax.';
      case 'receiver_incompatible_destination':
        return 'Receiver is incompatible with this fax.';
      case 'fax_initial_communication_timeout':
        return 'Timed out waiting for a fax response.';
      case 'receiver_recovery_on_timer_expire':
        return 'Receiver connection timed out.';
      case 'receiver_call_dropped':
      case 'sender_call_dropped':
      case 'carrier_lost':
        return 'Fax connection was interrupted.';
      case 'receiver_communication_error':
      case 'sender_communication_error':
      case 'fax_signaling_error':
      case 'invalid_ecm_response_from_receiver':
        return 'Fax communication failed.';
      case 'sender_canceled':
        return 'Sender canceled the fax.';
      case 'file_download_failed':
      case 'file_format_invalid':
        return 'Unable to prepare the fax document.';
      case 'file_size_limit_exceeded':
      case 'page_count_limit_exceeded':
        return 'Fax document exceeds the allowed limit.';
      case 'destination_not_in_countries_whitelist':
      case 'destination_not_in_service_plan':
      case 'unverified_destination_not_allowed':
        return 'Sending to this destination is unavailable.';
      default:
        return 'Fax delivery failed. Please try again later.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalize(status);

    IconData icon;
    Color color;
    String label;

    switch (normalized) {
      case 'delivered':
      case 'received':
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Successful';
        break;

      case 'failed':
        icon = Icons.error;
        color = Colors.red;
        label = 'Failed';
        break;

      case 'sending':
      case 'sending_started':
        icon = Icons.send;
        color = Colors.orange;
        label = 'Sending';
        break;

      case 'media_processed':
      case 'media_processing':
      case 'media_processing_started':
        icon = Icons.description;
        color = Colors.orange;
        label = 'Processing';
        break;

      case 'originated':
        icon = Icons.phone_in_talk;
        color = Colors.orange;
        label = 'Connecting';
        break;

      case 'initiated':
      case 'receiving':
      case 'receiving_started':
        icon = Icons.call_received;
        color = Colors.orange;
        label = 'Receiving';
        break;

      case 'queued':
        icon = Icons.schedule;
        color = Colors.orange;
        label = 'Queued';
        break;

      default:
        icon = Icons.info_outline;
        color = Colors.grey;
        label = 'Unknown';
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
