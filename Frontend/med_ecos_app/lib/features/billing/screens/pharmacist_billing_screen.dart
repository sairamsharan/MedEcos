import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  
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
  
  @override
  void dispose() {
    _abhaController.dispose();
    _searchController.dispose();
    _medNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

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
      
      debugPrint("Prescriptions API returned: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> allPrescriptions = jsonDecode(response.body);
        final patientPrescriptions = allPrescriptions.where((p) => p['abhaId'] == _abhaId).toList();
        
        // Fetch patient details to get the name
        final patientResponse = await http.get(
          Uri.parse('${AppConstants.apiBaseUrl}/api/v1/pharmacist/patients'),
          headers: {'Authorization': 'Bearer $token'},
        );

        String? foundName;
        if (patientResponse.statusCode == 200) {
          final List<dynamic> patients = jsonDecode(patientResponse.body);
          try {
            final patient = patients.firstWhere((p) => p['abhaId'] == _abhaId);
            foundName = patient['username'];
          } catch (e) {}
        }
        
        if (mounted) {
          setState(() {
            _prescriptions = patientPrescriptions;
            _patientName = foundName ?? "Unknown Patient";
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error searching prescriptions: ${response.statusCode}')));
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

  
  void _addManualToCart() {
    final medName = _medNameController.text.trim();
    final priceStr = _priceController.text.trim();
    final qtyStr = _quantityController.text.trim();

    if (medName.isEmpty || priceStr.isEmpty || qtyStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final price = double.tryParse(priceStr) ?? 0.0;
    final qty = int.tryParse(qtyStr) ?? 1;

    if (price <= 0 || qty <= 0) return;

    final existingIndex = _cart.indexWhere((c) => c['medicineName'].toString().toLowerCase() == medName.toLowerCase());
    if (existingIndex >= 0) {
      setState(() {
        _cart[existingIndex]['quantity'] += qty;
      });
    } else {
      setState(() {
        _cart.add({
          'medicineName': medName,
          'pricePerUnit': price,
          'quantity': qty,
          'maxQuantity': 1000,
        });
      });
    }
    _medNameController.clear();
    _priceController.clear();
    _quantityController.clear();
  }

  void _showEditDialog(int index) {
    final item = _cart[index];
    final priceCtrl = TextEditingController(text: item['pricePerUnit'].toString());
    final qtyCtrl = TextEditingController(text: item['quantity'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit ${item['medicineName']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final newPrice = double.tryParse(priceCtrl.text) ?? item['pricePerUnit'];
                final newQty = int.tryParse(qtyCtrl.text) ?? item['quantity'];
                setState(() {
                  if (newQty <= 0) {
                    _cart.removeAt(index);
                  } else {
                    _cart[index]['pricePerUnit'] = newPrice;
                    _cart[index]['quantity'] = newQty;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        );
      }
    );
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
        if (_abhaId != null && _abhaId!.isNotEmpty) 'abhaId': _abhaId,
        'patientName': _patientName ?? 'Guest Patient',
        if (_prescriptionId != null && _prescriptionId!.isNotEmpty) 'prescriptionId': _prescriptionId,
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
                  child: SingleChildScrollView(
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
                                      inputFormatters: [_AbhaInputFormatter()],
                                      keyboardType: TextInputType.number,
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
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 150),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _prescriptions.length,
                                    itemBuilder: (context, index) {
                                      final p = _prescriptions[index];
                                      final date = DateFormat.yMMMd().format(DateTime.parse(p['date']));
                                      return ListTile(
                                        title: Text("Rx from $date"),
                                        subtitle: Text("Doctor: ${p['doctorName'] ?? 'Unknown'}"),
                                        trailing: ElevatedButton(
                                          onPressed: () => _importPrescription(p),
                                          child: const Text('Import'),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Inventory Search
                      Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Add Medicines", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                Autocomplete<Map<String, dynamic>>(
                                  optionsBuilder: (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<Map<String, dynamic>>.empty();
                                    }
                                    return _inventory.where((dynamic item) {
                                      return item['medicineName']
                                          .toString()
                                          .toLowerCase()
                                          .contains(textEditingValue.text.toLowerCase());
                                    }).map((e) => Map<String, dynamic>.from(e as Map));
                                  },
                                  displayStringForOption: (Map<String, dynamic> option) => option['medicineName'],
                                  onSelected: (Map<String, dynamic> selection) {
                                    _medNameController.text = selection['medicineName'];
                                    _priceController.text = selection['price'].toString();
                                    _quantityController.text = '1';
                                  },
                                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                    controller.addListener(() {
                                      if (controller.text != _medNameController.text) {
                                        _medNameController.text = controller.text;
                                      }
                                    });
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(labelText: 'Medicine Name', border: OutlineInputBorder()),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                                    const SizedBox(width: 8),
                                    Expanded(child: TextField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                                  ]
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(onPressed: _addManualToCart, icon: const Icon(Icons.add_shopping_cart), label: const Text("Add to Bill"))
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                                              icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                              onPressed: () => _showEditDialog(index),
                                            ),
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


class _AbhaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('-', '');
    if (text.length > 16) text = text.substring(0, 16);
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write('-');
      }
    }
    final newText = buffer.toString();
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
