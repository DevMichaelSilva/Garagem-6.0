import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Para formatar data

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static const String _userProfileKey = 'user_profile_data'; // Manter para dados locais
  static const String baseUrl = 'http://127.0.0.1:5000/api'; // Ajuste se necessário

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _syncUserWithBackend(); // Chama a sincronização

      return {
        'success': true,
        'user': userCredential.user, // Retorna o objeto User do Firebase
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Falha no login.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Email ou senha inválidos.';
      } else if (e.code == 'invalid-email') {
        message = 'Formato de email inválido.';
      }
      print("Firebase Login Error: ${e.code} - ${e.message}");
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print("General Login Error: $e");
      return {
        'success': false,
        'message': 'Erro desconhecido. Tente novamente.',
      };
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String cpf, String phone) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload(); // Recarregar para obter o nome atualizado

      await _syncUserWithBackend(cpf: cpf, phone: phone); // Chama a sincronização com dados extras

      return {
        'success': true,
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Falha no registro.';
      if (e.code == 'weak-password') {
        message = 'A senha fornecida é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Este email já está em uso.';
      } else if (e.code == 'invalid-email') {
        message = 'Formato de email inválido.';
      }
      print("Firebase Register Error: ${e.code} - ${e.message}");
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print("General Register Error: $e");
      return {
        'success': false,
        'message': 'Erro desconhecido. Tente novamente.',
      };
    }
  }

  Future<bool> isLoggedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  Future<String?> getToken() async {
    try {
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        return await currentUser.getIdToken(true); // true força a atualização se expirado
      }
      return null;
    } catch (e) {
      print("Error getting Firebase ID token: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final userString = prefs.getString(_userProfileKey);
        Map<String, dynamic> localData = {};
        if (userString != null) {
          localData = jsonDecode(userString);
          if (localData['id'] != currentUser.uid) {
            localData = {}; // Limpa se for de outro usuário
          }
        }

        return {
          'id': currentUser.uid,
          'name': currentUser.displayName ?? localData['name'] ?? '', // Fallback
          'email': currentUser.email ?? localData['email'] ?? '', // Fallback
          'tier': localData['tier'] ?? 'Free', // Pega do local ou default
          'subscription_end_date': localData['subscription_end_date'], // Pega do local
        };
      }
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userProfileKey);
      if (userString != null) {
        return jsonDecode(userString);
      }

      return {};
    } catch (e) {
      print("Error getting current user data: $e");
      return {};
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  Future<void> _syncUserWithBackend({String? cpf, String? phone}) async {
    try {
      String? token = await getToken();
      if (token == null) {
        print("Sync Error: Token não disponível.");
        return;
      }

      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        print("Sync Error: Usuário Firebase não encontrado.");
        return;
      }

      Map<String, dynamic> body = {};
      if (cpf != null) body['cpf'] = cpf;
      if (phone != null) body['phone'] = phone;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/sync_user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Envia o token Firebase
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Usuário sincronizado com backend com sucesso.");
        final responseData = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userProfileKey, jsonEncode({
          'id': currentUser.uid, // Usar UID do Firebase como ID local
          'name': currentUser.displayName ?? '',
          'email': currentUser.email ?? '',
          'tier': responseData['tier'], // Salvar tier do backend
          'subscription_end_date': responseData['subscription_end_date'], // Salvar data do backend
          'cpf': cpf ?? (await _getAdditionalUserData(currentUser.uid, 'cpf')),
          'phone': phone ?? (await _getAdditionalUserData(currentUser.uid, 'phone')),
        }));

      } else {
        print("Erro ao sincronizar usuário com backend: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exceção ao sincronizar usuário com backend: $e");
    }
  }

  Future<void> _saveAdditionalUserData(String uid, String name, String cpf, String phone) async {
     print("Simulando salvamento de dados adicionais para UID: $uid");
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString(_userProfileKey, jsonEncode({
       'uid': uid,
       'name': name,
       'cpf': cpf,
       'phone': phone,
     }));
  }

  Future<String?> _getAdditionalUserData(String uid, String field) async {
     print("Simulando busca de dados adicionais ($field) para UID: $uid");
     final prefs = await SharedPreferences.getInstance();
     final userString = prefs.getString(_userProfileKey);
     if (userString != null) {
       final data = jsonDecode(userString);
       if (data['uid'] == uid) {
         return data[field];
       }
     }
     return null;
  }
}
