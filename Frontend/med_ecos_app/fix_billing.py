import sys

with open('lib/features/billing/screens/pharmacist_billing_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _AbhaInputFormatter
content = content.replace("import 'package:intl/intl.dart';", "import 'package:intl/intl.dart';\nimport 'package:flutter/services.dart';")
formatter_code = """
class _AbhaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('-', '');
    if (text.length > 14) text = text.substring(0, 14);
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
"""
content = content + "\n" + formatter_code

# 2. Add controllers
controllers_code = """
  final TextEditingController _abhaController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
"""
content = content.replace("  final TextEditingController _abhaController = TextEditingController();\n  final TextEditingController _searchController = TextEditingController();", controllers_code)

# 3. Add dispose
dispose_code = """
  @override
  void dispose() {
    _abhaController.dispose();
    _searchController.dispose();
    _medNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
"""
content = content.replace("void initState() {", dispose_code + "\n  @override\n  void initState() {")

# 4. Replace /pharmacist/ to /api/v1/pharmacist/
content = content.replace("Uri.parse('${AppConstants.apiBaseUrl}/pharmacist/", "Uri.parse('${AppConstants.apiBaseUrl}/api/v1/pharmacist/")

# 5. Replace _searchPatient logic
search_patient_orig = """      if (response.statusCode == 200) {
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
      }"""
search_patient_new = """      if (response.statusCode == 200) {
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
      }"""
content = content.replace(search_patient_orig, search_patient_new)

# 6. Add _addManualToCart and _showEditDialog
functions_code = """
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
"""
content = content.replace("void _addToCart(dynamic item, {int defaultQuantity = 1}) {", functions_code + "\n  void _addToCart(dynamic item, {int defaultQuantity = 1}) {")

# 7. Update _checkout to not send nulls
checkout_orig = """      final billData = {
        'abhaId': _abhaId,
        'patientName': _patientName ?? 'Guest Patient',
        'prescriptionId': _prescriptionId,"""
checkout_new = """      final billData = {
        if (_abhaId != null && _abhaId!.isNotEmpty) 'abhaId': _abhaId,
        'patientName': _patientName ?? 'Guest Patient',
        if (_prescriptionId != null && _prescriptionId!.isNotEmpty) 'prescriptionId': _prescriptionId,"""
content = content.replace(checkout_orig, checkout_new)

# 8. ABHA Formatter in text field
content = content.replace("controller: _abhaController,", "controller: _abhaController,\n                                      inputFormatters: [_AbhaInputFormatter()],\n                                      keyboardType: TextInputType.number,")

# 9. Doctor name in subtitle
content = content.replace("subtitle: Text(\"Doctor: ${p['doctorId']?['username'] ?? 'Unknown'}\"),", "subtitle: Text(\"Doctor: ${p['doctorName'] ?? 'Unknown'}\"),")

# 10. Replace Inventory list with Autocomplete
inventory_orig = """                                TextField(
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
                                )"""
inventory_new = """                                Autocomplete<Map<String, dynamic>>(
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
                                const Spacer(),"""
content = content.replace(inventory_orig, inventory_new)

# 11. Add Edit button to cart items
cart_orig = """                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 16),
                                              onPressed: () => _updateQuantity(index, item['quantity'] - 1),
                                            ),"""
cart_new = """                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                              onPressed: () => _showEditDialog(index),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 16),
                                              onPressed: () => _updateQuantity(index, item['quantity'] - 1),
                                            ),"""
content = content.replace(cart_orig, cart_new)

# Write back
with open('lib/features/billing/screens/pharmacist_billing_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
