import 'package:flutter/material.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/signature_verification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../patient/screens/patient_details_screen.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final prescriptions = DataService().searchPrescriptions(_searchQuery);

    return Column(
      children: [
        // Header & Search
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Prescription History",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search by ID, Patient Name, or Date...",
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
          child: prescriptions.isEmpty
              ? Center(
                  child: Text(
                    "No prescriptions found.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: prescriptions.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = prescriptions[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.description, color: AppColors.primary),
                        ),
                        title: Text(p.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("ID: ${p.id} • ${p.date.toString().split(' ')[0]}"),
                            Text("${p.pharmacistName} • ${p.medicines.length} Medicines"),
                            const SizedBox(height: 8),
                            // ── Signature status chip ──
                            Row(
                              children: [
                                _buildSignatureChip(p),
                                if (p.isSigned) ...[
                                  const SizedBox(width: 8),
                                  _buildVerifyButton(context, p),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailsScreen(patientId: p.patientId)));
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ───────────────────────── helpers ─────────────────────────

  /// Green "Signed" or orange "Unsigned" chip.
  Widget _buildSignatureChip(Prescription p) {
    if (p.isSigned) {
      return Chip(
        avatar: const Icon(Icons.lock, size: 16, color: Colors.white),
        label: const Text('Signed', style: TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: AppColors.success,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }
    return Chip(
      avatar: const Icon(Icons.lock_open, size: 16, color: Colors.white),
      label: const Text('Unsigned', style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: AppColors.warning,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Small teal "Verify ✓" button that opens the verification dialog.
  Widget _buildVerifyButton(BuildContext context, Prescription p) {
    return SizedBox(
      height: 28,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: AppColors.primary,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.verified_user, size: 16),
        label: const Text('Verify', style: TextStyle(fontSize: 12)),
        onPressed: () => _showVerifyDialog(context, p),
      ),
    );
  }

  /// Dialog that shows signature details and lets the user run verification.
  void _showVerifyDialog(BuildContext context, Prescription p) {
    showDialog(
      context: context,
      builder: (ctx) => _VerifySignatureDialog(prescription: p),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Stateful dialog – runs verification on button tap
// ═══════════════════════════════════════════════════════════════

class _VerifySignatureDialog extends StatefulWidget {
  final Prescription prescription;
  const _VerifySignatureDialog({required this.prescription});

  @override
  State<_VerifySignatureDialog> createState() => _VerifySignatureDialogState();
}

class _VerifySignatureDialogState extends State<_VerifySignatureDialog> {
  bool? _result; // null = not yet verified

  void _verify() {
    final p = widget.prescription;

    final canonical = SignatureVerificationService.buildCanonicalString(
      prescriptionId: p.id,
      patientId: p.patientId,
      patientName: p.patientName,
      doctorName: p.doctorName ?? p.pharmacistName,
      isoDate: p.date.toIso8601String(),
      diagnosis: p.diagnosis,
      medicines: p.medicines,
      labTests: p.labTests,
    );

    final ok = SignatureVerificationService.verifySignature(
      canonical,
      p.digitalSignature!,
      p.signerPublicKeyJson!,
    );

    setState(() => _result = ok);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prescription;
    final sigPreview = p.digitalSignature != null && p.digitalSignature!.length > 32
        ? '${p.digitalSignature!.substring(0, 32)}…'
        : p.digitalSignature ?? '';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.verified_user, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Verify Signature'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Doctor', p.doctorName ?? 'N/A'),
            _infoRow('Prescription ID', p.id),
            _infoRow('Date', p.date.toString().split(' ')[0]),
            const Divider(height: 24),
            const Text('Signature preview', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sigPreview,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            // ── Result ──
            if (_result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _result! ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _result! ? AppColors.success : AppColors.error),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _result! ? Icons.check_circle : Icons.cancel,
                      color: _result! ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _result! ? 'Signature Valid' : 'Signature Invalid',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _result! ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_result == null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.verified_user, size: 18),
            label: const Text('Verify Signature'),
            onPressed: _verify,
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
