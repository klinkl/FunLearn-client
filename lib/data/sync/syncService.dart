import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:funlearn_client/data/studySessionController.dart';

class SyncService {
  final StudySessionController studySessionController;
  final Stream<ConnectivityResult> connectivityStream; //for test

  bool _syncInProgress = false;
  DateTime? _lastFailure;
  StreamSubscription<ConnectivityResult>? _sub;

  SyncService({
    required this.studySessionController,
    Stream<ConnectivityResult>? connectivityStream,
  }) : connectivityStream =
           connectivityStream ??
           Connectivity().onConnectivityChanged.cast<ConnectivityResult>();

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
    if (_syncInProgress) return;

    if (_lastFailure != null) {
      final diff = DateTime.now().difference(_lastFailure!);
      if (diff.inSeconds < 30) return;
    }

    _syncInProgress = true;
    try {
      await studySessionController.syncPendingSessions();
      _lastFailure = null;
    } catch (_) {
      _lastFailure = DateTime.now();
    } finally {
      _syncInProgress = false;
    }
  }
}
