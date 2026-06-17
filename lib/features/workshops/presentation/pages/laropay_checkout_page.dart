import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/domain/entities/laropay_link.dart';
import '../../../payments/domain/entities/laropay_link_request.dart';
import '../../../payments/domain/usecases/generate_laropay_link.dart';

class LaropayCheckoutPage extends StatefulWidget {
  const LaropayCheckoutPage({
    super.key,
    required this.appointmentId,
    required this.amountLabel,
    required this.workshopName,
    required this.onClose,
  });

  final String appointmentId;
  final String amountLabel;
  final String workshopName;
  final VoidCallback onClose;

  @override
  State<LaropayCheckoutPage> createState() => _LaropayCheckoutPageState();
}

class _LaropayCheckoutPageState extends State<LaropayCheckoutPage> {
  final GenerateLaropayLink _generateLaropayLink = sl<GenerateLaropayLink>();
  final SupabaseClient _supabase = sl<SupabaseClient>();

  _LaropayCheckoutStatus _status = _LaropayCheckoutStatus.loading;
  LaropayLink? _link;
  String? _errorMessage;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _generateAndOpenLink();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final statusConfig = _statusConfig(primary);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.onClose();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: primary),
                      ),
                      child: Text(
                        'Laropay',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: statusConfig.color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                statusConfig.icon,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              statusConfig.title,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              statusConfig.subtitle,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 16,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Divider(height: 34, color: AppColors.border),
                            _LaropayStatusCard(
                              icon: statusConfig.icon,
                              message: statusConfig.message,
                              color: statusConfig.color,
                              background: statusConfig.background,
                              showProgress:
                                  _status == _LaropayCheckoutStatus.loading ||
                                  _isOpening,
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              _LaropayNotice(
                                message: _errorMessage!,
                                color: const Color(0xFFB3261E),
                                background: const Color(0xFFFFECEA),
                              ),
                            ],
                            const SizedBox(height: 18),
                            _LaropayDetailRow(
                              label: 'Monto',
                              value: widget.amountLabel,
                              emphasize: true,
                            ),
                            _LaropayDetailRow(
                              label: 'Comercio',
                              value: widget.workshopName,
                            ),
                            _LaropayDetailRow(
                              label: 'Referencia',
                              value: widget.appointmentId,
                            ),
                            if (_link != null)
                              _LaropayDetailRow(
                                label: 'Link ID',
                                value: _link!.linkId,
                              ),
                            const SizedBox(height: 22),
                            const _LaropayNotice(
                              message:
                                  'La confirmación final del pago se validará desde backend. Mientras no exista confirmación, la orden permanece pendiente.',
                            ),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton.icon(
                                onPressed: _primaryAction,
                                icon: Icon(_primaryActionIcon),
                                label: Text(_primaryActionLabel),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: OutlinedButton(
                                onPressed: widget.onClose,
                                child: const Text('Volver al taller'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback? get _primaryAction {
    if (_status == _LaropayCheckoutStatus.loading || _isOpening) {
      return null;
    }

    if (_status == _LaropayCheckoutStatus.error) {
      return _generateAndOpenLink;
    }

    return _openCurrentLink;
  }

  IconData get _primaryActionIcon {
    if (_status == _LaropayCheckoutStatus.error) {
      return Icons.refresh_rounded;
    }

    return Icons.open_in_new_rounded;
  }

  String get _primaryActionLabel {
    if (_isOpening) {
      return 'Abriendo Laropay';
    }

    if (_status == _LaropayCheckoutStatus.loading) {
      return 'Generando link';
    }

    if (_status == _LaropayCheckoutStatus.error) {
      return 'Reintentar';
    }

    return 'Abrir Laropay';
  }

  ({
    IconData icon,
    String title,
    String subtitle,
    String message,
    Color color,
    Color background,
  })
  _statusConfig(Color primary) {
    return switch (_status) {
      _LaropayCheckoutStatus.loading => (
        icon: Icons.sync_rounded,
        title: 'Generando link de pago',
        subtitle: 'Estamos preparando el checkout seguro de Laropay.',
        message: 'No cierres esta pantalla mientras se genera el link.',
        color: primary,
        background: const Color(0xFFEAF2FF),
      ),
      _LaropayCheckoutStatus.pending => (
        icon: Icons.schedule_outlined,
        title: 'Pago pendiente',
        subtitle: 'El checkout de Laropay se abrió en el navegador.',
        message:
            'Completa el pago en Laropay. La orden seguirá pendiente hasta recibir confirmación del backend.',
        color: const Color(0xFFB26A00),
        background: const Color(0xFFFFF5DF),
      ),
      _LaropayCheckoutStatus.error => (
        icon: Icons.error_outline,
        title: 'No pudimos abrir Laropay',
        subtitle: 'Intenta nuevamente o vuelve al taller.',
        message: 'El pago no fue iniciado. Puedes generar el link otra vez.',
        color: const Color(0xFFB3261E),
        background: const Color(0xFFFFECEA),
      ),
    };
  }

  Future<void> _generateAndOpenLink() async {
    if (_isOpening) {
      return;
    }

    setState(() {
      _status = _LaropayCheckoutStatus.loading;
      _errorMessage = null;
    });

    try {
      final context = await _loadLaropayContext();
      final result = await _generateLaropayLink(
        LaropayLinkRequest(
          internalTransactionId: context.orderId,
          idTransaction: 1,
          amount: context.amount,
          document: context.orderNumber ?? widget.appointmentId,
          detail: 'Autolab ${widget.workshopName}',
          customerFirstName: context.customerFirstName,
          customerLastName: context.customerLastName,
          customerEmail: context.customerEmail,
          customerPhone: context.customerPhone,
          customerLocation: widget.workshopName,
          expirationType: 'D',
          expirationValue: 1,
        ),
      );

      await result.fold(
        (failure) async {
          throw _LaropayCheckoutException(_failureMessage(failure));
        },
        (link) async {
          if (!mounted) {
            return;
          }

          setState(() {
            _link = link;
            _status = _LaropayCheckoutStatus.pending;
          });
          await _openLink(link.linkUrl);
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = _LaropayCheckoutStatus.error;
        _errorMessage = error is _LaropayCheckoutException
            ? error.message
            : 'No fue posible generar el link de pago. Intenta nuevamente.';
      });
    }
  }

  Future<_LaropayCheckoutContext> _loadLaropayContext() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const _LaropayCheckoutException(
        'Inicia sesión nuevamente para continuar con el pago.',
      );
    }

    final response = await _supabase
        .from('appointments')
        .select('''
          id,
          order_services!inner(
            order_id,
            orders!inner(
              id,
              order_number,
              remaining_amount,
              total_amount,
              customers!inner(user_id)
            )
          )
        ''')
        .eq('id', widget.appointmentId)
        .eq('order_services.orders.customers.user_id', user.id)
        .single();

    final payload = Map<String, dynamic>.from(response);
    final orderService = _mapValue(payload['order_services']);
    final order = _mapValue(orderService['orders']);
    final orderId = _stringValue(orderService['order_id']).isNotEmpty
        ? _stringValue(orderService['order_id'])
        : _stringValue(order['id']);
    final amount = _paymentAmount(order);
    final profile = _userProfile(user);

    if (orderId.isEmpty || !amount.isFinite || amount <= 0) {
      throw const _LaropayCheckoutException(
        'La orden no tiene un monto pendiente válido para pagar.',
      );
    }

    return _LaropayCheckoutContext(
      orderId: orderId,
      orderNumber: _nullableString(order['order_number']),
      amount: amount,
      customerFirstName: profile.firstName,
      customerLastName: profile.lastName,
      customerEmail: profile.email,
      customerPhone: profile.phone,
    );
  }

  Future<void> _openCurrentLink() async {
    final link = _link;
    if (link == null) {
      await _generateAndOpenLink();
      return;
    }

    await _openLink(link.linkUrl);
  }

  Future<void> _openLink(Uri uri) async {
    if (_isOpening) {
      return;
    }

    setState(() {
      _isOpening = true;
      _errorMessage = null;
    });

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);

    if (!mounted) {
      return;
    }

    setState(() {
      _isOpening = false;
      if (!launched) {
        _status = _LaropayCheckoutStatus.error;
        _errorMessage = 'No fue posible abrir el navegador seguro de Laropay.';
      } else {
        _status = _LaropayCheckoutStatus.pending;
      }
    });
  }

  double _paymentAmount(Map<String, dynamic> order) {
    final remainingAmount = _numberValue(order['remaining_amount']);
    if (remainingAmount > 0) {
      return remainingAmount;
    }

    return _numberValue(order['total_amount']);
  }

  _LaropayUserProfile _userProfile(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email?.trim().isNotEmpty == true
        ? user.email!.trim()
        : _stringValue(metadata['email']);
    final fullName = _stringValue(metadata['name']).isNotEmpty
        ? _stringValue(metadata['name'])
        : email.split('@').first;
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    return _LaropayUserProfile(
      firstName: parts.isEmpty ? 'Cliente' : parts.first,
      lastName: parts.length <= 1 ? 'Autolab' : parts.skip(1).join(' '),
      email: email,
      phone: _nullableString(metadata['phone']),
    );
  }

  String _failureMessage(Failure failure) {
    final message = failure.message.trim();
    return message.isEmpty
        ? 'No fue posible generar el link de pago. Intenta nuevamente.'
        : message;
  }
}

