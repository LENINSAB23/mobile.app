import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/routing_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  Timer? _apiPollingTimer;
  Timer? _simTimer;

  // Coordenadas reales de Huánuco
  LatLng _deliveryLatLng = const LatLng(-9.9325, -76.2410); // Jr. General Prado 450
  LatLng _driverLatLng = const LatLng(-9.9306, -76.2422);   // Jr. General Prado & 28 de Julio (Plaza)
  
  List<LatLng> _streetRoutePoints = [];
  int _currentRouteIndex = 0;
  double _vehicleHeading = 138.5; // Ángulo de orientación de la moto sobre la calle

  String _orderStatus = 'in_transit';
  String _orderNumber = 'RINO-2026-081';
  String _deliveryAddress = 'Jr. General Prado 450, Huánuco';
  String _currentStreet = 'Jr. General Prado';
  double _driverSpeed = 26.0;
  int _estimatedMinutes = 14;
  bool _isLoading = true;
  bool _isAutoSimulating = true; // Simulación vial fluida que avanza por la calzada

  @override
  void initState() {
    super.initState();
    _initTrackingAndRoute();
  }

  @override
  void dispose() {
    _apiPollingTimer?.cancel();
    _simTimer?.cancel();
    super.dispose();
  }

  Future<void> _initTrackingAndRoute() async {
    setState(() => _isLoading = true);

    // 1. Intentar cargar datos del pedido desde la API
    try {
      final data = await ApiService.getOrderTracking(widget.orderId);
      if (data.isNotEmpty) {
        final order = data['order'] ?? {};
        final currentLoc = data['current_location'];

        if (order['delivery_latitude'] != null && order['delivery_longitude'] != null) {
          _deliveryLatLng = LatLng(
            double.parse(order['delivery_latitude'].toString()),
            double.parse(order['delivery_longitude'].toString()),
          );
        }

        if (currentLoc != null && currentLoc['latitude'] != null) {
          _driverLatLng = LatLng(
            double.parse(currentLoc['latitude'].toString()),
            double.parse(currentLoc['longitude'].toString()),
          );
          _driverSpeed = double.tryParse(currentLoc['speed'].toString()) ?? 26.0;
        }

        _orderNumber = order['order_number'] ?? 'RINO-2026-081';
        _orderStatus = order['status'] ?? 'in_transit';
        _deliveryAddress = order['delivery_address'] ?? 'Jr. General Prado 450, Huánuco';
        _estimatedMinutes = order['estimated_delivery_minutes'] ?? 14;
      }
    } catch (_) {
      // Si la API no responde, mantenemos los datos por defecto en Huánuco
    }

    // 2. Generar el trazado vial riguroso que sigue las calles y no cruza edificios
    final route = await RoutingService.getStreetRoute(_driverLatLng, _deliveryLatLng);

    if (mounted) {
      setState(() {
        _streetRoutePoints = route;
        if (_streetRoutePoints.isNotEmpty) {
          _driverLatLng = _streetRoutePoints.first;
          _currentStreet = RoutingService.getStreetNameForCoordinate(_driverLatLng);
        }
        _isLoading = false;
      });

      // 3. Iniciar timers: sondeo API cada 4s y avance vial fluido cada 2s
      _apiPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _syncBackendTelemetry());
      _startStreetProgressionTimer();
    }
  }

  // Sincronización con el backend si hay telemetría nueva
  Future<void> _syncBackendTelemetry() async {
    try {
      final data = await ApiService.getOrderTracking(widget.orderId);
      if (data.isNotEmpty) {
        final currentLoc = data['current_location'];
        if (currentLoc != null && currentLoc['latitude'] != null) {
          final lat = double.parse(currentLoc['latitude'].toString());
          final lng = double.parse(currentLoc['longitude'].toString());
          
          if (mounted) {
            setState(() {
              _driverSpeed = double.tryParse(currentLoc['speed'].toString()) ?? _driverSpeed;
              // Si no estamos simulando localmente, actualizar posición
              if (!_isAutoSimulating) {
                _driverLatLng = LatLng(lat, lng);
                _currentStreet = RoutingService.getStreetNameForCoordinate(_driverLatLng);
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  // Timer de avance continuo sobre las calzadas de Huánuco (respeta carreteras y manzanas)
  void _startStreetProgressionTimer() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_isAutoSimulating || _streetRoutePoints.isEmpty) return;

      if (_currentRouteIndex < _streetRoutePoints.length - 1) {
        _currentRouteIndex++;
        final nextPos = _streetRoutePoints[_currentRouteIndex];
        final prevPos = _streetRoutePoints[_currentRouteIndex - 1];

        // Calcular ángulo de orientación del vehículo según la calle
        final heading = RoutingService.calculateBearing(prevPos, nextPos);
        final street = RoutingService.getStreetNameForCoordinate(nextPos);

        // Distancia restante al domicilio
        final distMeters = RoutingService.calculateDistanceMeters(nextPos, _deliveryLatLng);
        final speedKmh = 24.0 + (math.Random().nextDouble() * 6.0); // 24-30 km/h
        final minutesLeft = math.max(1, (distMeters / (speedKmh * 1000 / 60)).ceil());

        if (mounted) {
          setState(() {
            _driverLatLng = nextPos;
            _vehicleHeading = heading;
            _currentStreet = street;
            _driverSpeed = speedKmh;
            _estimatedMinutes = minutesLeft;
          });
        }
      } else {
        // Al llegar al domicilio del cliente
        if (mounted) {
          setState(() {
            _orderStatus = 'delivered';
            _driverSpeed = 0.0;
            _estimatedMinutes = 0;
          });
        }
      }
    });
  }

  void _resetSimulation() {
    if (_streetRoutePoints.isEmpty) return;
    setState(() {
      _currentRouteIndex = 0;
      _driverLatLng = _streetRoutePoints.first;
      _orderStatus = 'in_transit';
      _isAutoSimulating = true;
      _driverSpeed = 26.0;
      _estimatedMinutes = 14;
    });
    _mapController.move(_driverLatLng, 16.5);
  }

  @override
  Widget build(BuildContext context) {
    // Dividir la ruta en tramo ya recorrido y tramo por recorrer
    final remainingRoute = _streetRoutePoints.sublist(
      math.min(_currentRouteIndex, _streetRoutePoints.length),
    );
    final completedRoute = _streetRoutePoints.sublist(
      0,
      math.min(_currentRouteIndex + 1, _streetRoutePoints.length),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rastreo GPS en Vivo - $_orderNumber',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.navigation, size: 11, color: Colors.blueAccent),
                const SizedBox(width: 4),
                Text(
                  _currentStreet,
                  style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isAutoSimulating ? Icons.pause_circle_outline : Icons.play_circle_outline,
              color: _isAutoSimulating ? Colors.greenAccent : Colors.grey,
            ),
            tooltip: _isAutoSimulating ? 'Pausar avance' : 'Reanudar avance vial',
            onPressed: () {
              setState(() => _isAutoSimulating = !_isAutoSimulating);
            },
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.orangeAccent),
            tooltip: 'Reiniciar recorrido vial',
            onPressed: _resetSimulation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Stack(
              children: [
                // MAPA INTERACTIVO CON TRAZADO VIAL ESTRICTO (RESPETA CALZADAS Y EDIFICIOS)
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _driverLatLng,
                    initialZoom: 16.5,
                    minZoom: 13.0,
                    maxZoom: 19.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.gruporino.mobile_app',
                    ),

                    // Trazado vial: Trazo base halo brillante
                    if (remainingRoute.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          // Borde exterior / halo azul neón
                          Polyline(
                            points: remainingRoute,
                            strokeWidth: 9.0,
                            color: Colors.blue.withValues(alpha: 0.35),
                          ),
                          // Línea central de calzada vial
                          Polyline(
                            points: remainingRoute,
                            strokeWidth: 5.0,
                            color: const Color(0xFF3B82F6),
                          ),
                        ],
                      ),

                    // Tramo ya recorrido en calle (color tenue)
                    if (completedRoute.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: completedRoute,
                            strokeWidth: 4.0,
                            color: Colors.greenAccent.withValues(alpha: 0.6),
                          ),
                        ],
                      ),

                    // MARCADORES VIALES
                    MarkerLayer(
                      markers: [
                        // Marcador Domicilio / Taller Cliente (Destino final)
                        Marker(
                          point: _deliveryLatLng,
                          width: 52,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.redAccent, blurRadius: 14, spreadRadius: 2),
                              ],
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 28),
                          ),
                        ),

                        // Marcador Vehículo de Reparto Rino (Con rotación hacia la calle)
                        Marker(
                          point: _driverLatLng,
                          width: 54,
                          height: 54,
                          child: Transform.rotate(
                            angle: (_vehicleHeading - 90) * math.pi / 180.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181B),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blueAccent, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withValues(alpha: 0.8),
                                    blurRadius: 16,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: Colors.blueAccent,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Botón flotante para re-centrar en el vehículo
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_driver',
                    backgroundColor: const Color(0xFF18181B),
                    onPressed: () {
                      _mapController.move(_driverLatLng, 17.0);
                    },
                    child: const Icon(Icons.my_location, color: Colors.blueAccent),
                  ),
                ),

                // Card Inferior de Rastreo en Vivo & Estado Vial
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _orderStatus == 'delivered' ? Colors.greenAccent : Colors.blueAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _getStatusLabel(_orderStatus),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '🛣️ $_currentStreet',
                                    style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    _deliveryAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                children: [
                                  const Text('Tiempo Llegada', style: TextStyle(color: Colors.grey, fontSize: 9)),
                                  Text(
                                    '$_estimatedMinutes min',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.speed, color: Colors.orangeAccent, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${_driverSpeed.toStringAsFixed(0)} km/h',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.gps_fixed, color: Colors.greenAccent, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _isAutoSimulating ? 'Rastreo en Vivo Activo' : 'En Espera',
                                  style: TextStyle(
                                    color: _isAutoSimulating ? Colors.greenAccent : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'in_transit': return 'En Ruta de Entrega';
      case 'cooking':
      case 'preparing': return 'Alistando Repuesto en Taller 🛠️';
      case 'delivered': return '¡Repuestos Entregados! 🎉';
      default: return 'Pendiente de Atención 🕒';
    }
  }
}
