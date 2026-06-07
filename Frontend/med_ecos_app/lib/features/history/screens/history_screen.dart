import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await ApiService().getMedicineHistory();
      setState(() {
        _history = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error loading history: $_error', style: const TextStyle(color: Colors.red)))
              : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final log = _history[index];
                final date = DateTime.parse(log['takenTime']);
                final status = log['status'];
                final isTaken = status == 'TAKEN';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: isTaken ? Colors.green.withOpacity(0.1) : (status == 'SKIPPED' ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                      child: Icon(
                        isTaken ? Icons.check_circle : (status == 'SKIPPED' ? Icons.skip_next : Icons.cancel),
                        color: isTaken ? Colors.green : (status == 'SKIPPED' ? Colors.orange : Colors.red),
                      ),
                    ),
                    title: Text(log['medicineName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isTaken ? Colors.green.withOpacity(0.1) : (status == 'SKIPPED' ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isTaken ? Colors.green : (status == 'SKIPPED' ? Colors.orange : Colors.red),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
