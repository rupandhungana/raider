import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../data/repositories/ride_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/ride.dart';
import '../../shared/format.dart';

class RideGroup {
  const RideGroup(this.title, this.rides);

  final String title;
  final List<Ride> rides;
}

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({required this._rides, required this._settings, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _rides.addListener(notifyListeners);
    _settings.addListener(notifyListeners);
  }

  final RideRepository _rides;
  final SettingsRepository _settings;
  final DateTime Function() _clock;

  Units get units => _settings.settings.units;
  List<Ride> get rides => _rides.rides;
  double get totalKm => rides.fold(0, (sum, r) => sum + r.distanceKm);
  Duration get movingTime => rides.fold(Duration.zero, (sum, r) => sum + r.moving);
  double get averageKmh => movingTime.inMilliseconds == 0 ? 0 : totalKm / (movingTime.inMilliseconds / 3600000);
  double get topKmh => rides.isEmpty ? 0 : rides.map((r) => r.topKmh).reduce(math.max);
  Ride? get longest => rides.isEmpty ? null : rides.reduce((a, b) => a.distanceKm >= b.distanceKm ? a : b);

  /// "This Week" for the last seven days, then one section per month.
  List<RideGroup> get groups {
    final now = _clock();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final thisWeek = <Ride>[];
    final byMonth = <String, List<Ride>>{};
    for (final ride in rides) {
      if (!ride.startedAt.isBefore(weekStart)) {
        thisWeek.add(ride);
        continue;
      }
      final sameMonth = ride.startedAt.year == now.year && ride.startedAt.month == now.month;
      final title = sameMonth
          ? 'Earlier in ${monthName(ride.startedAt.month)}'
          : ride.startedAt.year == now.year
          ? monthName(ride.startedAt.month)
          : '${monthName(ride.startedAt.month)} ${ride.startedAt.year}';
      byMonth.putIfAbsent(title, () => []).add(ride);
    }
    return [
      if (thisWeek.isNotEmpty) RideGroup('This Week', thisWeek),
      for (final entry in byMonth.entries) RideGroup(entry.key, entry.value),
    ];
  }

  @override
  void dispose() {
    _rides.removeListener(notifyListeners);
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}
