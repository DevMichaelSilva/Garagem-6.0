import 'package:flutter/material.dart';
import 'package:garagem/theme/theme_screen.dart';
import 'package:garagem/services/vehicle_service.dart';
import 'package:garagem/services/maintenance_service.dart';
import 'package:garagem/screens/add_service_screen.dart';
import 'package:garagem/models/service_model.dart';
import 'package:garagem/screens/image_viewer_screen.dart';
import 'package:intl/intl.dart';
import 'package:garagem/screens/service_detail_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({Key? key, required this.vehicle}) : super(key: key);

  @override
  _VehicleDetailScreenState createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  List<ServiceModel> _services = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final services = await _maintenanceService.getMaintenancesByVehicle(widget.vehicle.id!);
      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMaintenance(ServiceModel service) async {
    try {
      if (service.id == null) {
        throw Exception('ID do serviço não encontrado');
      }
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Deseja realmente excluir o serviço "${service.serviceType}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
      
      if (confirmed) {
        await _maintenanceService.deleteMaintenance(service.id!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Serviço excluído com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          
          // Recarregar a lista após exclusão
          _fetchServices();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir serviço: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
    
  @override
  void dispose() {
    // Limpar recursos se necessário
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detalhes do Veículo'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchServices,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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

                      if (result != null && result is ServiceModel) {
                        _fetchServices(); // Recarregar todos os serviços para garantir ordem correta
                      }
                    },
                    style: AppTheme.primaryButtonStyle,
                    child: const Text('REGISTRAR SERVIÇO'),
                  ),
                  const SizedBox(height: 32),
                  _buildServiceList(),
                ],
              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildServiceList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar serviços',
                style: AppTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchServices,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
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

  Widget _buildServiceCard(ServiceModel service) {
  final dateFormatter = DateFormat('dd/MM/yyyy');
  final formattedDate = dateFormatter.format(service.dateTime);
  
  double totalCost = 0;
  if (service.laborCost != null) totalCost += service.laborCost!;
  if (service.partsCost != null) totalCost += service.partsCost!;

  return Dismissible(
    key: Key(service.id?.toString() ?? UniqueKey().toString()),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.red,
      child: const Icon(
        Icons.delete,
        color: Colors.white,
      ),
    ),
    confirmDismiss: (direction) async {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Deseja realmente excluir o serviço "${service.serviceType}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
    },
    onDismissed: (direction) {
      _deleteMaintenance(service);
    },
    child: Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryColorLight.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () {
          // Navegação para a tela de detalhes ao invés de editar
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(service: service),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      service.serviceType,
                      style: AppTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.store,
                    size: 14,
                    color: AppTheme.textColorLight,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      service.workshop,
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textColorLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (service.mechanic != null && service.mechanic!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: AppTheme.textColorLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          service.mechanic!,
                          style: AppTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (totalCost > 0)
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'R\$ ${totalCost.toStringAsFixed(2)}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              if (service.imagePaths.isNotEmpty)
                _buildServiceImagePreview(service.imagePaths),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Deslize para excluir →',
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppTheme.textColorLight.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildServiceImagePreview(List<String> imagePaths) {
    if (imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 4),
        Text(
          'Imagens (${imagePaths.length})',
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              String imagePath = imagePaths[index];
              // Converter URL relativa para absoluta se necessário
              if (imagePath.startsWith('/uploads/')) {
                imagePath = 'http://127.0.0.1:5000$imagePath';
              }
              // Ignorar imagens em base64 para visualização
              if (imagePath.startsWith('data:image/')) {
                return const SizedBox.shrink();
              }
              
              return GestureDetector(
                onTap: () {
                  // Abrir visualizador de imagem em tela cheia
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewerScreen(
                        imageUrls: imagePaths.where((path) => !path.startsWith('data:image/')).map((path) {
                          if (path.startsWith('/uploads/')) {
                            return 'http://127.0.0.1:5000$path';
                          }
                          return path;
                        }).toList(),
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColorLight),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}