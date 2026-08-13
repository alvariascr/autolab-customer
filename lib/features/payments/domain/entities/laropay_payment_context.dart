class LaropayPaymentContext {
  const LaropayPaymentContext({
    required this.orderId,
    required this.amount,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerEmail,
    this.orderNumber,
    this.customerPhone,
    this.workshopName,
  });

  final String orderId;
  final String? orderNumber;
  final double amount;
  final String customerFirstName;
  final String customerLastName;
  final String customerEmail;
  final String? customerPhone;
  final String? workshopName;
}
