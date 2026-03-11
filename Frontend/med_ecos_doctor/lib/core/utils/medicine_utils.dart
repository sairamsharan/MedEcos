class MedicineUtils {
  static bool isActiveMedicine(DateTime prescribedDate, String durationStr) {
    if (durationStr == 'Ongoing') {
      return true;
    }

    int days = 0;
    final parts = durationStr.split(' ');
    if (parts.length == 2) {
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

    final expirationDate = prescribedDate.add(Duration(days: days));
    // It's still active if now is before the expiration date boundary (start of that day)
    final now = DateTime.now();
    // Normalize to dates
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedExp = DateTime(expirationDate.year, expirationDate.month, expirationDate.day);

    return normalizedNow.compareTo(normalizedExp) <= 0;
  }
}
