import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagem/services/auth_service.dart';
import 'package:garagem/models/service_model.dart';
import 'package:intl/intl.dart';

class MaintenanceService {
  static const String baseUrl = 'http://127.0.0.1:5000/api';  // Para emulador Android
  // static const String baseUrl = 'http://localhost:5000/api';  // Para iOS simulator
  // static const String baseUrl = 'http://127.0.0.1:5000/api';  // Para desenvolvimento web

  Future<List<ServiceModel>> getMaintenancesByVehicle(int vehicleId) async {
    try {
      final token = await AuthService().getToken();
      
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/maintenances/vehicle/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> maintenancesJson = data['maintenances'];
        return maintenancesJson.map((json) {
          return ServiceModel(
            id: json['id'],
            vehicleId: vehicleId,
            serviceType: json['service_type'],
            workshop: json['workshop'],
            mechanic: json['mechanic'],
            laborWarrantyDate: json['labor_warranty_date'],
            laborCost: json['labor_cost'] != null ? double.parse(json['labor_cost'].toString()) : null,
            parts: json['parts'],
            partsStore: json['parts_store'],
            partsWarrantyDate: json['parts_warranty_date'],
            partsCost: json['parts_cost'] != null ? double.parse(json['parts_cost'].toString()) : null,
            dateTime: DateTime.parse(json['service_date']),
            imagePaths: List<String>.from(json['images'] ?? []),
          );
        }).toList();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erro ao buscar manutenções');
      }
    } catch (e) {
      print('Erro em getMaintenancesByVehicle: $e');
      throw Exception('Erro ao carregar manutenções: ${e.toString()}');
    }
  }

  Future<ServiceModel> addMaintenance(ServiceModel service) async {
    try {
      final token = await AuthService().getToken();
      
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      // Data preparation remains largely the same.
      // 'images' will now contain Firebase Storage URLs.
      final Map<String, dynamic> data = {
        'vehicle_id': service.vehicleId,
        'service_type': service.serviceType,
        'workshop': service.workshop,
        'mechanic': service.mechanic ?? '',
        'labor_warranty_date': service.laborWarrantyDate ?? '',
        'labor_cost': service.laborCost,
        'parts': service.parts ?? '',
        'parts_store': service.partsStore ?? '',
        'parts_warranty_date': service.partsWarrantyDate ?? '',
        'parts_cost': service.partsCost,
        'service_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(service.dateTime),
        'images': service.imagePaths, // This now contains URLs
      };

      print('Enviando dados para API (com URLs): $data'); // Log updated data

      final response = await http.post(
        Uri.parse('$baseUrl/maintenances/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final maintenanceData = responseData['maintenance'];
        // Parsing the response remains the same
        return ServiceModel(
          id: maintenanceData['id'],
          vehicleId: maintenanceData['vehicle_id'],
          serviceType: maintenanceData['service_type'],
          workshop: maintenanceData['workshop'],
          mechanic: maintenanceData['mechanic'],
          laborWarrantyDate: maintenanceData['labor_warranty_date'],
          laborCost: maintenanceData['labor_cost'] != null
              ? double.parse(maintenanceData['labor_cost'].toString())
              : null,
          parts: maintenanceData['parts'],
          partsStore: maintenanceData['parts_store'],
          partsWarrantyDate: maintenanceData['parts_warranty_date'],
          partsCost: maintenanceData['parts_cost'] != null
              ? double.parse(maintenanceData['parts_cost'].toString())
              : null,
          dateTime: DateTime.parse(maintenanceData['service_date']),
          imagePaths: List<String>.from(maintenanceData['images'] ?? []), // Expecting URLs back
        );
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Erro ao adicionar manutenção');
      }
    } catch (e) {
      print('Erro em addMaintenance: $e');
      throw Exception('Erro ao registrar manutenção: ${e.toString()}');
    }
  }

  Future<bool> deleteMaintenance(int maintenanceId) async {
    try {
      final token = await AuthService().getToken();
      
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/maintenances/$maintenanceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erro ao excluir manutenção');
      }
    } catch (e) {
      print('Erro em deleteMaintenance: $e');
      throw Exception('Erro ao excluir manutenção: ${e.toString()}');
    }
  }

  Future<ServiceModel> getMaintenanceById(int maintenanceId) async {
    try {
      final token = await AuthService().getToken();
      
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/maintenances/$maintenanceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final json = data['maintenance'];
        return ServiceModel(
          id: json['id'],
          vehicleId: json['vehicle_id'],
          serviceType: json['service_type'],
          workshop: json['workshop'],
          mechanic: json['mechanic'],
          laborWarrantyDate: json['labor_warranty_date'],
          laborCost: json['labor_cost'] != null ? double.parse(json['labor_cost'].toString()) : null,
          parts: json['parts'],
          partsStore: json['parts_store'],
          partsWarrantyDate: json['parts_warranty_date'],
          partsCost: json['parts_cost'] != null ? double.parse(json['parts_cost'].toString()) : null,
          dateTime: DateTime.parse(json['service_date']),
          imagePaths: List<String>.from(json['images'] ?? []),
        );
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erro ao buscar detalhes da manutenção');
      }
    } catch (e) {
      print('Erro em getMaintenanceById: $e');
      throw Exception('Erro ao carregar detalhes da manutenção: ${e.toString()}');
    }
  }

  Future<ServiceModel> updateMaintenance(ServiceModel service) async {
    try {
      if (service.id == null) {
        throw Exception('ID da manutenção não fornecido');
      }

      final token = await AuthService().getToken();
      
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final Map<String, dynamic> data = {
        'service_type': service.serviceType,
        'workshop': service.workshop,
        'mechanic': service.mechanic ?? '',
        'labor_warranty_date': service.laborWarrantyDate ?? '',
        'labor_cost': service.laborCost,
        'parts': service.parts ?? '',
        'parts_store': service.partsStore ?? '',
        'parts_warranty_date': service.partsWarrantyDate ?? '',
        'parts_cost': service.partsCost,
        'service_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(service.dateTime),
        'images': service.imagePaths ?? [],
      };

      print('Enviando dados para atualização: $data');

      final response = await http.put(
        Uri.parse('$baseUrl/maintenances/${service.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Recarregar os dados atualizados do serviço
        return await getMaintenanceById(service.id!);
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Erro ao atualizar manutenção');
      }
    } catch (e) {
      print('Erro em updateMaintenance: $e');
      throw Exception('Erro ao atualizar manutenção: ${e.toString()}');
    }
  }
}