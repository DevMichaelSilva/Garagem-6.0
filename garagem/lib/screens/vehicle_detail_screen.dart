import 'package:flutter/material.dart';
import 'package:garagem/theme/theme_screen.dart';
import 'package:garagem/services/vehicle_service.dart';
import 'package:garagem/screens/add_service_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({Key? key, required this.vehicle}) : super(key: key);

  @override
  _VehicleDetailScreenState createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
    });

    // Mock data for services (replace with API call in the future)
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _services = [
        {
          'id': 1,
          'type': 'Troca de Óleo',
          'description': 'Troca de óleo e revisão geral',
          'date': DateTime.now().subtract(const Duration(days: 5)),
          'cost': 150.0,
        },
        {
          'id': 2,
          'type': 'Alinhamento',
          'description': 'Alinhamento e balanceamento',
          'date': DateTime.now().subtract(const Duration(days: 30)),
          'cost': 80.0,
        },
      ];
      _isLoading = false;
    });
  }

  void _deleteVehicle() {
    // Dialog para confirmação de exclusão
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Veículo'),
          content: const Text('Tem certeza de que deseja excluir este veículo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Chamada para API para excluir (a implementar)
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Retorna para a tela anterior
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detalhes do Veículo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildVehicleCard(vehicle),
                const SizedBox(height: 24),
                ElevatedButton(
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServiceScreen(vehicleId: widget.vehicle.id!),
      ),
    );

    if (result == true) {
      _fetchServices(); // Atualiza a lista de serviços após registrar um novo
    }
  },
  style: AppTheme.primaryButtonStyle,
  child: const Text('Registrar Serviço'),
),
                const SizedBox(height: 32),
                _buildServiceList(),
              ],
            ),
          ),
        ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryColorLight.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Transferir funcionalidade a ser implementada
                  },
                  icon: const Icon(Icons.swap_horiz, color: AppTheme.primaryColor),
                  label: const Text(
                    'Transferir Veículo',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
                TextButton.icon(
                  onPressed: _deleteVehicle,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Excluir Veículo',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_services.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(
              Icons.history,
              size: 80,
              color: AppTheme.primaryColorLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum serviço registrado',
              style: AppTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Registre o primeiro serviço utilizando o\nbotão acima.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textColorLight),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serviços Registrados',
          style: AppTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final service = _services[index];
            return _buildServiceCard(service);
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final date = service['date'] as DateTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryColorLight.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service['type'],
              style: AppTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              service['description'],
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textColorLight),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppTheme.textColorLight),
                    const SizedBox(width: 4),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 14, color: AppTheme.textColorLight),
                    const SizedBox(width: 4),
                    Text(
                      service['cost'].toStringAsFixed(2),
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}