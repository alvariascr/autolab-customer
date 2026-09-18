import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../core/theme/autolab_theme_extension.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/application/cart_pricing.dart';
import '../../../payments/application/laropay_checkout_launcher.dart';
import '../../../payments/application/laropay_return_navigation_controller.dart';
import '../../../payments/domain/entities/laropay_purchase.dart';
import '../../../payments/domain/usecases/refresh_laropay_purchase_status.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/widgets/product_price_text.dart';
import '../../application/appointment_cubit.dart';
import '../../application/appointment_state.dart';

class WorkshopAppointmentPage extends StatefulWidget {
  const WorkshopAppointmentPage({
    super.key,
    required this.workshopId,
    required this.initialServiceId,
    this.initialSelection,
  });

  final String workshopId;
  final String initialServiceId;
  final WorkshopAppointmentInitialSelection? initialSelection;

  @override
  State<WorkshopAppointmentPage> createState() =>
      _WorkshopAppointmentPageState();
}

class _WorkshopAppointmentPageState extends State<WorkshopAppointmentPage>
    with WidgetsBindingObserver {
  static const _externalPaymentTransitionTimeout = Duration(seconds: 5);
  static const _paymentReturnFallbackDelay = Duration(seconds: 3);
  static const _paymentStatusVerificationTimeout = Duration(seconds: 10);

  _AppointmentLoadingPhase? _loadingPhase;
  Completer<bool>? _externalPaymentTransitionCompleter;
  Timer? _paymentReturnFallbackTimer;
  bool _awaitingPaymentReturn = false;
  bool _paymentReturnFallbackScheduled = false;
  int? _paymentReturnBaselineCallbackCount;
  String? _pendingPaymentLinkId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelPaymentReturnFallback();
    _completeExternalPaymentTransition();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _completeExternalPaymentTransition();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _handlePaymentReturnIfAbandoned();
    }
  }

  // Called when the app comes back to the foreground while a Laropay
  // checkout was in flight. A brief delay gives a deep-link payment result
  // (which navigates on its own) a chance to arrive first; if nothing
  // arrives, the customer closed the gateway without finishing.
  void _handlePaymentReturnIfAbandoned() {
    if (!_awaitingPaymentReturn) {
      return;
    }
    if (_paymentReturnFallbackScheduled) {
      return;
    }
    _paymentReturnFallbackScheduled = true;

    // The gateway is no longer "opening" once we're back -- update the
    // overlay copy so it doesn't read as if we're about to reopen it while
    // we briefly wait to see whether a real result is on its way.
    setState(() => _loadingPhase = _AppointmentLoadingPhase.confirmingReturn);

    final baselineCallbackCount = _paymentReturnBaselineCallbackCount;

    _paymentReturnFallbackTimer = Timer(_paymentReturnFallbackDelay, () {
      if (!mounted || !_awaitingPaymentReturn) {
        return;
      }
      if (LaropayReturnNavigationController.handledCallbackCount.value !=
          baselineCallbackCount) {
        // A real Laropay deep-link result was processed while we were
        // waiting -- it owns navigation, not this fallback.
        _awaitingPaymentReturn = false;
        _pendingPaymentLinkId = null;
        _cancelPaymentReturnFallback();
        return;
      }
      unawaited(_verifyPaymentReturnFallback(baselineCallbackCount));
    });
  }

  Future<void> _verifyPaymentReturnFallback(int? baselineCallbackCount) async {
    final paymentLinkId = _pendingPaymentLinkId?.trim() ?? '';
    if (paymentLinkId.isEmpty) {
      _finishUnverifiedPaymentReturn();
      return;
    }

    late final Either<Failure, LaropayPurchase> result;
    try {
      result = await sl<RefreshLaropayPurchaseStatus>()(
        paymentLinkId,
      ).timeout(_paymentStatusVerificationTimeout);
    } on TimeoutException {
      _finishUnverifiedPaymentReturn();
      return;
    }

    if (!mounted || !_awaitingPaymentReturn) {
      return;
    }
    if (LaropayReturnNavigationController.handledCallbackCount.value !=
        baselineCallbackCount) {
      _awaitingPaymentReturn = false;
      _pendingPaymentLinkId = null;
      _cancelPaymentReturnFallback();
      return;
    }

    _awaitingPaymentReturn = false;
    _pendingPaymentLinkId = null;
    _cancelPaymentReturnFallback();
    setState(() => _loadingPhase = null);

    result.fold((_) {
      _showPendingPaymentReviewMessage();
      context.go('/purchases');
    }, (_) => context.go('/purchases?paymentLinkId=$paymentLinkId'));
  }

  void _finishUnverifiedPaymentReturn() {
    if (!mounted) {
      return;
    }
    _awaitingPaymentReturn = false;
    _pendingPaymentLinkId = null;
    _cancelPaymentReturnFallback();
    setState(() => _loadingPhase = null);
    _showPendingPaymentReviewMessage();
    context.go('/purchases');
  }

  void _showPendingPaymentReviewMessage() {
    final l10n = AppLocalizations.of(context)!;
    _showAppointmentMessage(
      context,
      message: l10n.laropayPaymentResultPendingMessage,
      type: AppMessageType.warning,
    );
  }

  void _startAwaitingPaymentReturn(String paymentLinkId) {
    _cancelPaymentReturnFallback();
    _paymentReturnBaselineCallbackCount =
        LaropayReturnNavigationController.handledCallbackCount.value;
    _pendingPaymentLinkId = paymentLinkId;
    _awaitingPaymentReturn = true;
  }

  void _stopAwaitingPaymentReturn() {
    _awaitingPaymentReturn = false;
    _pendingPaymentLinkId = null;
    _cancelPaymentReturnFallback();
  }

  void _cancelPaymentReturnFallback() {
    _paymentReturnFallbackTimer?.cancel();
    _paymentReturnFallbackTimer = null;
    _paymentReturnFallbackScheduled = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppointmentCubit>()
        ..load(
          widget.workshopId,
          initialServiceId: widget.initialServiceId,
          initialService: widget.initialSelection?.service,
          initialProducts: widget.initialSelection?.products,
        ),
      child: BlocBuilder<AppointmentCubit, AppointmentState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          final steps = _appointmentSteps(l10n);
          final isDesktop = MediaQuery.sizeOf(context).width >= 900;

          return Scaffold(
            backgroundColor: AutolabCustomer.customerBackgroundColor(context),
            body: SafeArea(
              child: isDesktop
                  ? Row(
                      children: [
                        SizedBox(
                          width: 430,
                          child: _DesktopRail(
                            steps: steps,
                            currentStep: state.currentStep,
                            workshopName: _workshopName(state),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: _pageBody(
                            context: context,
                            state: state,
                            steps: steps,
                            isDesktop: true,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: _pageBody(
                            context: context,
                            state: state,
                            steps: steps,
                            isDesktop: false,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _pageBody({
    required BuildContext context,
    required AppointmentState state,
    required List<_AppointmentStep> steps,
    required bool isDesktop,
  }) {
    final isSubmitting =
        state.submitStatus == AppointmentSubmitStatus.submitting;
    final isBusy = isSubmitting || _loadingPhase != null;
    final horizontalPadding = isDesktop
        ? AutolabCustomer.responsiveDouble(
            context,
            compact: 56,
            regular: 72,
            tablet: 92,
          )
        : AutolabCustomer.responsiveScreenMargin(context);
    final topPadding = isDesktop
        ? AutolabCustomer.responsiveDouble(
            context,
            compact: 56,
            regular: 72,
            tablet: 96,
          )
        : AutolabCustomer.responsiveDouble(
            context,
            compact: AutolabCustomer.spacingSmd,
            regular: AutolabCustomer.spacingLg,
            tablet: AutolabCustomer.spacingXl,
          );

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1224),
                    child: _buildStepContent(
                      context: context,
                      state: state,
                      steps: steps,
                      isDesktop: isDesktop,
                    ),
                  ),
                ),
              ),
            ),
            _FooterActions(
              canGoBack: state.currentStep > 0,
              isLastStep: state.currentStep == steps.length - 1,
              isSubmitting: isBusy,
              onBack: () => _handleBack(context, state),
              onNext: () => _goNextStep(context, state, steps.length),
            ),
          ],
        ),
        if (isBusy)
          _BookingSubmittingOverlay(
            phase: _loadingPhase ?? _AppointmentLoadingPhase.creating,
          ),
      ],
    );
  }

  Widget _buildStepContent({
    required BuildContext context,
    required AppointmentState state,
    required List<_AppointmentStep> steps,
    required bool isDesktop,
  }) {
    switch (state.currentStep) {
      case 0:
        return _DateTimeMock(
          title: steps[state.currentStep].title,
          selectedDate: state.selectedDate,
          selectedTime: state.selectedTime,
          focusedDate: state.focusedDate ?? DateTime.now(),
          unavailableDates: state.unavailableDates,
          unavailableTimesByDate: state.unavailableTimesByDate,
          availableTimesByDate: state.availableTimesByDate,
          availabilityStatus: state.availabilityStatus,
          onDaySelected: context.read<AppointmentCubit>().selectDate,
          onFocusedDateChanged: context.read<AppointmentCubit>().focusDate,
          onSelected: context.read<AppointmentCubit>().selectTime,
        );
      case 1:
        return _BookingReviewStep(
          title: steps[state.currentStep].title,
          workshopName: _workshopName(state),
          service: state.selectedService,
          licensePlate: state.vehicleLicensePlate,
          products: state.selectedProducts,
          date: state.selectedDate,
          time: state.selectedTime ?? '9:00 AM',
          onNoteChanged: context.read<AppointmentCubit>().updateCustomerNote,
          note: state.customerNote,
          hasChargeableProducts: state.hasChargeableProducts,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<bool> _waitForExternalPaymentTransition() async {
    final transitionCompleter = Completer<bool>();
    _externalPaymentTransitionCompleter = transitionCompleter;

    try {
      return await transitionCompleter.future.timeout(
        _externalPaymentTransitionTimeout,
      );
    } on TimeoutException {
      // Some in-app browser implementations do not emit lifecycle changes.
      // Do not treat this as a return from Laropay; the gateway may still be
      // opening and checking status now can produce a false provider error.
      return false;
    } finally {
      if (identical(_externalPaymentTransitionCompleter, transitionCompleter)) {
        _externalPaymentTransitionCompleter = null;
      }
    }
  }

  void _completeExternalPaymentTransition() {
    final completer = _externalPaymentTransitionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(true);
    }
    if (identical(_externalPaymentTransitionCompleter, completer)) {
      _externalPaymentTransitionCompleter = null;
    }
  }

  String _workshopName(AppointmentState state) {
    final name = state.workshop?.name.trim();
    return name == null || name.isEmpty ? 'Taller Autolab' : name;
  }

  void _handleBack(BuildContext context, AppointmentState state) {
    if (state.currentStep == 0) {
      _closeAppointmentFlow(context);
      return;
    }

    context.read<AppointmentCubit>().goBack();
  }

  void _closeAppointmentFlow(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    _goToWorkshopProfileOrHome(context);
  }

  void _goToWorkshopProfileOrHome(BuildContext context) {
    final workshopId = widget.workshopId.trim();
    context.go(
      workshopId.isEmpty ? '/home-customer' : '/workshops/$workshopId',
    );
  }

  Future<void> _goNextStep(
    BuildContext context,
    AppointmentState state,
    int stepCount,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (state.currentStep == stepCount - 1) {
      final cubit = context.read<AppointmentCubit>();
      final appointmentId = await cubit.submitBooking();

      if (!context.mounted) {
        return;
      }

      final submitState = cubit.state;
      if (appointmentId != null) {
        if (submitState.hasChargeableProducts) {
          try {
            setState(() => _loadingPhase = _AppointmentLoadingPhase.payment);
            await WidgetsBinding.instance.endOfFrame;
            final checkoutSession = await sl<LaropayCheckoutLauncher>().launch(
              appointmentId: appointmentId,
              workshopName: _workshopName(submitState),
              chargeableAmount: submitState.chargeableProductsAmount,
            );
            if (!context.mounted) {
              return;
            }
            _startAwaitingPaymentReturn(checkoutSession.paymentLinkId);
            await sl<LaropayCheckoutBrowserLauncher>()
                .open(checkoutSession)
                .timeout(_externalPaymentTransitionTimeout);
            if (!context.mounted) {
              return;
            }
            final didLeaveForPayment =
                await _waitForExternalPaymentTransition();
            if (!context.mounted) {
              return;
            }
            if (!didLeaveForPayment) {
              _stopAwaitingPaymentReturn();
              setState(() => _loadingPhase = null);
              return;
            }
            // When the app really left for Laropay, wait for
            // AppLifecycleState.resumed to decide whether a fallback status
            // check is needed. Running it here would query Laropay while the
            // gateway is still opening.
          } on LaropayCheckoutLaunchException catch (_) {
            if (!context.mounted) {
              return;
            }

            _stopAwaitingPaymentReturn();
            setState(() => _loadingPhase = null);
            _showAppointmentMessage(
              context,
              message: l10n.laropayPaymentStartError,
              type: AppMessageType.error,
            );
            _goToWorkshopProfileOrHome(context);
          } on TimeoutException {
            if (!context.mounted) {
              return;
            }

            _stopAwaitingPaymentReturn();
            setState(() => _loadingPhase = null);
            _showAppointmentMessage(
              context,
              message: l10n.laropayPaymentStartError,
              type: AppMessageType.error,
            );
            _goToWorkshopProfileOrHome(context);
          }
          return;
        }

        final shouldReturnToWorkshop = await _showAppointmentCreatedDialog(
          context,
        );
        if (!context.mounted || !shouldReturnToWorkshop) {
          return;
        }
        _goToWorkshopProfileOrHome(context);
      } else {
        _showAppointmentMessage(
          context,
          message: _appointmentSubmitErrorMessage(submitState, l10n),
          type: AppMessageType.error,
        );
      }
      return;
    }

    if (state.currentStep == 0) {
      final cubit = context.read<AppointmentCubit>();
      final isVehicleValid = await cubit.validateVehicleForBooking();

      if (!context.mounted) {
        return;
      }

      if (!isVehicleValid) {
        _showAppointmentMessage(
          context,
          message: _appointmentSubmitErrorMessage(cubit.state, l10n),
          type: AppMessageType.warning,
        );
        return;
      }
    }

    if (state.selectedService == null) {
      _showAppointmentMessage(
        context,
        message: l10n.appointmentNoSchedulableServices,
        type: AppMessageType.warning,
      );
      return;
    }

    if (state.currentStep == 0) {
      if (state.selectedDate == null || state.selectedTime == null) {
        _showAppointmentMessage(
          context,
          message: l10n.appointmentSelectDateTimeRequired,
          type: AppMessageType.warning,
        );
        return;
      }

      final cubit = context.read<AppointmentCubit>();
      final isScheduleAvailable = await cubit
          .validateSelectedScheduleForBooking();

      if (!context.mounted) {
        return;
      }

      if (!isScheduleAvailable) {
        _showAppointmentMessage(
          context,
          message: _appointmentSubmitErrorMessage(cubit.state, l10n),
          type: AppMessageType.warning,
        );
        return;
      }
    }

    context.read<AppointmentCubit>().goNext();
  }

  Future<bool> _showAppointmentCreatedDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final shouldReturnToWorkshop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            icon: const Icon(
              Icons.check_circle_outline,
              color: AutolabCustomer.success,
              size: 42,
            ),
            title: Text(
              l10n.appointmentCreatedSuccess,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              l10n.appointmentConfirmationDeliveryMessage,
              textAlign: TextAlign.center,
              style: AutolabCustomer.body.copyWith(height: 1.35),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.laropayPaymentResultBackToWorkshopAction),
              ),
            ],
          ),
        );
      },
    );

    return shouldReturnToWorkshop ?? false;
  }

  void _showAppointmentMessage(
    BuildContext context, {
    required String message,
    required AppMessageType type,
  }) {
    showAppSnackBar(context, message: message, type: type);
  }
}

