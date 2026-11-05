import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // IP local actual de la PC en la red WiFi (detectada: 10.212.84.82)
  static const String detectedLocalIp = '10.212.84.82';
  static const String usbAdbIp = '127.0.0.1';
  static const String emulatorIp = '10.0.2.2';

  static String _serverIp = detectedLocalIp;
  static String _serverPort = '8000';

  static String get baseUrl => 'http://$_serverIp:$_serverPort/api';
  static String get serverIp => _serverIp;
  static String get serverPort => _serverPort;

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    
    // Si no hay IP o tiene una IP obsoleta anterior, actualizar a la IP actual
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
  }

  static Future<void> setServerIp(String ip, {String port = '8000'}) async {
    _serverIp = ip.trim();
    _serverPort = port.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', _serverIp);
    await prefs.setString('server_port', _serverPort);
  }
}
