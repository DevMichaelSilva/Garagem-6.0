class ServiceModel {
  final int? id;
  final int vehicleId;
  final String serviceType;
  final String workshop;
  final String? mechanic;
  final String? laborWarrantyDate;
  final double? laborCost;
  final String? parts;
  final String? partsStore;
  final String? partsWarrantyDate;
  final double? partsCost;
  final DateTime dateTime;
  final List<String> imagePaths;

  ServiceModel({
    this.id,
    required this.vehicleId,
    required this.serviceType,
    required this.workshop,
    this.mechanic,
    this.laborWarrantyDate,
    this.laborCost,
    this.parts,
    this.partsStore,
    this.partsWarrantyDate,
    this.partsCost,
    required this.dateTime,
    this.imagePaths = const [],
  });

  // Converte o modelo para um mapa para facilitar a exibição e serialização
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'serviceType': serviceType,
      'workshop': workshop,
      'mechanic': mechanic,
      'laborWarrantyDate': laborWarrantyDate,
      'laborCost': laborCost,
      'parts': parts,
      'partsStore': partsStore,
      'partsWarrantyDate': partsWarrantyDate,
      'partsCost': partsCost,
      'dateTime': dateTime,
      'imagePaths': imagePaths,
    };
  }

  // Factory para criar um ServiceModel a partir de um mapa
  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'],
      vehicleId: map['vehicleId'],
      serviceType: map['serviceType'],
      workshop: map['workshop'],
      mechanic: map['mechanic'],
      laborWarrantyDate: map['laborWarrantyDate'],
      laborCost: map['laborCost'],
      parts: map['parts'],
      partsStore: map['partsStore'],
      partsWarrantyDate: map['partsWarrantyDate'],
      partsCost: map['partsCost'],
      dateTime: map['dateTime'] is DateTime 
          ? map['dateTime'] 
          : DateTime.parse(map['dateTime']),
      imagePaths: List<String>.from(map['imagePaths'] ?? []),
    );
  }
}