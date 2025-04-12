import 'package:flutter/material.dart';
import 'package:garagem/services/vehicle_service.dart';
import 'package:garagem/services/auth_service.dart';
import 'package:garagem/theme/theme_screen.dart';
import 'package:garagem/screens/add_vehicle_screen.dart';
import 'package:garagem/screens/login_screen.dart';
import 'package:garagem/screens/vehicle_detail_screen.dart'; // Adicionando a importação da VehicleDetailScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VehicleService _vehicleService = VehicleService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Vehicle> _vehicles = [];
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchVehicles();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await AuthService().getCurrentUser();
    if (userInfo.isNotEmpty) {
      setState(() {
        _userName = userInfo['name'] ?? '';
      });
    }
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _vehicleService.getVehicles();

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _vehicles = result['vehicles'];
      } else {
        _errorMessage = result['message'];
      }
    });
  }

  Future<void> _logout() async {
    await AuthService().logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Meus Veículos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchVehicles,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
          
          if (result == true) {
            _fetchVehicles();
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchVehicles,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return _buildEmptyState();
    }

    return _buildVehicleList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 80,
            color: AppTheme.primaryColorLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Você ainda não possui veículos',
            style: AppTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione seu primeiro veículo tocando no\nbotão "+" abaixo.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textColorLight),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList() {
    return RefreshIndicator(
      onRefresh: _fetchVehicles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehicles.length + 1, // +1 para o cabeçalho
        itemBuilder: (context, index) {
          if (index == 0) {
            // Cabeçalho
            return _buildHeader();
          }
          
          // Itens da lista de veículos
          final vehicle = _vehicles[index - 1];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $_userName',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Aqui estão seus veículos cadastrados:',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final IconData iconData;
    
    switch (vehicle.getIconData()) {
      case 'directions_car':
        iconData = Icons.directions_car;
        break;
      case 'motorcycle':
        iconData = Icons.motorcycle;
        break;
      case 'local_shipping':
        iconData = Icons.local_shipping;
        break;
      default:
        iconData = Icons.commute;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryColorLight.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navegar para a tela de detalhes do veículo
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailScreen(vehicle: vehicle),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: AppTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppTheme.textColorLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${vehicle.year}',
                          style: AppTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.label,
                          size: 14,
                          color: AppTheme.textColorLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.typeDisplay,
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 14,
                          color: AppTheme.textColorLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.licensePlate,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (vehicle.color != null && vehicle.color!.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.color_lens,
                            size: 14,
                            color: AppTheme.textColorLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.color!,
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.primaryColorLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}