class _LaropayStatusCard extends StatelessWidget {
  const _LaropayStatusCard({
    required this.icon,
    required this.message,
    required this.color,
    required this.background,
    required this.showProgress,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color background;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          if (showProgress)
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: color),
            )
          else
            Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaropayNotice extends StatelessWidget {
  const _LaropayNotice({
    required this.message,
    this.color = const Color(0xFFB26A00),
    this.background = const Color(0xFFFFF5DF),
  });

  final String message;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaropayDetailRow extends StatelessWidget {
  const _LaropayDetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: emphasize ? 2 : 3,
              style: TextStyle(
                color: emphasize
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.ink,
                fontSize: emphasize ? 22 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LaropayCheckoutStatus { loading, pending, error }

class _LaropayCheckoutContext {
  const _LaropayCheckoutContext({
    required this.orderId,
    required this.amount,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerEmail,
    this.orderNumber,
    this.customerPhone,
  });

  final String orderId;
  final String? orderNumber;
  final double amount;
  final String customerFirstName;
  final String customerLastName;
  final String customerEmail;
  final String? customerPhone;
}

class _LaropayUserProfile {
  const _LaropayUserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
}

class _LaropayCheckoutException implements Exception {
  const _LaropayCheckoutException(this.message);

  final String message;
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const {};
}

String _stringValue(Object? value) {
  return value?.toString().trim() ?? '';
}

String? _nullableString(Object? value) {
  final text = _stringValue(value);
  return text.isEmpty ? null : text;
}

double _numberValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? double.nan;
}
