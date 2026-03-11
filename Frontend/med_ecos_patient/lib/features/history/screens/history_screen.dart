import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await _db.getHistory();
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
                return ListTile(
                  title: Text(log['medicineName']),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                  trailing: Text(
                    log['status'],
                    style: TextStyle(
                      color: log['status'] == 'TAKEN' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
