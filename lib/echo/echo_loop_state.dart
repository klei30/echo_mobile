import 'package:flutter/foundation.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_runtime_service.dart';

class EchoLoopState extends ChangeNotifier {
  static final EchoLoopState _instance = EchoLoopState._();
  factory EchoLoopState() => _instance;
  EchoLoopState._();

  Map<String, dynamic>? snapshot;
  Map<String, dynamic>? todayPriority;
  Map<String, dynamic>? thesis;
  Map<String, dynamic>? rank;
  Map<String, dynamic>? practice;
  Map<String, dynamic>? trainingSummary;
  Map<String, dynamic>? mission;
  Map<String, dynamic>? realityCheck;
  Map<String, dynamic>? growthTimeline;
  Map<String, dynamic>? intervention;
  bool loading = false;

  void apply({
    Map<String, dynamic>? snapshot,
    Map<String, dynamic>? todayPriority,
    Map<String, dynamic>? thesis,
    Map<String, dynamic>? mission,
    Map<String, dynamic>? intervention,
    Map<String, dynamic>? practice,
    Map<String, dynamic>? trainingSummary,
  }) {
    if (snapshot != null) this.snapshot = snapshot;
    if (todayPriority != null) this.todayPriority = todayPriority;
    if (thesis != null) this.thesis = thesis;
    if (mission != null) this.mission = mission;
    if (intervention != null) this.intervention = intervention;
    if (practice != null) this.practice = practice;
    if (trainingSummary != null) this.trainingSummary = trainingSummary;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (loading) return;
    if (EchoRuntimeService().isDevice) {
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        EchoApiClient().getLoopSnapshot(),
        EchoApiClient().getTodayPriority(),
        EchoApiClient().getCurrentThesis(),
        EchoApiClient().getUserRank(),
        EchoApiClient().getPracticeToday(),
        EchoApiClient().getTodayMission(),
        EchoApiClient().getRealityCheck(),
        EchoApiClient().getGrowthTimeline(),
        EchoApiClient().getNextIntervention(),
      ]);
      snapshot = results[0];
      todayPriority = results[1];
      thesis = results[2];
      rank = results[3];
      practice = results[4];
      mission = results[5];
      realityCheck = results[6];
      growthTimeline = results[7];
      final interventionData = results[8];
      final next = interventionData?['intervention'];
      intervention = next is Map ? Map<String, dynamic>.from(next) : null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
