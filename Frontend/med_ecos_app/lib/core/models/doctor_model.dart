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

  /// Creates a Doctor from a backend JSON response.
  factory Doctor.fromJson(Map<String, dynamic> json) {
    final String docName = json['username'] ?? json['name'] ?? 'Unknown Doctor';
    return Doctor(
      id: json['_id'] ?? json['id'] ?? '',
      name: docName,
      specialization: json['speciality'] ?? json['specialization'] ?? 'General',
      hospital: json['hospital'] ?? json['address'] ?? '',
      imageInitials: json['imageInitials'] ?? docName
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join(),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      distanceKm: (json['distanceKm'] ?? 0).toDouble(), // Calculated dynamically later if needed
      lat: (json['location']?['lat'] ?? 0).toDouble(),
      lng: (json['location']?['lng'] ?? 0).toDouble(),
      isAvailable: json['isAvailable'] ?? true, // Defaulting to true for now
      isVerified: json['isVerified'] ?? true,
      experienceYears: json['experienceYears'] ?? 0,
      consultationFee: json['consultationFee'] ?? 0,
    );
  }
}
