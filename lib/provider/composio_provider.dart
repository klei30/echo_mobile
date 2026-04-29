import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class ComposioProvider extends ChangeNotifier {
  final _logger = Logger('ComposioProvider');
  final String apiKey;
  
  String? _entityId;
  List<String> _connectedToolkits = [];
  bool _isLoading = false;

  ComposioProvider({required this.apiKey}) {
    _init();
  }

  String? get entityId => _entityId;
  List<String> get connectedToolkits => _connectedToolkits;
  bool get isLoading => _isLoading;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    
    // Get or create unique Entity ID for this device
    _entityId = prefs.getString('composio_entity_id');
    if (_entityId == null) {
      _entityId = const Uuid().v4();
      await prefs.setString('composio_entity_id', _entityId!);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Opens the Composio Managed Connect page for a toolkit.
  Future<void> connectToolkit(String toolkitId) async {
    if (_entityId == null) return;

    // The simple way to connect for Managed MCP:
    // https://connect.composio.dev/connect/{toolkit}?entity_id={id}&api_key={key}
    final toolkitSlug = toolkitId.toLowerCase().replaceAll(' ', '');
    final urlString = 'https://connect.composio.dev/connect/$toolkitSlug?entity_id=$_entityId&api_key=$apiKey';
    
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _logger.severe('Failed to launch connect URL: $urlString', e);
    }
  }

  bool isConnected(String toolkitId) {
    // Note: With the simple approach, we can't easily check connection status 
    // without the management API, but we can assume it's handled on the connect page.
    return false; 
  }
}
