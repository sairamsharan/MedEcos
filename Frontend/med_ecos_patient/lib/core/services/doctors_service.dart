import 'dart:math';
import '../models/doctor_model.dart';

class DoctorsService {
  static final DoctorsService _instance = DoctorsService._internal();
  factory DoctorsService() => _instance;
  DoctorsService._internal();

  // ---------------------------------------------------------------------------
  // Mock dataset — swap the getNearbyDoctors() body with an HTTP call later.
  // Coordinates are spread around Mumbai / Pune for realism.
  // ---------------------------------------------------------------------------
  static const List<Doctor> _mockDoctors = [
    Doctor(
      id: 'D001', name: 'Dr. Priya Sharma', specialization: 'General Physician',
      hospital: 'Apollo Clinic, Andheri', imageInitials: 'PS',
      rating: 4.8, reviewCount: 312, distanceKm: 0.8,
      lat: 19.1196, lng: 72.8468, isAvailable: true, isVerified: true,
      experienceYears: 12, consultationFee: 400,
    ),
    Doctor(
      id: 'D002', name: 'Dr. Rajesh Mehta', specialization: 'Cardiologist',
      hospital: 'Kokilaben Hospital, Versova', imageInitials: 'RM',
      rating: 4.9, reviewCount: 518, distanceKm: 1.4,
      lat: 19.1313, lng: 72.8197, isAvailable: true, isVerified: true,
      experienceYears: 20, consultationFee: 900,
    ),
    Doctor(
      id: 'D003', name: 'Dr. Ayesha Khan', specialization: 'Dermatologist',
      hospital: 'SkinCare Center, Bandra', imageInitials: 'AK',
      rating: 4.7, reviewCount: 204, distanceKm: 2.1,
      lat: 19.0596, lng: 72.8295, isAvailable: false, isVerified: true,
      experienceYears: 8, consultationFee: 600,
    ),
    Doctor(
      id: 'D004', name: 'Dr. Vikram Nair', specialization: 'Orthopedic',
      hospital: 'Lilavati Hospital, Bandra', imageInitials: 'VN',
      rating: 4.6, reviewCount: 189, distanceKm: 2.4,
      lat: 19.0510, lng: 72.8257, isAvailable: true, isVerified: true,
      experienceYears: 15, consultationFee: 750,
    ),
    Doctor(
      id: 'D005', name: 'Dr. Sneha Patil', specialization: 'Pediatrician',
      hospital: 'Rainbow Children\'s Clinic', imageInitials: 'SP',
      rating: 4.9, reviewCount: 421, distanceKm: 0.5,
      lat: 19.1110, lng: 72.8578, isAvailable: true, isVerified: true,
      experienceYears: 10, consultationFee: 500,
    ),
    Doctor(
      id: 'D006', name: 'Dr. Arjun Desai', specialization: 'ENT Specialist',
      hospital: 'City ENT Clinic, Goregaon', imageInitials: 'AD',
      rating: 4.5, reviewCount: 98, distanceKm: 3.0,
      lat: 19.1630, lng: 72.8492, isAvailable: false, isVerified: true,
      experienceYears: 9, consultationFee: 550,
    ),
    Doctor(
      id: 'D007', name: 'Dr. Meena Iyer', specialization: 'Neurologist',
      hospital: 'Hinduja Hospital, Mahim', imageInitials: 'MI',
      rating: 4.8, reviewCount: 276, distanceKm: 3.6,
      lat: 19.0380, lng: 72.8407, isAvailable: true, isVerified: true,
      experienceYears: 18, consultationFee: 1100,
    ),
    Doctor(
      id: 'D008', name: 'Dr. Suresh Joshi', specialization: 'General Physician',
      hospital: 'Joshi Clinic, Borivali', imageInitials: 'SJ',
      rating: 4.3, reviewCount: 67, distanceKm: 4.2,
      lat: 19.2307, lng: 72.8567, isAvailable: true, isVerified: false,
      experienceYears: 6, consultationFee: 300,
    ),
    Doctor(
      id: 'D009', name: 'Dr. Farah Siddiqui', specialization: 'Gynecologist',
      hospital: 'Wockhardt Hospital, Mulund', imageInitials: 'FS',
      rating: 4.7, reviewCount: 355, distanceKm: 5.0,
      lat: 19.1756, lng: 72.9566, isAvailable: true, isVerified: true,
      experienceYears: 14, consultationFee: 800,
    ),
    Doctor(
      id: 'D010', name: 'Dr. Anil Kapoor', specialization: 'Cardiologist',
      hospital: 'Fortis Hospital, Mulund', imageInitials: 'AK',
      rating: 4.6, reviewCount: 290, distanceKm: 5.3,
      lat: 19.1720, lng: 72.9610, isAvailable: false, isVerified: true,
      experienceYears: 22, consultationFee: 1000,
    ),
    Doctor(
      id: 'D011', name: 'Dr. Priyanka Rao', specialization: 'Dermatologist',
      hospital: 'Glow Skin Clinic, Juhu', imageInitials: 'PR',
      rating: 4.4, reviewCount: 143, distanceKm: 1.9,
      lat: 19.1075, lng: 72.8263, isAvailable: true, isVerified: true,
      experienceYears: 7, consultationFee: 650,
    ),
    Doctor(
      id: 'D012', name: 'Dr. Kiran Chavan', specialization: 'Orthopedic',
      hospital: 'Sion Hospital, Sion', imageInitials: 'KC',
      rating: 4.2, reviewCount: 55, distanceKm: 6.1,
      lat: 19.0430, lng: 72.8627, isAvailable: true, isVerified: false,
      experienceYears: 5, consultationFee: 350,
    ),
    Doctor(
      id: 'D013', name: 'Dr. Nisha Thomas', specialization: 'Pediatrician',
      hospital: 'KEM Hospital, Parel', imageInitials: 'NT',
      rating: 4.8, reviewCount: 387, distanceKm: 4.7,
      lat: 18.9983, lng: 72.8419, isAvailable: false, isVerified: true,
      experienceYears: 11, consultationFee: 500,
    ),
    Doctor(
      id: 'D014', name: 'Dr. Rahul Gupte', specialization: 'ENT Specialist',
      hospital: 'ENT Care, Chembur', imageInitials: 'RG',
      rating: 4.5, reviewCount: 112, distanceKm: 4.0,
      lat: 19.0619, lng: 72.9001, isAvailable: true, isVerified: true,
      experienceYears: 13, consultationFee: 600,
    ),
    Doctor(
      id: 'D015', name: 'Dr. Deepa Kulkarni', specialization: 'Neurologist',
      hospital: 'Breach Candy Hospital', imageInitials: 'DK',
      rating: 4.9, reviewCount: 462, distanceKm: 5.8,
      lat: 18.9726, lng: 72.8093, isAvailable: true, isVerified: true,
      experienceYears: 24, consultationFee: 1200,
    ),
  ];

