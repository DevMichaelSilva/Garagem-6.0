import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagem/services/auth_service.dart';

class Vehicle {
  final int? id;
  final String type;
  final String brand;
  final String model;
  final int year;
  final String licensePlate;
  final String? color;

  Vehicle({
    this.id,
    required this.type,
    required this.brand, 
    required this.model,
    required this.year,
    required this.licensePlate,
    this.color,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      type: json['type'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      licensePlate: json['license_plate'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'brand': brand,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'color': color,
    };
  }

  String get typeDisplay {
    switch (type.toLowerCase()) {
      case 'carro':
        return 'Carro';
      case 'moto':
        return 'Moto';
      case 'caminhao':
        return 'Caminhão';
      default:
        return 'Outro';
    }
  }

  String getIconData() {
    switch (type.toLowerCase()) {
      case 'carro':
        return 'directions_car';
      case 'moto':
        return 'motorcycle';
      case 'caminhao':
        return 'local_shipping';
      default:
        return 'commute';
    }
  }
}

class VehicleService {
  static const String baseUrl = 'http://127.0.0.1:5000/api';  // Para emulador Android
  // static const String baseUrl = 'http://localhost:5000/api';  // Para iOS simulator

  Future<Map<String, dynamic>> getVehicles() async {
    try {
      final token = await AuthService().getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Usuário não autenticado',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<Vehicle> vehicles = (data['vehicles'] as List)
            .map((vehicleJson) => Vehicle.fromJson(vehicleJson))
            .toList();

        return {
          'success': true,
          'vehicles': vehicles,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao buscar veículos',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente mais tarde.',
      };
    }
  }
  
  Future<bool> deleteVehicle(int vehicleId) async {
  try {
    final token = await AuthService().getToken();
    
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/vehicles/$vehicleId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Se a resposta for 200, é sucesso mesmo que o corpo não seja o esperado
      return true;
    } else {
      // Tentamos extrair a mensagem de erro, mas com tratamento de exceção
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erro ao excluir veículo');
      } catch (e) {
        throw Exception('Erro ao excluir veículo. Status code: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('Erro em deleteVehicle: $e');
    throw Exception('Erro ao excluir veículo: ${e.toString()}');
  }
}

  Future<Map<String, dynamic>> addVehicle(Vehicle vehicle) async {
    try {
      final token = await AuthService().getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Usuário não autenticado',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(vehicle.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Veículo adicionado com sucesso!',
          'vehicle': Vehicle.fromJson(data['vehicle']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao adicionar veículo',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente mais tarde.',
      };
    }
  }
}