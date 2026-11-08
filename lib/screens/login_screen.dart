import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import 'home_customer_screen.dart';
import 'driver_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'customer'; // customer or driver

  @override
  void initState() {
    super.initState();
    _applyDefaultCredentials('customer');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _applyDefaultCredentials(String role) {
    if (role == 'customer') {
      _emailController.text = 'cliente@gmail.com';
      _passwordController.text = 'cliente123';
    } else {
      _emailController.text = 'repartidor1@gruporino.pe';
      _passwordController.text = 'driver123';
    }
  }

  void _navigateToRoleScreen() {
    if (_selectedRole == 'driver') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeCustomerScreen()),
      );
    }
  }

  void _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      auth.setRole(_selectedRole);
      _navigateToRoleScreen();
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF27272A)),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Error de Autenticación', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.errorMessage ?? 'No se pudo iniciar sesión. Verifique sus credenciales o la conectividad con el servidor central.',
                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showServerIpDialog();
              },
              child: const Text('Ajustes de Servidor', style: TextStyle(color: Color(0xFFA1A1AA))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF09090B),
              ),
              child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }

  void _showServerIpDialog() {
    final ipController = TextEditingController(text: ApiConfig.serverIp);
    final portController = TextEditingController(text: ApiConfig.serverPort);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF27272A)),
        ),
        title: const Row(
          children: [
            Icon(Icons.tune_outlined, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Parámetros de Servidor', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dirección IP o Host del Backend Laravel:',
              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Host / IP',
                labelStyle: TextStyle(color: Color(0xFF71717A), fontSize: 12),
                filled: true,
                fillColor: Color(0xFF09090B),
                border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Puerto',
                labelStyle: TextStyle(color: Color(0xFF71717A), fontSize: 12),
                filled: true,
                fillColor: Color(0xFF09090B),
                border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF27272A))),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Presets Rápidos:', style: TextStyle(color: Color(0xFF71717A), fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('USB adb reverse (127.0.0.1)', style: TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFF27272A),
                  side: BorderSide.none,
                  onPressed: () {
                    ipController.text = '127.0.0.1';
                    portController.text = '8000';
                  },
                ),
                ActionChip(
                  label: const Text('Emulador Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFF27272A),
                  side: BorderSide.none,
                  onPressed: () {
                    ipController.text = '10.0.2.2';
                    portController.text = '8000';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFFA1A1AA))),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.setServerIp(
                ipController.text.trim(),
                port: portController.text.trim(),
              );
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF09090B),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: Color(0xFFA1A1AA), size: 20),
            tooltip: 'Configuración de Conexión',
            onPressed: _showServerIpDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de Empresa Oficial (Rinoceronte minimalista)
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Image.asset(
                    'assets/images/logo_white.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'GRUPO RINO E.I.R.L.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Repuestos Automotrices & Motocicletas • Huánuco',
                  style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                ),
                const SizedBox(height: 32),

                // Role Selector Monocromático
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'customer';
                              _applyDefaultCredentials('customer');
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'customer'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: _selectedRole == 'customer'
                                      ? const Color(0xFF09090B)
                                      : const Color(0xFFA1A1AA),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cliente',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _selectedRole == 'customer'
                                        ? const Color(0xFF09090B)
                                        : const Color(0xFFA1A1AA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'driver';
                              _applyDefaultCredentials('driver');
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'driver'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delivery_dining_outlined,
                                  size: 16,
                                  color: _selectedRole == 'driver'
                                      ? const Color(0xFF09090B)
                                      : const Color(0xFFA1A1AA),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Repartidor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _selectedRole == 'driver'
                                        ? const Color(0xFF09090B)
                                        : const Color(0xFFA1A1AA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Inputs Minimalistas
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFA1A1AA), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF18181B),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF27272A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF71717A)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFA1A1AA), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF18181B),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF27272A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF71717A)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Ingresar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF09090B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Color(0xFF09090B), strokeWidth: 2),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Conexión Indicador Minimalista
                GestureDetector(
                  onTap: _showServerIpDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF27272A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: Color(0xFF22C55E)),
                        SizedBox(width: 7),
                        Text(
                          'Sistema Preparado',
                          style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
