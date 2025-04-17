import 'dart:convert';
// Remover 'hide User' para permitir o uso do tipo User do Firebase Auth
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Adicionar import http

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Chaves para armazenamento local (podem ser removidas se não usar mais SharedPreferences aqui)
  // static const String _tokenKey = 'auth_token'; // Firebase Auth gerencia o token
  static const String _userProfileKey = 'user_profile_data'; // Para dados adicionais (nome, etc.)
  // Adicionar URL base do backend
  static const String baseUrl = 'http://127.0.0.1:5000/api'; // Ajuste se necessário

  // Método para fazer login com Firebase Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Após login bem-sucedido, sincronizar com o backend
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

  // Método para registrar um novo usuário com Firebase Auth
  // Nota: CPF e Telefone não são tratados pelo Firebase Auth padrão.
  // Você precisará salvar esses dados separadamente (ex: Firestore ou seu backend) após o registro.
  Future<Map<String, dynamic>> register(String name, String email, String password, String cpf, String phone) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Atualizar o nome de exibição do usuário no Firebase Auth
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload(); // Recarregar para obter o nome atualizado

      // Após registro bem-sucedido, sincronizar com o backend, enviando CPF e Telefone
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

  // Método para verificar se o usuário está logado (usando Firebase Auth)
  Future<bool> isLoggedIn() async {
    // Verifica se há um usuário atualmente logado no Firebase Auth
    return _firebaseAuth.currentUser != null;
  }

  // Método para obter o ID Token do Firebase (usado para autenticar no seu backend)
  Future<String?> getToken() async {
    try {
      // Agora 'User' é reconhecido
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        // Retorna o ID Token JWT do Firebase
        return await currentUser.getIdToken(true); // true força a atualização se expirado
      }
      return null;
    } catch (e) {
      print("Error getting Firebase ID token: $e");
      return null;
    }
  }

  // Método para obter informações do usuário atual do Firebase Auth
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      // Agora 'User' é reconhecido
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        // Retorna dados básicos do usuário Firebase
        return {
          'id': currentUser.uid, // ID único do Firebase
          'name': currentUser.displayName ?? '',
          'email': currentUser.email ?? '',
          // Você pode buscar dados adicionais (CPF, Telefone) de onde os salvou
          // 'cpf': await _getAdditionalUserData(currentUser.uid, 'cpf'),
          // 'phone': await _getAdditionalUserData(currentUser.uid, 'phone'),
        };
      }
      // Tenta carregar do SharedPreferences como fallback (se você salvou algo lá)
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

  // Método para fazer logout do Firebase Auth
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      // Limpar dados adicionais salvos localmente, se houver
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // Método privado para sincronizar com o backend
  Future<void> _syncUserWithBackend({String? cpf, String? phone}) async {
    try {
      String? token = await getToken(); // Obter o token Firebase
      if (token == null) {
        print("Sync Error: Token não disponível.");
        return; // Não pode sincronizar sem token
      }

      // Agora 'User' é reconhecido
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        print("Sync Error: Usuário Firebase não encontrado.");
        return;
      }

      // Prepara dados adicionais (se houver)
      Map<String, dynamic> body = {};
      if (cpf != null) body['cpf'] = cpf;
      if (phone != null) body['phone'] = phone;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/sync_user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Envia o token Firebase
        },
        body: jsonEncode(body), // Envia CPF/Telefone se disponíveis
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Usuário sincronizado com backend com sucesso.");
        // Opcional: Salvar/atualizar dados locais se o backend retornar algo útil
        // final responseData = jsonDecode(response.body);
        // await _saveUserProfileDataLocally(responseData['user_id'], currentUser.displayName, currentUser.email, cpf, phone);
      } else {
        print("Erro ao sincronizar usuário com backend: ${response.statusCode} - ${response.body}");
        // Tratar erro de sincronização se necessário
      }
    } catch (e) {
      print("Exceção ao sincronizar usuário com backend: $e");
      // Tratar exceção de rede/etc.
    }
  }

  // --- Métodos auxiliares (Exemplos - precisam ser implementados) ---

  // Exemplo: Salvar dados adicionais (CPF, Telefone) após registro
  // Substitua isso pela sua lógica real (Firestore, API Backend, etc.)
  Future<void> _saveAdditionalUserData(String uid, String name, String cpf, String phone) async {
     print("Simulando salvamento de dados adicionais para UID: $uid");
     // Exemplo com SharedPreferences (NÃO RECOMENDADO PARA PRODUÇÃO - use Firestore ou seu backend)
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString(_userProfileKey, jsonEncode({
       'uid': uid,
       'name': name,
       'cpf': cpf,
       'phone': phone,
     }));
     // Exemplo: Chamada para sua API Flask para salvar/atualizar usuário
     // await http.post(Uri.parse('YOUR_BACKEND_URL/api/users/update_profile'),
     //   headers: {'Content-Type': 'application/json'},
     //   body: jsonEncode({'firebase_uid': uid, 'name': name, 'cpf': cpf, 'phone': phone}),
     // );
  }

  // Exemplo: Buscar dados adicionais
  // Substitua pela sua lógica real
  Future<String?> _getAdditionalUserData(String uid, String field) async {
     print("Simulando busca de dados adicionais ($field) para UID: $uid");
     // Exemplo com SharedPreferences
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

  // Método verifyToken não é mais necessário no frontend,
  // pois getIdToken() já lida com a validade/atualização.
  // O backend verificará o token recebido.
}
