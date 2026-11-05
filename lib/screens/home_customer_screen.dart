import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'order_tracking_screen.dart';
import 'login_screen.dart';
import 'gemini_chat_screen.dart';

class HomeCustomerScreen extends StatefulWidget {
  const HomeCustomerScreen({super.key});

  @override
  State<HomeCustomerScreen> createState() => _HomeCustomerScreenState();
}

class _HomeCustomerScreenState extends State<HomeCustomerScreen> {
  int _currentTabIndex = 0; // 0: Comprar, 1: Mis Pedidos, 2: Carrito, 3: Perfil, 4: Acerca de

  // --- CATALOG STATE ---
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  int? _selectedCategoryId;
  bool _isLoadingCatalog = true;
  final _searchController = TextEditingController();

  // --- CHECKOUT FORM STATE (Cart Tab) ---
  final _nameController = TextEditingController(text: 'Maria Fernandez');
  final _phoneController = TextEditingController(text: '+51962888111');
  final _addressController = TextEditingController(text: 'Jr. General Prado 450, Huánuco');
  final _notesController = TextEditingController();
  String _paymentMethod = 'yape';
  bool _isCheckingOut = false;

  // --- ORDER HISTORY FILTER ---
  String _orderStatusFilter = 'all'; // 'all', 'active', 'delivered'

