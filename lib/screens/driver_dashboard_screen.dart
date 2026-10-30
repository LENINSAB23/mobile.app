import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/routing_service.dart';
import '../services/telemetry_service.dart';
import 'driver_route_map_screen.dart';
import 'login_screen.dart';
import 'gemini_chat_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _currentTabIndex = 0; // 0: Pedidos, 1: Historial, 2: Mapa, 3: Perfil

  List<OrderModel> _activeOrders = [];
  List<OrderModel> _deliveredOrders = [];
  bool _isLoading = true;

  // Mapa state
  final MapController _mapController = MapController();
  List<LatLng> _activeStreetRoute = [];
  OrderModel? _selectedOrderForMap;
  String _currentStreetName = 'Jr. General Prado';

  @override
  void initState() {
    super.initState();
    _initDriverData();
  }

  void _initDriverData() {
    _loadFallbackOrders();
    _loadDriverOrders();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final telemetry = Provider.of<TelemetryService>(context, listen: false);
      telemetry.fetchRealGpsLocation().then((pos) {
        if (pos != null && mounted) {
          final realPos = LatLng(pos.latitude, pos.longitude);
          _mapController.move(realPos, 16.5);
          if (_selectedOrderForMap != null) {
            _calculateMapRouteForOrder(_selectedOrderForMap!);
          }
        }
      });
    });
  }

  void _loadFallbackOrders() {
    // Órdenes activas de demostración iniciales
    _activeOrders = [
      OrderModel(
        id: 1,
        orderNumber: 'RINO-2026-081',
        customerName: 'Maria Fernandez',
        customerPhone: '+51 962 888 111',
        deliveryAddress: 'Jr. General Prado 450, Huánuco',
        deliveryLatitude: -9.9325,
        deliveryLongitude: -76.2410,
        status: 'in_transit',
        paymentMethod: 'yape',
        paymentStatus: 'paid',
        subtotal: 203.00,
        deliveryFee: 5.00,
        total: 208.00,
        estimatedDeliveryMinutes: 12,
        notes: 'Entregar en el 2do piso del taller.',
        items: [
          OrderItemModel(
            id: 101,
            productId: 1,
            productName: 'Aceite Sintético Mobil 1 5W-30 (1 Galón)',
            quantity: 1,
            unitPrice: 145.00,
            subtotal: 145.00,
          ),
          OrderItemModel(
            id: 102,
            productId: 2,
            productName: 'Aceite para Moto Motul 7100 4T 10W-40 (1L)',
            quantity: 1,
            unitPrice: 58.00,
            subtotal: 58.00,
          ),
        ],
        createdAt: '2026-10-15 14:10:00',
      ),
      OrderModel(
        id: 2,
        orderNumber: 'RINO-2026-092',
        customerName: 'Jorge Ramos',
        customerPhone: '+51 962 555 333',
        deliveryAddress: 'Av. Universitaria 1200, Cayhuayna, Huánuco',
        deliveryLatitude: -9.9510,
        deliveryLongitude: -76.2450,
        status: 'cooking',
        paymentMethod: 'card',
        paymentStatus: 'paid',
        subtotal: 230.00,
        deliveryFee: 5.00,
        total: 235.00,
        estimatedDeliveryMinutes: 25,
        notes: 'Llamar al llegar a la puerta principal.',
        items: [
          OrderItemModel(
            id: 103,
            productId: 5,
            productName: 'Pastillas de Freno Cerámicas Fras-le (Juego Auto)',
            quantity: 1,
            unitPrice: 95.00,
            subtotal: 95.00,
          ),
          OrderItemModel(
            id: 104,
            productId: 7,
            productName: 'Juego de 4 Bujías de Iridio NGK Laser Iridium',
            quantity: 1,
            unitPrice: 135.00,
            subtotal: 135.00,
          ),
        ],
        createdAt: '2026-10-15 14:40:00',
      ),
    ];

    // Historial de entregas completadas
    _deliveredOrders = [
      OrderModel(
        id: 3,
        orderNumber: 'RINO-2026-042',
        customerName: 'Juan Carlos Perez',
        customerPhone: '+51 962 777 888',
        deliveryAddress: 'Jr. Dos de Mayo 780, Huánuco',
        deliveryLatitude: -9.9290,
        deliveryLongitude: -76.2400,
        status: 'delivered',
        paymentMethod: 'cash',
        paymentStatus: 'paid',
        subtotal: 160.00,
        deliveryFee: 5.00,
        total: 165.00,
        estimatedDeliveryMinutes: 0,
        notes: 'Entregado conforme con boleta de venta.',
        items: [
          OrderItemModel(
            id: 105,
            productId: 15,
            productName: 'Kit de Focos LED H4 Philips Ultinon Essential (Par)',
            quantity: 1,
            unitPrice: 160.00,
            subtotal: 160.00,
          ),
        ],
        createdAt: '2026-10-14 11:20:00',
      ),
      OrderModel(
        id: 4,
        orderNumber: 'RINO-2026-031',
        customerName: 'Taller San Cristóbal',
        customerPhone: '+51 962 444 222',
        deliveryAddress: 'Jr. Dámaso Beraún 320, Huánuco',
        deliveryLatitude: -9.9315,
        deliveryLongitude: -76.2415,
        status: 'delivered',
        paymentMethod: 'yape',
        paymentStatus: 'paid',
        subtotal: 280.00,
        deliveryFee: 5.00,
        total: 285.00,
        estimatedDeliveryMinutes: 0,
        notes: 'Batería instalada en taller.',
        items: [
          OrderItemModel(
            id: 106,
            productId: 14,
            productName: 'Batería Capsa Gold 13 Placas Libre Mantenimiento',
            quantity: 1,
            unitPrice: 280.00,
            subtotal: 280.00,
          ),
        ],
        createdAt: '2026-10-14 09:45:00',
      ),
    ];

    if (_activeOrders.isNotEmpty) {
      _selectedOrderForMap = _activeOrders.first;
      _calculateMapRouteForOrder(_selectedOrderForMap!);
    }
  }

  Future<void> _loadDriverOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ApiService.getOrders();
      if (orders.isNotEmpty) {
        final active = orders.where((o) => o.status == 'in_transit' || o.status == 'cooking' || o.status == 'pending').toList();
        final delivered = orders.where((o) => o.status == 'delivered').toList();

        setState(() {
          if (active.isNotEmpty) _activeOrders = active;
          if (delivered.isNotEmpty) _deliveredOrders = delivered;
          if (_activeOrders.isNotEmpty) {
            _selectedOrderForMap = _activeOrders.first;
            _calculateMapRouteForOrder(_selectedOrderForMap!);
          }
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _calculateMapRouteForOrder(OrderModel order) async {
    final telemetry = Provider.of<TelemetryService>(context, listen: false);
    final driverPos = LatLng(telemetry.currentLat, telemetry.currentLng);
    final destPos = LatLng(order.deliveryLatitude, order.deliveryLongitude);

    final route = await RoutingService.getStreetRoute(driverPos, destPos);
    if (mounted) {
      setState(() {
        _activeStreetRoute = route;
        _currentStreetName = RoutingService.getStreetNameForCoordinate(driverPos);
      });
    }
  }

  void _markOrderAsDelivered(OrderModel order) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Confirmar Entrega', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          '¿Confirmas la entrega de los repuestos de la orden #${order.orderNumber} al cliente ${order.customerName}?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _activeOrders.removeWhere((o) => o.id == order.id);
                final completedOrder = OrderModel(
                  id: order.id,
                  orderNumber: order.orderNumber,
                  customerName: order.customerName,
                  customerPhone: order.customerPhone,
                  deliveryAddress: order.deliveryAddress,
                  deliveryLatitude: order.deliveryLatitude,
                  deliveryLongitude: order.deliveryLongitude,
                  status: 'delivered',
                  paymentMethod: order.paymentMethod,
                  paymentStatus: 'paid',
                  subtotal: order.subtotal,
                  deliveryFee: order.deliveryFee,
                  total: order.total,
                  estimatedDeliveryMinutes: 0,
                  notes: order.notes,
                  items: order.items,
                  createdAt: DateTime.now().toString().substring(0, 19),
                );
                _deliveredOrders.insert(0, completedOrder);
                if (_activeOrders.isNotEmpty) {
                  _selectedOrderForMap = _activeOrders.first;
                  _calculateMapRouteForOrder(_selectedOrderForMap!);
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('¡Orden #${order.orderNumber} marcada como entregada con éxito! (+S/ 5.00 ganados)'),
                  backgroundColor: const Color(0xFF1E293B),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34D399)),
            child: const Text('Confirmar Entrega', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final telemetry = Provider.of<TelemetryService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cerrar Sesión?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Se detendrá el servicio de rastreo GPS y saldrás de tu panel de repartidor.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              telemetry.stopTelemetryService();
              await auth.logout();
              if (!mounted) return;
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout, size: 16, color: Colors.white),
            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 0: PEDIDOS ACTIVOS ASIGNADOS
  // ==========================================
  Widget _buildActiveOrdersTab() {
    final telemetry = Provider.of<TelemetryService>(context);

    return Column(
      children: [
        // GPS Satelital Status Card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: telemetry.isTracking ? Colors.greenAccent : Colors.orangeAccent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rastreo GPS en Tiempo Real',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      Text(
                        telemetry.isTracking ? '🟢 MODO ACTIVO EN CALLE' : '🔴 MODO INACTIVO',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: telemetry.isTracking ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: telemetry.isTracking,
                    activeThumbColor: Colors.greenAccent,
                    onChanged: (val) async {
                      if (val) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                                ),
                                SizedBox(width: 10),
                                Text('Activando GPS satelital en tiempo real...'),
                              ],
                            ),
                            backgroundColor: Color(0xFF1E293B),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        await telemetry.startTelemetryService(orderId: _selectedOrderForMap?.id);
                        if (telemetry.hasRealGpsFix) {
                          _mapController.move(LatLng(telemetry.currentLat, telemetry.currentLng), 16.5);
                        }
                      } else {
                        telemetry.stopTelemetryService();
                      }
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('Velocidad', '${telemetry.currentSpeed.toStringAsFixed(1)} km/h'),
                  _buildMetric('Batería', '90%'),
                  _buildMetric('Calle Actual', _currentStreetName),
                ],
              ),
            ],
          ),
        ),

        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Órdenes en Despacho (${_activeOrders.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blueAccent, size: 20),
                onPressed: _loadDriverOrders,
              ),
            ],
          ),
        ),

        // List of Active Orders
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
              : _activeOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 54, color: Colors.greenAccent),
                          const SizedBox(height: 12),
                          const Text('¡Excelente! No tienes pedidos pendientes', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          const Text('Las nuevas órdenes asignadas aparecerán aquí', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _activeOrders.length,
                      itemBuilder: (context, index) {
                        final order = _activeOrders[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.build_circle, color: Colors.orangeAccent, size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '#${order.orderNumber} - ${order.customerName}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 12, color: Colors.greenAccent),
                                            const SizedBox(width: 4),
                                            Text(
                                              order.customerPhone,
                                              style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'S/ ${order.total.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      order.deliveryAddress,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              if (order.notes != null && order.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Nota: ${order.notes}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                              ],
                              const Divider(color: Colors.white12, height: 20),

                              // Items summary
                              ...order.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      '• ${item.quantity}x ${item.productName}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  )),

                              const SizedBox(height: 14),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedOrderForMap = order;
                                          _calculateMapRouteForOrder(order);
                                          _currentTabIndex = 2; // Switch to Mapa Tab
                                        });
                                      },
                                      icon: const Icon(Icons.map_outlined, color: Colors.black, size: 16),
                                      label: const Text('Ver en Mapa', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _markOrderAsDelivered(order),
                                      icon: const Icon(Icons.check, color: Colors.white, size: 16),
                                      label: const Text('Entregado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 1: HISTORIAL DE PEDIDOS ENTREGADOS
  // ==========================================
  Widget _buildHistoryTab() {
    final double totalEarnings = _deliveredOrders.length * 5.00;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Metrics Summary Banner
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Entregas Realizadas', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '${_deliveredOrders.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text('Completadas con éxito', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ganancias por Flete', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      'S/ ${totalEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text('S/ 5.00 por cada pedido', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        const Text(
          'Historial de Entregas Realizadas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),

        if (_deliveredOrders.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Aún no has completado órdenes de entrega', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ..._deliveredOrders.map((order) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              order.orderNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '+ S/ 5.00 Ganados',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cliente: ${order.customerName}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'Destino: ${order.deliveryAddress}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha: ${order.createdAt.isEmpty ? "Hoy" : order.createdAt}',
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // ==========================================
  // TAB 2: MAPA SATELITAL DE RUTAS
  // ==========================================
  Widget _buildMapTab() {
    final telemetry = Provider.of<TelemetryService>(context);
    final driverLatLng = LatLng(telemetry.currentLat, telemetry.currentLng);
    final destination = _selectedOrderForMap != null
        ? LatLng(_selectedOrderForMap!.deliveryLatitude, _selectedOrderForMap!.deliveryLongitude)
        : null;

    return Stack(
      children: [
        // Mapa Interactivo
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

            // Trazado Vial Real (Solo cuando hay pedido seleccionado)
            if (_selectedOrderForMap != null && _activeStreetRoute.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _activeStreetRoute,
                    strokeWidth: 9.0,
                    color: Colors.blue.withValues(alpha: 0.35),
                  ),
                  Polyline(
                    points: _activeStreetRoute,
                    strokeWidth: 5.0,
                    color: const Color(0xFF3B82F6),
                  ),
                ],
              ),

            // Marcadores de Repartidor y Destino
            MarkerLayer(
              markers: [
                // Destino del Cliente (solo si hay orden seleccionada)
                if (destination != null)
                  Marker(
                    point: destination,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [BoxShadow(color: Colors.redAccent, blurRadius: 12)],
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 26),
                    ),
                  ),

                // Moto del Repartidor / Posición del Conductor
                Marker(
                  point: driverLatLng,
                  width: 54,
                  height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: telemetry.hasRealGpsFix ? Colors.greenAccent : Colors.orangeAccent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (telemetry.hasRealGpsFix ? Colors.greenAccent : Colors.orangeAccent).withValues(alpha: 0.8),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.two_wheeler,
                      color: telemetry.hasRealGpsFix ? Colors.greenAccent : Colors.orangeAccent,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Indicador Flotante de Estado GPS Satelital
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: telemetry.hasRealGpsFix ? Colors.greenAccent : Colors.orangeAccent,
                width: 1.5,
              ),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  telemetry.hasRealGpsFix ? Icons.gps_fixed : Icons.gps_not_fixed,
                  size: 14,
                  color: telemetry.hasRealGpsFix ? Colors.greenAccent : Colors.orangeAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  telemetry.hasRealGpsFix ? 'GPS Real Satelital Activo' : 'Buscando Señal GPS...',
                  style: TextStyle(
                    color: telemetry.hasRealGpsFix ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Botón flotante para re-centrar
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'driver_recenter',
                backgroundColor: const Color(0xFF1E293B),
                tooltip: 'Obtener mi ubicación GPS actual',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent),
                          ),
                          SizedBox(width: 10),
                          Text('Obteniendo ubicación GPS real...', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      backgroundColor: Color(0xFF1E293B),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  final pos = await telemetry.fetchRealGpsLocation(promptSettings: true);
                  if (pos != null) {
                    final myPos = LatLng(pos.latitude, pos.longitude);
                    _mapController.move(myPos, 16.5);
                    if (_selectedOrderForMap != null) {
                      _calculateMapRouteForOrder(_selectedOrderForMap!);
                    }
                  } else {
                    _mapController.move(driverLatLng, 16.5);
                  }
                },
                child: Icon(
                  Icons.my_location,
                  color: telemetry.hasRealGpsFix ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedOrderForMap != null)
                FloatingActionButton.small(
                  heroTag: 'open_fullscreen_nav',
                  backgroundColor: const Color(0xFF1E293B),
                  tooltip: 'Navegación Pantalla Completa',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverRouteMapScreen(order: _selectedOrderForMap!),
                      ),
                    );
                  },
                  child: const Icon(Icons.fullscreen, color: Colors.blueAccent),
                ),
            ],
          ),
        ),

        // Bottom Navigation Helper Overlay
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedOrderForMap != null
                            ? 'Destino: #${_selectedOrderForMap!.orderNumber}'
                            : (telemetry.hasRealGpsFix ? '📍 Mi Ubicación GPS Real' : 'Modo Conducción Libre'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      Text(
                        _selectedOrderForMap != null
                            ? _selectedOrderForMap!.deliveryAddress
                            : 'Lat: ${telemetry.currentLat.toStringAsFixed(5)}, Lng: ${telemetry.currentLng.toStringAsFixed(5)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${telemetry.currentSpeed.toStringAsFixed(0)} km/h',
                    style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: PERFIL DEL REPARTIDOR
  // ==========================================
  Widget _buildProfileTab() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Driver Identity Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                child: const Icon(Icons.two_wheeler, size: 40, color: Colors.orangeAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Carlos Repartidor Rino',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'repartidor1@gruporino.pe',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🟢 En Turno • Huánuco Centro',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Vehicle Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehículo de Reparto Asignado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.two_wheeler, color: Colors.orangeAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Moto: Honda CB190R Repsol 2022', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.pin, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Placa de Rodaje: 4512-4W', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Text('SOAT & Revisión Técnica: Vigente 2026', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Server Configuration Tile
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: const Color(0xFF1E293B),
          leading: const Icon(Icons.wifi, color: Colors.blueAccent),
          title: const Text('Configuración de Conexión', style: TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: const Text('Ajustes de red y sincronización', style: TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            _showServerIpDialog();
          },
        ),

        const SizedBox(height: 24),

        // Logout Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _showServerIpDialog() {
    final ipController = TextEditingController(text: ApiConfig.serverIp);
    final portController = TextEditingController(text: ApiConfig.serverPort);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Configuración de Conexión', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Dirección del Servidor', labelStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: portController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Puerto', labelStyle: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.setServerIp(ipController.text, port: portController.text);
              if (!mounted) return;
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
              _loadDriverOrders();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    switch (_currentTabIndex) {
      case 0: appBarTitle = 'Panel de Despacho (Pedidos)'; break;
      case 1: appBarTitle = 'Historial de Entregas'; break;
      case 2: appBarTitle = 'Mapa de Entregas GPS'; break;
      case 3: appBarTitle = 'Perfil del Repartidor'; break;
      default: appBarTitle = 'Panel de Repartidor';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.two_wheeler, color: Colors.orangeAccent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                appBarTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF60A5FA)),
            tooltip: 'Asistente IA (Gemini)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GeminiChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),

      // Tab Body
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildActiveOrdersTab(),
          _buildHistoryTab(),
          _buildMapTab(),
          _buildProfileTab(),
        ],
      ),

      // BARRA INFERIOR (BOTTOM NAVIGATION BAR)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() => _currentTabIndex = index);
            if (index == 2) {
              final telemetry = Provider.of<TelemetryService>(context, listen: false);
              telemetry.fetchRealGpsLocation().then((pos) {
                if (pos != null && mounted) {
                  _mapController.move(LatLng(pos.latitude, pos.longitude), 16.5);
                }
              });
            }
          },
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: Colors.orangeAccent,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: _activeOrders.isNotEmpty,
                label: Text('${_activeOrders.length}'),
                backgroundColor: Colors.orangeAccent,
                child: const Icon(Icons.moped_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: _activeOrders.isNotEmpty,
                label: Text('${_activeOrders.length}'),
                backgroundColor: Colors.orangeAccent,
                child: const Icon(Icons.moped),
              ),
              label: 'Pedidos',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Historial',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
