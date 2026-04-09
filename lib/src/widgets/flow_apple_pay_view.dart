import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';
import 'package:flutter/material.dart';

/// CheckoutFlowApplePayView - Complete Apple Pay payment widget with all callbacks
///
/// This widget provides a complete Apple Pay payment solution with:
/// - Loading state management (shows loader until Apple Pay button is ready)
/// - Availability checking
/// - Payment success/error handling
/// - Token and session data callbacks
/// - Built-in Apple Pay button rendering
///
/// Example usage:
/// ```dart
/// CheckoutFlowApplePayView(
///   paymentConfig: config,
///   applePayConfig: applePayConfig,
///   onReady: () => print('Apple Pay button ready'),
///   onCardTokenized: (result) => print('Token: ${result.token}'),
///   onSessionData: (sessionData) => _submitToBackend(sessionData),
///   onPaymentSuccess: (result) => _showSuccess(result.paymentId),
///   onError: (error) => _showError(error.errorMessage),
///   onUnavailable: () => _showAlternativePayments(),
///   loader: CircularProgressIndicator(), // Optional custom loader
/// )
/// ```
class CheckoutFlowApplePayView extends StatefulWidget {
  /// Payment configuration for the Apple Pay component
  final PaymentConfig paymentConfig;

  /// Apple Pay configuration passed to the native SDK
  final ApplePayConfig applePayConfig;

  /// Callback when Apple Pay button is ready for interaction
  final Function()? onReady;

  /// Callback when Apple Pay is successfully tokenized
  final Function(CardTokenResult)? onCardTokenized;

  /// Callback when payment succeeds
  final Function(PaymentSuccessResult)? onPaymentSuccess;

  /// Callback when session data is ready for backend submission
  final Function(String)? onSessionData;

  /// Callback when any payment error occurs
  final Function(PaymentErrorResult)? onError;

  /// Callback when Apple Pay is not available on this device
  final Function()? onUnavailable;

  /// Callback when calculation/submission starts (before sheet opens)
  final Function()? onSubmitted;

  /// Callback when the payment sheet is dismissed by the user
  final Function()? onDismissed;

  /// Widget to show when Apple Pay is not available
  /// If not provided and Apple Pay is unavailable, widget returns SizedBox.shrink()
  final Widget? unavailableWidget;

  /// Custom loader widget to show while Apple Pay button is loading
  /// If not provided, no loader is shown
  final Widget? loader;

  final double height;

  const CheckoutFlowApplePayView({
    super.key,
    required this.paymentConfig,
    required this.applePayConfig,
    this.onReady,
    this.onCardTokenized,
    this.onPaymentSuccess,
    this.onSessionData,
    this.onError,
    this.onUnavailable,
    this.onSubmitted,
    this.onDismissed,
    this.unavailableWidget,
    this.loader,
    this.height = 50,
  });

  @override
  State<CheckoutFlowApplePayView> createState() =>
      _CheckoutFlowApplePayViewState();
}

class _CheckoutFlowApplePayViewState extends State<CheckoutFlowApplePayView> {
  bool _isReady = false;
  bool _isFailed = false;
  final PaymentBridge _paymentBridge = PaymentBridge();

  @override
  void initState() {
    super.initState();
    _paymentBridge.initialize();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    // Apple Pay ready event
    _paymentBridge.onApplePayReady = () {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
        widget.onReady?.call();
      }
    };

    _paymentBridge.onCardTokenized = (result) {
      if (mounted) widget.onCardTokenized?.call(result);
    };

    _paymentBridge.onPaymentSuccess = (result) {
      if (mounted) widget.onPaymentSuccess?.call(result);
    };

    _paymentBridge.onSessionData = (sessionData) {
      if (mounted) widget.onSessionData?.call(sessionData);
    };

    _paymentBridge.onSubmitted = () {
      if (mounted) widget.onSubmitted?.call();
    };

    _paymentBridge.onDismissed = () {
      if (mounted) widget.onDismissed?.call();
    };

    // Error callback handles unavailability - SDK sends APPLEPAY_UNAVAILABLE error
    _paymentBridge.onPaymentError = (error) {
      if (mounted) {
        setState(() {
          _isFailed = true;
        });
        // If Apple Pay is unavailable, call the onUnavailable callback
        if (error.errorCode == 'APPLEPAY_UNAVAILABLE' ||
            error.errorCode == 'APPLEPAY_NOT_AVAILABLE') {
          widget.onUnavailable?.call();
        }
        widget.onError?.call(error);
      }
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Apple Pay button with loader overlay
    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          child: ApplePayNativeView(
            paymentConfig: widget.paymentConfig,
            applePayConfig: widget.applePayConfig,
          ),
        ),

        if (_isFailed)
          SizedBox.shrink()
        // Loader - shown until Apple Pay button is ready
        else if (!_isReady && widget.loader != null)
          widget.loader!,
      ],
    );
  }
}
