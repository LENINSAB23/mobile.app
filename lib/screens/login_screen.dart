import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
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
      final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: isDark ? Colors.white70 : const Color(0xFF09090B), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error de Autenticación',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.errorMessage ?? 'No se pudo iniciar sesión. Verifique sus credenciales o la conectividad con el servidor central.',
                style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showServerIpDialog();
              },
              child: Text(
                'Ajustes de Servidor',
                style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF09090B),
                foregroundColor: isDark ? const Color(0xFF09090B) : Colors.white,
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
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            Icon(Icons.tune_outlined, color: isDark ? Colors.white : const Color(0xFF09090B), size: 18),
            const SizedBox(width: 8),
            Text(
              'Parámetros de Servidor',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF09090B),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dirección IP o Host del Backend Laravel:',
              style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF09090B), fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Host / IP',
                labelStyle: TextStyle(color: isDark ? const Color(0xFF71717A) : const Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF09090B), fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Puerto',
                labelStyle: TextStyle(color: isDark ? const Color(0xFF71717A) : const Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 14),
            Text('Presets Rápidos:', style: TextStyle(color: isDark ? const Color(0xFF71717A) : const Color(0xFF64748B), fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('USB adb reverse (127.0.0.1)', style: TextStyle(fontSize: 11)),
                  backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
                  side: BorderSide.none,
                  onPressed: () {
                    ipController.text = '127.0.0.1';
                    portController.text = '8000';
                  },
                ),
                ActionChip(
                  label: const Text('Emulador Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
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
            child: Text('Cancelar', style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B))),
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
              backgroundColor: isDark ? Colors.white : const Color(0xFF09090B),
              foregroundColor: isDark ? const Color(0xFF09090B) : Colors.white,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
              size: 20,
            ),
            tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: Icon(
              Icons.tune_outlined,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
              size: 20,
            ),
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
                // Logo de Empresa Oficial (Rinoceronte minimalista conmutable)
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Image.asset(
                    isDark ? 'assets/images/logo_white.png' : 'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'GRUPO RINO E.I.R.L.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Repuestos Automotrices & Motocicletas • Huánuco',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),

                // Role Selector Monocromático
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                    ),
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
                                  ? (isDark ? Colors.white : const Color(0xFF09090B))
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
                                      ? (isDark ? const Color(0xFF09090B) : Colors.white)
                                      : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cliente',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _selectedRole == 'customer'
                                        ? (isDark ? const Color(0xFF09090B) : Colors.white)
                                        : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
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
                                  ? (isDark ? Colors.white : const Color(0xFF09090B))
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
                                      ? (isDark ? const Color(0xFF09090B) : Colors.white)
                                      : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Repartidor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _selectedRole == 'driver'
                                        ? (isDark ? const Color(0xFF09090B) : Colors.white)
                                        : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: TextStyle(
                      color: isDark ? const Color(0xFF71717A) : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                      size: 18,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF71717A) : const Color(0xFF64748B),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(
                      color: isDark ? const Color(0xFF71717A) : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                      size: 18,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF71717A) : const Color(0xFF64748B),
                      ),
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
                      backgroundColor: isDark ? Colors.white : const Color(0xFF09090B),
                      foregroundColor: isDark ? const Color(0xFF09090B) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: auth.isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: isDark ? const Color(0xFF09090B) : Colors.white,
                              strokeWidth: 2,
                            ),
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
                      color: isDark ? const Color(0xFF18181B) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 7, color: Color(0xFF22C55E)),
                        const SizedBox(width: 7),
                        Text(
                          'Sistema Preparado',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
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