class WorkshopAppointmentInitialSelection {
  const WorkshopAppointmentInitialSelection({
    required this.service,
    this.products = const [],
  });

  final Product service;
  final List<AppointmentSelectedProduct> products;
}

List<_AppointmentStep> _appointmentSteps(AppLocalizations l10n) {
  return [
    _AppointmentStep(l10n.appointmentStepDateTime, Icons.event_outlined),
    _AppointmentStep(
      l10n.appointmentStepConfirmation,
      Icons.check_circle_outline,
    ),
  ];
}

String _appointmentSubmitErrorMessage(
  AppointmentState state,
  AppLocalizations l10n,
) {
  return switch (state.submitError) {
    AppointmentSubmitError.dateUnavailable => l10n.appointmentDateUnavailable,
    AppointmentSubmitError.scheduleRequired => l10n.appointmentScheduleRequired,
    AppointmentSubmitError.slotUnavailable => l10n.appointmentSlotUnavailable,
    AppointmentSubmitError.scheduleValidationFailed =>
      l10n.appointmentScheduleValidationFailed,
    AppointmentSubmitError.vehiclePlateRequired =>
      l10n.appointmentVehiclePlateRequired,
    AppointmentSubmitError.vehiclePlateConflict =>
      l10n.appointmentVehiclePlateConflict,
    AppointmentSubmitError.vehicleValidationFailed =>
      l10n.appointmentVehicleValidationFailedDetailed,
    AppointmentSubmitError.bookingIncomplete =>
      l10n.appointmentBookingIncomplete,
    AppointmentSubmitError.authRequired => l10n.appointmentAuthRequired,
    AppointmentSubmitError.dateTimeInPast => l10n.appointmentDateTimeInPast,
    AppointmentSubmitError.invalidSlotInterval =>
      l10n.appointmentInvalidSlotInterval,
    AppointmentSubmitError.businessHoursUnavailable =>
      l10n.appointmentBusinessHoursUnavailable,
    AppointmentSubmitError.workshopClosed => l10n.appointmentWorkshopClosed,
    AppointmentSubmitError.outsideBusinessHours =>
      l10n.appointmentOutsideBusinessHours,
    AppointmentSubmitError.serviceNotSchedulable =>
      l10n.appointmentServiceNotSchedulable,
    AppointmentSubmitError.serviceDurationRequired =>
      l10n.appointmentServiceDurationRequired,
    AppointmentSubmitError.noActiveEmployees =>
      l10n.appointmentNoActiveEmployees,
    AppointmentSubmitError.vehicleNotOwned => l10n.appointmentVehicleNotOwned,
    AppointmentSubmitError.vehiclePlateRequiredForBooking =>
      l10n.appointmentVehiclePlateRequiredForBooking,
    AppointmentSubmitError.productsInvalid => l10n.appointmentProductsInvalid,
    AppointmentSubmitError.productStockUnavailable =>
      l10n.appointmentProductStockUnavailable,
    AppointmentSubmitError.bookingConfigurationFailed =>
      l10n.appointmentBookingConfigurationFailed,
    AppointmentSubmitError.bookingFailed => l10n.appointmentCreateFailed,
    null => state.submitErrorMessage ?? l10n.appointmentCreateFailed,
  };
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.steps,
    required this.currentStep,
    required this.workshopName,
  });

  final List<_AppointmentStep> steps;
  final int currentStep;
  final String workshopName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 38, 32, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AutolabLogo(large: true),
          const SizedBox(height: 64),
          ...List.generate(steps.length, (index) {
            return _DesktopStepItem(
              number: index + 1,
              title: steps[index].title,
              active: index == currentStep,
              done: index < currentStep,
              showLine: index < steps.length - 1,
            );
          }),
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.appointmentStepWorkshop,
            style: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: context.customerPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            workshopName,
            style: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: context.customerInk,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(
              context,
            )!.appointmentWorkshopFallbackDescription,
            style: const TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: AutolabCustomer.gray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Autolab Customer',
            style: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: context.customerMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopStepItem extends StatelessWidget {
  const _DesktopStepItem({
    required this.number,
    required this.title,
    required this.active,
    required this.done,
    required this.showLine,
  });

  final int number;
  final String title;
  final bool active;
  final bool done;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final color = active || done
        ? context.customerPrimary
        : AutolabCustomer.gray;
    final titleColor = active || done
        ? context.customerPrimary
        : context.customerMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active || done ? color : context.customerElevatedSurface,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: AutolabCustomer.shadowBlackIntense,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '$number',
                style: TextStyle(
                  fontFamily: AutolabCustomer.primaryFont,
                  color: active || done ? AutolabCustomer.white : color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (showLine)
              Container(width: 1, height: 48, color: context.customerBorder),
          ],
        ),
        const SizedBox(width: 30),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductsSelectionStep extends StatefulWidget {
  const _ProductsSelectionStep({
    required this.products,
    required this.status,
    required this.includeProducts,
    required this.selectedProducts,
    required this.onIncludeChanged,
    required this.onProductToggled,
    required this.onQuantityChanged,
  });

  final List<Product> products;
  final AppointmentLoadStatus status;
  final bool includeProducts;
  final List<AppointmentSelectedProduct> selectedProducts;
  final ValueChanged<bool> onIncludeChanged;
  final ValueChanged<Product> onProductToggled;
  final void Function(Product product, int delta) onQuantityChanged;

  @override
  State<_ProductsSelectionStep> createState() => _ProductsSelectionStepState();
}

