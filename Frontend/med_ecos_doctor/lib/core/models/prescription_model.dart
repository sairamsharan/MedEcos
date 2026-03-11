class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorName;
  final DateTime date;
  final String diagnosis;
  final List<Map<String, String>> medicines;
  final List<String> labTests;

  Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.date,
    required this.diagnosis,
    required this.medicines,
    required this.labTests,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'doctorName': doctorName,
        'date': date.toIso8601String(),
        'diagnosis': diagnosis,
        'medicines': medicines,
        'labTests': labTests,
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
      );
}
