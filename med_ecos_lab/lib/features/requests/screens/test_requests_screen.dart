import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/data_service.dart';
import '../../reports/screens/upload_report_screen.dart';

class TestRequestsScreen extends StatefulWidget {
  const TestRequestsScreen({super.key});

  @override
  State<TestRequestsScreen> createState() => _TestRequestsScreenState();
}

class _TestRequestsScreenState extends State<TestRequestsScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final requests = DataService().searchRequests(_searchQuery);

    return Column(
      children: [
        // Header & Search
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pending Test Requests",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search by Request ID or Patient Name...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: requests.isEmpty
              ? Center(
                  child: Text(
                    "No pending test requests.",
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: requests.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          child: const Icon(Icons.science,
                              color: Colors.orange, size: 28),
                        ),
                        title: Text(req.patientName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                                "Request ID: ${req.id} • ${req.dateRequested.toString().split('.')[0]}"),
                            Text("Referred by: ${req.doctorName}"),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: req.requestedTests
                                  .map((test) => Chip(
                                        label: Text(test,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        backgroundColor:
                                            AppColors.surfaceVariant,
                                        side: BorderSide.none,
                                      ))
                                  .toList(),
                            )
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        UploadReportScreen(request: req)));
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text("Process Test"),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
