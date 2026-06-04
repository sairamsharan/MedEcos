import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class LabOrdersScreen extends StatefulWidget {
  const LabOrdersScreen({super.key});

  @override
  State<LabOrdersScreen> createState() => _LabOrdersScreenState();
}

class _LabOrdersScreenState extends State<LabOrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final res = await http.get(
        Uri.parse('http://localhost:5000/api/labtester/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _orders = jsonDecode(res.body);
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final res = await http.put(
        Uri.parse('http://localhost:5000/api/labtester/orders/$orderId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'status': newStatus})
      );
      
      if (res.statusCode == 200) {
        _fetchOrders();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'In_Progress': return Colors.blue;
      case 'Completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Lab Test Orders'), automaticallyImplyLeading: false),
      body: _orders.isEmpty
        ? const Center(child: Text("No test orders found.", style: TextStyle(fontSize: 18)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              final order = _orders[index];
              final status = order['status'] ?? 'Pending';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order['testName'] ?? 'Unknown Test',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(
                              status.replaceAll('_', ' '),
                              style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)
                            )
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Patient: ${order['patientName'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
                      Text("Requested: ${DateTime.parse(order['createdAt']).toLocal().toString().split('.')[0]}"),
                      if (order['dateCompleted'] != null)
                        Text("Completed: ${DateTime.parse(order['dateCompleted']).toLocal().toString().split('.')[0]}"),
                      
                      const SizedBox(height: 16),
                      if (status != 'Completed')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == 'Pending')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                onPressed: () => _updateStatus(order['_id'], 'In_Progress'),
                                child: const Text("Start Test")
                              ),
                            if (status == 'In_Progress')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                onPressed: () => _updateStatus(order['_id'], 'Completed'),
                                child: const Text("Mark Completed")
                              ),
                          ],
                        )
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
