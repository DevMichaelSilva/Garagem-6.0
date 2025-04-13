import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:garagem/services/auth_service.dart';

class ImageService {
  static const String baseUrl = 'http://127.0.0.1:5000/api';
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB

  final ImagePicker _picker = ImagePicker();

  // Selecionar imagem da galeria
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Limita a resolução
        maxHeight: 1920,
        imageQuality: 85  // Compressão inicial
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Erro ao selecionar imagem da galeria: $e');
    }
    return null;
  }

  // Selecionar imagem da câmera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920, // Limita a resolução
        maxHeight: 1920,
        imageQuality: 85  // Compressão inicial
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Erro ao capturar imagem com a câmera: $e');
    }
    return null;
  }

  // Comprimir imagem usando um método mais simples
  Future<File> compressImage(File file) async {
    final fileSize = await file.length();
    
    // Se a imagem já estiver abaixo do limite, retornar sem comprimir
    if (fileSize <= maxImageSizeBytes) {
      return file;
    }
    
    try {
      // Criar arquivo temporário para a imagem comprimida
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Comprimir com qualidade reduzida
      int quality = 80;
      if (fileSize > maxImageSizeBytes * 2) {
        quality = 50;
      } else if (fileSize > maxImageSizeBytes * 1.5) {
        quality = 60;
      }
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      
      if (result != null) {
        return File(result.path);
      }
      
      // Se falhar, retorna o original
      return file;
    } catch (e) {
      print('Erro na compressão de imagem: $e');
      return file;
    }
  }

  // Método alternativo usando Uint8List para evitar problemas de namespace
  Future<String> imageToBase64New(File file) async {
    try {
      // Ler o arquivo como bytes
      final bytes = await file.readAsBytes();
      
      // Determinar o formato da imagem pelo path
      final extension = path_lib.extension(file.path).toLowerCase().replaceAll('.', '');
      final format = extension == 'png' ? 'png' : 'jpeg';
      
      // Codificar para base64
      final base64String = base64Encode(bytes);
      
      return 'data:image/$format;base64,$base64String';
    } catch (e) {
      print('Erro ao converter imagem para base64: $e');
      throw Exception('Falha ao converter imagem');
    }
  }

  Future<Map<String, dynamic>> uploadImageMultipart(int maintenanceId, File imageFile) async {
  try {
    final token = await AuthService().getToken();
    
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }
    
    // Comprimir imagem se necessário
    final compressedImage = await compressImage(imageFile);
    
    // Criar request multipart
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/images/upload/$maintenanceId/multipart'),
    );
    
    // Adicionar headers
    request.headers['Authorization'] = 'Bearer $token';
    
    // Adicionar arquivo
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      compressedImage.path,
    ));
    
    // Enviar request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao fazer upload da imagem');
      } catch (_) {
        throw Exception('Erro ao fazer upload da imagem: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('Erro ao fazer upload de imagem: $e');
    throw Exception('Falha ao enviar imagem: ${e.toString()}');
  }
}
  // Fazer upload de imagem para o backend - Método otimizado
  Future<Map<String, dynamic>> uploadImage(int maintenanceId, File imageFile) async {
    try {
      final token = await AuthService().getToken();
      
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Comprimir imagem
      final compressedImage = await compressImage(imageFile);
      
      // Converter para base64 usando o novo método
      final base64Image = await imageToBase64New(compressedImage);
      
      // Log para debug
      print('Tamanho da string base64: ${base64Image.length} caracteres');
      
      // Enviar para a API
      final response = await http.post(
        Uri.parse('$baseUrl/images/upload/$maintenanceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'image_data': base64Image,
        }),
      );
      
      print('Resposta do servidor: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao fazer upload da imagem');
      }
    } catch (e) {
      print('Erro ao fazer upload de imagem: $e');
      throw Exception('Falha ao enviar imagem: ${e.toString()}');
    }
  }

  // Excluir uma imagem
  Future<bool> deleteImage(int imageId) async {
    try {
      final token = await AuthService().getToken();
      
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final response = await http.delete(
        Uri.parse('$baseUrl/images/$imageId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao excluir imagem: $e');
      throw Exception('Falha ao excluir imagem: ${e.toString()}');
    }
  }
  
  // Extrair ID da imagem a partir da URL
  int? getImageIdFromUrl(String url) {
    try {
      final segments = url.split('/');
      return int.parse(segments.last);
    } catch (e) {
      return null;
    }
  }
}