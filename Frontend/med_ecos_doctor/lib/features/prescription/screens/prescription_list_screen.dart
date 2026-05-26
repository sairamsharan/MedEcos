import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/crypto_service.dart';
import '../../patient/screens/patient_details_screen.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  String _searchQuery = '';

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
                'Prescription History',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by ID, Patient Name, or Date...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ],
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _LegendChip(color: Colors.green.shade600, label: 'Signed — RSA-2048'),
              const SizedBox(width: 12),
              _LegendChip(color: Colors.orange.shade600, label: 'Unsigned'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List
        Expanded(
          child: prescriptions.isEmpty
              ? Center(
                  child: Text(
                    'No prescriptions found.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: prescriptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = prescriptions[index];
                    return _PrescriptionCard(
                      prescription: p,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PatientDetailsScreen(patientId: p.patientId)),
                      ),
                      onVerify: () => _showVerifyDialog(context, p),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showVerifyDialog(BuildContext context, Prescription p) {
    showDialog(
      context: context,
      builder: (_) => _VerifyDialog(prescription: p),
    );
  }
}

// ─── Prescription Card ────────────────────────────────────────────────────────

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.onTap,
    required this.onVerify,
  });

  final Prescription prescription;
  final VoidCallback onTap;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final p = prescription;
    final signed = p.isSigned;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: signed ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (signed ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  signed ? Icons.verified_rounded : Icons.description_outlined,
                  color: signed ? Colors.green.shade700 : Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        // Signature badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (signed ? Colors.green : Colors.orange).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                signed ? Icons.lock_rounded : Icons.lock_open_rounded,
                                size: 11,
                                color: signed ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                signed ? 'Signed' : 'Unsigned',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: signed ? Colors.green.shade800 : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${p.id}  •  ${p.date.toString().split(' ')[0]}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${p.doctorName}  •  ${p.medicines.length} medicine${p.medicines.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (signed) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sig: ${p.digitalSignature!.substring(0, 32)}…',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),
              // Actions column
              Column(
                children: [
                  if (signed)
                    Tooltip(
                      message: 'Verify signature',
                      child: IconButton(
                        icon: const Icon(Icons.fact_check_rounded, color: AppColors.primary),
                        onPressed: onVerify,
                      ),
                    ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Verify Dialog ────────────────────────────────────────────────────────────

class _VerifyDialog extends StatefulWidget {
  const _VerifyDialog({required this.prescription});
  final Prescription prescription;

  @override
  State<_VerifyDialog> createState() => _VerifyDialogState();
}

class _VerifyDialogState extends State<_VerifyDialog> {
  _VerifyState _state = _VerifyState.idle;
  bool? _isValid;

  Future<void> _verify() async {
    setState(() => _state = _VerifyState.verifying);

    await Future.delayed(const Duration(milliseconds: 400)); // let UI update

    final p = widget.prescription;
    if (!p.isSigned) {
      setState(() { _state = _VerifyState.done; _isValid = false; });
      return;
    }

    final canonical = CryptoService.buildCanonicalString(
      prescriptionId: p.id,
      patientId: p.patientId,
      patientName: p.patientName,
      doctorName: p.doctorName,
      isoDate: p.date.toIso8601String(),
      diagnosis: p.diagnosis,
      medicines: p.medicines,
      labTests: p.labTests,
    );

    final valid = CryptoService.verifySignature(
      canonical,
      p.digitalSignature!,
      p.signerPublicKeyJson!,
    );

    setState(() { _state = _VerifyState.done; _isValid = valid; });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prescription;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.fact_check_rounded, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Verify Signature'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prescription info
            _InfoRow(label: 'Patient', value: p.patientName),
            _InfoRow(label: 'Prescription ID', value: p.id),
            _InfoRow(label: 'Date', value: p.date.toString().split(' ')[0]),
            _InfoRow(label: 'Signer', value: p.doctorName),
            const SizedBox(height: 12),

            // Signature hex preview
            if (p.isSigned) ...[
              Text('Signature (RSA-2048 / SHA-256)',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: p.digitalSignature!));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signature copied to clipboard')));
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    p.digitalSignature!,
                    style: const TextStyle(fontSize: 9, fontFamily: 'monospace'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('Tap to copy full signature', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],

            const SizedBox(height: 16),

            // Result
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildResultWidget(theme),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        if (_state == _VerifyState.idle)
          FilledButton.icon(
            onPressed: p.isSigned ? _verify : null,
            icon: const Icon(Icons.verified_user_rounded, size: 18),
            label: const Text('Verify Now'),
          ),
      ],
    );
  }

  Widget _buildResultWidget(ThemeData theme) {
    switch (_state) {
      case _VerifyState.idle:
        return Padding(
          key: const ValueKey('idle'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            widget.prescription.isSigned
                ? 'Press "Verify Now" to mathematically verify the RSA-2048 signature against the prescription data.'
                : '⚠️  This prescription has no digital signature.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        );

      case _VerifyState.verifying:
        return const Padding(
          key: ValueKey('verifying'),
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Verifying RSA signature…'),
            ],
          ),
        );

      case _VerifyState.done:
        final ok = _isValid == true;
        return Container(
          key: const ValueKey('done'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ok ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ok ? Colors.green.shade300 : Colors.red.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    ok ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                    color: ok ? Colors.green.shade700 : Colors.red.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ok ? 'Signature Valid ✓' : 'Signature Invalid ✗',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ok ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ok
                    ? 'This prescription is authentic. The data matches the RSA-2048 signature and has not been tampered with since it was signed by ${widget.prescription.doctorName}.'
                    : 'Signature verification failed. The prescription data may have been modified after signing, or the signature is corrupted.',
                style: TextStyle(
                  fontSize: 12,
                  color: ok ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              if (ok) ...[
                const SizedBox(height: 8),
                Text(
                  'Algorithm: RSASSA-PKCS1-v1_5 with SHA-256\nKey Size: 2048 bits',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade600, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        );
    }
  }
}

enum _VerifyState { idle, verifying, done }

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
            ),
          ],
        ),
      );
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      );
}
