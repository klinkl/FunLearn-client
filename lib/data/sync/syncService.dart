import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/service/batteryGate.dart';
import 'package:funlearn_client/data/studySessionController.dart';
import 'package:funlearn_client/data/questController.dart';

class SyncService {
  final StudySessionController studySessionController;
  final QuestController questController;
  final DatabaseHelper dbHelper;
  final BatteryGate batteryGate;
  final Stream<ConnectivityResult> connectivityStream; //for test

  bool _syncInProgress = false;
  DateTime? _lastFailure;
  StreamSubscription<ConnectivityResult>? _sub;

  SyncService({
    required this.studySessionController,
    required this.questController,
    required this.dbHelper,
    required this.batteryGate,
    Stream<ConnectivityResult>? connectivityStream,
  }) : connectivityStream =
           connectivityStream ??
           Connectivity().onConnectivityChanged.map<ConnectivityResult>((
             event,
           ) {
             try {
               if (event is List<ConnectivityResult>) {
                 if (event.contains(ConnectivityResult.wifi)) {
                   return ConnectivityResult.wifi;
                 }
                 if (event.contains(ConnectivityResult.mobile)) {
                   return ConnectivityResult.mobile;
                 }
                 if (event.contains(ConnectivityResult.ethernet)) {
                   return ConnectivityResult.ethernet;
                 }
                 return ConnectivityResult.none;
               }
             } catch (_) {
               return ConnectivityResult.none;
             }
           });

  Future<void> syncNow() => _trySync();

  Future<void> start() async {
    await _trySync();

    _sub = connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        _trySync();
      }
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _trySync() async {
    if (!batteryGate.networkAllowed) return;
    if (_syncInProgress) return;

    if (_lastFailure != null) {
      final diff = DateTime.now().difference(_lastFailure!);
      if (diff.inSeconds < 30) return;
    }

    _syncInProgress = true;
    try {
      await studySessionController.syncPendingSessions();
      final stillPending = await dbHelper.getPendingStudySessions();

      if (stillPending.isEmpty) {
        await questController.refreshFromServer();
      }
      _lastFailure = null;
    } catch (_) {
      _lastFailure = DateTime.now();
    } finally {
      _syncInProgress = false;
    }
  }
}
