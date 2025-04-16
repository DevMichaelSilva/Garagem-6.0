import 'dart:io'; // Import dart:io for File (ainda pode ser útil, mas menos central)
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garagem/theme/theme_screen.dart';
import 'package:garagem/models/service_model.dart';
import 'package:garagem/services/maintenance_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage

class AddServiceScreen extends StatefulWidget {
  final int vehicleId;

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
  List<XFile> _selectedImages = []; // Store selected XFile objects
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  DateTime _currentDateTime = DateTime.now();
  bool _isSubmitting = false;
  String? _errorMessage;

  // Regex para validação de data DD/MM/YYYY
  final RegExp _dateRegex = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
  
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

  // Updated function to upload images to Firebase Storage using bytes
  Future<List<String>> _uploadImagesToFirebase(List<XFile> images) async {
    List<String> downloadUrls = [];
    final storageRef = FirebaseStorage.instance.ref();

    for (XFile imageFile in images) {
      try {
        // Create a unique filename
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}'; // Use imageFile.name
        // Create a reference
        Reference serviceImageRef = storageRef.child('services/${widget.vehicleId}/$fileName');

        // Read file bytes
        final Uint8List bytes = await imageFile.readAsBytes();

        // Determine content type (optional but recommended)
        final metadata = SettableMetadata(contentType: imageFile.mimeType ?? 'image/jpeg'); // Use mimeType if available

        // Upload the bytes
        UploadTask uploadTask = serviceImageRef.putData(bytes, metadata); // Use putData

        // Get the download URL
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print("Error uploading image: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar imagem: ${imageFile.name}'), // Use imageFile.name
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
    return downloadUrls;
  }

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

    String errorMsg = 'Erro desconhecido ao registrar serviço.'; // Default error message

    try {
      // 1. Upload images (List<XFile>) to Firebase and get URLs
      List<String> imageUrls = await _uploadImagesToFirebase(_selectedImages);

      // 2. Create the service object with image URLs
      final service = ServiceModel(
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
        imagePaths: imageUrls, // Use the URLs from Firebase
      );

      // 3. Save service data (including URLs) to your backend
      final savedService = await MaintenanceService().addMaintenance(service);

      // Verificar se o widget ainda está montado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço registrado com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Navigator.pop(context, savedService);
        // Don't reset _isSubmitting here if navigating away
        return; // Exit after successful navigation
      }
    } on FirebaseException catch (e) { // Catch Firebase specific exceptions FIRST
      print("Caught FirebaseException in 'on FirebaseException': ${e.code} - ${e.message}");
      errorMsg = 'Erro no Firebase: ${e.message ?? e.code}';
    } catch (e, stackTrace) { // Catch other general exceptions
      print("Caught exception in generic 'catch': Type=${e.runtimeType}, Error=$e");
      print("Stack trace: $stackTrace");

      // Simplificado: Apenas tenta converter para string de forma segura.
      // A verificação 'is FirebaseException' foi removida daqui.
      try {
          errorMsg = 'Erro ao registrar serviço: ${e.toString()}';
      } catch (toStringError) {
          print("Error calling toString() on exception: $toStringError");
          errorMsg = 'Erro ao registrar serviço (tipo desconhecido).';
      }

    } finally {
      // Ensure state is updated only if mounted and an error occurred
      if (mounted && _isSubmitting) { // Check _isSubmitting to avoid setting state after success
         setState(() {
           if (errorMsg != 'Erro desconhecido ao registrar serviço.') { // Only set _errorMessage if an error actually happened
             _errorMessage = errorMsg;
           }
           _isSubmitting = false;
         });
         // Show error SnackBar if an error occurred
         if (_errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_errorMessage!),
                backgroundColor: AppTheme.errorColor,
              ),
            );
         }
      }
    }
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
                _buildImageUpload(), // Ensure this uses _selectedImages (List<XFile>)
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

  // O resto dos widgets de construção do formulário permanece o mesmo...
  // Métodos _buildDateTimeField(), _buildRequiredField(), _buildOptionalTextField(), etc.
  // (mantendo os mesmos da versão anterior)
  
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
        // Substituir prefixText por uma solução mais compatível
        prefix: const Text('R\$ ', style: TextStyle(fontSize: 16)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Imagens (opcional)', style: AppTheme.bodyMedium),
            const SizedBox(width: 8),
            Text(
              '${_selectedImages.length}/4', // Use _selectedImages.length
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
            ..._selectedImages.map((file) => _buildImageThumbnail(file)), // Pass XFile
            if (_selectedImages.length < 4)
              GestureDetector(
                onTap: _selectImage, // Call _selectImage directly
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

  // Updated _selectImage to use ImagePicker and store XFile
  Future<void> _selectImage() async {
    if (_selectedImages.length >= 4) return;

    try {
      // pickImage directly returns XFile?
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        // Check file size using readAsBytes length
        int fileSize = await pickedFile.readAsBytes().then((list) => list.length);
        if (fileSize > 5 * 1024 * 1024) { // 5MB
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem muito grande! (Máx 5MB)'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }

        setState(() {
          _selectedImages.add(pickedFile); // Add XFile directly
        });
      }
    } catch (e) {
      print("Error picking image: $e"); // This is where the original error likely occurred
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: ${e.toString()}'), // Show error details
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Updated _buildImageThumbnail to display image from XFile bytes
  Widget _buildImageThumbnail(XFile imageFile) {
    // Use FutureBuilder to handle async reading of bytes for display
    return FutureBuilder<Uint8List>(
      future: imageFile.readAsBytes(), // Read bytes from XFile
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container( // Placeholder while loading
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColorLight, width: 1),
              color: Colors.grey[200],
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Container( // Placeholder on error
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.errorColor, width: 1),
              color: Colors.grey[200],
            ),
            child: const Center(child: Icon(Icons.error_outline, color: AppTheme.errorColor)),
          );
        }

        // Display image using Image.memory
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
                  image: MemoryImage(snapshot.data!), // Use MemoryImage with bytes
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
                    _selectedImages.remove(imageFile); // Remove the XFile object
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}