import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // IP local actual de la PC en la red WiFi (detectada: 10.212.84.82)
  static const String detectedLocalIp = '10.212.84.82';
  static const String usbAdbIp = '127.0.0.1';
  static const String emulatorIp = '10.0.2.2';

  static String _serverIp = detectedLocalIp;
  static String _serverPort = '8000';

  // Configuración de Agente Dify AI (Legado)
  static const String defaultDifyBaseUrl = 'https://api.dify.ai/v1';
  static const String defaultDifyApiKey = 'app-75iHcP4HXHu21h9YbiwSUcP9';
  static String _difyBaseUrl = defaultDifyBaseUrl;
  static String _difyApiKey = defaultDifyApiKey;

  static String get baseUrl => 'http://$_serverIp:$_serverPort/api';
  static String get serverIp => _serverIp;
  static String get serverPort => _serverPort;

  static String get difyBaseUrl => _difyBaseUrl;
  static String get difyApiKey => _difyApiKey;
  static bool get hasDifyApiKey => _difyApiKey.trim().isNotEmpty;

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    
    // Si no hay IP o tiene una IP obsoleta anterior (192.168.137.11 / 10.34.97.82), actualizar a la IP actual
    if (savedIp == null ||
        savedIp == '192.168.137.11' ||
        savedIp == '10.34.97.82' ||
        savedIp.isEmpty) {
      _serverIp = detectedLocalIp;
      await prefs.setString('server_ip', detectedLocalIp);
    } else {
      _serverIp = savedIp;
    }
    
    _serverPort = prefs.getString('server_port') ?? '8000';
    _difyBaseUrl = prefs.getString('dify_base_url') ?? defaultDifyBaseUrl;
    final savedKey = prefs.getString('dify_api_key');
    if (savedKey != null && savedKey.trim().isNotEmpty) {
      _difyApiKey = savedKey;
    } else {
      _difyApiKey = defaultDifyApiKey;
      await prefs.setString('dify_api_key', defaultDifyApiKey);
    }
  }

  static Future<void> setServerIp(String ip, {String port = '8000'}) async {
    _serverIp = ip.trim();
    _serverPort = port.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', _serverIp);
    await prefs.setString('server_port', _serverPort);
  }

  static Future<void> setDifyConfig(String apiKey, {String? baseUrl}) async {
    _difyApiKey = apiKey.trim();
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _difyBaseUrl = baseUrl.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dify_api_key', _difyApiKey);
    await prefs.setString('dify_base_url', _difyBaseUrl);
  }
}
