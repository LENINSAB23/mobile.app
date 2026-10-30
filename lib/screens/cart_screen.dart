import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'order_tracking_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameController = TextEditingController(text: 'Maria Fernandez');
  final _phoneController = TextEditingController(text: '+51962888111');
  final _addressController = TextEditingController(text: 'Jr. General Prado 450, Huánuco');
  String _paymentMethod = 'yape';
  bool _isProcessing = false;

  void _submitOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final itemsPayload = cart.cartItemList.map((i) => {
        'product_id': i.product.id,
        'quantity': i.quantity,
      }).toList();

      final newOrder = await ApiService.createOrder(
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        latitude: -9.9325,
        longitude: -76.2410,
        paymentMethod: _paymentMethod,
        items: itemsPayload,
      );

      cart.clearCart();
      setState(() => _isProcessing = false);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('¡Pedido Confirmado!', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64),
              const SizedBox(height: 12),
              Text(
                'Tu orden #${newOrder.orderNumber} ha sido enviada al centro de despacho automotriz de Grupo Rino.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(orderId: newOrder.id),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Rastrear Pedido en Mapa', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar pedido: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Mi Carrito & Checkout'),
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Tu carrito está vacío',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Cart Item List
                      const Text(
                        'Resumen del Pedido',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      ...cart.cartItemList.map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${item.quantity}x  S/ ${item.product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'S/ ${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => cart.deleteItem(item.product.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),

                      const Divider(color: Colors.grey, height: 32),

                      // Delivery Info Form
                      const Text(
                        'Datos de Entrega en Huánuco',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nombre Completo',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Teléfono de contacto',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _addressController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Dirección de Entrega',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Payment Method Selector
                      const Text(
                        'Método de Pago Digital',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('📱 Yape'),
                            selected: _paymentMethod == 'yape',
                            selectedColor: Colors.purpleAccent,
                            onSelected: (_) => setState(() => _paymentMethod = 'yape'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('💳 Tarjeta'),
                            selected: _paymentMethod == 'card',
                            selectedColor: Colors.blueAccent,
                            onSelected: (_) => setState(() => _paymentMethod = 'card'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('💵 Efectivo'),
                            selected: _paymentMethod == 'cash',
                            selectedColor: Colors.greenAccent,
                            onSelected: (_) => setState(() => _paymentMethod = 'cash'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Totals Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(color: Colors.grey)),
                          Text('S/ ${cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Costo Delivery:', style: TextStyle(color: Colors.grey)),
                          Text('S/ ${cart.deliveryFee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      const Divider(color: Colors.grey),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('S/ ${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF34D399))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _submitOrder,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          child: _isProcessing
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Confirmar & Pagar Pedido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
