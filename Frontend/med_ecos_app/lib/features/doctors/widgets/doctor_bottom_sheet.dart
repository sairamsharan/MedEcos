import 'package:flutter/material.dart';
import '../../../core/models/doctor_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../appointments/widgets/book_appointment_dialog.dart';

class DoctorBottomSheet extends StatelessWidget {
  final Doctor doctor;

  const DoctorBottomSheet({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Doctor header row
          Row(
            children: [
              // Avatar
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    doctor.imageInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name, spec, verified
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            doctor.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (doctor.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: AppColors.primary, size: 18),
                        ]
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialization,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.hospital,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Available badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: doctor.isAvailable
                      ? AppColors.success.withOpacity(0.12)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  doctor.isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: doctor.isAvailable ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _statChip(
                Icons.star_rounded,
                '${doctor.rating} (${doctor.reviewCount})',
                Colors.amber,
              ),
              const SizedBox(width: 10),
              _statChip(
                Icons.location_on_rounded,
                '${doctor.distanceKm.toStringAsFixed(1)} km',
                AppColors.primary,
              ),
              const SizedBox(width: 10),
              _statChip(
                Icons.work_outline_rounded,
                '${doctor.experienceYears} yrs',
                Colors.blueGrey,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Consultation fee
          Row(
            children: [
              const Icon(Icons.currency_rupee, size: 16, color: AppColors.textSecondary),
              Text(
                '${doctor.consultationFee} Consultation Fee',
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await showDialog(
                      context: context,
                      builder: (_) => BookAppointmentDialog(initialDoctorId: doctor.id),
                    );
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: const Text('Book Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
