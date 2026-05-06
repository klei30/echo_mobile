import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chatmcp/echo/auth_service.dart';
import 'package:logging/logging.dart';

class EchoApiClient {
  static final EchoApiClient _i = EchoApiClient._();
  factory EchoApiClient() => _i;
  EchoApiClient._();

  static final _log = Logger('echo.api');

  String get _base => AuthService().baseUrl;
  Map<String, String> get _h => AuthService().authHeaders;

  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/user/stats'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getUserStats HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getUserStats error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getConfidence() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/user/confidence'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getConfidence HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getConfidence error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserInsights() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/user/insights'), headers: _h).timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getUserInsights HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getUserInsights error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getEmergence() async {
    try {
      final resp = await http.post(Uri.parse('$_base/v1/emergence'), headers: _h).timeout(const Duration(seconds: 35));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getEmergence HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getEmergence error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getWeeklyMirror() async {
    try {
      final resp = await http.post(Uri.parse('$_base/v1/mirror/weekly'), headers: _h).timeout(const Duration(seconds: 35));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getWeeklyMirror HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getWeeklyMirror error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getMemories() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/user/memories'), headers: _h).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['memories'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      _log.warning('getMemories HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getMemories error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getSkills() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/user/skills'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['skills'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      _log.warning('getSkills HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getSkills error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getTalent() async {
    try {
      final resp = await http.post(Uri.parse('$_base/v1/user/talent'), headers: _h).timeout(const Duration(seconds: 45));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getTalent HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getTalent error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getNotableQuote() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/user/notable-quote'), headers: _h).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getNotableQuote HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getNotableQuote error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getExperiment() async {
    try {
      final resp = await http.post(Uri.parse('$_base/v1/user/experiment'), headers: _h).timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getExperiment HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getExperiment error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getUserHistory() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/user/history'), headers: _h).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['pairs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      _log.warning('getUserHistory HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getUserHistory error: $e');
    }
    return [];
  }

  Future<bool> getCheckinStatus() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/daily/checkin/status'), headers: _h).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['done'] as bool? ?? false;
      }
    } catch (e) {
      _log.warning('getCheckinStatus error: $e');
    }
    return false;
  }

  Future<List<String>?> getDailyQuestions() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/daily/questions'), headers: _h).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['questions'] as List? ?? []).map((e) => e.toString()).toList();
      }
      _log.warning('getDailyQuestions HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getDailyQuestions error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserReport() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/user/report'), headers: _h).timeout(const Duration(seconds: 45));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getUserReport HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getUserReport error: $e');
    }
    return null;
  }

  Future<void> registerFcmToken(String token) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      await http
          .post(Uri.parse('$_base/v1/user/fcm-token'), headers: h, body: jsonEncode({'token': token, 'platform': 'android'}))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _log.warning('registerFcmToken error: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserSignal() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/user/signal'), headers: _h).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getUserSignal HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getUserSignal error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> submitOnboardingFirstRead(String answer) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      final resp = await http
          .post(Uri.parse('$_base/v1/onboarding/first-read'), headers: h, body: jsonEncode({'answer': answer}))
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('submitOnboardingFirstRead HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('submitOnboardingFirstRead error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getPracticeToday() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/practice/today'), headers: _h).timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getPracticeToday HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getPracticeToday error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> logPractice(String repId, bool done) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      final resp = await http
          .post(Uri.parse('$_base/v1/practice/log'), headers: h, body: jsonEncode({'rep_id': repId, 'done': done}))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('logPractice HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('logPractice error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> askTwin(String question) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      final resp = await http
          .post(Uri.parse('$_base/v1/twin/ask'), headers: h, body: jsonEncode({'question': question}))
          .timeout(const Duration(seconds: 45));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('askTwin HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('askTwin error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> chooseTwin(String sessionId, String chosen) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      final resp = await http
          .post(Uri.parse('$_base/v1/twin/choose'), headers: h, body: jsonEncode({'session_id': sessionId, 'chosen': chosen}))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('chooseTwin HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('chooseTwin error: $e');
    }
    return null;
  }

  Future<String> getTrainingStatus({String? lane}) async {
    try {
      final uri = Uri.parse('$_base/v1/training/status').replace(
        queryParameters: lane == null ? null : {'lane': lane},
      );
      final resp = await http.get(uri, headers: _h).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return (jsonDecode(resp.body) as Map<String, dynamic>)['status'] as String? ?? 'idle';
      }
    } catch (e) {
      _log.warning('getTrainingStatus error: $e');
    }
    return 'idle';
  }

  Future<Map<String, dynamic>?> getLoopSnapshot() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/loop/snapshot'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getLoopSnapshot HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getLoopSnapshot error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTodayPriority() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/today/priority'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getTodayPriority HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getTodayPriority error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTodayMission() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/today/mission'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getTodayMission HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getTodayMission error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getRealityCheck() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/reality/check'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getRealityCheck HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getRealityCheck error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getGrowthTimeline() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/growth/timeline'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getGrowthTimeline HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getGrowthTimeline error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getRevelationStatus() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/revelation/status'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getRevelationStatus HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getRevelationStatus error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLatestCloneMission() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/clone-mission/latest'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getLatestCloneMission HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getLatestCloneMission error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getNextIntervention() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/interventions/next'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getNextIntervention HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getNextIntervention error: $e');
    }
    return null;
  }

  Future<bool> ackIntervention(String id, {String status = 'acknowledged'}) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_base/v1/interventions/ack'),
            headers: {..._h, 'Content-Type': 'application/json'},
            body: jsonEncode({'id': id, 'status': status}),
          )
          .timeout(const Duration(seconds: 8));
      return resp.statusCode == 200;
    } catch (e) {
      _log.warning('ackIntervention error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentThesis() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/thesis/current'), headers: _h).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getCurrentThesis HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getCurrentThesis error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTrainingSummary({String? lane}) async {
    try {
      final uri = Uri.parse('$_base/v1/training/summary').replace(
        queryParameters: lane == null ? null : {'lane': lane},
      );
      final resp = await http.get(uri, headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getTrainingSummary HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getTrainingSummary error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getTrainingRuns({String? lane}) async {
    try {
      final uri = Uri.parse('$_base/v1/training/runs').replace(
        queryParameters: lane == null ? null : {'lane': lane},
      );
      final resp = await http.get(uri, headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['runs'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      _log.warning('getTrainingRuns error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getTrainingEval({String? lane}) async {
    try {
      final uri = Uri.parse('$_base/v1/training/eval').replace(
        queryParameters: lane == null ? null : {'lane': lane},
      );
      final resp = await http.get(uri, headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getTrainingEval HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getTrainingEval error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getSystemHealth() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/system/health'), headers: _h).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getSystemHealth HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getSystemHealth error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> runTournament(String prompt) async {
    try {
      final resp = await http
          .post(Uri.parse('$_base/v1/tournament/run'), headers: {..._h, 'Content-Type': 'application/json'}, body: jsonEncode({'prompt': prompt}))
          .timeout(const Duration(seconds: 60));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('runTournament HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('runTournament error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> chooseTournamentCandidate(String runId, String candidateId) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_base/v1/tournament/choose'),
            headers: {..._h, 'Content-Type': 'application/json'},
            body: jsonEncode({'run_id': runId, 'candidate_id': candidateId}),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('chooseTournamentCandidate HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('chooseTournamentCandidate error: $e');
    }
    return null;
  }

  Future<bool> recordOutcome({required String subjectType, String? subjectId, required String outcome, double score = 0.5, String note = ''}) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_base/v1/outcome'),
            headers: {..._h, 'Content-Type': 'application/json'},
            body: jsonEncode({'subject_type': subjectType, 'subject_id': subjectId, 'outcome': outcome, 'score': score, 'note': note}),
          )
          .timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (e) {
      _log.warning('recordOutcome error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProofItems({int limit = 50}) async {
    try {
      final uri = Uri.parse('$_base/v1/proof/items').replace(queryParameters: {'limit': '$limit'});
      final resp = await http.get(uri, headers: _h).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getProofItems HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getProofItems error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> createProofItem({
    required String title,
    String description = '',
    String category = 'practice',
    String? sourceType,
    String? sourceId,
    String evidence = '',
    List<String> skillTags = const [],
    String opportunityType = 'personal_goal',
  }) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      final resp = await http
          .post(
            Uri.parse('$_base/v1/proof/items'),
            headers: h,
            body: jsonEncode({
              'title': title,
              'description': description,
              'category': category,
              'source_type': sourceType,
              'source_id': sourceId,
              'evidence': evidence,
              'skill_tags': skillTags,
              'opportunity_type': opportunityType,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('createProofItem HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('createProofItem error: $e');
    }
    return null;
  }

  Future<bool> deleteProofItem(String itemId) async {
    try {
      final resp = await http.delete(Uri.parse('$_base/v1/proof/items/$itemId'), headers: _h).timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (e) {
      _log.warning('deleteProofItem error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getOpportunities() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/opportunities'), headers: _h).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getOpportunities HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getOpportunities error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> generateOpportunity() async {
    try {
      final resp = await http.post(Uri.parse('$_base/v1/opportunities/generate'), headers: _h).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('generateOpportunity HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('generateOpportunity error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> createOpportunity({
    required String title,
    String type = 'personal_goal',
    String description = '',
    List<String> requiredProof = const [],
    List<String> missingProof = const [],
    String nextStep = '',
  }) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      final resp = await http
          .post(
            Uri.parse('$_base/v1/opportunities'),
            headers: h,
            body: jsonEncode({
              'title': title,
              'type': type,
              'description': description,
              'required_proof': requiredProof,
              'missing_proof': missingProof,
              'next_step': nextStep,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('createOpportunity HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('createOpportunity error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> triggerTraining({String? lane}) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      final body = lane == null ? <String, dynamic>{} : {'lane': lane};
      final resp = await http
          .post(Uri.parse('$_base/trigger-training'), headers: h, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('triggerTraining HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('triggerTraining error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getTrainingHistory({String? lane}) async {
    try {
      final uri = Uri.parse('$_base/v1/training/history').replace(
        queryParameters: lane == null ? null : {'lane': lane},
      );
      final resp = await http.get(uri, headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['checkpoints'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      _log.warning('getTrainingHistory error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getUserRank() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/user/rank'), headers: _h).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getUserRank HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getUserRank error: $e');
    }
    return null;
  }

  /// Timing Engine: which of the 4 Echo states applies right now?
  /// Returns { state, speak_now, reason, statement?, letter?, clone_lead? }
  Future<Map<String, dynamic>?> decideState({String message = ''}) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      final resp = await http
          .post(Uri.parse('$_base/v1/echo/decide'), headers: h, body: jsonEncode({'message': message}))
          .timeout(const Duration(seconds: 40));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('decideState HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('decideState error: $e');
    }
    return null;
  }

  /// Parallel self simulation: two diverging trajectories from current patterns.
  /// Returns { current_path, avoided_path, ready }
  Future<Map<String, dynamic>?> getSimulation() async {
    try {
      final resp = await http
          .post(Uri.parse('$_base/v1/echo/simulate'), headers: {..._h, 'Content-Type': 'application/json'}, body: '{}')
          .timeout(const Duration(seconds: 50));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getSimulation HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getSimulation error: $e');
    }
    return null;
  }

  /// Council API: run a question through all 5 clone personalities.
  /// Returns { question, voices: {Builder,Creative,...}, verdict }
  Future<Map<String, dynamic>?> askCouncil(String question, {String? threadId, String? threadContext}) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      final body = <String, dynamic>{'question': question};
      if (threadId != null) body['thread_id'] = threadId;
      if (threadContext != null) body['thread_context'] = threadContext;
      final resp = await http.post(Uri.parse('$_base/v1/council/ask'), headers: h, body: jsonEncode(body)).timeout(const Duration(seconds: 90));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('askCouncil HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('askCouncil error: $e');
    }
    return null;
  }

  /// Get active and resolved threads for the current user.
  /// Returns { active: [...], resolved: [...] }
  Future<Map<String, dynamic>?> getThreads() async {
    try {
      final resp = await http.get(Uri.parse('$_base/v1/threads'), headers: _h).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getThreads HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getThreads error: $e');
    }
    return null;
  }

  /// Resolve a thread after user reads a revelation or council verdict.
  Future<bool> resolveThread(String threadId, {String note = 'user acknowledged'}) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_base/v1/threads/$threadId/resolve'),
            headers: {..._h, 'Content-Type': 'application/json'},
            body: jsonEncode({'note': note}),
          )
          .timeout(const Duration(seconds: 15));
      return resp.statusCode == 200;
    } catch (e) {
      _log.warning('resolveThread error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> submitDailyCheckin(List<Map<String, String>> qas) async {
    try {
      final h = {..._h, 'Content-Type': 'application/json'};
      final resp = await http
          .post(
            Uri.parse('$_base/v1/daily/checkin'),
            headers: h,
            body: jsonEncode({'qas': qas, 'date': DateTime.now().toIso8601String().substring(0, 10)}),
          )
          .timeout(const Duration(seconds: 25));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('submitDailyCheckin HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('submitDailyCheckin error: $e');
    }
    return null;
  }
}
