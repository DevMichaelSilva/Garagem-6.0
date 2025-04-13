import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garagem/theme/theme_screen.dart';
import 'package:garagem/models/service_model.dart';
import 'package:garagem/services/maintenance_service.dart';
import 'package:garagem/services/image_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class AddServiceScreen extends StatefulWidget {
  final int vehicleId;
  final ServiceModel? service; // Para edição de serviço existente

  const AddServiceScreen({Key? key, required this.vehicleId, this.service}) : super(key: key);

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
  
  // Imagens locais sendo manipuladas
  List<File> _selectedImages = [];
  // URLs de imagens já carregadas (em caso de edição)
  List<String> _uploadedImageUrls = [];
  
  final ImageService _imageService = ImageService();
  final MaintenanceService _maintenanceService = MaintenanceService();

  DateTime _currentDateTime = DateTime.now();
  bool _isSubmitting = false;
  bool _isUploadingImages = false;
  String? _errorMessage;
  int? _serviceId; // ID do serviço em caso de edição

  // Regex para validação de data DD/MM/YYYY
  final RegExp _dateRegex = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
  
  @override
  void initState() {
    super.initState();
    // Se for edição, preencher os campos
    if (widget.service != null) {
      _serviceId = widget.service!.id;
      _serviceController.text = widget.service!.serviceType;
      _workshopController.text = widget.service!.workshop;
      _mechanicController.text = widget.service!.mechanic ?? '';
      _laborWarrantyController.text = widget.service!.laborWarrantyDate ?? '';
      _laborCostController.text = widget.service!.laborCost != null ? widget.service!.laborCost.toString() : '';
      _partsController.text = widget.service!.parts ?? '';
      _partsStoreController.text = widget.service!.partsStore ?? '';
      _partsWarrantyController.text = widget.service!.partsWarrantyDate ?? '';
      _partsCostController.text = widget.service!.partsCost != null ? widget.service!.partsCost.toString() : '';
      _currentDateTime = widget.service!.dateTime;
      
      // Adicionar imagens já existentes
      if (widget.service!.imagePaths.isNotEmpty) {
        _uploadedImageUrls = List.from(widget.service!.imagePaths);
      }
    }
  }
  
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

  // Função para validar data no formato DD/MM/YYYY
  bool _isValidDate(String date) {
    if (!_dateRegex.hasMatch(date)) {
      return false;
    }

    final match = _dateRegex.firstMatch(date)!;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);

    if (month < 1 || month > 12) {
      return false;
    }

    final daysInMonth = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (day < 1 || day > daysInMonth[month]) {
      return false;
    }

    // Verificar se é uma data no futuro (para garantia)
    final inputDate = DateTime(year, month, day);
    final now = DateTime.now();
    return inputDate.isAfter(now);
  }

  // Função para converter string para double
  double? _parseMoneyValue(String value) {
    if (value.isEmpty) return null;
    try {
      final cleanValue = value.replaceAll(RegExp(r'[^\d,.]'), '');
      return double.parse(cleanValue.replaceAll(',', '.'));
    } catch (e) {
      return null;
    }
  }
  
  // Selecionar imagem da galeria ou câmera
  Future<void> _selectImage() async {
    if (_selectedImages.length + _uploadedImageUrls.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo de 4 imagens permitido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final imageSource = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeria'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Câmera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (imageSource == null) return;

      // Selecionar imagem
      File? imageFile;
      if (imageSource == ImageSource.gallery) {
        imageFile = await _imageService.pickImageFromGallery();
      } else {
        imageFile = await _imageService.pickImageFromCamera();
      }

      if (imageFile == null) return;

      // Processar imagem (comprimir se necessário)
      setState(() {
        _selectedImages.add(imageFile!); // Adicionamos ! para garantir não-nulidade
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem adicionada com sucesso'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar imagem: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Remover imagem
  void _removeImage(int index) {
    setState(() {
      if (index < _selectedImages.length) {
        _selectedImages.removeAt(index);
      } else {
        // Se for uma imagem já enviada, remove da lista de URLs
        final urlIndex = index - _selectedImages.length;
        if (urlIndex >= 0 && urlIndex < _uploadedImageUrls.length) {
          _uploadedImageUrls.removeAt(urlIndex);
        }
      }
    });
  }

  // Fazer upload de imagens e salvar serviço
  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrija os campos destacados antes de prosseguir.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Lista de URLs das imagens (já existentes + novas)
      List<String> allImageUrls = List.from(_uploadedImageUrls);
      
      // Se não houver serviço criado ainda, enviar serviço primeiro sem imagens
      if (_serviceId == null && _selectedImages.isNotEmpty) {
        // Criar objeto de serviço sem imagens
        final initialService = ServiceModel(
          vehicleId: widget.vehicleId,
          serviceType: _serviceController.text.trim(),
          workshop: _workshopController.text.trim(),
          mechanic: _mechanicController.text.trim(),
          laborWarrantyDate: _laborWarrantyController.text.trim(),
          laborCost: _parseMoneyValue(_laborCostController.text),
          parts: _partsController.text.trim(),
          partsStore: _partsStoreController.text.trim(),
          partsWarrantyDate: _partsWarrantyController.text.trim(),
          partsCost: _parseMoneyValue(_partsCostController.text),
          dateTime: _currentDateTime,
          imagePaths: [],  // Inicialmente sem imagens
        );

        // Salvar serviço
        final savedService = await _maintenanceService.addMaintenance(initialService);
        _serviceId = savedService.id; // Armazenar ID para upload de imagens
      }

      // Fazer upload das imagens selecionadas, se houver
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
        });
        
        for (var imageFile in _selectedImages) {
          try {
            if (_serviceId != null) {
              // Atualizar para usar um método existente em ImageService
              // Por exemplo, substituindo uploadImageMultipart por uploadImage
              final result = await _imageService.uploadImage(_serviceId!, imageFile);
              if (result.containsKey('image') && result['image']['url'] != null) {
                allImageUrls.add(result['image']['url']);
              }
            }
            // Se _serviceId for null, não deveria chegar aqui, pois já criamos acima
          } catch (e) {
            print('Erro no upload da imagem: $e');
            // Continue com as outras imagens mesmo se uma falhar
          }
        }
        
        setState(() {
          _isUploadingImages = false;
        });
      }

      // Atualizar ou criar o serviço com todas as URLs de imagens
      final service = ServiceModel(
        id: _serviceId,
        vehicleId: widget.vehicleId,
        serviceType: _serviceController.text.trim(),
        workshop: _workshopController.text.trim(),
        mechanic: _mechanicController.text.trim(),
        laborWarrantyDate: _laborWarrantyController.text.trim(),
        laborCost: _parseMoneyValue(_laborCostController.text),
        parts: _partsController.text.trim(),
        partsStore: _partsStoreController.text.trim(),
        partsWarrantyDate: _partsWarrantyController.text.trim(),
        partsCost: _parseMoneyValue(_partsCostController.text),
        dateTime: _currentDateTime,
        imagePaths: allImageUrls,
      );

      // Se já criamos anteriormente (para obter ID), então atualizamos
      final savedService = _serviceId != null 
          ? await _maintenanceService.updateMaintenance(service)
          : await _maintenanceService.addMaintenance(service);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_serviceId == null 
              ? 'Serviço registrado com sucesso!' 
              : 'Serviço atualizado com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Navigator.pop(context, savedService);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro: ${e.toString()}';
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_serviceId == null ? 'Registrar Serviço' : 'Editar Serviço'),
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
                _buildRequiredField(
                  _serviceController, 
                  'Serviço Executado', 
                  'Informe o tipo de serviço realizado',
                  'Por favor, informe qual serviço foi executado',
                ),
                const SizedBox(height: 16),
                _buildRequiredField(
                  _workshopController, 
                  'Oficina', 
                  'Informe onde o serviço foi realizado',
                  'Por favor, informe o nome da oficina',
                ),
                const SizedBox(height: 16),
                _buildOptionalTextField(
                  _mechanicController, 
                  'Mecânico Responsável', 
                  'Informe quem realizou o serviço (opcional)'
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  _laborWarrantyController, 
                  'Garantia da Mão de Obra', 
                  'Informe a data no formato DD/MM/AAAA (opcional)'
                ),
                const SizedBox(height: 16),
                _buildCurrencyField(
                  _laborCostController, 
                  'Valor Cobrado (R\$)', 
                  'Informe o valor da mão de obra (opcional)'
                ),
                const SizedBox(height: 16),
                _buildOptionalTextField(
                  _partsController, 
                  'Peças Trocadas', 
                  'Informe as peças utilizadas (opcional)'
                ),
                const SizedBox(height: 16),
                _buildOptionalTextField(
                  _partsStoreController, 
                  'Loja das Peças', 
                  'Informe onde as peças foram compradas (opcional)'
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  _partsWarrantyController, 
                  'Garantia das Peças', 
                  'Informe a data no formato DD/MM/AAAA (opcional)'
                ),
                const SizedBox(height: 16),
                _buildCurrencyField(
                  _partsCostController, 
                  'Valor das Peças (R\$)', 
                  'Informe o valor das peças (opcional)'
                ),
                const SizedBox(height: 16),
                _buildImageUpload(),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: (_isSubmitting || _isUploadingImages) ? null : _submitService,
                  style: AppTheme.primaryButtonStyle,
                  child: _isSubmitting || _isUploadingImages
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(_isUploadingImages ? 'ENVIANDO IMAGENS...' : 'REGISTRANDO...'),
                          ],
                        )
                      : Text(_serviceId == null ? 'REGISTRAR SERVIÇO' : 'SALVAR ALTERAÇÕES'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeField() {
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(_currentDateTime);
    
    return TextFormField(
      initialValue: formattedDate,
      readOnly: true,
      decoration: AppTheme.inputDecoration('Data e Hora', hintText: 'Gerado automaticamente'),
    );
  }

  Widget _buildRequiredField(
    TextEditingController controller,
    String label,
    String hintText,
    String errorMessage,
  ) {
    return TextFormField(
      controller: controller,
      decoration: AppTheme.inputDecoration(label, hintText: hintText),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return errorMessage;
        }
        return null;
      },
    );
  }

  Widget _buildOptionalTextField(
    TextEditingController controller,
    String label,
    String hintText,
  ) {
    return TextFormField(
      controller: controller,
      decoration: AppTheme.inputDecoration(label, hintText: hintText),
    );
  }

  Widget _buildDateField(
    TextEditingController controller,
    String label,
    String hintText,
  ) {
    return TextFormField(
      controller: controller,
      decoration: AppTheme.inputDecoration(
        label, 
        hintText: hintText,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            // Aqui você pode implementar um selector de data no futuro
          },
        ),
      ),
      keyboardType: TextInputType.datetime,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null; // Campo opcional
        }
        if (!_isValidDate(value)) {
          return 'Data inválida. Use o formato DD/MM/AAAA e certifique-se que é uma data futura';
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
        LengthLimitingTextInputFormatter(10),
      ],
    );
  }

  Widget _buildCurrencyField(
    TextEditingController controller,
    String label,
    String hintText,
  ) {
    return TextFormField(
      controller: controller,
      decoration: AppTheme.inputDecoration(
        label, 
        hintText: hintText,
      ).copyWith(
        prefixText: 'R\$ ', // Usa copyWith para adicionar prefixText à decoração retornada
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null; // Campo opcional
        }
        if (_parseMoneyValue(value) == null) {
          return 'Valor inválido. Digite um número positivo (ex: 125,90)';
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      ],
    );
  }

  Widget _buildImageUpload() {
    final int totalImages = _selectedImages.length + _uploadedImageUrls.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Imagens (opcional)', style: AppTheme.bodyMedium),
            const SizedBox(width: 8),
            Text(
              '$totalImages/4',
              style: TextStyle(
                color: AppTheme.textColorLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Máximo de 4 imagens, 5MB cada',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textColorLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Mostrar imagens temporárias selecionadas
            ..._selectedImages.asMap().entries.map((entry) => 
              _buildLocalImageThumbnail(entry.value, entry.key)
            ),
            
            // Mostrar URLs de imagens já carregadas
            ..._uploadedImageUrls.asMap().entries.map((entry) => 
              _buildUrlImageThumbnail(entry.value, entry.key + _selectedImages.length)
            ),
            
            // Botão para adicionar mais imagens
            if (totalImages < 4)
              GestureDetector(
                onTap: _selectImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColorLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColorLight,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_photo_alternate, color: AppTheme.primaryColor),
                      SizedBox(height: 4),
                      Text(
                        'Adicionar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocalImageThumbnail(File imageFile, int index) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColorLight,
              width: 1,
            ),
            image: DecorationImage(
              image: FileImage(imageFile),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrlImageThumbnail(String imageUrl, int index) {
    // Converter URL relativa para absoluta se necessário
    String fullUrl = imageUrl;
    if (imageUrl.startsWith('/uploads/')) {
      fullUrl = 'http://127.0.0.1:5000$imageUrl'; // Ajuste para ambiente de desenvolvimento
    }
    
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColorLight,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fullUrl,
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
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}