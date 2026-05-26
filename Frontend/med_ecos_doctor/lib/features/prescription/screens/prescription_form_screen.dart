import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/pdf_service.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/crypto_service.dart';
import '../../../core/utils/medicine_utils.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PrescriptionFormScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final List<Map<String, String>> _medicines = [];
  final List<String> _selectedLabTests = [];

  // Form Controllers
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _medicineSearchController = TextEditingController();
  final TextEditingController _labTestSearchController = TextEditingController();

  // ── Signature State ──────────────────────────────────────────────────────
  // These are set atomically when the doctor signs. Editing the prescription
  // after signing clears them (the canonical data changes → old sig is invalid).
  String? _digitalSignature;
  String? _signerPublicKeyJson;
  // Pre-generated ID & date so signing and saving use the same values:
  String? _lockedPrescriptionId;
  DateTime? _lockedDate;

  // Dosage Selections
  final Set<String> _selectedTimings = {'Morning'};
  String _selectedContext = 'After Food';
  String _selectedInstructions = 'None';
  String _selectedDuration = '5 Days';

  final List<String> _timings = ['Morning', 'Afternoon', 'Evening', 'Night'];
  final List<String> _contexts = ['After Food', 'Before Food', 'With Food', 'Empty Stomach'];
  final List<String> _instructions = ['None', 'With Warm Water', 'With Milk', 'Chewable', 'Dissolve in water'];
  final List<String> _durations = ['1 Day', '2 Days', '3 Days', '5 Days', '1 Week', '2 Weeks', '1 Month', '3 Months', 'Ongoing'];

  final List<String> _labTests = [
    'Complete Blood Count (CBC)', 'Lipid Profile', 'Liver Function Test (LFT)',
    'Kidney Function Test (KFT)', 'Blood Sugar Fasting', 'Blood Sugar PP',
    'HbA1c', 'Thyroid Profile', 'Urine Routine', 'X-Ray Chest', 'ECG', 'USG Abdomen'
  ];

  final List<String> _allMedicines = [
    'Paracetamol 500mg', 'Amoxicillin 250mg', 'Cetirizine 10mg', 'Ibuprofen 400mg',
    'Omeprazole 20mg', 'Metformin 500mg', 'Atorvastatin 10mg', 'Aspirin 75mg'
  ];

  @override
  void initState() {
    super.initState();
    // Clear signature whenever diagnosis text changes (canonical data changed)
    _symptomsController.addListener(_invalidateSignatureOnEdit);
  }

  @override
  void dispose() {
    _symptomsController.removeListener(_invalidateSignatureOnEdit);
    _symptomsController.dispose();
    _medicineSearchController.dispose();
    _labTestSearchController.dispose();
    super.dispose();
  }

  // ── Signature Invalidation ───────────────────────────────────────────────

  void _invalidateSignatureOnEdit() {
    if (_digitalSignature != null) {
      setState(() {
        _digitalSignature = null;
        _signerPublicKeyJson = null;
        _lockedPrescriptionId = null;
        _lockedDate = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ Signature cleared — prescription was modified'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ));
    }
  }

  void _invalidateSignature() {
    // Call when medicines or lab tests change
    if (_digitalSignature != null) {
      setState(() {
        _digitalSignature = null;
        _signerPublicKeyJson = null;
        _lockedPrescriptionId = null;
        _lockedDate = null;
      });
    }
  }

  // ── Medicine Management ──────────────────────────────────────────────────

  Future<void> _addMedicine() async {
    final newMedicineName = _medicineSearchController.text.trim();
    if (newMedicineName.isEmpty) return;
    if (_selectedTimings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one timing')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final patientPrescriptions = DataService().getPrescriptionsForPatient(widget.patientId);
    final currentMedsSet = <String>{};
    for (var p in patientPrescriptions) {
      for (var med in p.medicines) {
        if (med['name'] != null && med['duration'] != null) {
          if (MedicineUtils.isActiveMedicine(p.date, med['duration']!)) {
            currentMedsSet.add(med['name']!);
          }
        }
      }
    }
    final addingSet = _medicines.map((m) => m['name']!).toSet();
    final allCurrent = {...currentMedsSet, ...addingSet}.toList();

    final result = await GeminiService.checkMedicineClashes(allCurrent, newMedicineName);
    if (mounted) Navigator.pop(context);

    if (result != null && result.startsWith('CLASH:')) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('⚠️ Potential Drug Interaction'),
          content: Text(result.substring(6).trim()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('Add Anyway', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (proceed != true) return;
    } else if (result != null && result.startsWith('Error:')) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      return;
    }

    setState(() {
      _medicines.add({
        'name': newMedicineName,
        'timing': _selectedTimings.join(', '),
        'context': _selectedContext,
        'instruction': _selectedInstructions,
        'duration': _selectedDuration,
      });
      _medicineSearchController.clear();
      _selectedInstructions = 'None';
      _selectedTimings
        ..clear()
        ..add('Morning');
      _selectedDuration = '5 Days';
    });
    _invalidateSignature();
  }

  void _addLabTest() {
    if (_labTestSearchController.text.isNotEmpty &&
        !_selectedLabTests.contains(_labTestSearchController.text)) {
      setState(() {
        _selectedLabTests.add(_labTestSearchController.text);
        _labTestSearchController.clear();
      });
      _invalidateSignature();
    }
  }

  // ── Cryptographic Signing ──────────────────────────────────────────────────

  static const _defaultPassword = 'doctor123';

  /// Signs the prescription using the default password.
  /// Auto-generates RSA-2048 keys on first run (no dialog needed).
  Future<void> _signPrescription() async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medicine before signing')));
      return;
    }

    // Generate a stable ID and date for this prescription (locked after signing)
    _lockedPrescriptionId ??=
        'PRES-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _lockedDate ??= DateTime.now();

    // Build the canonical string from current form data
    final canonical = CryptoService.buildCanonicalString(
      prescriptionId: _lockedPrescriptionId!,
      patientId: widget.patientId,
      patientName: widget.patientName,
      doctorName: 'Dr. Tanishq', // TODO(auth-team): replace with real session user
      isoDate: _lockedDate!.toIso8601String(),
      diagnosis: _symptomsController.text,
      medicines: List.from(_medicines),
      labTests: List.from(_selectedLabTests),
    );

    // Show signing progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Applying cryptographic signature…', textAlign: TextAlign.center),
              SizedBox(height: 4),
              Text('(This may take 10-20 seconds on first run)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );

    // Yield to the event loop so Flutter can actually render the dialog
    // before the heavy math blocks the main thread (especially on Web).
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Auto-generate keys on first run using the default password
      final hasKeys = await CryptoService.hasKeyPair();
      if (!hasKeys) {
        await CryptoService.generateAndStoreKeyPair(_defaultPassword);
      }

      final signature = await CryptoService.signData(canonical, _defaultPassword);
      final pubKey = await CryptoService.getPublicKeyJson();
      if (!mounted) return;
      Navigator.pop(context); // close progress dialog
      setState(() {
        _digitalSignature = signature;
        _signerPublicKeyJson = pubKey;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Prescription cryptographically signed (RSA-2048)'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signing error: $e'), backgroundColor: Colors.red));
    }
  }

  // ── Unsigned Guard ────────────────────────────────────────────────────────

  /// Returns true when there is something worth guarding
  /// (medicines added but prescription not signed yet).
  bool get _hasUnsignedContent => _medicines.isNotEmpty && _digitalSignature == null;

  /// Shows the "please sign" dialog and optionally jumps straight to signing.
  Future<void> _showUnsignedDialog({required String action}) async {
    final sign = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.gpp_maybe_rounded, color: Colors.orange, size: 40),
        title: const Text(
          'Prescription Not Signed',
          textAlign: TextAlign.center,
        ),
        content: Text(
          'You need to digitally sign this prescription before you can $action it.\n\n'
          'A cryptographic signature (RSA-2048) proves authenticity and prevents tampering.',
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.draw_rounded, size: 18),
            label: const Text('Sign Now'),
          ),
        ],
      ),
    );
    if (sign == true && mounted) await _signPrescription();
  }

  // ── Save & Print ─────────────────────────────────────────────────────────

  void _savePrescription() {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one medicine')));
      return;
    }
    if (_digitalSignature == null) {
      _showUnsignedDialog(action: 'save');
      return;
    }

    try {
      final prescription = Prescription(
        id: _lockedPrescriptionId!,
        patientId: widget.patientId,
        patientName: widget.patientName,
        doctorName: 'Dr. Tanishq', // TODO(auth-team): replace with real session user
        date: _lockedDate!,
        diagnosis: _symptomsController.text,
        medicines: List.from(_medicines),
        labTests: List.from(_selectedLabTests),
        digitalSignature: _digitalSignature,
        signerPublicKeyJson: _signerPublicKeyJson,
      );

      DataService().addPrescription(prescription);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription saved successfully')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _printPrescription() async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one medicine to print')));
      return;
    }
    if (_digitalSignature == null) {
      await _showUnsignedDialog(action: 'print');
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Generating PDF…')));

    try {
      await PdfService.generateAndPrintPrescription(
        doctorName: 'Dr. Tanishq', // TODO(auth-team): replace with real session user
        patientName: widget.patientName,
        patientId: widget.patientId,
        prescriptionId: _lockedPrescriptionId!,
        symptoms: _symptomsController.text,
        medicines: List.from(_medicines),
        labTests: List.from(_selectedLabTests),
        date: _lockedDate!.toString().split(' ')[0],
        digitalSignature: _digitalSignature,
        signerPublicKeyJson: _signerPublicKeyJson,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error printing: $e')));
    }
  }

  // ── Autocomplete Helper ───────────────────────────────────────────────────

  Widget _buildOptionsView(
      BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250, maxWidth: 400),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final opt = options.elementAt(i);
              return InkWell(
                onTap: () => onSelected(opt),
                child: Padding(
                    padding: const EdgeInsets.all(16), child: Text(opt)),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  // ── Back / discard guard ─────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    if (!_hasUnsignedContent) return true; // nothing to guard, allow pop

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
        title: const Text(
          'Prescription Not Signed',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'You have added medicines but haven\'t signed the prescription yet.\n\n'
          'Unsigned prescriptions cannot be saved and will be lost if you go back.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'keep'),
            child: const Text('Keep Editing'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, 'sign'),
            icon: const Icon(Icons.draw_rounded, size: 18),
            label: const Text('Sign Now'),
          ),
        ],
      ),
    );

    if (!mounted) return false;
    if (result == 'discard') return true;          // allow pop
    if (result == 'sign') await _signPrescription(); // open signing flow, stay
    return false;                                    // keep editing / after sign
  }

  @override
  Widget build(BuildContext context) {
    final isSigned = _digitalSignature != null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Write Prescription'),
          bottom: _hasUnsignedContent
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(36),
                  child: GestureDetector(
                    onTap: _signPrescription,
                    child: Container(
                      width: double.infinity,
                      color: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open_rounded, size: 15, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Prescription unsigned — tap here to sign',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
        ),
        body: Row(
        children: [
          // ── Left: Form ──────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient: ${widget.patientName} (${widget.patientId})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Symptoms
                  TextField(
                    controller: _symptomsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms / Diagnosis',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  Text('Add Medicine',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  Autocomplete<String>(
                    optionsBuilder: (v) => v.text.isEmpty
                        ? const Iterable<String>.empty()
                        : _allMedicines.where(
                            (o) => o.toLowerCase().contains(v.text.toLowerCase())),
                    optionsViewBuilder: _buildOptionsView,
                    onSelected: (s) => setState(() => _medicineSearchController.text = s),
                    fieldViewBuilder: (ctx, ctrl, fn, oec) {
                      if (ctrl.text != _medicineSearchController.text) {
                        ctrl.text = _medicineSearchController.text;
                      }
                      return TextField(
                        controller: ctrl,
                        focusNode: fn,
                        onEditingComplete: oec,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name (Select or Type New)',
                          prefixIcon: Icon(Icons.medication),
                        ),
                        onChanged: (v) => _medicineSearchController.text = v,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text('Select Timings',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _timings.map((t) {
                      final sel = _selectedTimings.contains(t);
                      return FilterChip(
                        label: Text(t),
                        selected: sel,
                        onSelected: (v) => setState(() => v ? _selectedTimings.add(t) : _selectedTimings.remove(t)),
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedContext,
                        items: _contexts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _selectedContext = v!),
                        decoration: const InputDecoration(labelText: 'Context'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDuration,
                        items: _durations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _selectedDuration = v!),
                        decoration: const InputDecoration(labelText: 'Duration'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  Autocomplete<String>(
                    initialValue: TextEditingValue(
                        text: _selectedInstructions == 'None' ? '' : _selectedInstructions),
                    optionsBuilder: (v) => _instructions.where(
                        (o) => o.toLowerCase().contains(v.text.toLowerCase())),
                    optionsViewBuilder: _buildOptionsView,
                    onSelected: (s) => setState(() => _selectedInstructions = s),
                    fieldViewBuilder: (ctx, ctrl, fn, oec) => TextField(
                      controller: ctrl,
                      focusNode: fn,
                      onEditingComplete: oec,
                      decoration: const InputDecoration(
                        labelText: 'Special Instructions',
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      onChanged: (v) => _selectedInstructions = v,
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _addMedicine,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Medicine'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  Text('Lab Tests',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  Autocomplete<String>(
                    optionsBuilder: (v) => v.text.isEmpty
                        ? const Iterable<String>.empty()
                        : _labTests.where(
                            (o) => o.toLowerCase().contains(v.text.toLowerCase())),
                    optionsViewBuilder: _buildOptionsView,
                    onSelected: (s) => setState(() => _labTestSearchController.text = s),
                    fieldViewBuilder: (ctx, ctrl, fn, oec) {
                      if (ctrl.text != _labTestSearchController.text) {
                        ctrl.text = _labTestSearchController.text;
                      }
                      return TextField(
                        controller: ctrl,
                        focusNode: fn,
                        onEditingComplete: oec,
                        decoration: const InputDecoration(
                          labelText: 'Lab Test Name',
                          prefixIcon: Icon(Icons.science),
                        ),
                        onChanged: (v) => _labTestSearchController.text = v,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addLabTest,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Add Lab Test'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.accent),
                  ),
                ],
              ),
            ),
          ),

          // ── Right: Preview + Sign + Actions ─────────────────────────────
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Prescription Preview',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView.separated(
                      itemCount: _medicines.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final med = _medicines[i];
                        return ListTile(
                          title: Text(med['name']!,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${med['timing']} • ${med['context']} • ${med['duration']}\nNote: ${med['instruction']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () => setState(() { _medicines.removeAt(i); _invalidateSignature(); }),
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),

                  if (_selectedLabTests.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Lab Tests',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: ListView.builder(
                        itemCount: _selectedLabTests.length,
                        itemBuilder: (_, i) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.science, size: 16, color: AppColors.textSecondary),
                          title: Text(_selectedLabTests[i]),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() { _selectedLabTests.removeAt(i); _invalidateSignature(); }),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Signature Status Banner ──────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSigned ? Colors.green.shade50 : Colors.orange.shade50,
                      border: Border.all(
                          color: isSigned ? Colors.green.shade300 : Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(
                            isSigned ? Icons.verified_rounded : Icons.gpp_maybe_rounded,
                            size: 18,
                            color: isSigned ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isSigned
                                  ? 'Signed — RSA-2048'
                                  : 'Unsigned — signature required',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isSigned ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ]),
                        if (isSigned) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Sig: ${_digitalSignature!.substring(0, 32)}…',
                            style: TextStyle(fontSize: 10, color: Colors.green.shade700,
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Sign Button ──────────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: _signPrescription,
                    icon: Icon(isSigned ? Icons.refresh_rounded : Icons.draw_rounded, size: 18),
                    label: Text(isSigned ? 'Re-sign Prescription' : '🔐  Sign Prescription'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: isSigned ? Colors.green.shade700 : AppColors.primary,
                      side: BorderSide(
                          color: isSigned ? Colors.green.shade400 : AppColors.primary),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Print & Save ─────────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _printPrescription,
                        icon: const Icon(Icons.print),
                        label: const Text('Print'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _savePrescription,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    ), // Scaffold
    ); // WillPopScope
  }
}
