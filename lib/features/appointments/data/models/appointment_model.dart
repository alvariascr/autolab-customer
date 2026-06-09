import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.id,
    super.customerId,
    required super.workshopId,
    required super.serviceId,
    required super.customerName,
    required super.customerPhone,
    required super.customerEmail,
    required super.vehicleType,
    super.vehiclePlate,
    required super.scheduledAt,
    required super.status,
    super.workshopName,
    super.serviceName,
    super.workshopAvatarUrl,
    super.paymentMethod,
    super.notes,
    super.totalAmount,
    super.createdAt,
    super.products,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: _requiredString(map['id'], 'id'),
      customerId: _customerIdFromMap(map),
      workshopId: _requiredFirstString([
        map['workshop_id'],
        _nestedValue(map, ['order_services', 'orders', 'workshop_id']),
      ], 'workshop_id'),
      serviceId: _requiredFirstString([
        map['service_id'],
        _nestedValue(map, ['order_services', 'inventory_item_id']),
        map['order_service_id'],
      ], 'service_id'),
      customerName: _nullableString(map['customer_name']) ?? '',
      customerPhone: _nullableString(map['customer_phone']) ?? '',
      customerEmail: _nullableString(map['customer_email']) ?? '',
      vehicleType: _requiredFirstString([
        map['vehicle_type'],
        _nestedValue(map, ['vehicles', 'vehicle_type']),
      ], 'vehicle_type'),
      vehiclePlate:
          _nullableString(map['vehicle_plate']) ??
          _nestedString(map, ['vehicles', 'license_plate']),
      scheduledAt: _requiredDateTime(
        map['scheduled_at'] ?? map['scheduled_datetime'],
        'scheduled_at',
      ),
      status:
          map['status']?.toString() ??
          map['appointment_status']?.toString() ??
          'pending',
      workshopName:
          _nestedString(map, ['workshops', 'name']) ??
          _nestedString(map, ['order_services', 'orders', 'workshops', 'name']),
      serviceName:
          _nestedString(map, ['inventory_items', 'name']) ??
          _nestedString(map, ['order_services', 'inventory_items', 'name']),
      workshopAvatarUrl:
          _nestedString(map, ['workshops', 'avatar_url']) ??
          _nestedString(map, [
            'order_services',
            'orders',
            'workshops',
            'avatar_url',
          ]),
      paymentMethod: _nullableString(map['payment_method']),
      notes: _nullableString(map['notes']) ?? _nullableString(map['note']),
      totalAmount: _nullableMoney(map['total_amount'], 'total_amount'),
      createdAt: _nullableDateTime(map['created_at'] ?? map['updated_at']),
      products: _productsFromMap(map),
    );
  }

  static Map<String, dynamic> toCreateRpcParams(AppointmentDraft draft) {
    return {
      'p_workshop_id': draft.workshopId,
      'p_service_id': draft.serviceId,
      'p_customer_name': draft.customerName,
      'p_customer_phone': draft.customerPhone,
      'p_customer_email': draft.customerEmail,
      'p_vehicle_type': draft.vehicleType,
      'p_scheduled_at': draft.scheduledAt.toUtc().toIso8601String(),
      'p_payment_method': draft.paymentMethod,
      'p_notes': draft.notes,
      'p_total_amount': draft.totalAmount,
      'p_products': draft.products
          .map(
            (product) => {
              'product_id': product.productId,
              'quantity': product.quantity,
              'unit_price': product.unitPrice,
            },
          )
          .toList(),
    };
  }

  /// Serializes only flat appointment columns. Joined display data such as
  /// workshopName, serviceName and products is read-only query payload.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'workshop_id': workshopId,
      'service_id': serviceId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'status': status,
      'payment_method': paymentMethod,
      'notes': notes,
      'total_amount': totalAmount,
      'created_at': createdAt?.toUtc().toIso8601String(),
    };
  }

  static String? _customerIdFromMap(Map<String, dynamic> map) {
    return _nullableString(map['customer_id']) ??
        _nullableString(map['customer_user_id']) ??
        _nestedString(map, [
          'order_services',
          'orders',
          'customers',
          'updated_by',
        ]);
  }

  static String _requiredFirstString(List<dynamic> values, String fieldName) {
    final text = _firstString(values);
    if (text == null) {
      throw FormatException(
        'Missing required appointment field $fieldName',
        values,
      );
    }

    return text;
  }

  static String? _firstString(List<dynamic> values) {
    for (final value in values) {
      final text = _nullableString(value);
      if (text != null) {
        return text;
      }
    }

    return null;
  }

  static String? _nestedString(Map<String, dynamic> map, List<String> path) {
    return _nullableString(_nestedValue(map, path));
  }

  static Object? _nestedValue(Map<String, dynamic> map, List<String> path) {
    Object? current = map;

    for (final key in path) {
      if (current is List && current.isNotEmpty) {
        current = current.first;
      }

      if (current is Map<String, dynamic>) {
        current = current[key];
        continue;
      }

      if (current is Map) {
        current = current[key];
        continue;
      }

      return null;
    }

    return current;
  }

  static List<AppointmentProductLine> _productsFromMap(
    Map<String, dynamic> map,
  ) {
    final items = map['appointment_products'];

    if (items == null) {
      return const [];
    }

    if (items is! List) {
      throw FormatException('Invalid appointment products payload', items);
    }

    return items.map((item) {
      if (item is! Map<String, dynamic>) {
        throw FormatException('Invalid appointment product item', item);
      }

      return AppointmentProductLine(
        productId: _requiredString(item['product_id'], 'product_id'),
        quantity: _positiveInt(item['quantity'], 'quantity'),
        unitPrice: _nullableMoney(item['unit_price'], 'unit_price'),
      );
    }).toList();
  }

  static String _requiredString(dynamic value, String fieldName) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw FormatException(
        'Missing required appointment field $fieldName',
        value,
      );
    }

    return text;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static DateTime _requiredDateTime(dynamic value, String fieldName) {
    final dateTime = _nullableDateTime(value);
    if (dateTime == null) {
      throw FormatException(
        'Invalid appointment datetime for $fieldName',
        value,
      );
    }

    return dateTime;
  }

  static DateTime? _nullableDateTime(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static double? _nullableMoney(dynamic value, String fieldName) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return _nonNegativeDouble(value.toDouble(), fieldName, value);
    }

    final parsed = double.tryParse(value.toString());
    if (parsed == null) {
      throw FormatException('Invalid appointment amount for $fieldName', value);
    }

    return _nonNegativeDouble(parsed, fieldName, value);
  }

  static double _nonNegativeDouble(
    double value,
    String fieldName,
    Object originalValue,
  ) {
    if (value < 0) {
      throw FormatException(
        'Invalid negative appointment amount for $fieldName',
        originalValue,
      );
    }

    return value;
  }

  static int _positiveInt(dynamic value, String fieldName) {
    if (value is int) {
      return _validatePositiveInt(value, fieldName, value);
    }

    if (value is num) {
      return _validatePositiveInt(value.toInt(), fieldName, value);
    }

    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException(
        'Invalid appointment integer for $fieldName',
        value,
      );
    }

    return _validatePositiveInt(parsed, fieldName, value);
  }

  static int _validatePositiveInt(
    int value,
    String fieldName,
    Object? originalValue,
  ) {
    if (value <= 0) {
      throw FormatException(
        'Invalid non-positive appointment integer for $fieldName',
        originalValue,
      );
    }

    return value;
  }
}
