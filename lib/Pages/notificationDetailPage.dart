// notification_detail_page.dart
import 'package:flutter/material.dart';

class NotificationDetailPage extends StatelessWidget {
  final String transactionId;

  const NotificationDetailPage({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Approval')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: $transactionId',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            const Text('Amount: \$100.00'), // Replace with actual data
            const Text('Recipient: +1234567890'),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {}, // Handle accept
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept'),
                ),
                ElevatedButton(
                  onPressed: () {}, // Handle reject
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
