import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garagem/services/vehicle_service.dart';
import 'package:garagem/theme/theme_screen.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({Key? key}) : super(key: key);

  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _colorController = TextEditingController();
  String _selectedType = 'carro';
  
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'value': 'carro', 'label': 'Carro', 'icon': Icons.directions_car},
    {'value': 'moto', 'label': 'Moto', 'icon': Icons.motorcycle},
    {'value': 'caminhao', 'label': 'Caminhão', 'icon': Icons.local_shipping},
  ];

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final vehicle = Vehicle(
      type: _selectedType,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      licensePlate: _licensePlateController.text.trim().toUpperCase(),
      color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
    );

    try {
      final result = await VehicleService().addVehicle(vehicle);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veículo adicionado com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        Navigator.pop(context, true);  // Retorna true para atualizar a lista de veículos
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao adicionar veículo. Tente novamente mais tarde.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Adicionar Veículo'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                  _buildFormFields(),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Veículo',
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColorLight.withOpacity(0.3)),
          ),
          child: Row(
            children: _vehicleTypes.map((type) {
              final bool isSelected = _selectedType == type['value'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type['value'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryColor 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'],
                          color: isSelected 
                              ? Colors.white 
                              : AppTheme.primaryColorLight,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type['label'],
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.white 
                                : AppTheme.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _brandController,
          decoration: AppTheme.inputDecoration('Marca', hintText: 'Ex: Ford, Honda, Volvo'),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, informe a marca do veículo';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _modelController,
          decoration: AppTheme.inputDecoration('Modelo', hintText: 'Ex: Civic, Ka, FH'),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, informe o modelo do veículo';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _yearController,
          decoration: AppTheme.inputDecoration('Ano', hintText: 'Ex: 2022'),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, informe o ano do veículo';
            }
            
            final year = int.tryParse(value);
            if (year == null) {
              return 'Ano inválido';
            }
            
            final currentYear = DateTime.now().year;
            if (year < 1900 || year > currentYear + 1) {
              return 'Ano deve estar entre 1900 e ${currentYear + 1}';
            }
            
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _licensePlateController,
          decoration: AppTheme.inputDecoration('Placa', hintText: 'Ex: ABC1234 ou ABC1D23'),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(7),
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, informe a placa do veículo';
            }
            
            if (value.length < 7) {
              return 'Placa deve ter 7 caracteres';
            }
            
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _colorController,
          decoration: AppTheme.inputDecoration('Cor (opcional)', hintText: 'Ex: Prata, Vermelho, Azul'),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveVehicle,
      style: AppTheme.primaryButtonStyle,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('SALVAR VEÍCULO'),
    );
  }
}