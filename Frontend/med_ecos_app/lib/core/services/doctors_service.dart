import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/doctor_model.dart';

class DoctorsService {
  static final DoctorsService _instance = DoctorsService._internal();
  factory DoctorsService() => _instance;
  DoctorsService._internal();

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

  /// Returns filtered & sorted doctors from backend.
  Future<List<Doctor>> getNearbyDoctors({
    String selectedSpecialization = 'All',
    bool availableOnly = false,
    String searchQuery = '',
    SortOption sortBy = SortOption.nearest,
    double? userLat,
    double? userLng,
  }) async {
    try {
      final response = await http.get(Uri.parse('https://medecos.onrender.com/api/public/doctors'));
      if (response.statusCode != 200) {
        throw Exception('Failed to load doctors');
      }
      final List<dynamic> data = jsonDecode(response.body);
      List<Doctor> result = data.map((json) => Doctor.fromJson(json)).toList();

      if (userLat != null && userLng != null) {
        for (var d in result) {
          d.distanceKm = haversineDistance(userLat, userLng, d.lat, d.lng);
        }
      }

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
    } catch (e) {
      print('Error fetching doctors: $e');
      return [];
    }
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
