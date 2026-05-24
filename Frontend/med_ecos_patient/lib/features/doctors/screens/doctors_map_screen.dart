import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/doctor_model.dart';
import '../../../core/services/doctors_service.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/doctor_bottom_sheet.dart';

class DoctorsMapScreen extends StatefulWidget {
  const DoctorsMapScreen({super.key});

  @override
  State<DoctorsMapScreen> createState() => _DoctorsMapScreenState();
}

class _DoctorsMapScreenState extends State<DoctorsMapScreen> {
  final DoctorsService _service = DoctorsService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Default centre: Mumbai
  LatLng _centre = const LatLng(19.1136, 72.8697);
  String _selectedSpec = 'All';
  bool _availableOnly = false;
  SortOption _sortBy = SortOption.nearest;
  List<Doctor> _doctors = [];
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _refreshDoctors();
    _searchController.addListener(_refreshDoctors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshDoctors() {
    setState(() {
      _doctors = _service.getNearbyDoctors(
        selectedSpecialization: _selectedSpec,
        availableOnly: _availableOnly,
        searchQuery: _searchController.text,
        sortBy: _sortBy,
      );
    });
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permissions are permanently denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final newCentre = LatLng(pos.latitude, pos.longitude);
      setState(() => _centre = newCentre);
      _mapController.move(newCentre, 14);
    } catch (e) {
      _showSnack('Could not get location: $e');
    } finally {
      setState(() => _locating = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showDoctorSheet(Doctor doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorBottomSheet(doctor: doc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── MAP ──────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centre,
              initialZoom: 13.0,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.medecos.patient',
              ),
              // User location pulse marker
              MarkerLayer(markers: [
                Marker(
                  point: _centre,
                  width: 20, height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8, spreadRadius: 4,
                        )
                      ],
                    ),
                  ),
                ),
              ]),
              // Doctor pins
              MarkerLayer(
                markers: _doctors.map((doc) {
                  return Marker(
                    point: LatLng(doc.lat, doc.lng),
                    width: 50, height: 60,
                    child: GestureDetector(
                      onTap: () => _showDoctorSheet(doc),
                      child: _DoctorPin(doctor: doc),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── TOP BAR: AppBar + Search + Filters ───────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // AppBar row
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search doctors, specialization...',
                            hintStyle: TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _refreshDoctors();
                          },
                        ),
                      const Icon(Icons.search_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Specialization chips row
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: DoctorsService.specializations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final spec = DoctorsService.specializations[i];
                      final selected = spec == _selectedSpec;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedSpec = spec);
                          _refreshDoctors();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            spec,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Secondary filters row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Available Only toggle
                      GestureDetector(
                        onTap: () {
                          setState(() => _availableOnly = !_availableOnly);
                          _refreshDoctors();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _availableOnly
                                ? AppColors.success.withOpacity(0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _availableOnly
                                  ? AppColors.success
                                  : Colors.grey.shade300,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _availableOnly
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 14,
                                color: _availableOnly
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Available Now',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _availableOnly
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Sort dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SortOption>(
                            value: _sortBy,
                            isDense: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: AppColors.textSecondary),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: SortOption.nearest,
                                child: Text('Nearest First'),
                              ),
                              DropdownMenuItem(
                                value: SortOption.topRated,
                                child: Text('Top Rated'),
                              ),
                              DropdownMenuItem(
                                value: SortOption.availableFirst,
                                child: Text('Available First'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _sortBy = v);
                              _refreshDoctors();
                            },
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_doctors.length} found',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── LOCATE ME FAB ─────────────────────────────────────────────────────
          Positioned(
            bottom: 32,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'locateMe',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 4,
              onPressed: _locating ? null : _locateMe,
              child: _locating
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),

          // ── NO RESULTS ────────────────────────────────────────────────────────
          if (_doctors.isEmpty)
            Positioned(
              bottom: 100,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: const Text(
                    'No doctors found with these filters',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom map pin widget
// ─────────────────────────────────────────────────────────────────────────────
class _DoctorPin extends StatelessWidget {
  final Doctor doctor;
  const _DoctorPin({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bubble
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: doctor.isAvailable
                  ? [AppColors.primary, AppColors.primaryDark]
                  : [Colors.grey.shade400, Colors.grey.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: (doctor.isAvailable ? AppColors.primary : Colors.grey)
                    .withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Center(
            child: Text(
              doctor.imageInitials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Tail
        CustomPaint(
          size: const Size(14, 8),
          painter: _PinTailPainter(
            color: doctor.isAvailable ? AppColors.primaryDark : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}