class _ProductsSelectionStepState extends State<_ProductsSelectionStep> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: context.customerElevatedSurface,
            border: Border.all(color: context.customerBorder),
            boxShadow: const [
              BoxShadow(
                color: AutolabCustomer.shadowBlackLight,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appointmentProductsSwitchLabel,
                  style: TextStyle(
                    fontFamily: AutolabCustomer.primaryFont,
                    color: context.customerInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(
                value: widget.includeProducts,
                activeThumbColor: context.customerPrimary,
                onChanged: widget.onIncludeChanged,
              ),
            ],
          ),
        ),
        if (!widget.includeProducts) ...[
          const SizedBox(height: 16),
          _ProductsInfoMessage(
            message: l10n.appointmentProductsOptionalMessage,
          ),
        ] else ...[
          const SizedBox(height: 18),
          if (widget.status == AppointmentLoadStatus.loading)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.products.isEmpty)
            _ProductsInfoMessage(message: l10n.appointmentProductsEmpty)
          else
            ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
                AppointmentSelectedProduct? selectedProduct;
                for (final item in widget.selectedProducts) {
                  if (item.product.id == product.id) {
                    selectedProduct = item;
                    break;
                  }
                }
                final selected = selectedProduct != null;
                final quantity = selectedProduct?.quantity ?? 0;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == widget.products.length - 1 ? 0 : 12,
                  ),
                  child: _ProductOptionCard(
                    product: product,
                    selected: selected,
                    quantity: quantity,
                    onTap: () => widget.onProductToggled(product),
                    onQuantityChanged: (delta) =>
                        widget.onQuantityChanged(product, delta),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}

