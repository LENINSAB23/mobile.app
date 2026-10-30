import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/routing_service.dart';
import '../services/telemetry_service.dart';

class DriverRouteMapScreen extends StatefulWidget {
  final OrderModel order;
  const DriverRouteMapScreen({super.key, required this.order});

  @override
  State<DriverRouteMapScreen> createState() => _DriverRouteMapScreenState();
}

class _DriverRouteMapScreenState extends State<DriverRouteMapScreen> {
  final MapController _mapController = MapController();
  late LatLng _destinationLatLng;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _destinationLatLng = LatLng(
      widget.order.deliveryLatitude,
      widget.order.deliveryLongitude,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final telemetry = Provider.of<TelemetryService>(context, listen: false);
      if (!telemetry.isTracking) {
        telemetry.startTelemetryService(orderId: widget.order.id);
      }
      _calculateStreetRoute(LatLng(telemetry.currentLat, telemetry.currentLng));
    });
  }

  Future<void> _calculateStreetRoute(LatLng driverPos) async {
    final points = await RoutingService.getStreetRoute(driverPos, _destinationLatLng);
    if (mounted) {
      setState(() {
        _routePoints = points;
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = Provider.of<TelemetryService>(context);
    final driverLatLng = LatLng(telemetry.currentLat, telemetry.currentLng);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Navegación a: ${widget.order.customerName}', style: const TextStyle(fontSize: 16)),
            Text(widget.order.deliveryAddress, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              telemetry.isTracking ? Icons.satellite_alt : Icons.satellite_outlined,
              color: telemetry.isTracking ? Colors.greenAccent : Colors.grey,
            ),
            tooltip: 'Rastreo GPS Satelital',
            onPressed: () {
              if (telemetry.isTracking) {
                telemetry.stopTelemetryService();
              } else {
                telemetry.startTelemetryService(orderId: widget.order.id);
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Mapa Interactivo de Navegación Vehicular
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: driverLatLng,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gruporino.mobile_app',
              ),

              // Trazado Vial Real por Calles y Avenidas (No atraviesa edificios)
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 9.0,
                      color: Colors.blue.withValues(alpha: 0.35),
                    ),
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF3B82F6),
                    ),
                  ],
                ),

              // Marcadores de Vehículo y Destino
              MarkerLayer(
                markers: [
                  // Marcador Destino del Cliente
                  Marker(
                    point: _destinationLatLng,
                    width: 50,
                    height: 50,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 10)],
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 30),
                    ),
                  ),

                  // Marcador Posición Actual del Vehículo Rino
                  Marker(
                    point: driverLatLng,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.orangeAccent, blurRadius: 12)],
                      ),
                      child: const Icon(Icons.navigation, color: Colors.black, size: 26),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_isLoadingRoute)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)),
                    SizedBox(width: 8),
                    Text('Trazando ruta por vías de circulación...', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),

          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'route_driver_recenter',
              backgroundColor: const Color(0xFF1E293B),
              tooltip: 'Re-centrar en vehículo',
              onPressed: () {
                _mapController.move(driverLatLng, 17.0);
              },
              child: const Icon(Icons.my_location, color: Colors.orangeAccent),
            ),
          ),

          // Control Bottom Card
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Orden #${widget.order.orderNumber}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Contacto: ${widget.order.customerPhone}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${telemetry.currentSpeed.toStringAsFixed(0)} km/h',
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await ApiService.getOrders();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('¡Entrega de repuesto confirmada!')),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text(
                        'Marcar como ENTREGADO',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
