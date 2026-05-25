import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages online presence via heartbeat + app lifecycle.
/// Call [start] once after authentication and [stop] on logout/dispose.
/// Online definition: last_seen < 2 minutes (enforced by stats_zone SQL cutoff).
class PresenceService with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;
  Timer? _timer;
  String? _uid;

  // 60s heartbeat → 60s margin before the 2-minute SQL cutoff
  static const _heartbeatInterval = Duration(seconds: 60);

  void start(String uid) {
    if (_uid == uid) return;
    stop();
    _uid = uid;
    WidgetsBinding.instance.addObserver(this);
    _ping(true);
    _timer = Timer.periodic(_heartbeatInterval, (_) => _ping(true));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_uid != null) {
      WidgetsBinding.instance.removeObserver(this);
      _ping(false);
      _uid = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _ping(true);
        break;
      case AppLifecycleState.paused:
        // Web: paused = tab not visible but not closed — rely on last_seen expiry
        // Mobile: paused = app backgrounded → set offline immediately
        if (!kIsWeb) _ping(false);
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _ping(false);
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _ping(bool online) {
    final uid = _uid;
    if (uid == null) return;
    final payload = online
        ? {
            'est_en_ligne': true,
            'last_seen': DateTime.now().toUtc().toIso8601String(),
          }
        : {'est_en_ligne': false};
    _supabase
        .from('utilisateurs')
        .update(payload)
        .eq('id', uid)
        .then((_) {}, onError: (e) => debugPrint('PresenceService: $e'));
  }
}