class _ServiceMetaChip extends StatelessWidget {
  const _ServiceMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.customerSoftSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.customerPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: context.customerInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductOptionCard extends StatelessWidget {
  const _ProductOptionCard({
    required this.product,
    required this.selected,
    required this.quantity,
    required this.onTap,
    required this.onQuantityChanged,
  });

  final Product product;
  final bool selected;
  final int quantity;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.customerSoftSurface
          : context.customerElevatedSurface,
      elevation: 2,
      shadowColor: AutolabCustomer.shadowBlack26,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? context.customerPrimary
                  : context.customerBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: context.customerPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AutolabCustomer.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontFamily: AutolabCustomer.primaryFont,
                        color: context.customerInk,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.effectiveDescription,
                      style: TextStyle(
                        fontFamily: AutolabCustomer.primaryFont,
                        color: context.customerMuted,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    if (product.sellingPrice != null) ...[
                      const SizedBox(height: 12),
                      _ServiceMetaChip(
                        icon: Icons.payments_outlined,
                        label: formatProductPrice(product.sellingPrice),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (selected)
                _QuantityStepper(
                  quantity: quantity,
                  onChanged: onQuantityChanged,
                )
              else
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: AutolabCustomer.gray,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsInfoMessage extends StatelessWidget {
  const _ProductsInfoMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.customerElevatedSurface,
        border: Border.all(color: context.customerBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: context.customerPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                color: context.customerInk,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.customerElevatedSurface,
        border: Border.all(color: context.customerBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove_rounded,
            onTap: () => onChanged(-1),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                color: context.customerInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _QuantityButton(icon: Icons.add_rounded, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 20, color: context.customerPrimary),
      ),
    );
  }
}

enum _AppointmentLoadingPhase { creating, payment, confirmingReturn }

class _BookingSubmittingOverlay extends StatelessWidget {
  const _BookingSubmittingOverlay({required this.phase});

  final _AppointmentLoadingPhase phase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (title, message) = switch (phase) {
      _AppointmentLoadingPhase.payment => (
        l10n.appointmentOpeningPaymentTitle,
        l10n.appointmentOpeningPaymentMessage,
      ),
      _AppointmentLoadingPhase.confirmingReturn => (
        l10n.cartConfirmingPaymentTitle,
        l10n.cartConfirmingPaymentMessage,
      ),
      _AppointmentLoadingPhase.creating => (
        l10n.appointmentCreatingTitle,
        l10n.appointmentCreatingMessage,
      ),
    };

    return Positioned.fill(
      child: AbsorbPointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AutolabCustomer.isDark(context)
                ? AutolabCustomer.overlayBlackMedium
                : AutolabCustomer.overlayWhiteStrong,
          ),
          child: Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              decoration: BoxDecoration(
                color: context.customerElevatedSurface,
                border: Border.all(color: context.customerBorder),
                boxShadow: const [
                  BoxShadow(
                    color: AutolabCustomer.shadowBlackStrong,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: context.customerPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AutolabCustomer.primaryFont,
                      color: context.customerInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AutolabCustomer.primaryFont,
                      color: context.customerMuted,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.canGoBack,
    required this.isLastStep,
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
  });

  final bool canGoBack;
  final bool isLastStep;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final horizontalPadding = isDesktop
        ? AutolabCustomer.spacingXl
        : AutolabCustomer.responsiveScreenMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AutolabCustomer.spacingSm,
        horizontalPadding,
        isDesktop ? AutolabCustomer.spacingXl : AutolabCustomer.spacingLg,
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    label: canGoBack
                        ? l10n.appointmentBackAction
                        : l10n.appointmentExitAction,
                    onPressed: isSubmitting ? null : onBack,
                  ),
                ),
                const SizedBox(width: AutolabCustomer.spacingSm),
                Expanded(
                  child: _OutlineActionButton(
                    label: isSubmitting
                        ? l10n.appointmentCreatingAction
                        : isLastStep
                        ? l10n.appointmentConfirmAction
                        : l10n.appointmentNextAction,
                    onPressed: isSubmitting ? null : onNext,
                    isLoading: isSubmitting,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AutolabCustomer.responsiveDouble(
        context,
        compact: 46,
        regular: 52,
        tablet: 58,
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isPrimary
              ? AutolabCustomer.primary
              : AutolabCustomer.transparent,
          foregroundColor: isPrimary
              ? AutolabCustomer.white
              : context.customerInk,
          disabledBackgroundColor: isPrimary
              ? AutolabCustomer.primary.withValues(alpha: 0.45)
              : AutolabCustomer.transparent,
          disabledForegroundColor: AutolabCustomer.customerSecondaryTextColor(
            context,
          ),
          side: BorderSide(color: AutolabCustomer.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
          ),
          textStyle: AutolabCustomer.body.copyWith(fontWeight: FontWeight.w800),
        ),
        child: FittedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentFlowHeader extends StatelessWidget {
  const _AppointmentFlowHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [const _AutolabLogo()],
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingMd),
        Text(
          title,
          style: AutolabCustomer.bodyLarge.copyWith(
            color: context.customerInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AutolabCustomer.spacingXs),
          Text(
            subtitle!,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _DateTimeMock extends StatelessWidget {
  const _DateTimeMock({
    required this.title,
    required this.selectedDate,
    required this.selectedTime,
    required this.focusedDate,
    required this.unavailableDates,
    required this.unavailableTimesByDate,
    required this.availableTimesByDate,
    required this.availabilityStatus,
    required this.onDaySelected,
    required this.onFocusedDateChanged,
    required this.onSelected,
  });

  final String title;
  final DateTime? selectedDate;
  final String? selectedTime;
  final DateTime focusedDate;
  final List<DateTime> unavailableDates;
  final Map<DateTime, Set<String>> unavailableTimesByDate;
  final Map<DateTime, List<String>> availableTimesByDate;
  final AppointmentLoadStatus availabilityStatus;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onFocusedDateChanged;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppointmentFlowHeader(title: title),
        const SizedBox(height: AutolabCustomer.spacingMd),
        _AppointmentCalendar(
          selectedDate: selectedDate,
          focusedDate: focusedDate,
          unavailableDates: unavailableDates,
          shouldBlockUnavailableDates:
              availabilityStatus == AppointmentLoadStatus.success,
          onDaySelected: onDaySelected,
          onFocusedDateChanged: onFocusedDateChanged,
        ),
        if (selectedDate != null) ...[
          const SizedBox(height: 24),
          _AvailableHoursPanel(
            times: _timesForSelectedDate(),
            selectedTime: selectedTime,
            unavailableTimes: _unavailableTimesForSelectedDate(),
            availabilityStatus: availabilityStatus,
            onSelected: onSelected,
          ),
        ],
      ],
    );
  }

  List<String> _availableTimesForSelectedDate() {
    final date = selectedDate;
    if (date == null) {
      return const [];
    }

    for (final entry in availableTimesByDate.entries) {
      if (isSameDay(entry.key, date)) {
        return entry.value;
      }
    }

    return const [];
  }

  Set<String> _unavailableTimesForSelectedDate() {
    final date = selectedDate;
    if (date == null) {
      return const {};
    }

    for (final entry in unavailableTimesByDate.entries) {
      if (isSameDay(entry.key, date)) {
        return entry.value;
      }
    }

    return const {};
  }

  List<String> _timesForSelectedDate() {
    final times = {
      ..._availableTimesForSelectedDate(),
      ..._unavailableTimesForSelectedDate(),
    }.toList();

    times.sort();
    return times;
  }
}

class _AppointmentCalendar extends StatelessWidget {
  const _AppointmentCalendar({
    required this.selectedDate,
    required this.focusedDate,
    required this.unavailableDates,
    required this.shouldBlockUnavailableDates,
    required this.onDaySelected,
    required this.onFocusedDateChanged,
  });

  final DateTime? selectedDate;
  final DateTime focusedDate;
  final List<DateTime> unavailableDates;
  final bool shouldBlockUnavailableDates;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onFocusedDateChanged;

  static final _firstDay = DateTime.utc(2020, 1, 1);
  static final _lastDay = DateTime.utc(2035, 12, 31);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rowHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 38,
      regular: 43,
      tablet: 50,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar<void>(
          firstDay: _firstDay,
          lastDay: _lastDay,
          focusedDay: focusedDate,
          locale: 'es',
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableGestures: AvailableGestures.none,
          daysOfWeekHeight: 26,
          rowHeight: rowHeight,
          enabledDayPredicate: (day) {
            final calendarDay = DateTime(day.year, day.month, day.day);
            if (calendarDay.isBefore(today)) {
              return false;
            }

            if (!shouldBlockUnavailableDates) {
              return true;
            }

            return !unavailableDates.any(
              (unavailableDate) => isSameDay(unavailableDate, day),
            );
          },
          selectedDayPredicate: (day) =>
              selectedDate != null && isSameDay(day, selectedDate),
          onDaySelected: (selected, focused) {
            onDaySelected(selected);
          },
          onPageChanged: onFocusedDateChanged,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: context.customerInk,
              size: AutolabCustomer.iconSm,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: context.customerInk,
              size: AutolabCustomer.iconSm,
            ),
            leftChevronPadding: EdgeInsets.zero,
            rightChevronPadding: EdgeInsets.zero,
            leftChevronMargin: EdgeInsets.zero,
            rightChevronMargin: EdgeInsets.zero,
            titleTextStyle: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: context.customerInk,
              fontSize: AutolabCustomer.responsiveDouble(
                context,
                compact: 12,
                regular: 13,
                tablet: 16,
              ),
              fontWeight: FontWeight.w800,
            ),
            titleTextFormatter: (date, locale) {
              final month = DateFormat.MMMM(locale).format(date);
              return l10n.appointmentMonthYearTitle(
                _capitalize(month),
                date.year,
              );
            },
            headerPadding: const EdgeInsets.only(bottom: 6),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: context.customerInk,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            weekendStyle: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: context.customerInk,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          calendarStyle: const CalendarStyle(outsideDaysVisible: true),
          calendarBuilders: CalendarBuilders<void>(
            defaultBuilder: (context, day, focusedDay) {
              return _TableCalendarDay(day: day);
            },
            disabledBuilder: (context, day, focusedDay) {
              return _TableCalendarDay(day: day, disabled: true);
            },
            outsideBuilder: (context, day, focusedDay) {
              return _TableCalendarDay(day: day, outside: true);
            },
            selectedBuilder: (context, day, focusedDay) {
              return _TableCalendarDay(day: day, selected: true);
            },
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingMd),
        Wrap(
          spacing: AutolabCustomer.spacingSm,
          runSpacing: AutolabCustomer.spacingXs,
          children: [
            _CalendarLegend(
              color: AutolabCustomer.primary,
              shape: BoxShape.circle,
              label: l10n.appointmentSelectedDayLegend,
            ),
            _CalendarLegend(
              color: AutolabCustomer.transparent,
              borderColor: context.customerBorder,
              label: l10n.appointmentAvailableDayLegend,
            ),
            if (shouldBlockUnavailableDates)
              _CalendarLegend(
                color: AutolabCustomer.gray,
                label: l10n.appointmentOccupiedDayLegend,
              ),
          ],
        ),
      ],
    );
  }
}

class _TableCalendarDay extends StatelessWidget {
  const _TableCalendarDay({
    required this.day,
    this.selected = false,
    this.outside = false,
    this.disabled = false,
  });

