import 'package:flutter/material.dart';
import 'package:garagem/theme/theme_screen.dart';
import 'package:garagem/models/service_model.dart';
import 'package:garagem/screens/image_viewer_screen.dart';
import 'package:intl/intl.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;

  const ServiceDetailScreen({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Formatadores para data e valores monetários
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    // Calcular o custo total
    double totalCost = 0;
    if (service.laborCost != null) totalCost += service.laborCost!;
    if (service.partsCost != null) totalCost += service.partsCost!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detalhes do Serviço'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar',
            onPressed: () {
              // Implementação futura de compartilhamento
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Função de compartilhamento em desenvolvimento'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com tipo de serviço e data
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.build,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.serviceType,
                                style: AppTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppTheme.textColorLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${dateFormatter.format(service.dateTime)} às ${timeFormatter.format(service.dateTime)}',
                                    style: AppTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (totalCost > 0) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Custo total:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currencyFormatter.format(totalCost),
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informações do local de serviço
            _buildSectionTitle('Local de Serviço'),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      icon: Icons.store,
                      title: 'Oficina',
                      value: service.workshop,
                    ),
                    if (service.mechanic != null && service.mechanic!.isNotEmpty)
                      _buildDetailItem(
                        icon: Icons.person,
                        title: 'Mecânico',
                        value: service.mechanic!,
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informações da mão de obra
            _buildSectionTitle('Mão de Obra'),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (service.laborCost != null)
                      _buildDetailItem(
                        icon: Icons.attach_money,
                        title: 'Valor',
                        value: currencyFormatter.format(service.laborCost!),
                      ),
                    if (service.laborWarrantyDate != null && service.laborWarrantyDate!.isNotEmpty)
                      _buildDetailItem(
                        icon: Icons.verified_user,
                        title: 'Garantia até',
                        value: service.laborWarrantyDate!,
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informações sobre peças
            if ((service.parts != null && service.parts!.isNotEmpty) ||
                (service.partsStore != null && service.partsStore!.isNotEmpty) ||
                (service.partsCost != null) ||
                (service.partsWarrantyDate != null && service.partsWarrantyDate!.isNotEmpty)) ...[
              _buildSectionTitle('Peças'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (service.parts != null && service.parts!.isNotEmpty)
                        _buildDetailItem(
                          icon: Icons.settings,
                          title: 'Peças Utilizadas',
                          value: service.parts!,
                        ),
                      if (service.partsStore != null && service.partsStore!.isNotEmpty)
                        _buildDetailItem(
                          icon: Icons.storefront,
                          title: 'Loja',
                          value: service.partsStore!,
                        ),
                      if (service.partsCost != null)
                        _buildDetailItem(
                          icon: Icons.attach_money,
                          title: 'Valor das Peças',
                          value: currencyFormatter.format(service.partsCost!),
                        ),
                      if (service.partsWarrantyDate != null && service.partsWarrantyDate!.isNotEmpty)
                        _buildDetailItem(
                          icon: Icons.verified_user,
                          title: 'Garantia das Peças até',
                          value: service.partsWarrantyDate!,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Imagens
            if (service.imagePaths.isNotEmpty)
              _buildImagesSection(context, service.imagePaths),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColorLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textColorLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context, List<String> imagePaths) {
    // Filtrar imagens que não são base64 (apenas URLs)
    final List<String> displayableImages = imagePaths
        .where((path) => !path.startsWith('data:image/'))
        .toList();

    if (displayableImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Imagens'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: displayableImages.length,
          itemBuilder: (context, index) {
            String imagePath = displayableImages[index];
            // Converter URL relativa para absoluta se necessário
            if (imagePath.startsWith('/uploads/')) {
              imagePath = 'http://10.0.2.2:5000$imagePath';
            }

            return GestureDetector(
              onTap: () {
                // Abrir visualizador de imagem em tela cheia
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerScreen(
                      imageUrls: displayableImages.map((path) {
                        if (path.startsWith('/uploads/')) {
                          return 'http://10.0.2.2:5000$path';
                        }
                        return path;
                      }).toList(),
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColorLight.withOpacity(0.3),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
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
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}