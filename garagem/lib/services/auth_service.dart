import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // URL base da API - ajuste conforme necessário
  final String _baseUrl = 'http://localhost:5000/api/auth';

  // Método para fazer login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        ...jsonDecode(response.body),
      };
    } else {
      return {
        'success': false,
        'message': 'Falha no login: ${response.body}',
      };
    }
  }

  // Método para registrar um novo usuário
  Future<Map<String, dynamic>> register(String name, String email, String password, String cpf, String phone, String confirmPassword) async {
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

    if (response.statusCode == 201 || response.statusCode == 200) {
      return {
        'success': true,
        ...jsonDecode(response.body),
      };
    } else {
      return {
        'success': false,
        'message': 'Falha no registro: ${response.body}',
      };
    }
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
