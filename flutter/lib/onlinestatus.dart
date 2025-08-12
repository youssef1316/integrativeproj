import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';


class OnlineStatus {
  OnlineStatus._();
  static final OnlineStatus instance = OnlineStatus._();

  // Listen to this in UI
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription? _connSub;
  Timer? _pingTimer;

  Future<void> init() async {
    // initial read
    final conn = await Connectivity().checkConnectivity();
    _setOnline(_connToBool(conn));

    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen((result) async {
      final maybeOnline = _connToBool(result);
      _setOnline(maybeOnline);
      _debouncedPing(); // verifies with DNS lookup
    });
    // periodic verification (optional)
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) => _debouncedPing());
  }

  void dispose() {
    _connSub?.cancel();
    _pingTimer?.cancel();
  }

  bool _connToBool(dynamic r) {
    if (r is ConnectivityResult) {
      return r != ConnectivityResult.none;
    }
    if (r is List<ConnectivityResult>) {
      if (r.isEmpty) return false;
      return r.any((e) => e != ConnectivityResult.none);
    }
    return false;
  }

  void _setOnline(bool v) {
    if (isOnline.value != v) isOnline.value = v;
  }

  Future<void> _debouncedPing() async {
    try {
      final res = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 3));
      _setOnline(res.isNotEmpty && res.first.rawAddress.isNotEmpty);
    } catch (_) {
      _setOnline(false);
    }
  }
}