  static const List<String> specializations = [
    'All',
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Orthopedic',
    'Pediatrician',
    'ENT Specialist',
    'Neurologist',
    'Gynecologist',
  ];

  /// Returns filtered & sorted doctors.
  /// When the backend is ready, replace the body with an HTTP call.
  List<Doctor> getNearbyDoctors({
    String selectedSpecialization = 'All',
    bool availableOnly = false,
    String searchQuery = '',
    SortOption sortBy = SortOption.nearest,
  }) {
    List<Doctor> result = List.from(_mockDoctors);

    if (selectedSpecialization != 'All') {
      result = result.where((d) => d.specialization == selectedSpecialization).toList();
    }

    if (availableOnly) {
      result = result.where((d) => d.isAvailable).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((d) =>
          d.name.toLowerCase().contains(q) ||
          d.specialization.toLowerCase().contains(q) ||
          d.hospital.toLowerCase().contains(q)).toList();
    }

    switch (sortBy) {
      case SortOption.nearest:
        result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case SortOption.topRated:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.availableFirst:
        result.sort((a, b) {
          if (a.isAvailable == b.isAvailable) return a.distanceKm.compareTo(b.distanceKm);
          return a.isAvailable ? -1 : 1;
        });
        break;
    }

    return result;
  }

  /// Calculates Haversine distance between two lat/lon points (km).
  static double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;
}

enum SortOption { nearest, topRated, availableFirst }
