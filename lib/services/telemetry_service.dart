import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

class TelemetryService extends ChangeNotifier {
  bool _isTracking = false;
  int _driverId = 2; // Repartidor ID por defecto
  int? _activeOrderId;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  // Secuencia de waypoints reales sobre las calzadas de Huánuco para emulación vial sin cortar edificios
  static final List<LatLng> _huanucoRoadNodes = [
    const LatLng(-9.9306, -76.2422), // Jr. General Prado & 28 de Julio (Plaza)
    const LatLng(-9.9311, -76.2418), // Jr. General Prado (Cdra 3)
    const LatLng(-9.9315, -76.2414), // Jr. General Prado & Dámaso Beraún
    const LatLng(-9.9320, -76.2409), // Jr. General Prado (Cdra 4)
    const LatLng(-9.9325, -76.2405), // Jr. General Prado & Aguilar
    const LatLng(-9.9330, -76.2400), // Jr. General Prado (Cdra 5)
    const LatLng(-9.9338, -76.2393), // Jr. General Prado & Ayacucho
    const LatLng(-9.9330, -76.2385), // Jr. Dos de Mayo & Ayacucho (Giro en esquina)
    const LatLng(-9.9322, -76.2393), // Jr. Dos de Mayo & Aguilar
    const LatLng(-9.9313, -76.2401), // Jr. Dos de Mayo & Dámaso Beraún
    const LatLng(-9.9303, -76.2410), // Jr. Dos de Mayo & 28 de Julio
  ];

  int _simNodeIndex = 0;

  double _currentLat = -9.9306;
  double _currentLng = -76.2422;
  double _currentSpeed = 0.0;
  double _currentAltitude = 1900.0;
  final int _batteryLevel = 90;
  bool _hasRealGpsFix = false;

  final List<String> _logs = [];

  bool get isTracking => _isTracking;
  bool get hasRealGpsFix => _hasRealGpsFix;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  double get currentSpeed => _currentSpeed;
  int? get activeOrderId => _activeOrderId;
  List<String> get logs => List.unmodifiable(_logs);

  void setDriverId(int id) {
    _driverId = id;
    notifyListeners();
  }

  void setActiveOrderId(int? orderId) {
    _activeOrderId = orderId;
    notifyListeners();
  }

