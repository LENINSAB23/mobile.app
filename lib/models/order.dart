class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Producto',
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
    );
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String status; // pending, cooking, in_transit, delivered, cancelled
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final int? estimatedDeliveryMinutes;
  final String? notes;
  final List<OrderItemModel> items;
  final String createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.estimatedDeliveryMinutes,
    this.notes,
    required this.items,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<OrderItemModel> itemList = rawItems.map((i) => OrderItemModel.fromJson(i)).toList();

    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      deliveryLatitude: double.tryParse(json['delivery_latitude'].toString()) ?? -9.9306,
      deliveryLongitude: double.tryParse(json['delivery_longitude'].toString()) ?? -76.2422,
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'yape',
      paymentStatus: json['payment_status'] ?? 'pending',
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      deliveryFee: double.tryParse(json['delivery_fee'].toString()) ?? 5.0,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      estimatedDeliveryMinutes: json['estimated_delivery_minutes'],
      notes: json['notes'],
      items: itemList,
      createdAt: json['created_at'] ?? '',
    );
  }
}
