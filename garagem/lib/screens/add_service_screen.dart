import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garagem/theme/theme_screen.dart';

class AddServiceScreen extends StatefulWidget {
  final int vehicleId; // ID do veículo para associar o serviço

  const AddServiceScreen({Key? key, required this.vehicleId}) : super(key: key);

  @override
  _AddServiceScreenState createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _workshopController = TextEditingController();
  final TextEditingController _mechanicController = TextEditingController();
  final TextEditingController _laborWarrantyController = TextEditingController();
  final TextEditingController _laborCostController = TextEditingController();
  final TextEditingController _partsController = TextEditingController();
  final TextEditingController _partsStoreController = TextEditingController();
  final TextEditingController _partsWarrantyController = TextEditingController();
  final TextEditingController _partsCostController = TextEditingController();
  List<String> _imagePaths = [];

  DateTime _currentDateTime = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _serviceController.dispose();
    _workshopController.dispose();
    _mechanicController.dispose();
    _laborWarrantyController.dispose();
    _laborCostController.dispose();
    _partsController.dispose();
    _partsStoreController.dispose();
    _partsWarrantyController.dispose();
    _partsCostController.dispose();
    super.dispose();
  }

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Mock API call (substituir pelo registro real do serviço no backend)
    await Future.delayed(const Duration(seconds: 2));

    // Sucesso na submissão
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Serviço registrado com sucesso!')),
    );

    Navigator.pop(context, true); // Retorna para a tela anterior
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Registrar Serviço'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDateTimeField(),
                const SizedBox(height: 16),
                _buildTextField(_serviceController, 'Serviço Executado', true),
                const SizedBox(height: 16),
                _buildTextField(_workshopController, 'Oficina', true),
                const SizedBox(height: 16),
                _buildTextField(_mechanicController, 'Mecânico Responsável'),
                const SizedBox(height: 16),
                _buildTextField(_laborWarrantyController, 'Garantia da Mão de Obra (Data)', false, TextInputType.datetime),
                const SizedBox(height: 16),
                _buildTextField(_laborCostController, 'Valor Cobrado (R\$)', false, TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(_partsController, 'Peças Trocadas'),
                const SizedBox(height: 16),
                _buildTextField(_partsStoreController, 'Loja das Peças'),
                const SizedBox(height: 16),
                _buildTextField(_partsWarrantyController, 'Garantia das Peças (Data)', false, TextInputType.datetime),
                const SizedBox(height: 16),
                _buildTextField(_partsCostController, 'Valor das Peças (R\$)', false, TextInputType.number),
                _buildImageUpload(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitService,
                  style: AppTheme.primaryButtonStyle,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('REGISTRAR SERVIÇO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeField() {
    return TextFormField(
      initialValue: '${_currentDateTime.day}/${_currentDateTime.month}/${_currentDateTime.year} ${_currentDateTime.hour}:${_currentDateTime.minute}',
      readOnly: true,
      decoration: AppTheme.inputDecoration('Data e Hora', hintText: 'Gerado automaticamente'),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, [
    bool isRequired = false,
    TextInputType inputType = TextInputType.text,
  ]) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: AppTheme.inputDecoration(label),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Este campo é obrigatório';
        }
        return null;
      },
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imagens (opcional)', style: AppTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._imagePaths.map((path) => _buildImageThumbnail(path)),
            if (_imagePaths.length < 4)
              GestureDetector(
                onTap: () {
                  // Implementar lógica para selecionar imagens
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColorLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: AppTheme.primaryColor),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(String path) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(path), // Substituir pelo carregamento correto da imagem
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _imagePaths.remove(path);
              });
            },
            child: const Icon(Icons.close, color: Colors.red, size: 24),
          ),
        ),
      ],
    );
  }
}