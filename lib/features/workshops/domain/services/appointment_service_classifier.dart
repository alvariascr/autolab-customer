import '../../../products/domain/entities/product.dart';

class AppointmentServiceClassifier {
  const AppointmentServiceClassifier._();

  static bool isInspectionService(Product service) {
    return isInspectionText(service.name);
  }

  static bool isInspectionText(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    return normalized.contains('inspeccion') ||
        normalized.contains('inspection') ||
        normalized.contains('revision');
  }
}