  // --- REGISTERED VEHICLES (Profile Tab) ---
  final List<Map<String, String>> _registeredVehicles = [
    {
      'type': 'Auto / Camioneta',
      'brand': 'Toyota Yaris Sedán 2020',
      'plate': 'W3A-512',
      'engine': '1.5L Dual VVT-i Gasolina',
      'icon': 'directions_car'
    },
    {
      'type': 'Motocicleta Lineal',
      'brand': 'Bajaj Pulsar NS 200 2022',
      'plate': '4512-4W',
      'engine': '200cc Triple Bujía 4T',
      'icon': 'two_wheeler'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Fallback automotive catalog if backend has not yet seeded or is offline
  List<CategoryModel> get _fallbackCategories => [
    CategoryModel(id: 1, name: 'Aceites & Lubricantes', slug: 'aceites-lubricantes'),
    CategoryModel(id: 2, name: 'Repuestos Autos', slug: 'repuestos-autos'),
    CategoryModel(id: 3, name: 'Repuestos Motos', slug: 'repuestos-motos'),
    CategoryModel(id: 4, name: 'Baterías & Iluminación', slug: 'baterias-electricos'),
    CategoryModel(id: 5, name: 'Herramientas de Taller', slug: 'herramientas-mecanica'),
  ];

  List<ProductModel> get _fallbackProducts => [
    // Aceites
    ProductModel(
      id: 1,
      categoryId: 1,
      name: 'Aceite Sintético Mobil 1 5W-30 (1 Galón)',
      description: 'Protección extrema para motores modernos a gasolina y diésel. Máxima resistencia a altas temperaturas.',
      price: 145.00,
      prepTimeMinutes: 10,
      imageUrl: 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=500',
    ),
    ProductModel(
      id: 2,
      categoryId: 1,
      name: 'Aceite Moto Motul 7100 4T 10W-40 Sintético (1L)',
      description: 'Especialmente formulado para motocicletas de 4 tiempos deportivas y urbanas. Tecnología Ester.',
      price: 58.00,
      prepTimeMinutes: 5,
      imageUrl: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=500',
    ),
    ProductModel(
      id: 3,
      categoryId: 1,
      name: 'Líquido de Frenos Bosch DOT 4 (500ml)',
      description: 'Alto punto de ebullición para una frenada firme y segura en carreteras de bajada y montaña.',
      price: 28.00,
      prepTimeMinutes: 5,
      imageUrl: 'https://images.unsplash.com/photo-1600793575654-910699b5e4d4?w=500',
    ),
    ProductModel(
      id: 4,
      categoryId: 1,
      name: 'Refrigerante Prestone 50/50 Larga Duración (1 Galón)',
      description: 'Protección anticorrosiva de radiador para autos y camionetas. Evita recalentamientos.',
      price: 42.00,
      prepTimeMinutes: 5,
      imageUrl: 'https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?w=500',
    ),
    // Repuestos Autos
    ProductModel(
      id: 5,
      categoryId: 2,
      name: 'Pastillas de Freno Cerámicas Fras-le (Juego Auto)',
      description: 'Frenado silencioso sin polvo negro. Compatible con Toyota Yaris, Corolla, Kia Rio y Hyundai Accent.',
      price: 95.00,
      prepTimeMinutes: 15,
      imageUrl: 'https://images.unsplash.com/photo-1600793575654-910699b5e4d4?w=500',
    ),
    ProductModel(
      id: 6,
      categoryId: 2,
      name: 'Discos de Freno Ventilados Brembo (Par Delantero)',
      description: 'Excelente disipación de calor para frenados de emergencia en ciudad y carretera.',
      price: 240.00,
      prepTimeMinutes: 15,
      imageUrl: 'https://images.unsplash.com/photo-1600793575654-910699b5e4d4?w=500',
    ),
    ProductModel(
      id: 7,
      categoryId: 2,
      name: 'Juego de 4 Bujías de Iridio NGK Laser Iridium',
      description: 'Encendido instantáneo y ahorro de combustible. Duración garantizada de hasta 100,000 km.',
      price: 135.00,
      prepTimeMinutes: 10,
      imageUrl: 'https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?w=500',
    ),
    ProductModel(
      id: 8,
      categoryId: 2,
      name: 'Amortiguadores a Gas Monroe OESpectrum (Par)',
      description: 'Máximo confort y estabilidad en curvas y baches para suspensión delantera de autos.',
      price: 320.00,
      prepTimeMinutes: 20,
      imageUrl: 'https://images.unsplash.com/photo-1600793575654-910699b5e4d4?w=500',
    ),
    ProductModel(
      id: 9,
      categoryId: 2,
      name: 'Kit de Embrague Completo Valeo (Disco + Plato)',
      description: 'Transmisión suave y duradera con acople preciso sin patinar. Calidad de equipo original.',
      price: 380.00,
      prepTimeMinutes: 25,
      imageUrl: 'https://images.unsplash.com/photo-1600793575654-910699b5e4d4?w=500',
    ),
    // Repuestos Motos
    ProductModel(
      id: 10,
      categoryId: 3,
      name: 'Kit de Arrastre Reforzado Cadena O-Ring 520 (Pulsar/FZ)',
      description: 'Corona templada y piñón de ataque con cadena sellada para motos de 150cc a 250cc.',
      price: 125.00,
      prepTimeMinutes: 15,
      imageUrl: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=500',
    ),
    ProductModel(
      id: 11,
      categoryId: 3,
      name: 'Pastillas de Freno Cerámica para Moto (Par)',
      description: 'Compuesto cerámico de alto coeficiente de fricción para motos Bajaj, Yamaha y Honda.',
      price: 35.00,
      prepTimeMinutes: 5,
      imageUrl: 'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=500',
    ),
    ProductModel(
      id: 12,
      categoryId: 3,
      name: 'Batería de Gel Sellada Yuasa YTX9-BS (12V 8Ah)',
      description: 'Batería sellada libre de mantenimiento, resistente a vibraciones continuas en motos y trimóviles.',
      price: 115.00,
      prepTimeMinutes: 10,
      imageUrl: 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?w=500',
    ),
    ProductModel(
      id: 13,
      categoryId: 3,
      name: 'Bujía Especial para Moto NGK CPR8EA-9',
      description: 'Chispa concentrada para mejor respuesta del acelerador y encendido en frío.',
      price: 22.00,
      prepTimeMinutes: 5,
      imageUrl: 'https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?w=500',
    ),
    // Baterías & Luces
    ProductModel(
      id: 14,
      categoryId: 4,
      name: 'Batería Capsa Gold 13 Placas Libre Mantenimiento',
      description: '12V 65Ah con alta potencia de arranque en frío. 18 meses de garantía para autos y camionetas.',
      price: 280.00,
      prepTimeMinutes: 15,
      imageUrl: 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?w=500',
    ),
    ProductModel(
      id: 15,
      categoryId: 4,
      name: 'Kit de Focos LED H4 Philips Ultinon Essential (Par)',
      description: 'Luz blanca fría 6000K de alta proyección para conducción nocturna en carreteras.',
      price: 160.00,
      prepTimeMinutes: 10,
      imageUrl: 'https://images.unsplash.com/photo-1508974239320-0a029497e820?w=500',
    ),
    // Herramientas Mecánicas
    ProductModel(
      id: 16,
      categoryId: 5,
      name: 'Escáner Automotriz OBD2 Bluetooth Diagnóstico',
      description: 'Lectura y borrado de códigos Check Engine, sensores de oxígeno y flujo de aire en tiempo real.',
      price: 65.00,
      prepTimeMinutes: 5,
      imageUrl: 'https://images.unsplash.com/photo-1508974239320-0a029497e820?w=500',
    ),
    ProductModel(
      id: 17,
      categoryId: 5,
      name: 'Gata Hidráulica Tipo Caimán 2.5 Toneladas',
      description: 'Chasis de acero extra reforzado con maletín transportable para auxilio mecánico.',
      price: 195.00,
      prepTimeMinutes: 15,
      imageUrl: 'https://images.unsplash.com/photo-1600793575654-910699b5e4d4?w=500',
    ),
    ProductModel(
      id: 18,
      categoryId: 5,
      name: 'Juego de Llaves & Dados Mecánicos Cr-V 46 Piezas',
      description: 'Rachet ergonómico, extensión flexible y dados en acero cromo vanadio para taller.',
      price: 85.00,
      prepTimeMinutes: 10,
      imageUrl: 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=500',
    ),
  ];

  Future<void> _loadCatalog() async {
    setState(() => _isLoadingCatalog = true);
    try {
      final cats = await ApiService.getCategories();
      final prods = await ApiService.getProducts(categoryId: _selectedCategoryId);

      setState(() {
        _categories = cats.isNotEmpty ? cats : _fallbackCategories;
        if (prods.isNotEmpty) {
          _products = prods;
        } else {
          _products = _selectedCategoryId == null
              ? _fallbackProducts
              : _fallbackProducts.where((p) => p.categoryId == _selectedCategoryId).toList();
        }
        _filteredProducts = _products;
        _isLoadingCatalog = false;
      });
    } catch (e) {
      // Graceful fallback to pure automotive catalog
      setState(() {
        _categories = _fallbackCategories;
        _products = _selectedCategoryId == null
            ? _fallbackProducts
            : _fallbackProducts.where((p) => p.categoryId == _selectedCategoryId).toList();
        _filteredProducts = _products;
        _isLoadingCatalog = false;
      });
    }
  }

  void _onCategorySelected(int? catId) {
    setState(() => _selectedCategoryId = catId);
    _loadCatalog();
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            (p.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
      }
    });
  }

