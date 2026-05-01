import 'package:flutter/foundation.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class EchoLoopState extends ChangeNotifier {
  static final EchoLoopState _instance = EchoLoopState._();
  factory EchoLoopState() => _instance;
  EchoLoopState._();

  Map<String, dynamic>? snapshot;
  Map<String, dynamic>? todayPriority;
  Map<String, dynamic>? thesis;
  Map<String, dynamic>? rank;
  Map<String, dynamic>? practice;
  bool loading = false;

  void apply({
    Map<String, dynamic>? snapshot,
    Map<String, dynamic>? todayPriority,
    Map<String, dynamic>? thesis,
  }) {
    if (snapshot != null) this.snapshot = snapshot;
    if (todayPriority != null) this.todayPriority = todayPriority;
    if (thesis != null) this.thesis = thesis;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        EchoApiClient().getLoopSnapshot(),
        EchoApiClient().getTodayPriority(),
        EchoApiClient().getCurrentThesis(),
        EchoApiClient().getUserRank(),
        EchoApiClient().getPracticeToday(),
      ]);
      snapshot = results[0];
      todayPriority = results[1];
      thesis = results[2];
      rank = results[3];
      practice = results[4];
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