  /// Consulta y obtiene de forma directa la posición GPS real del teléfono móvil
  Future<Position?> fetchRealGpsLocation({bool promptSettings = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _addLog('⚠️ El GPS del celular está apagado. Por favor actívalo.');
        if (promptSettings) {
          await Geolocator.openLocationSettings();
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _addLog('❌ Permiso de ubicación denegado.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _addLog('❌ Permiso de ubicación denegado permanente. Abre Ajustes.');
        if (promptSettings) {
          await Geolocator.openAppSettings();
        }
        return null;
      }

      // 1. Intentar primero con la última posición conocida (respuesta instantánea)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && lastPos.latitude != 0 && lastPos.longitude != 0) {
        _currentLat = lastPos.latitude;
        _currentLng = lastPos.longitude;
        _currentSpeed = (lastPos.speed * 3.6).clamp(0.0, 160.0);
        _hasRealGpsFix = true;
        _addLog('📍 GPS instantáneo: ${_currentLat.toStringAsFixed(5)}, ${_currentLng.toStringAsFixed(5)}');
        notifyListeners();
      }

      // 2. Obtener posición satelital fresca y precisa con timeout seguro
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (position.latitude != 0 && position.longitude != 0) {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _currentSpeed = (position.speed * 3.6).clamp(0.0, 160.0);
        _currentAltitude = position.altitude;
        _hasRealGpsFix = true;
        _addLog('📍 GPS Satelital Real fijado: ${_currentLat.toStringAsFixed(5)}, ${_currentLng.toStringAsFixed(5)}');
        notifyListeners();
        return position;
      }
    } catch (e) {
      // 3. Fallback a precisión media (red / WiFi) en caso de que esté bajo techo
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        if (position.latitude != 0 && position.longitude != 0) {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _currentSpeed = (position.speed * 3.6).clamp(0.0, 160.0);
          _currentAltitude = position.altitude;
          _hasRealGpsFix = true;
          _addLog('📍 GPS Red/Wi-Fi fijado: ${_currentLat.toStringAsFixed(5)}, ${_currentLng.toStringAsFixed(5)}');
          notifyListeners();
          return position;
        }
      } catch (_) {
        _addLog('⚠️ Esperando señal satelital GPS...');
      }
    }
    return null;
  }

  // Iniciar servicio de captura y envío de ubicación GPS
  Future<bool> startTelemetryService({int? orderId}) async {
    _activeOrderId = orderId;

    // Intentar obtener la ubicación real de inmediato
    await fetchRealGpsLocation(promptSettings: true);

    _isTracking = true;
    _addLog('🟢 Rastreo GPS en tiempo real INICIADO.');
    notifyListeners();

    // Iniciar escucha continua de hardware GPS (Stream en tiempo real)
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Emitir cada 2 metros
      );
      _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position pos) {
          if (pos.latitude != 0 && pos.longitude != 0) {
            _currentLat = pos.latitude;
            _currentLng = pos.longitude;
            _currentSpeed = (pos.speed * 3.6).clamp(0.0, 160.0);
            _currentAltitude = pos.altitude;
            _hasRealGpsFix = true;
            notifyListeners();
            _sendTelemetryPacket();
          }
        },
        onError: (_) {},
      );
    } catch (_) {}

    // Capturar y enviar inmediatamente
    _captureAndSendTelemetry();

    // Programar envío periódico cada 3 segundos
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _captureAndSendTelemetry();
    });

    return true;
  }

  void stopTelemetryService() {
    _positionStream?.cancel();
    _positionStream = null;
    _timer?.cancel();
    _timer = null;
    _isTracking = false;
    _addLog('🔴 Rastreo GPS DETENIDO.');
    notifyListeners();
  }

  Future<void> _captureAndSendTelemetry() async {
    bool gotHardwareGps = false;

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      if (position.latitude != 0 && position.longitude != 0) {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _currentSpeed = (position.speed * 3.6).clamp(0.0, 160.0);
        _currentAltitude = position.altitude;
        gotHardwareGps = true;
        _hasRealGpsFix = true;
      }
    } catch (_) {
      gotHardwareGps = _hasRealGpsFix;
    }

    // SOLO si NUNCA se ha obtenido señal GPS real (ej. emulador sin sensor), simular en Huánuco
    if (!gotHardwareGps && !_hasRealGpsFix) {
      _simNodeIndex = (_simNodeIndex + 1) % _huanucoRoadNodes.length;
      final node = _huanucoRoadNodes[_simNodeIndex];
      _currentLat = node.latitude;
      _currentLng = node.longitude;
      _currentSpeed = 22.0 + (DateTime.now().second % 8); // 22 a 29 km/h
      _currentAltitude = 1912.0;
    }

    await _sendTelemetryPacket();
  }

  Future<void> _sendTelemetryPacket() async {
    try {
      final payload = {
        'driver_id': _driverId,
        'order_id': _activeOrderId,
        'latitude': _currentLat,
        'longitude': _currentLng,
        'altitude': _currentAltitude,
        'speed': _currentSpeed,
        'battery_level': _batteryLevel,
        'recorded_at': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/telemetry/location'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 201) {
        final nowStr = DateTime.now().toString().split('.').first.split(' ').last;
        _addLog('[$nowStr] Tx OK: ${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)} (${_currentSpeed.toStringAsFixed(1)} km/h)');
      } else {
        _addLog('⚠️ Tx HTTP ${response.statusCode}');
      }
    } catch (e) {
      // Silencioso para no saturar si backend está en standby
    }

    notifyListeners();
  }

  void _addLog(String msg) {
    _logs.insert(0, msg);
    if (_logs.length > 50) _logs.removeLast();
  }
}
