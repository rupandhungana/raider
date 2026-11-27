import 'package:flutter/foundation.dart';

import '../../domain/models/ride.dart';
import '../services/local_store.dart';

/// The single source of truth for recorded rides, newest first. Summaries stay
/// in memory; each ride's GPS track is read from the store when it's needed.
class RideRepository extends ChangeNotifier {
  RideRepository(this._store) : _rides = _load(_store);

  final LocalStore _store;
  final List<Ride> _rides;
  final Map<String, List<RoutePoint>> _points = {};

  static const _indexKey = 'rides';
  static String _pointsKey(String id) => 'ride-points-$id';

  static List<Ride> _load(LocalStore store) {
    final saved = store.read(_indexKey);
    if (saved is! List) return [];
    final rides = <Ride>[];
    for (final item in saved) {
      try {
        rides.add(Ride.fromJson((item as Map).cast<String, Object?>()));
      } on Object {
        // Skip a damaged entry rather than lose the whole history.
      }
    }
    return rides..sort(_newestFirst);
  }

  List<Ride> get rides => List.unmodifiable(_rides);

  Ride? byId(String id) => _rides.where((ride) => ride.id == id).firstOrNull;

  /// The ride's GPS track, oldest fix first. Empty if it has none.
  List<RoutePoint> points(String id) => _points[id] ??= switch (_store.read(_pointsKey(id))) {
    final List<Object?> list => [for (final p in list) RoutePoint.fromJson((p as Map).cast<String, Object?>())],
    _ => const [],
  };

  void add(Ride ride, List<RoutePoint> points) {
    _store.write(_pointsKey(ride.id), [for (final p in points) p.toJson()]);
    _points[ride.id] = List.unmodifiable(points);
    _rides
      ..add(ride)
      ..sort(_newestFirst);
    _save();
  }

  /// Renames a ride, e.g. once its start and end have been looked up.
  void rename(String id, String route) {
    final i = _rides.indexWhere((r) => r.id == id);
    if (i < 0) return;
    _rides[i] = _rides[i].copyWith(route: route);
    _save();
  }

  void remove(String id) {
    _store.delete(_pointsKey(id));
    _points.remove(id);
    _rides.removeWhere((ride) => ride.id == id);
    _save();
  }

  void _save() {
    _store.write(_indexKey, [for (final r in _rides) r.toJson()]);
    notifyListeners();
  }

  static int _newestFirst(Ride a, Ride b) => b.startedAt.compareTo(a.startedAt);
}