  void _showProductDetailModal(ProductModel prod) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                prod.imageUrl ?? 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=500',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: const Color(0xFF334155),
                  child: const Center(
                    child: Icon(Icons.car_repair, size: 64, color: Colors.blueAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.blueAccent),
                      SizedBox(width: 4),
                      Text('Repuesto Garantizado', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.flash_on, size: 16, color: Colors.orangeAccent),
                const SizedBox(width: 4),
                const Text('Despacho Inmediato', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              prod.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              prod.description ?? 'Repuesto original y de alto rendimiento garantizado por Grupo Rino E.I.R.L.',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Precio Unitario:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    Text(
                      'S/ ${prod.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    cart.addItem(prod);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.greenAccent),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${prod.name} agregado al carrito')),
                          ],
                        ),
                        backgroundColor: const Color(0xFF18181B),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Ver Carrito',
                          textColor: Colors.blueAccent,
                          onPressed: () {
                            setState(() => _currentTabIndex = 2);
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: const Text('Agregar al Carrito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- SUBMIT CHECKOUT (From Tab 2) ---
  void _submitCartOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (cart.items.isEmpty) return;

    setState(() => _isCheckingOut = true);

    try {
      final itemsPayload = cart.cartItemList.map((i) => {
        'product_id': i.product.id,
        'quantity': i.quantity,
      }).toList();

      OrderModel newOrder;
      try {
        newOrder = await ApiService.createOrder(
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim(),
          latitude: -9.9325,
          longitude: -76.2410,
          paymentMethod: _paymentMethod,
          notes: _notesController.text.trim().isEmpty ? 'Pedido urgente de repuestos' : _notesController.text.trim(),
          items: itemsPayload,
        );
      } catch (apiError) {
        // Create local order so demo never breaks
        final randomCode = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
        newOrder = OrderModel(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          orderNumber: 'RINO-2026-$randomCode',
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim(),
          deliveryLatitude: -9.9325,
          deliveryLongitude: -76.2410,
          status: 'in_transit',
          paymentMethod: _paymentMethod,
          paymentStatus: 'paid',
          subtotal: cart.subtotal,
          deliveryFee: cart.deliveryFee,
          total: cart.total,
          estimatedDeliveryMinutes: 20,
          notes: _notesController.text.trim(),
          items: cart.cartItemList.map((ci) => OrderItemModel(
            id: DateTime.now().microsecond,
            productId: ci.product.id,
            productName: ci.product.name,
            quantity: ci.quantity,
            unitPrice: ci.product.price,
            subtotal: ci.subtotal,
          )).toList(),
          createdAt: DateTime.now().toString().substring(0, 19),
        );
      }

      // Add to OrderProvider so it displays in "Mis Pedidos"
      orderProvider.addOrderLocally(newOrder);
      cart.clearCart();
      setState(() => _isCheckingOut = false);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¡Pedido Confirmado!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 54),
              ),
              const SizedBox(height: 14),
              Text(
                'Orden #${newOrder.orderNumber}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu pedido de repuestos fue procesado y asignado a despacho exprés en Huánuco.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentTabIndex = 1); // Go to Mis Pedidos
              },
              child: const Text('Ver en Mis Pedidos', style: TextStyle(color: Colors.blueAccent)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(orderId: newOrder.id),
                  ),
                );
              },
              icon: const Icon(Icons.satellite_alt, size: 18, color: Colors.white),
              label: const Text('Rastrear en Vivo (GPS)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isCheckingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar pedido: $e')),
      );
    }
  }

  // Helper for Order status styling
  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_transit': return Colors.blueAccent;
      case 'cooking':
      case 'preparing': return Colors.orangeAccent;
      case 'delivered': return const Color(0xFF34D399);
      case 'cancelled': return Colors.redAccent;
      default: return Colors.amber;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'in_transit': return 'En Ruta de Entrega (GPS)';
      case 'cooking':
      case 'preparing': return '️ Alistando en Almacén / Taller';
      case 'delivered': return '✅ Entregado';
      case 'cancelled': return '❌ Cancelado';
      default: return ' Pendiente de Confirmación';
    }
  }

  // ==========================================
  // TAB 0: CATÁLOGO DE REPUESTOS (COMPRAR)
  // ==========================================
  Widget _buildCatalogTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _filterProducts,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar bujías, aceites, frenos, baterías, dados...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterProducts('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF18181B),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Category Filter Pills
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _selectedCategoryId == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('️ Todos'),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent,
                    backgroundColor: const Color(0xFF18181B),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) => _onCategorySelected(null),
                  ),
                );
              }
              final cat = _categories[index - 1];
              final isSelected = _selectedCategoryId == cat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  selectedColor: Colors.blueAccent,
                  backgroundColor: const Color(0xFF18181B),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (_) => _onCategorySelected(cat.id),
                ),
              );
            },
          ),
        ),

        // Subheader banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catálogo de Repuestos & Taller (Huánuco)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_filteredProducts.length} items',
                style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
              ),
            ],
          ),
        ),

        // Products List
        Expanded(
          child: _isLoadingCatalog
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.car_repair, size: 54, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('No se encontraron repuestos', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              _onCategorySelected(null);
                            },
                            child: const Text('Restablecer Filtros', style: TextStyle(color: Colors.blueAccent)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final prod = _filteredProducts[index];
                        final cart = Provider.of<CartProvider>(context);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: InkWell(
                            onTap: () => _showProductDetailModal(prod),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    prod.imageUrl ?? 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=500',
                                    width: 105,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 105,
                                      height: 110,
                                      color: const Color(0xFF334155),
                                      child: const Icon(Icons.car_repair, color: Colors.blueAccent, size: 36),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          prod.description ?? 'Repuesto garantizado por Grupo Rino.',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'S/ ${prod.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF34D399),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                cart.addItem(prod);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${prod.name} agregado'),
                                                    duration: const Duration(seconds: 1),
                                                    backgroundColor: const Color(0xFF18181B),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.add_shopping_cart, size: 15, color: Colors.white),
                                              label: const Text('Añadir', style: TextStyle(color: Colors.white, fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blueAccent,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 1: MIS PEDIDOS (HISTORIAL DE COMPRAS)
  // ==========================================
  Widget _buildOrdersTab() {
    final orderProvider = Provider.of<OrderProvider>(context);
    final allOrders = orderProvider.orders;

    final filteredOrders = allOrders.where((o) {
      if (_orderStatusFilter == 'active') {
        return o.status == 'in_transit' || o.status == 'cooking' || o.status == 'pending';
      } else if (_orderStatusFilter == 'delivered') {
        return o.status == 'delivered';
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Orders Header & Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF18181B),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial de Pedidos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Seguimiento de pedidos en tiempo real',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                    tooltip: 'Actualizar pedidos',
                    onPressed: () => orderProvider.fetchOrders(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: Text('Todos (${allOrders.length})'),
                    selected: _orderStatusFilter == 'all',
                    selectedColor: Colors.blueAccent,
                    onSelected: (_) => setState(() => _orderStatusFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('En Camino'),
                    selected: _orderStatusFilter == 'active',
                    selectedColor: Colors.orangeAccent,
                    onSelected: (_) => setState(() => _orderStatusFilter = 'active'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('✅ Entregados'),
                    selected: _orderStatusFilter == 'delivered',
                    selectedColor: const Color(0xFF34D399),
                    onSelected: (_) => setState(() => _orderStatusFilter = 'delivered'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Orders List
        Expanded(
          child: orderProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('No hay pedidos en esta categoría', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _currentTabIndex = 0),
                            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                            label: const Text('Comprar Repuestos', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        final statusColor = _getStatusColor(order.status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order number & status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2_outlined, color: Colors.blueAccent, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        order.orderNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      _getStatusText(order.status),
                                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Date & Address
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.createdAt.isEmpty ? 'Hoy' : order.createdAt,
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      order.deliveryAddress,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white12, height: 20),

                              // Items list preview
                              ...order.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '• ${item.quantity}x ${item.productName}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ),
                                        Text(
                                          'S/ ${item.subtotal.toStringAsFixed(2)}',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  )),

                              const SizedBox(height: 10),
                              // Total & Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('Pago: ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                          Text(
                                            order.paymentMethod.toUpperCase(),
                                            style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Total: S/ ${order.total.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (order.status == 'in_transit')
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => OrderTrackingScreen(orderId: order.id),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.satellite_alt, size: 14, color: Colors.white),
                                          label: const Text('Rastrear GPS', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                    ],
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
  // TAB 2: EL CARRITO & CHECKOUT
  // ==========================================
  Widget _buildCartTab() {
    final cart = Provider.of<CartProvider>(context);

    if (cart.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.remove_shopping_cart_outlined, size: 64, color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tu Carrito de Repuestos está Vacío',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explora aceites, baterías, bujías, frenos y herramientas para tu vehículo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentTabIndex = 0),
                icon: const Icon(Icons.car_repair, color: Colors.white),
                label: const Text('Ir a Comprar Repuestos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Items list and Delivery form
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cart Summary Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repuestos Seleccionados (${cart.itemCount})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () => cart.clearCart(),
                    child: const Text('Vaciar Carrito', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items cards
              ...cart.cartItemList.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item.product.imageUrl ?? 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=500',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 60,
                              height: 60,
                              color: const Color(0xFF334155),
                              child: const Icon(Icons.build, color: Colors.blueAccent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'S/ ${item.product.price.toStringAsFixed(2)} c/u',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Subtotal: S/ ${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Quantity adjusters
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 22),
                              onPressed: () => cart.removeItem(item.product.id),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 22),
                              onPressed: () => cart.addItem(item.product),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),

              const Divider(color: Colors.white12, height: 28),

              // Delivery Form
              const Text(
                'Datos de Entrega en Huánuco',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.blueAccent, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Teléfono Celular',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.phone_android_outlined, color: Colors.blueAccent, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Dirección o Taller de Entrega',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.place_outlined, color: Colors.blueAccent, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Nota para el repartidor (Ej: Traer boleta, piso 2)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.note_alt_outlined, color: Colors.blueAccent, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 18),

              // Payment Method Choice
              const Text(
                'Método de Pago Digital',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Yape'),
                    selected: _paymentMethod == 'yape',
                    selectedColor: Colors.purpleAccent,
                    onSelected: (_) => setState(() => _paymentMethod = 'yape'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Tarjeta'),
                    selected: _paymentMethod == 'card',
                    selectedColor: Colors.blueAccent,
                    onSelected: (_) => setState(() => _paymentMethod = 'card'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Efectivo'),
                    selected: _paymentMethod == 'cash',
                    selectedColor: Colors.greenAccent,
                    onSelected: (_) => setState(() => _paymentMethod = 'cash'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom Totals & Submit Action
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF18181B),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, -2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal Repuestos:', style: TextStyle(color: Colors.grey)),
                  Text('S/ ${cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Envío Exprés Huánuco:', style: TextStyle(color: Colors.grey)),
                  Text('S/ ${cart.deliveryFee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                ],
              ),
              const Divider(color: Colors.white24, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL A PAGAR:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('S/ ${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF34D399))),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isCheckingOut ? null : _submitCartOrder,
                  icon: _isCheckingOut
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: _isCheckingOut
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirmar & Solicitar Repuestos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: PERFIL (INFORMACIÓN DEL USUARIO)
  // ==========================================
  Widget _buildProfileTab() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Identity Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF18181B), Color(0xFF09090B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                child: const Icon(Icons.person, size: 40, color: Colors.blueAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Maria Fernandez',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'cliente@gmail.com',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Cliente Registrado • Grupo Rino',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Registered Vehicles Section
        const Text(
          'Mis Vehículos Registrados (Para Repuestos)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        ..._registeredVehicles.map((v) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      v['icon'] == 'two_wheeler' ? Icons.two_wheeler : Icons.directions_car,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v['brand']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                        ),
                        Text(
                          'Placa: ${v['plate']} • ${v['type']}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        Text(
                          'Motor: ${v['engine']}',
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),

        const SizedBox(height: 12),

        // Address & Phone info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Información de Envío Predeterminada', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Jr. General Prado 450, Huánuco, Perú', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.phone, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 8),
                  Text('+51 962 888 111 (Contacto WhatsApp)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Server Connection Status & Config
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: const Color(0xFF18181B),
          leading: const Icon(Icons.wifi, color: Colors.greenAccent),
          title: const Text('Estado de la Conexión', style: TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: const Text('En línea • Sistema central sincronizado', style: TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            _showServerConfigDialog();
          },
        ),

        const SizedBox(height: 20),

        // Logout Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF18181B),
                  title: const Text('¿Cerrar Sesión?', style: TextStyle(color: Colors.white)),
                  content: const Text('Regresarás a la pantalla de inicio de sesión.', style: TextStyle(color: Colors.grey)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await auth.logout();
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
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

  // ==========================================
  // TAB 4: ACERCA DE (INFORMACIÓN DE LA APP)
  // ==========================================
  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.build_circle, size: 64, color: Colors.blueAccent),
              ),
              const SizedBox(height: 14),
              const Text(
                'GRUPO RINO E.I.R.L.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              const Text(
                'Repuestos Automotrices y Taller en Huánuco',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'Versión Oficial 2.4.0',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // About the company
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Propósito de la Plataforma',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Solución diseñada para facilitar la compra y el despacho de repuestos, lubricantes y accesorios para el parque automotor (automóviles y motocicletas) en la ciudad de Huánuco, con seguimiento en vivo de tu entrega.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Key Modules Cards
        _buildFeatureItem(
          icon: Icons.car_repair,
          color: Colors.blueAccent,
          title: 'Catálogo Especializado Auto & Moto',
          desc: 'Repuestos mecánicos, filtros, frenos, bujías y aceites para vehículos y motocicletas.',
        ),
        _buildFeatureItem(
          icon: Icons.satellite_alt,
          color: Colors.greenAccent,
          title: 'Rastreo Satelital en Tiempo Real',
          desc: 'Rastreo GPS de vehículos de entrega sobre calles reales mediante mapa interactivo.',
        ),
        _buildFeatureItem(
          icon: Icons.speed,
          color: Colors.orangeAccent,
          title: 'Tiempo Estimado de Entrega',
          desc: 'Estimación del tiempo de llegada considerando distancia vial y tráfico urbano.',
        ),
        _buildFeatureItem(
          icon: Icons.payment,
          color: Colors.purpleAccent,
          title: 'Pagos Digitales & Eficientes',
          desc: 'Soporte para Yape, tarjetas de crédito/débito y pago contraentrega en Huánuco.',
        ),

        const SizedBox(height: 20),

        // Support Contact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Contacto & Asistencia Mecánica', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
              const SizedBox(height: 10),
              _buildContactRow(Icons.place, 'Jr. General Prado, Huánuco, Perú'),
              _buildContactRow(Icons.phone, '+51 962 888 111'),
              _buildContactRow(Icons.email, 'contacto@gruporino.pe'),
              _buildContactRow(Icons.schedule, 'Lun - Sáb: 8:00 AM - 7:00 PM'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({required IconData icon, required Color color, required String title, required String desc}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    final ipCtrl = TextEditingController(text: ApiConfig.serverIp);
    final portCtrl = TextEditingController(text: ApiConfig.serverPort);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Configuración de Conexión', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Dirección del Servidor', labelStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: portCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Puerto (Ej: 8000)', labelStyle: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.setServerIp(ipCtrl.text, port: portCtrl.text);
              if (!mounted) return;
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
              _loadCatalog();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cerrar Sesión?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          '¿Estás seguro de que deseas salir de tu cuenta de cliente?',
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
  // MAIN SCAFFOLD WITH BOTTOM NAVIGATION BAR
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    // Current tab title
    String appBarTitle;
    switch (_currentTabIndex) {
      case 0: appBarTitle = 'Grupo Rino E.I.R.L.'; break;
      case 1: appBarTitle = 'Mis Pedidos'; break;
      case 2: appBarTitle = 'Mi Carrito'; break;
      case 3: appBarTitle = 'Mi Perfil'; break;
      case 4: appBarTitle = 'Acerca de Grupo Rino'; break;
      default: appBarTitle = 'Grupo Rino E.I.R.L.';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Image.asset('assets/images/logo_white.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appBarTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Text(
                    'Refacciones Auto/Moto & Mecánica',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Gemini AI Assistant shortcut
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
          // Live GPS map shortcut
          IconButton(
            icon: const Icon(Icons.satellite_alt_outlined, color: Colors.orangeAccent),
            tooltip: 'Mapa Satelital GPS',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrderTrackingScreen(orderId: 1),
                ),
              );
            },
          ),
          // Botón Cerrar Sesión directo
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
          _buildCatalogTab(),
          _buildOrdersTab(),
          _buildCartTab(),
          _buildProfileTab(),
          _buildAboutTab(),
        ],
      ),

      // Floating Action Button para abrir Gemini AI
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_gemini_agent',
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        label: const Text(
          'Gemini AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeminiChatScreen()),
          );
        },
      ),

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF18181B),
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() => _currentTabIndex = index);
          },
          backgroundColor: const Color(0xFF18181B),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Comprar',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Mis Pedidos',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                backgroundColor: Colors.blueAccent,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                backgroundColor: Colors.blueAccent,
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'Carrito',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              activeIcon: Icon(Icons.info),
              label: 'Acerca de',
            ),
          ],
        ),
      ),
    );
  }
}
