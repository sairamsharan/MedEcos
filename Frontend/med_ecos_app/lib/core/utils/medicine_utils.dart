class MedicineUtils {
  static DateTime? parseEndDate(DateTime startDate, String durationStr) {
    if (durationStr == 'Ongoing' || durationStr.isEmpty) {
      return null;
    }

    int days = 0;
    final parts = durationStr.split(' ');
    if (parts.length >= 2) {
      final value = int.tryParse(parts[0]) ?? 0;
      final unit = parts[1].toLowerCase();

      if (unit.contains('day')) {
        days = value;
      } else if (unit.contains('week')) {
        days = value * 7;
      } else if (unit.contains('month')) {
        days = value * 30; // Approximation
      }
    }
    
    if (days == 0) return null;
    return startDate.add(Duration(days: days));
  }

  static bool isActiveMedicine(DateTime prescribedDate, String durationStr) {
    final expirationDate = parseEndDate(prescribedDate, durationStr);
    if (expirationDate == null) return true;
    
    // It's still active if now is before the expiration date boundary (start of that day)
    final now = DateTime.now();
    // Normalize to dates
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedExp = DateTime(expirationDate.year, expirationDate.month, expirationDate.day);

    return normalizedNow.compareTo(normalizedExp) <= 0;
  }
}
