class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorName;
  final DateTime date;
  final String diagnosis;
  final List<Map<String, String>> medicines;
  final List<String> labTests;

  /// Base64-encoded RSA-PKCS1v15/SHA-256 signature.
  /// Null until the doctor signs the prescription.
  final String? digitalSignature;

  /// The doctor's RSA public key (JSON: {n, e}) at the time of signing.
  /// Stored alongside the signature so any party can verify without a server.
  final String? signerPublicKeyJson;

  Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.date,
    required this.diagnosis,
    required this.medicines,
    required this.labTests,
    this.digitalSignature,
    this.signerPublicKeyJson,
  });

  /// True when the prescription carries a valid cryptographic signature.
  bool get isSigned => digitalSignature != null && signerPublicKeyJson != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'doctorName': doctorName,
        'date': date.toIso8601String(),
        'diagnosis': diagnosis,
        'medicines': medicines,
        'labTests': labTests,
        'digitalSignature': digitalSignature,
        'signerPublicKeyJson': signerPublicKeyJson,
      };

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        patientName: json['patientName'] as String,
        doctorName: json['doctorName'] as String,
        date: DateTime.parse(json['date'] as String),
        diagnosis: json['diagnosis'] as String,
        medicines: (json['medicines'] as List<dynamic>)
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
        labTests: List<String>.from(json['labTests'] as List),
        digitalSignature: json['digitalSignature'] as String?,
        signerPublicKeyJson: json['signerPublicKeyJson'] as String?,
      );
}
