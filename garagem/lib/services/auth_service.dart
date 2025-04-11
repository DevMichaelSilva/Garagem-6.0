import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // URL base da API - ajuste conforme necessário
  final String _baseUrl = 'http://127.0.0.1:5000/api/auth'; // Para emulador Android
  // final String _baseUrl = 'http://localhost:5000/api/auth'; // Para iOS simulator

  // Chaves para armazenamento local
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Método para fazer login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Salva o token e os dados do usuário
        final prefs = await SharedPreferences.getInstance();
        
        // Assumindo que o backend retorna um token
        if (responseData['token'] != null) {
          await prefs.setString(_tokenKey, responseData['token']);
        }
        
        // Salva os dados do usuário
        await prefs.setString(_userKey, jsonEncode({
          'id': responseData['user_id'],
          'name': responseData['username'],
          'email': responseData['email'],
        }));

        return {
          'success': true,
          ...responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Falha no login',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  // Método para registrar um novo usuário
  Future<Map<String, dynamic>> register(String name, String email, String password, String cpf, String phone, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': name,
          'email': email,
          'password': password,
          'cpf': cpf,
          'phone': phone,
          'confirm_password': confirmPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          ...responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Falha no registro',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  // Método para verificar se o usuário está logado
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Método para obter o token do armazenamento local
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Método para obter informações do usuário atual
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);
      
      if (userString != null) {
        return jsonDecode(userString);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Método para fazer logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Método para verificar se o token é válido
  Future<bool> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
