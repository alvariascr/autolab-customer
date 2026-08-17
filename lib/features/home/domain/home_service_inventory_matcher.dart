import '../../products/domain/entities/product.dart';

class HomeServiceInventoryMatcher {
  const HomeServiceInventoryMatcher();

  static const _termsByService = <String, List<String>>{
    'inspeccion': ['inspeccion', 'revision', 'diagnostico'],
    'cambio_aceite': ['cambio de aceite', 'aceite'],
    'cambio_llanta': ['cambio de llanta', 'llanta', 'neumatico'],
    'balanceo': ['balanceo'],
    'alineamiento': ['alineacion', 'alineamiento'],
    'reparacion_llanta': ['reparacion de llanta', 'llanta', 'neumatico'],
    'estetica_automotriz': ['estetica', 'detallado', 'detailing'],
    'electrico': ['electrico', 'electricidad'],
    'instalacion': ['instalacion'],
    'aire_acondicionado': ['aire acondicionado', 'a/c'],
    'grua': ['grua', 'remolque'],
    'llantas': ['llanta', 'neumatico'],
    'aceites': ['aceite'],
    'repuestos': ['repuesto', 'parte'],
    'coolant': ['coolant', 'refrigerante'],
    'producto_auto_lavado': ['lavado', 'limpieza', 'car wash'],
    'luces': ['luz', 'luces', 'bombillo', 'faro'],
    'baterias': ['bateria'],
    'liquidos': ['liquido', 'fluido'],
    'lubricantes': ['lubricante', 'lubricacion'],
    'quimicos': ['quimico'],
    'aditivos': ['aditivo'],
    'grasas': ['grasa'],
    'filtros': ['filtro'],
    'tecnologia': ['tecnologia', 'electronico', 'sensor'],
    'aros': ['aro', 'rin'],
    'racks': ['rack', 'portaequipaje'],
    'alfombras': ['alfombra'],
    'escobillas': ['escobilla', 'limpiaparabrisas'],
  };

  bool matchesProduct(String serviceKey, Product product) {
    return matches(
      serviceKey: serviceKey,
      name: product.name,
      categoryName: product.categoryName,
      description: product.description,
    );
  }

  bool matches({
    required String serviceKey,
    required String name,
    required String categoryName,
    String description = '',
  }) {
    final terms = _termsByService[serviceKey];
    if (terms == null) return false;

    final searchableText = _normalize('$name $categoryName $description');
    return terms.any((term) => searchableText.contains(_normalize(term)));
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }
}
