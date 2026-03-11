class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String contact;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'contact': contact,
      };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int,
        gender: json['gender'] as String,
        contact: json['contact'] as String,
      );
}
