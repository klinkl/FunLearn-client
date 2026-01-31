import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

class BatteryGate {
  final Battery _battery = Battery();

  final int criticalThreshold;
  bool _networkAllowed = true;

  bool get networkAllowed => _networkAllowed;

  StreamSubscription<BatteryState>? _sub;
  Timer? _poll;

  BatteryGate({this.criticalThreshold = 5});

  Future<void> start() async {
    await _recompute();

    _sub = _battery.onBatteryStateChanged.listen((_) async {
      await _recompute();
    });

    _poll = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _recompute();
    });
  }

  Future<void> _recompute() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;

    final isCharging =
        state == BatteryState.charging || state == BatteryState.full;

    _networkAllowed = !(level <= criticalThreshold && !isCharging);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _poll?.cancel();
  }
}
