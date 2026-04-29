import 'dart:async' as async;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

enum VoiceState { idle, connecting, listening, speaking, disconnecting }

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  static final _log = Logger('chatmcp.voice');

  Room? _room;
  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;

  String? _lastError;
  String? get lastError => _lastError;

  final _stateController = async.StreamController<VoiceState>.broadcast();
  Stream<VoiceState> get stateStream => _stateController.stream;

  // Transcript events from the voice agent: (role: "user"|"agent", text: "...")
  final _transcriptController = async.StreamController<({String role, String text})>.broadcast();
  Stream<({String role, String text})> get transcriptStream => _transcriptController.stream;

  String _lastUserText = '';
  String _lastEchoText = '';
  String get lastUserText => _lastUserText;
  String get lastEchoText => _lastEchoText;

  void _setState(VoiceState s) {
    _state = s;
    _stateController.add(s);
    _log.info('Voice state: $s');
  }

  String get _echoBase {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? 'http://10.0.2.2:8002' : 'http://localhost:8002';
  }

  /// On Android the emulator's localhost ≠ the host machine.
  /// Rewrite any localhost LiveKit URL to 10.0.2.2 so WebRTC can reach the host.
  String _fixLiveKitUrl(String url) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  Future<({String token, String url, String room})?> _fetchToken() async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_echoBase/v1/voice/token'),
            headers: AuthService().authHeaders,
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body) as Map<String, dynamic>;
        return (
          token: d['token'] as String,
          url: _fixLiveKitUrl(d['url'] as String),
          room: d['room'] as String,
        );
      }
      _log.warning('Voice token HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('Voice token fetch failed: $e');
    }
    return null;
  }

  Future<bool> connect() async {
    if (_state != VoiceState.idle) return false;
    _lastError = null;
    if (!AuthService().isLoggedIn) {
      _lastError = 'Not logged in';
      _log.warning('Not logged in — cannot start voice');
      return false;
    }

    _setState(VoiceState.connecting);

    final tokenData = await _fetchToken();
    if (tokenData == null) {
      _lastError = 'Token fetch failed (backend unreachable?)';
      _setState(VoiceState.idle);
      return false;
    }

    try {
      // Use RoomOptions to manage speakerphone — livekit_client calls setSpeakerphoneOn
      // internally via applyAudioSpeakerSettings() when the local mic track is published.
      _room = Room(
        roomOptions: const RoomOptions(
          defaultAudioOutputOptions: AudioOutputOptions(speakerOn: true),
          adaptiveStream: false,
          dynacast: false,
        ),
      );

      _room!.events.on<RoomConnectedEvent>((_) {
        _log.info('LiveKit connected to room ${tokenData.room}');
        _setState(VoiceState.listening);
      });

      _room!.events.on<RoomDisconnectedEvent>((_) {
        _log.info('LiveKit disconnected');
        _room = null;
        _setState(VoiceState.idle);
      });

      // Diagnostic: log when the agent participant joins the room.
      _room!.events.on<ParticipantConnectedEvent>((event) {
        _log.info('Remote participant joined: identity=${event.participant.identity} sid=${event.participant.sid}');
      });

      // Diagnostic: log when agent publishes a track (before media arrives).
      _room!.events.on<TrackPublishedEvent>((event) {
        _log.info('Remote track published: kind=${event.publication.kind} source=${event.publication.source} sid=${event.publication.sid}');
      });

      // Agent audio track subscribed — force speaker output and confirm audio is flowing.
      _room!.events.on<TrackSubscribedEvent>((event) {
        _log.info('Remote track subscribed: kind=${event.track.kind} source=${event.track.source}');
        if (event.track.kind == TrackType.AUDIO) {
          // Re-assert speakerphone when remote audio track arrives.
          if (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS) {
            Hardware.instance.setSpeakerphoneOn(true).then((_) {
              _log.info('Speakerphone re-asserted on remote audio track');
            });
          }
        }
      });

      _room!.events.on<DataReceivedEvent>((event) {
        _log.info('DataReceivedEvent: ${event.data.length} bytes from participant=${event.participant?.identity}');
        try {
          final str = utf8.decode(Uint8List.fromList(event.data));
          final msg = jsonDecode(str) as Map<String, dynamic>;
          final type = msg['type'] as String?;
          if (type == 'transcript') {
            final role = msg['role'] as String? ?? 'user';
            final text = msg['text'] as String? ?? '';
            if (role == 'user') _lastUserText = text;
            if (role == 'agent') _lastEchoText = text;
            _transcriptController.add((role: role, text: text));
          } else if (type == 'agent_state') {
            final agentState = msg['state'] as String? ?? '';
            _log.info('Agent state: $agentState');
            switch (agentState) {
              case 'speaking':
                _setState(VoiceState.speaking);
              case 'thinking':
                // Keep as listening — orb will reflect thinking visually via VoiceState.listening
                if (_state != VoiceState.speaking) _setState(VoiceState.listening);
              case 'listening':
              case 'initializing':
                _setState(VoiceState.listening);
            }
          }
        } catch (e) {
          _log.warning('DataReceivedEvent parse error: $e');
        }
      });

      _log.info('Connecting to LiveKit ${tokenData.url} room=${tokenData.room}');
      await _room!.connect(
        tokenData.url,
        tokenData.token,
        connectOptions: const ConnectOptions(autoSubscribe: true),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw async.TimeoutException(
            'WebRTC connect timeout - ICE could not establish (15s)',
            const Duration(seconds: 15),
          );
        },
      );
      _log.info('Connected. Enabling mic.');
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      return true;
    } catch (e) {
      _lastError = e.toString();
      _log.severe('LiveKit connect error: $e');
      try { await _room?.disconnect(); } catch (_) {}
      _room = null;
      _setState(VoiceState.idle);
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_state == VoiceState.idle) return;
    _setState(VoiceState.disconnecting);
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(false);
      await _room?.disconnect();
    } catch (_) {}
    _room = null;
    _setState(VoiceState.idle);
  }

  Future<void> dispose() async {
    await disconnect();
    _stateController.close();
    _transcriptController.close();
  }
}

class VoiceButton extends StatefulWidget {
  const VoiceButton({super.key});

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VoiceState>(
      stream: VoiceService().stateStream,
      initialData: VoiceService().state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? VoiceState.idle;
        final isActive = state == VoiceState.listening || state == VoiceState.speaking;
        final isConnecting = state == VoiceState.connecting || state == VoiceState.disconnecting;

        return GestureDetector(
          onTap: isConnecting ? null : () => _handleTap(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? Colors.red.withAlpha(30) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: isConnecting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    isActive ? Icons.mic : Icons.mic_none,
                    size: 22,
                    color: isActive
                        ? Colors.red
                        : Theme.of(context).iconTheme.color,
                  ),
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context) async {
    final service = VoiceService();
    final stateBefore = service.state;

    if (stateBefore == VoiceState.idle) {
      final ok = await service.connect();
      if (!ok && context.mounted) {
        final reason = service.lastError ?? 'unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice failed: $reason'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } else {
      await service.disconnect();
    }
  }
}
