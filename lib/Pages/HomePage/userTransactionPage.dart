import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('user_transactions') // Make sure table name matches!
          .select('*')
          .eq('userid', user.id)
          .order('time',
              ascending: false); // Make sure your column name is correct

      setState(() {
        _transactions = (response as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final date = DateTime.parse(transaction['time'] as String);
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    final amount = transaction['receiverAmount'];
    final type = transaction['type'] as String;
    final number = transaction['receiverNum'] as String;

    // Expense types
    final isExpense = type == 'Send Money' ||
        type == 'Mobile Recharge' ||
        type == 'Cash Out' ||
        type == 'Make Payment';
    final isIncome = type == 'Received Money';

    final amountColor = isExpense ? Colors.red : Colors.green;
    final amountSign = isExpense ? '-' : '+';
    final directionLabel = isIncome ? 'From' : 'To';
    return Card(
      color: const Color(0xFFEFE3C2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '$amountSign৳${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$directionLabel: $number',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFFEFE3C2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Text(
                    'No transactions found',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchTransactions,
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(_transactions[index]);
                    },
                  ),
                ),
    );
  }
}
