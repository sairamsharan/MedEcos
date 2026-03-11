class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String hospital;
  final String imageInitials;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final double lat;
  final double lng;
  final bool isAvailable;
  final bool isVerified;
  final int experienceYears;
  final int consultationFee;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.hospital,
    required this.imageInitials,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.lat,
    required this.lng,
    required this.isAvailable,
    required this.isVerified,
    required this.experienceYears,
    required this.consultationFee,
  });

  /// Creates a Doctor from a backend JSON response (future use).
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      hospital: json['hospital'] ?? '',
      imageInitials: (json['name'] as String? ?? 'DR')
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join(),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
      lat: (json['location']?['coordinates']?[1] ?? 0).toDouble(),
      lng: (json['location']?['coordinates']?[0] ?? 0).toDouble(),
      isAvailable: json['isAvailable'] ?? false,
      isVerified: json['isVerified'] ?? false,
      experienceYears: json['experienceYears'] ?? 0,
      consultationFee: json['consultationFee'] ?? 0,
    );
  }
}