  final DateTime day;
  final bool selected;
  final bool outside;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = disabled
        ? AutolabCustomer.gray
        : selected
        ? AutolabCustomer.primary
        : AutolabCustomer.transparent;
    final textColor = selected
        ? AutolabCustomer.white
        : disabled
        ? AutolabCustomer.white
        : outside
        ? AutolabCustomer.gray.withValues(alpha: 0.45)
        : day.weekday == DateTime.saturday || day.weekday == DateTime.sunday
        ? AutolabCustomer.primary
        : context.customerInk;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        // Both branches must stay finite -- AnimatedContainer tweens width
        // and height independently of the parent's real constraints, and
        // BoxConstraints.lerp can't interpolate a finite size against
        // double.infinity (that combination crashed every time the
        // selected day changed, since one cell animates in while another
        // animates out).
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: selected ? BoxShape.circle : BoxShape.rectangle,
          border: Border.all(
            color: AutolabCustomer.customerBorderColor(
              context,
            ).withValues(alpha: 0.32),
            width: 0.5,
          ),
        ),
        child: Text(
          '${day.day}',
          style: AutolabCustomer.label.copyWith(
            color: textColor,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({
    required this.color,
    required this.label,
    this.borderColor,
    this.shape = BoxShape.rectangle,
  });

  final Color color;
  final String label;
  final Color? borderColor;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
        ),
        const SizedBox(width: AutolabCustomer.spacingXs),
        Text(
          label,
          style: AutolabCustomer.caption.copyWith(
            color: context.customerInk,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _AvailableHoursPanel extends StatelessWidget {
  const _AvailableHoursPanel({
    required this.times,
    required this.selectedTime,
    required this.unavailableTimes,
    required this.availabilityStatus,
    required this.onSelected,
  });

  final List<String> times;
  final String? selectedTime;
  final Set<String> unavailableTimes;
  final AppointmentLoadStatus availabilityStatus;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appointmentAvailableHoursTitle,
          style: AutolabCustomer.bodyLarge.copyWith(
            color: context.customerInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingXs),
        Text(
          l10n.appointmentPickupLabel,
          style: AutolabCustomer.label.copyWith(
            color: AutolabCustomer.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingMd),
        if (availabilityStatus == AppointmentLoadStatus.loading)
          _AvailabilityPanelMessage(
            icon: Icons.schedule_outlined,
            message: l10n.appointmentAvailableHoursLoading,
          )
        else if (availabilityStatus == AppointmentLoadStatus.failure)
          _AvailabilityPanelMessage(
            icon: Icons.error_outline,
            message: l10n.appointmentAvailableHoursFailed,
            color: AutolabCustomer.primary,
          )
        else if (times.isEmpty)
          _AvailabilityPanelMessage(
            icon: Icons.info_outline,
            message: l10n.appointmentAvailableHoursEmpty,
          )
        else
          Wrap(
            spacing: AutolabCustomer.spacingXs,
            runSpacing: AutolabCustomer.spacingXs,
            children: times.map((time) {
              final selected = selectedTime == time;
              final unavailable = unavailableTimes.contains(time);

              return SizedBox(
                width: AutolabCustomer.responsiveDouble(
                  context,
                  compact: 70,
                  regular: 74,
                  tablet: 86,
                ),
                height: 34,
                child: OutlinedButton(
                  onPressed: unavailable ? null : () => onSelected(time),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: unavailable
                        ? AutolabCustomer.gray.withValues(alpha: 0.35)
                        : selected
                        ? AutolabCustomer.primary
                        : AutolabCustomer.transparent,
                    foregroundColor: unavailable
                        ? AutolabCustomer.gray
                        : selected
                        ? AutolabCustomer.white
                        : context.customerInk,
                    side: BorderSide(
                      color: unavailable
                          ? AutolabCustomer.gray.withValues(alpha: 0.5)
                          : selected
                          ? AutolabCustomer.primary
                          : context.customerBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AutolabCustomer.radiusChip,
                      ),
                    ),
                    textStyle: AutolabCustomer.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(time),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _AvailabilityPanelMessage extends StatelessWidget {
  const _AvailabilityPanelMessage({
    required this.icon,
    required this.message,
    this.color,
  });

  final IconData icon;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AutolabCustomer.gray;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: effectiveColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: effectiveColor,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppointmentNoteInput extends StatelessWidget {
  const _AppointmentNoteInput({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      borderSide: const BorderSide(color: AutolabCustomer.primary),
    );

    return TextFormField(
      key: const ValueKey('appointment-note-input'),
      initialValue: initialValue,
      minLines: 4,
      maxLines: 5,
      maxLength: 280,
      onChanged: onChanged,
      style: AutolabCustomer.caption.copyWith(color: context.customerInk),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.appointmentNoteHint,
        hintStyle: AutolabCustomer.caption.copyWith(
          color: AutolabCustomer.customerSecondaryTextColor(context),
        ),
        filled: true,
        fillColor: AutolabCustomer.transparent,
        contentPadding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(
            color: AutolabCustomer.primary,
            width: 1.4,
          ),
        ),
        counterStyle: AutolabCustomer.label.copyWith(
          color: context.customerInk,
        ),
      ),
    );
  }
}

class _BookingReviewStep extends StatelessWidget {
  const _BookingReviewStep({
    required this.title,
    required this.workshopName,
    required this.service,
    required this.licensePlate,
    required this.products,
    required this.date,
    required this.time,
    required this.onNoteChanged,
    required this.note,
    required this.hasChargeableProducts,
  });

  final String title;
  final String workshopName;
  final Product? service;
  final String licensePlate;
  final List<AppointmentSelectedProduct> products;
  final DateTime? date;
  final String time;
  final ValueChanged<String> onNoteChanged;
  final String note;
  // Whether submitting this booking will charge the customer online through
  // Laropay for the selected products (see submitBooking() /
  // AppointmentState.hasChargeableProducts). "Total a pagar" below already
  // folds the service price in as an informational figure, so without this
  // notice a customer could easily read that combined total as what they're
  // about to pay right now, when only the products portion is actually
  // charged -- the service itself is paid at the workshop, separately.
  final bool hasChargeableProducts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabel = date == null
        ? l10n.appointmentPendingDate
        : l10n.appointmentFullDate(
            date!.day,
            _monthName(context, date!),
            date!.year,
          );
    final productsTotal = products.fold<double>(
      0,
      (total, item) =>
          total + ((item.product.sellingPrice ?? 0) * item.quantity),
    );
    final hasPricelessItems = products.any(
      (item) => item.product.sellingPrice == null,
    );
    final servicePrice = service?.sellingPrice;
    final total = (servicePrice ?? 0) + productsTotal;
    final hasPriceToConfirm = servicePrice == null || hasPricelessItems;
    final iva = CartPricing.includedTaxes(total);
    final subtotal = CartPricing.netSubtotal(total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppointmentFlowHeader(
          title: title,
          subtitle: l10n.appointmentConfirmationReadyTitle,
        ),
        const SizedBox(height: AutolabCustomer.spacingLg),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            AutolabCustomer.responsiveDouble(
              context,
              compact: AutolabCustomer.spacingSmd,
              regular: AutolabCustomer.spacingMd,
              tablet: AutolabCustomer.spacingLg,
            ),
          ),
          decoration: BoxDecoration(
            color: AutolabCustomer.customerSurfaceColor(context),
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.16),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AutolabCustomer.responsiveDouble(
                    context,
                    compact: 56,
                    regular: 62,
                    tablet: 72,
                  ),
                  height: AutolabCustomer.responsiveDouble(
                    context,
                    compact: 56,
                    regular: 62,
                    tablet: 72,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AutolabCustomer.primary,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AutolabCustomer.primary,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              _SummaryRow(
                label: l10n.appointmentVehiclePlateLabel,
                value: licensePlate.trim().isEmpty
                    ? l10n.appointmentPendingPlate
                    : licensePlate.trim().toUpperCase(),
              ),
              _SummaryRow(
                label: l10n.appointmentWorkshopLabel,
                value: workshopName,
              ),
              _SummaryRow(
                label: l10n.appointmentServiceLabel,
                value: service?.name ?? l10n.appointmentPendingService,
              ),
              _SummaryRow(
                label: l10n.appointmentCostLabel,
                value: servicePrice == null
                    ? l10n.appointmentPriceToConfirm
                    : formatProductPrice(servicePrice),
              ),
              _SummaryRow(
                label: l10n.appointmentDateLabel,
                value: '$dayLabel, $time',
              ),
              _SummaryRow(
                label: l10n.appointmentDurationLabel,
                value: _durationLabel(l10n, service?.estimatedDurationHours),
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              Text(
                l10n.appointmentOptionalNoteLabel,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: context.customerInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingSm),
              _AppointmentNoteInput(
                initialValue: note,
                onChanged: onNoteChanged,
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              Text(
                l10n.appointmentProductsLabel,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: context.customerInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingXs),
              if (products.isEmpty)
                _SummaryRow(
                  label: l10n.appointmentNoAdditionalProducts,
                  value: formatProductPrice(0),
                  labelColor: AutolabCustomer.primary,
                )
              else
                ...products.map((item) => _ProductSummaryRow(item: item)),
              const SizedBox(height: AutolabCustomer.spacingLg),
              _SummaryRow(
                label: l10n.appointmentSubtotalLabel,
                value: hasPriceToConfirm
                    ? l10n.appointmentPriceToConfirm
                    : formatProductPrice(subtotal),
              ),
              _SummaryRow(
                label: l10n.appointmentTaxLabel,
                value: hasPriceToConfirm
                    ? l10n.appointmentPriceToConfirm
                    : formatProductPrice(iva),
              ),
              _SummaryRow(
                label: l10n.appointmentTotalToPayLabel,
                value: hasPriceToConfirm
                    ? l10n.appointmentPriceToConfirm
                    : l10n.appointmentPriceWithTaxSuffix(
                        formatProductPrice(total),
                      ),
                emphasize: true,
              ),
              if (hasChargeableProducts) ...[
                const SizedBox(height: AutolabCustomer.spacingSm),
                const _ProductsOnlyPaymentNotice(),
              ],
              const SizedBox(height: AutolabCustomer.spacingSm),
              Center(
                child: Text(
                  l10n.appointmentConfirmationDeliveryMessage,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.primary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthName(BuildContext context, DateTime date) {
    return DateFormat.MMMM(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
  }

  String _durationLabel(AppLocalizations l10n, double? hours) {
    final durationHours = hours ?? 1;
    final minutes = (durationHours * 60).round();

    if (minutes < 60) {
      return l10n.appointmentDurationMinutes(minutes);
    }

    final wholeHours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return l10n.appointmentDurationHours(wholeHours);
    }

    return l10n.appointmentDurationHoursMinutes(wholeHours, remainingMinutes);
  }
}

class _ProductsOnlyPaymentNotice extends StatelessWidget {
  const _ProductsOnlyPaymentNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AutolabCustomer.spacingSm),
      decoration: BoxDecoration(
        // A darker red than AutolabCustomer.error -- that one only gives
        // ~3.7:1 contrast against white text, under the 4.5:1 AA minimum
        // for text this size. This shade keeps the same urgency but stays
        // legible.
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AutolabCustomer.white,
            size: AutolabCustomer.iconSm,
          ),
          const SizedBox(width: AutolabCustomer.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appointmentProductsOnlyPaymentNoticeTitle,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.white,
                    fontWeight: FontWeight.w900,
                    height: 1.35,
                  ),
                ),
                Text(
                  l10n.appointmentProductsOnlyPaymentNoticeBody,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.white,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.labelColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final labelWidth = AutolabCustomer.responsiveDouble(
      context,
      compact: 92,
      regular: 110,
      tablet: 132,
    );
    final valueStyle = AutolabCustomer.caption.copyWith(
      color: context.customerInk,
      fontSize: AutolabCustomer.responsiveDouble(
        context,
        compact: emphasize ? 12 : 11,
        regular: emphasize ? 13 : 12,
        tablet: emphasize ? 14 : 13,
      ),
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AutolabCustomer.caption.copyWith(
                color: labelColor ?? context.customerInk,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AutolabCustomer.spacingSm),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: valueStyle),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;

  return '${value[0].toUpperCase()}${value.substring(1)}';
}

class _ProductSummaryRow extends StatelessWidget {
  const _ProductSummaryRow({required this.item});

  final AppointmentSelectedProduct item;

  @override
  Widget build(BuildContext context) {
    final price = item.product.sellingPrice;
    final subtotal = price == null ? null : price * item.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: context.customerInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatProductPrice(price)} x ${item.quantity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.caption.copyWith(
                    color: context.customerInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutolabCustomer.spacingSm),
          Flexible(
            flex: 0,
            child: Text(
              subtotal == null
                  ? AppLocalizations.of(context)!.appointmentPriceToConfirm
                  : formatProductPrice(subtotal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AutolabCustomer.body.copyWith(
                color: context.customerInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutolabLogo extends StatelessWidget {
  const _AutolabLogo({this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return AutolabLogoMark(width: large ? 260 : 88, height: large ? 118 : 34);
  }
}

class _AppointmentStep {
  const _AppointmentStep(this.title, this.icon);

  final String title;
  final IconData icon;
}
