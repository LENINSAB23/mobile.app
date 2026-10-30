import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';

class ApiService {
  static Map<String, String> _headers([String? token]) {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Auth: Login
  static Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 4), onTimeout: () {
      throw Exception('Tiempo de espera agotado al conectar con el servidor (${ApiConfig.baseUrl}).');
    });

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      final userJson = data['data']['user'];
      final token = data['data']['access_token'];
      return UserModel.fromJson(userJson, token: token);
    } else {
      throw Exception(data['message'] ?? 'Error al iniciar sesión');
    }
  }

  // Categories
  static Future<List<CategoryModel>> getCategories() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/categories'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? [];
      return list.map((c) => CategoryModel.fromJson(c)).toList();
    }
    return [];
  }

  // Products
  static Future<List<ProductModel>> getProducts({int? categoryId}) async {
    String url = '${ApiConfig.baseUrl}/products';
    if (categoryId != null) {
      url += '?category_id=$categoryId';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? [];
      return list.map((p) => ProductModel.fromJson(p)).toList();
    }
    return [];
  }

  // Create Order (Checkout)
  static Future<OrderModel> createOrder({
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required double latitude,
    required double longitude,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    String? notes,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: _headers(token),
      body: jsonEncode({
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'delivery_address': deliveryAddress,
        'delivery_latitude': latitude,
        'delivery_longitude': longitude,
        'payment_method': paymentMethod,
        'notes': notes,
        'items': items,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['status'] == 'success') {
      return OrderModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Error al registrar pedido');
    }
  }

  // Get Orders
  static Future<List<OrderModel>> getOrders({int? driverId, int? customerId, String? token}) async {
    final params = <String>[];
    if (driverId != null) params.add('driver_id=$driverId');
    if (customerId != null) params.add('customer_id=$customerId');
    
    String url = '${ApiConfig.baseUrl}/orders';
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    
    final response = await http.get(Uri.parse(url), headers: _headers(token));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? [];
      return list.map((o) => OrderModel.fromJson(o)).toList();
    }
    return [];
  }

  // Order Tracking Telemetry Data
  static Future<Map<String, dynamic>> getOrderTracking(int orderId) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/telemetry/order/$orderId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    }
    return {};
  }
}
