import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final name = prefs.getString('user_name');
    final role = prefs.getString('user_role');
    final id = prefs.getInt('user_id');

    if (token != null && id != null) {
      _user = UserModel(
        id: id,
        name: name ?? 'Usuario',
        email: prefs.getString('user_email') ?? '',
        role: role ?? 'customer',
        token: token,
      );
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await ApiService.login(email, password);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _user!.token ?? '');
      await prefs.setInt('user_id', _user!.id);
      await prefs.setString('user_name', _user!.name);
      await prefs.setString('user_email', _user!.email);
      await prefs.setString('user_role', _user!.role);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginAsDemo(String role) async {
    _isLoading = false;
    _errorMessage = null;

    if (role == 'driver') {
      _user = UserModel(
        id: 2,
        name: 'Carlos Repartidor Rino',
        email: 'repartidor1@gruporino.pe',
        role: 'driver',
        token: 'demo-token-driver-rino',
      );
    } else {
      _user = UserModel(
        id: 1,
        name: 'Maria Fernandez',
        email: 'cliente@gmail.com',
        role: 'customer',
        token: 'demo-token-customer-rino',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _user!.token ?? '');
    await prefs.setInt('user_id', _user!.id);
    await prefs.setString('user_name', _user!.name);
    await prefs.setString('user_email', _user!.email);
    await prefs.setString('user_role', _user!.role);

    notifyListeners();
    return true;
  }

  void setRole(String role) {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        role: role,
        token: _user!.token,
      );
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
