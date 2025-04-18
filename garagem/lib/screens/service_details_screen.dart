import 'package:flutter/material.dart';
import 'package:garagem/models/service_model.dart';
import 'package:garagem/theme/theme_screen.dart';
import 'package:intl/intl.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final ServiceModel service;

  const ServiceDetailsScreen({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final warrantyDateFormatter = DateFormat('dd/MM/yyyy');
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detalhes do Serviço'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(Icons.build, 'Tipo de Serviço', service.serviceType),
            _buildDetailItem(Icons.store, 'Oficina', service.workshop),
            if (service.mechanic != null && service.mechanic!.isNotEmpty)
              _buildDetailItem(Icons.person, 'Mecânico', service.mechanic!),
            _buildDetailItem(Icons.calendar_today, 'Data do Serviço', dateFormatter.format(service.dateTime)),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            Text('Mão de Obra', style: AppTheme.titleSmall),
            const SizedBox(height: 8),
            if (service.laborCost != null && service.laborCost! > 0)
              _buildDetailItem(Icons.attach_money, 'Custo', currencyFormatter.format(service.laborCost)),
            if (service.laborWarrantyDate != null && service.laborWarrantyDate!.isNotEmpty)
              _buildDetailItem(Icons.shield, 'Garantia até', service.laborWarrantyDate!), // Assumindo que já está formatado DD/MM/YYYY

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            Text('Peças', style: AppTheme.titleSmall),
            const SizedBox(height: 8),
            if (service.parts != null && service.parts!.isNotEmpty)
              _buildDetailItem(Icons.settings, 'Peças Utilizadas', service.parts!),
            if (service.partsStore != null && service.partsStore!.isNotEmpty)
              _buildDetailItem(Icons.storefront, 'Loja das Peças', service.partsStore!),
            if (service.partsCost != null && service.partsCost! > 0)
              _buildDetailItem(Icons.attach_money, 'Custo', currencyFormatter.format(service.partsCost)),
            if (service.partsWarrantyDate != null && service.partsWarrantyDate!.isNotEmpty)
              _buildDetailItem(Icons.shield, 'Garantia até', service.partsWarrantyDate!), // Assumindo que já está formatado DD/MM/YYYY

            const SizedBox(height: 16),
            if (service.imagePaths.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text('Imagens', style: AppTheme.titleSmall),
              const SizedBox(height: 12),
              _buildImageGallery(context, service.imagePaths),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColorLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textColorLight)),
                const SizedBox(height: 2),
                Text(value, style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context, List<String> imageUrls) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: imageUrls.map((url) {
        return GestureDetector(
          onTap: () {
            // Opcional: Abrir imagem em tela cheia
            Navigator.push(context, MaterialPageRoute(builder: (_) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: InteractiveViewer( // Permite zoom
                    panEnabled: false, // Desabilita pan para focar no zoom
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
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
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 40, color: AppTheme.errorColor),
                    ),
                  ),
                ),
              );
            }));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              url,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: AppTheme.errorColor),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
