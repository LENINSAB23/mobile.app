import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  OrderModel? _activeOrder;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  OrderModel? get activeOrder => _activeOrder;

  OrderProvider() {
    _initFallbackOrders();
  }

  void _initFallbackOrders() {
    _orders = [
      OrderModel(
        id: 1,
        orderNumber: 'RINO-20261015-081',
        customerName: 'Maria Fernandez',
        customerPhone: '+51962888111',
        deliveryAddress: 'Jr. General Prado 450, Huánuco',
        deliveryLatitude: -9.9325,
        deliveryLongitude: -76.2410,
        status: 'in_transit',
        paymentMethod: 'yape',
        paymentStatus: 'paid',
        subtotal: 203.00,
        deliveryFee: 5.00,
        total: 208.00,
        estimatedDeliveryMinutes: 18,
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
            productName: 'Aceite para Moto Motul 7100 4T 10W-40 100% Sintético (1L)',
            quantity: 1,
            unitPrice: 58.00,
            subtotal: 58.00,
          ),
        ],
        createdAt: '2026-10-15 14:10:00',
      ),
      OrderModel(
        id: 2,
        orderNumber: 'RINO-20261014-042',
        customerName: 'Maria Fernandez',
        customerPhone: '+51962888111',
        deliveryAddress: 'Av. Universitaria 1200, Cayhuayna, Huánuco',
        deliveryLatitude: -9.9510,
        deliveryLongitude: -76.2450,
        status: 'delivered',
        paymentMethod: 'card',
        paymentStatus: 'paid',
        subtotal: 160.00,
        deliveryFee: 5.00,
        total: 165.00,
        estimatedDeliveryMinutes: 25,
        notes: 'Focos LED H4 de reemplazo para camioneta.',
        items: [
          OrderItemModel(
            id: 103,
            productId: 4,
            productName: 'Kit de Focos LED H4 Philips Ultinon Essential (Par)',
            quantity: 1,
            unitPrice: 160.00,
            subtotal: 160.00,
          ),
        ],
        createdAt: '2026-10-14 09:30:00',
      ),
      OrderModel(
        id: 3,
        orderNumber: 'RINO-20261012-019',
        customerName: 'Maria Fernandez',
        customerPhone: '+51962888111',
        deliveryAddress: 'Jr. Dos de Mayo 780, Huánuco',
        deliveryLatitude: -9.9290,
        deliveryLongitude: -76.2400,
        status: 'delivered',
        paymentMethod: 'cash',
        paymentStatus: 'paid',
        subtotal: 95.00,
        deliveryFee: 5.00,
        total: 100.00,
        estimatedDeliveryMinutes: 20,
        notes: 'Repuesto urgente para mantenimiento preventivo.',
        items: [
          OrderItemModel(
            id: 104,
            productId: 3,
            productName: 'Pastillas de Freno Cerámicas Fras-le (Juego Delantero Auto)',
            quantity: 1,
            unitPrice: 95.00,
            subtotal: 95.00,
          ),
        ],
        createdAt: '2026-10-12 16:45:00',
      ),
    ];
    if (_orders.isNotEmpty) {
      _activeOrder = _orders.first;
    }
  }

  Future<void> fetchOrders({int? driverId, int? customerId, String? token}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final remoteOrders = await ApiService.getOrders(driverId: driverId, customerId: customerId, token: token);
      if (remoteOrders.isNotEmpty) {
        _orders = remoteOrders;
        if (_activeOrder == null || !_orders.any((o) => o.id == _activeOrder!.id)) {
          _activeOrder = _orders.first;
        }
      }
    } catch (e) {
      debugPrint('Error fetching orders from API: $e. Retaining local automotive orders.');
    }
    _isLoading = false;
    notifyListeners();
  }

  void addOrderLocally(OrderModel order) {
    _orders.insert(0, order);
    _activeOrder = order;
    notifyListeners();
  }

  void setActiveOrder(OrderModel order) {
    _activeOrder = order;
    notifyListeners();
  }
}
