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
    required super.scheduledAt,
    required super.status,
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
      workshopId: _requiredString(map['workshop_id'], 'workshop_id'),
      serviceId: _requiredString(map['service_id'], 'service_id'),
      customerName: _requiredString(map['customer_name'], 'customer_name'),
      customerPhone: _requiredString(map['customer_phone'], 'customer_phone'),
      customerEmail: _requiredString(map['customer_email'], 'customer_email'),
      vehicleType: _requiredString(map['vehicle_type'], 'vehicle_type'),
      scheduledAt: _requiredDateTime(map['scheduled_at'], 'scheduled_at'),
      status: map['status']?.toString() ?? 'pending',
      paymentMethod: _nullableString(map['payment_method']),
      notes: _nullableString(map['notes']),
      totalAmount: _nullableMoney(map['total_amount'], 'total_amount'),
      createdAt: _nullableDateTime(map['created_at']),
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
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'status': status,
      'payment_method': paymentMethod,
      'notes': notes,
      'total_amount': totalAmount,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'appointment_products': products
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

  static String? _customerIdFromMap(Map<String, dynamic> map) {
    return _nullableString(map['customer_id']) ??
        _nullableString(map['customer_user_id']);
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
      return value;
    }

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
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
