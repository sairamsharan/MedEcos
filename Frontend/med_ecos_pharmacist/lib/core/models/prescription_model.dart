class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String pharmacistName;
  final DateTime date;
  final String diagnosis;
  final List<Map<String, String>> medicines;
  final List<String> labTests;

  /// Optional fields for digital-signature verification (read-only).
  final String? doctorName;
  final String? digitalSignature;
  final String? signerPublicKeyJson;

  /// True when the prescription carries both a signature blob and its public key.
  bool get isSigned => digitalSignature != null && signerPublicKeyJson != null;

  Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.pharmacistName,
    required this.date,
    required this.diagnosis,
    required this.medicines,
    required this.labTests,
    this.doctorName,
    this.digitalSignature,
    this.signerPublicKeyJson,
  });
}
