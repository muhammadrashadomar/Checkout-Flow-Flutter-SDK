import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';
import 'package:flutter/material.dart';

/// A complete, self-contained Apple Pay payment widget.
///
/// ## How it works
///
/// 1. The native iOS Checkout SDK renders the Apple Pay button.
/// 2. When the user taps the button, the Apple Pay sheet opens.
/// 3. After Face ID / Touch ID authorisation, the SDK processes the payment
///    via Checkout.com's backend automatically.
/// 4. **[onPaymentSuccess]** fires with a [PaymentSuccessResult] containing the
///    `paymentId`. Use this to confirm the order on your own backend or navigate
///    to a success screen.
/// 5. **[onError]** fires for any failure (SDK init, unavailability, payment
///    decline, or user cancellation).
///
/// ## Error codes in [PaymentErrorResult.errorCode]
///
/// | Code | Meaning |
/// |------|---------|
/// | `APPLEPAY_NOT_AVAILABLE` | Device / region does not support Apple Pay |
/// | `APPLEPAY_USER_CANCELED` | User dismissed the sheet without paying |
/// | `APPLEPAY_PAYMENT_DECLINED` | Card was declined by the issuer |
/// | `CHECKOUT_ERROR` | General SDK / network error |
/// | `INVALID_CONFIG` | Missing merchant ID, session ID, or public key |
/// | `INITIALIZATION_FAILED` | SDK failed to initialise the component |
/// | `UPDATE_AMOUNT_FAILED` | Amount update after `onReady` failed |
///
/// ## Example
///
/// ```dart
/// CheckoutFlowApplePayView(
///   paymentConfig: paymentConfig,
///   applePayConfig: ApplePayConfig(
///     merchantIdentifier: 'merchant.com.example',
///     amount: 1999, // in cents
///   ),
///   onReady: () => setState(() => _applePayVisible = true),
///   onPaymentSuccess: (result) async {
///     // result.paymentId is the Checkout.com payment ID
///     await myBackend.confirmOrder(result.paymentId);
///     _navigateToSuccessScreen();
///   },
///   onError: (error) {
///     if (error.errorCode == 'APPLEPAY_USER_CANCELED') return; // silent
///     _showErrorDialog(error.userFriendlyMessage);
///   },
///   onUnavailable: () => setState(() => _showAlternativePayment = true),
///   loader: const CircularProgressIndicator(),
/// )
/// ```
class CheckoutFlowApplePayView extends StatefulWidget {
  /// Payment configuration (session ID, secret, public key, environment).
  final PaymentConfig paymentConfig;

  /// Apple Pay–specific configuration (merchant identifier, amount).
  final ApplePayConfig applePayConfig;

  /// Called when the native Apple Pay button finishes loading and is ready.
  final Function()? onReady;

  /// Called when the SDK produces a card token (tokenization flow only).
  final Function(CardTokenResult)? onCardTokenized;

  /// Called when the payment completes successfully.
  ///
  /// [PaymentSuccessResult.paymentId] is the Checkout.com payment ID you can
  /// use to confirm the order on your own backend.
  final Function(PaymentSuccessResult)? onPaymentSuccess;

  /// Called when session data is ready (card/saved-card flows only).
  ///
  /// Not called for Apple Pay — use [onPaymentSuccess] instead.
  final Function(String)? onSessionData;

  /// Called on any payment error (decline, cancellation, SDK error, etc.).
  ///
  /// Check [PaymentErrorResult.errorCode] to distinguish error types.
  /// [PaymentErrorResult.userFriendlyMessage] provides a display-ready string.
  final Function(PaymentErrorResult)? onError;

  /// Called when Apple Pay is not available on this device or region.
  ///
  /// Use this to hide the button and reveal an alternative payment method.
  final Function()? onUnavailable;

  /// Called when the user taps the Apple Pay button (before the sheet opens).
  final Function()? onSubmitted;

  /// Called when the user explicitly dismisses the Apple Pay sheet
  /// (i.e. taps "Cancel").
  final Function()? onDismissed;

  /// Widget to display when Apple Pay is not available.
  /// Defaults to [SizedBox.shrink] if not provided.
  final Widget? unavailableWidget;

  /// Custom loading indicator shown until the Apple Pay button is ready.
  final Widget? loader;

  /// Height of the Apple Pay button container. Defaults to `50`.
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

    // Error callback handles all native errors and user cancellation.
    _paymentBridge.onPaymentError = (error) {
      if (!mounted) return;

      // User explicitly tapped Cancel — not a real failure, treat like onDismissed.
      if (error.errorCode == 'APPLEPAY_USER_CANCELED' ||
          error.errorCode == 'APPLE_PAY_CANCELED') {
        widget.onDismissed?.call();
        return;
      }

      // Apple Pay not supported on this device.
      if (error.errorCode == 'APPLEPAY_NOT_AVAILABLE' ||
          error.errorCode == 'APPLEPAY_UNAVAILABLE') {
        setState(() => _isFailed = true);
        widget.onUnavailable?.call();
        widget.onError?.call(error);
        return;
      }

      // All other errors — surface to caller, but do NOT collapse the view
      // for transient errors so the user can retry without re-mounting the widget.
      widget.onError?.call(error);
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
