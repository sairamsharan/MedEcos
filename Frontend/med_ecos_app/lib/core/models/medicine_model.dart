enum MealType { breakfast, lunch, snack, dinner }
enum TimeType { beforeMeal, afterMeal, emptyStomach }

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final int frequency;
  final List<MedicineTiming> timings;
  final DateTime startDate;
  final DateTime? endDate;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timings,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'timings': timings.map((x) => x.toMap()).toList(), // We'll need to serialize this
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  // Factory constructor for deserialization
  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        id: json['id'] as String,
        name: json['name'] as String,
        dosage: json['dosage'] as String,
        frequency: json['frequency'] as int,
        timings: (json['timings'] as List<dynamic>)
            .map((t) => MedicineTiming.fromJson(t as Map<String, dynamic>))
            .toList(),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
      );
}

class MedicineTiming {
  final TimeType timeType;
  final MealType mealRef;
  final int offsetMinutes; // e.g., -30 for 30 mins before

  MedicineTiming({
    required this.timeType,
    required this.mealRef,
    required this.offsetMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'timeType': timeType.index,
      'mealRef': mealRef.index,
      'offsetMinutes': offsetMinutes,
    };
  }

  factory MedicineTiming.fromJson(Map<String, dynamic> json) => MedicineTiming(
        timeType: TimeType.values[json['timeType'] as int],
        mealRef: MealType.values[json['mealRef'] as int],
        offsetMinutes: json['offsetMinutes'] as int,
      );
}
