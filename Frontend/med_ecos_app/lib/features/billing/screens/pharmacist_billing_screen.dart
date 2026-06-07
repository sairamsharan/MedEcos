import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/constants.dart';
import '../services/billing_pdf_service.dart';

class PharmacistBillingScreen extends StatefulWidget {
  const PharmacistBillingScreen({super.key});

  @override
  State<PharmacistBillingScreen> createState() => _PharmacistBillingScreenState();
}

class _PharmacistBillingScreenState extends State<PharmacistBillingScreen> {
  final TextEditingController _abhaController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _loading = false;
  String? _patientName;
  String? _abhaId;
  String? _prescriptionId;
  
  List<dynamic> _inventory = [];
  List<dynamic> _filteredInventory = [];
  List<dynamic> _prescriptions = [];
  
  // Cart item format: { 'medicineName': '...', 'pricePerUnit': 0.0, 'quantity': 1, 'maxQuantity': 100 }
  final List<Map<String, dynamic>> _cart = [];
  
  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/pharmacist/inventory'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _inventory = jsonDecode(response.body);
            _filteredInventory = _inventory;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
    }
  }

  Future<void> _searchPatient() async {
    if (_abhaController.text.trim().isEmpty) return;
    
    setState(() {
      _loading = true;
      _patientName = null;
      _abhaId = _abhaController.text.trim();
      _prescriptions = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      // Fetch user profile based on ABHA ID (assuming endpoint exists, or fallback to mock)
      // For now, let's just fetch prescriptions for this abhaId. The Pharmacist doesn't have a direct patient lookup by ABHA
      // Wait, we can fetch prescriptions and derive the name from them, or use a guest.
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/pharmacist/prescriptions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> allPrescriptions = jsonDecode(response.body);
        final patientPrescriptions = allPrescriptions.where((p) => p['patientId']?['abhaId'] == _abhaId).toList();
        
        if (mounted) {
          setState(() {
            _prescriptions = patientPrescriptions;
            if (_prescriptions.isNotEmpty) {
              _patientName = _prescriptions.first['patientId']['username'];
            } else {
              _patientName = "Unknown (No Prescriptions)";
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error searching patient: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _importPrescription(dynamic prescription) {
    setState(() {
      _prescriptionId = prescription['_id'];
      _cart.clear();
      
      if (prescription['medicines'] != null) {
        for (var med in prescription['medicines']) {
          final medName = med['name'];
          // Find in inventory to get price
          final invItem = _inventory.firstWhere((item) => item['medicineName'] == medName, orElse: () => null);
          if (invItem != null) {
            _addToCart(invItem, defaultQuantity: 1); // Or parse dosage if possible
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$medName not in inventory!')));
            }
          }
        }
      }
    });
  }

  void _filterInventory(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInventory = _inventory;
      } else {
        _filteredInventory = _inventory.where((item) => 
          item['medicineName'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  void _addToCart(dynamic item, {int defaultQuantity = 1}) {
    final existingIndex = _cart.indexWhere((c) => c['medicineName'] == item['medicineName']);
    if (existingIndex >= 0) {
      if (_cart[existingIndex]['quantity'] < item['quantity']) {
        setState(() {
          _cart[existingIndex]['quantity']++;
        });
      }
    } else {
      if (item['quantity'] > 0) {
        setState(() {
          _cart.add({
            'medicineName': item['medicineName'],
            'pricePerUnit': item['price'].toDouble(),
            'quantity': defaultQuantity,
            'maxQuantity': item['quantity'],
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['medicineName']} is out of stock')));
      }
    }
  }

  void _updateQuantity(int index, int newQty) {
    if (newQty <= 0) {
      setState(() {
        _cart.removeAt(index);
      });
    } else if (newQty <= _cart[index]['maxQuantity']) {
      setState(() {
        _cart[index]['quantity'] = newQty;
      });
    }
  }

  double get _grandTotal {
    return _cart.fold(0.0, (sum, item) => sum + (item['pricePerUnit'] * item['quantity']));
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final billData = {
        'abhaId': _abhaId,
        'patientName': _patientName ?? 'Guest Patient',
        'prescriptionId': _prescriptionId,
        'medicines': _cart.map((c) => {
          'medicineName': c['medicineName'],
          'quantity': c['quantity'],
          'pricePerUnit': c['pricePerUnit'],
          'total': c['pricePerUnit'] * c['quantity'],
        }).toList(),
        'grandTotal': _grandTotal,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/pharmacist/bills'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(billData),
      );

      if (response.statusCode == 201) {
        final generatedBill = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill Generated Successfully!')));
        }
        await BillingPdfService.generateAndPrintBill(generatedBill);
        
        setState(() {
          _cart.clear();
          _abhaId = null;
          _patientName = null;
          _prescriptionId = null;
          _abhaController.clear();
          _prescriptions = [];
        });
        _fetchInventory(); // refresh inventory
      } else {
        throw Exception('Failed to generate bill');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Billing & Checkout",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Patient & Inventory Search
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Patient Search Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Patient lookup (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _abhaController,
                                      decoration: const InputDecoration(labelText: 'Enter ABHA ID', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _searchPatient,
                                    child: const Text('Search'),
                                  )
                                ],
                              ),
                              if (_patientName != null) ...[
                                const SizedBox(height: 16),
                                Text("Patient: $_patientName", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                              if (_prescriptions.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text("Unfulfilled Prescriptions:"),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _prescriptions.length,
                                  itemBuilder: (context, index) {
                                    final p = _prescriptions[index];
                                    final date = DateFormat.yMMMd().format(DateTime.parse(p['date']));
                                    return ListTile(
                                      title: Text("Rx from $date"),
                                      subtitle: Text("Doctor: ${p['doctorId']?['username'] ?? 'Unknown'}"),
                                      trailing: ElevatedButton(
                                        onPressed: () => _importPrescription(p),
                                        child: const Text('Import'),
                                      ),
                                    );
                                  },
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Inventory Search
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Add Medicines", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _searchController,
                                  onChanged: _filterInventory,
                                  decoration: const InputDecoration(
                                    labelText: 'Search Inventory...',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder()
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _filteredInventory.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredInventory[index];
                                      return ListTile(
                                        title: Text(item['medicineName']),
                                        subtitle: Text("Stock: ${item['quantity']} | ₹${item['price'].toStringAsFixed(2)}"),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.add_shopping_cart),
                                          onPressed: () => _addToCart(item),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right Column: Cart
                Expanded(
                  flex: 2,
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Current Bill", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _cart.isEmpty 
                              ? const Center(child: Text("Cart is empty"))
                              : ListView.builder(
                                  itemCount: _cart.length,
                                  itemBuilder: (context, index) {
                                    final item = _cart[index];
                                    return Card(
                                      child: ListTile(
                                        title: Text(item['medicineName']),
                                        subtitle: Text("₹${item['pricePerUnit'].toStringAsFixed(2)} x ${item['quantity']}"),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 16),
                                              onPressed: () => _updateQuantity(index, item['quantity'] - 1),
                                            ),
                                            Text(item['quantity'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add, size: 16),
                                              onPressed: () => _updateQuantity(index, item['quantity'] + 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Grand Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("₹${_grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading || _cart.isEmpty ? null : _checkout,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                              child: _loading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Generate Bill & Print", style: TextStyle(fontSize: 16)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
