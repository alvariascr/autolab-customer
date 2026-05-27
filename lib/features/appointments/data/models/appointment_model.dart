import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.id,
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
      id: map['id']?.toString() ?? '',
      workshopId: map['workshop_id']?.toString() ?? '',
      serviceId: map['service_id']?.toString() ?? '',
      customerName: map['customer_name']?.toString() ?? '',
      customerPhone: map['customer_phone']?.toString() ?? '',
      customerEmail: map['customer_email']?.toString() ?? '',
      vehicleType: map['vehicle_type']?.toString() ?? '',
      scheduledAt: _dateTime(map['scheduled_at']),
      status: map['status']?.toString() ?? 'pending',
      paymentMethod: _nullableString(map['payment_method']),
      notes: _nullableString(map['notes']),
      totalAmount: _nullableDouble(map['total_amount']),
      createdAt: _nullableDateTime(map['created_at']),
      products: _productsFromMap(map),
    );
  }

  static Map<String, dynamic> toInsertMap(AppointmentDraft draft) {
    return {
      'workshop_id': draft.workshopId,
      'service_id': draft.serviceId,
      'customer_name': draft.customerName,
      'customer_phone': draft.customerPhone,
      'customer_email': draft.customerEmail,
      'vehicle_type': draft.vehicleType,
      'scheduled_at': draft.scheduledAt.toUtc().toIso8601String(),
      'status': 'pending',
      'payment_method': draft.paymentMethod,
      'notes': draft.notes,
      'total_amount': draft.totalAmount,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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

  static List<Map<String, dynamic>> productLinesToInsertMaps({
    required String appointmentId,
    required List<AppointmentProductLine> products,
  }) {
    return products
        .map(
          (product) => {
            'appointment_id': appointmentId,
            'product_id': product.productId,
            'quantity': product.quantity,
            'unit_price': product.unitPrice,
          },
        )
        .toList();
  }

  static List<AppointmentProductLine> _productsFromMap(
    Map<String, dynamic> map,
  ) {
    final items = map['appointment_products'];

    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AppointmentProductLine(
            productId: item['product_id']?.toString() ?? '',
            quantity: _int(item['quantity'], fallback: 1),
            unitPrice: _nullableDouble(item['unit_price']),
          ),
        )
        .where((item) => item.productId.isNotEmpty)
        .toList();
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static DateTime _dateTime(dynamic value) {
    return _nullableDateTime(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
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

  static double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static int _int(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
