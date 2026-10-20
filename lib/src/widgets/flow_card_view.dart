import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';
import 'package:checkout_flow_flutter_sdk/src/widgets/card_form_heights.dart';
import 'package:flutter/material.dart';

/// CheckoutFlowCardView - Complete card payment widget with all callbacks
///
/// This widget provides a complete card payment solution with:
/// - Loading state management (shows loader until card view is ready)
/// - Payment success/error handling
/// - Token and session data callbacks
///
/// **Note on Validation:**
/// The Checkout.com SDK validates card input when you attempt to tokenize/submit.
/// The `onValidInput` callback will fire based on SDK feedback, but real-time
/// validation is not available. Enable your pay button after `onReady` fires,
/// then handle validation errors via the `onError` callback.
///
/// Example usage:
/// ```dart
/// bool _isReady = false;
///
/// CheckoutFlowCardView(
///   paymentConfig: config,
///   onReady: () => setState(() => _isReady = true),
///   onCardTokenized: (result) => print('Token: ${result.token}'),
///   onSessionData: (sessionData) => _submitToBackend(sessionData),
///   onPaymentSuccess: (result) => _showSuccess(result.paymentId),
///   onError: (error) => _showError(error.errorMessage),
/// )
///
/// Enable pay button after ready
/// ElevatedButton(
///   onPressed: _isReady ? _handlePayment : null,
///   child: Text('Pay'),
/// )
/// ```
class CheckoutFlowCardView extends StatefulWidget {
  /// Payment configuration for the card component
  final PaymentConfig paymentConfig;

  /// Card component display configuration
  final CardConfig cardConfig;

  /// Callback when the card view is fully rendered and ready for input
  final Function()? onReady;

  /// Callback when validation state changes (true = valid, false = invalid)
  final Function(bool)? onValidInput;

  /// Callback when card is successfully tokenized
  final Function(CardTokenResult)? onCardTokenized;

  /// Callback when card bin is changed
  final Function(CardMetadata)? onCardBinChanged;

  /// Callback when payment succeeds
  final Function(PaymentSuccessResult)? onPaymentSuccess;

  /// Callback when session data is ready for backend submission
  final Function(String)? onSessionData;

  /// Callback when any payment error occurs
  final Function(PaymentErrorResult)? onError;

  /// Called with the card form's natural height whenever it changes (Remember
  /// Me expanding, for example). The view already resizes itself to it.
  final Function(double)? onHeightChanged;

  /// Custom loader widget to show while card is initializing
  /// Defaults to CircularProgressIndicator if not provided
  final Widget? loader;

  /// Height until the native form reports its own, which replaces it.
  final double height;

  const CheckoutFlowCardView({
    super.key,
    required this.paymentConfig,
    this.cardConfig = const CardConfig(),
    this.onReady,
    this.onValidInput,
    this.onCardTokenized,
    this.onCardBinChanged,
    this.onPaymentSuccess,
    this.onSessionData,
    this.onError,
    this.onHeightChanged,
    this.loader,
    this.height = 200,
  });

  @override
  State<CheckoutFlowCardView> createState() => _CheckoutFlowCardViewState();
}

class _CheckoutFlowCardViewState extends State<CheckoutFlowCardView> {
  /// Height changes smaller than this are ignored, so sub-pixel layout noise
  /// doesn't move the form.
  static const double _minHeightChange = 1;

  /// How the visible height follows the form: the timing of Flutter's own
  /// text fields (`InputDecorator`), so the card fields move like them.
  static const Duration _heightAnimationDuration = Duration(milliseconds: 167);
  static const Curve _heightAnimationCurve = Curves.fastOutSlowIn;

  bool _isReady = false;
  bool _isFailed = false;
  late CardFormHeights _heights;
  int? _platformViewId;
  final PaymentBridge _paymentBridge = PaymentBridge();

  @override
  void initState() {
    super.initState();
    _heights = CardFormHeights.initial(widget.height);
    _paymentBridge.initialize();
    _setupCallbacks();
  }

  @override
  void didUpdateWidget(CheckoutFlowCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new config recreates the native view (see the key in build), which
    // reports ready again. The bridge's callback slots are shared, so take
    // them back in case another card view has set them since.
    if (oldWidget.paymentConfig != widget.paymentConfig ||
        oldWidget.cardConfig != widget.cardConfig) {
      _isReady = false;
      _isFailed = false;
      _setupCallbacks();
    }
  }

  void _onPlatformViewCreated(int viewId) {
    final previousViewId = _platformViewId;
    if (previousViewId != null) {
      _paymentBridge.setCardHeightListener(previousViewId, null);
    }
    _platformViewId = viewId;
    _paymentBridge.setCardHeightListener(viewId, _onNativeHeight);
  }

  void _onNativeHeight(double height) {
    if (!mounted || height <= 0) return;
    if ((height - _heights.visible).abs() < _minHeightChange) return;
    setState(() => _heights = _heights.withContentHeight(height));
    widget.onHeightChanged?.call(height);
  }

  void _setupCallbacks() {
    // Card ready event
    _paymentBridge.onCardReady = () {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
        widget.onReady?.call();
      }
    };

    // Validation changes
    if (widget.onValidInput != null) {
      _paymentBridge.onValidationChanged = (isValid) {
        if (mounted) {
          widget.onValidInput?.call(isValid);
        }
      };
    }

    // Card tokenized
    if (widget.onCardTokenized != null) {
      _paymentBridge.onCardTokenized = (result) {
        if (mounted) {
          widget.onCardTokenized?.call(result);
        }
      };
    }

    // Card bin changed
    if (widget.onCardBinChanged != null) {
      _paymentBridge.onCardBinChanged = (bin) {
        if (mounted) {
          widget.onCardBinChanged?.call(bin);
        }
      };
    }

    // Payment success
    if (widget.onPaymentSuccess != null) {
      _paymentBridge.onPaymentSuccess = (result) {
        if (mounted) {
          widget.onPaymentSuccess?.call(result);
        }
      };
    }

    // Session data ready
    if (widget.onSessionData != null) {
      _paymentBridge.onSessionData = (sessionData) {
        if (mounted) {
          widget.onSessionData?.call(sessionData);
        }
      };
    }

    // Payment error
    if (widget.onError != null) {
      _paymentBridge.onPaymentError = (error) {
        if (mounted) {
          setState(() {
            _isFailed = true;
          });
          widget.onError?.call(error);
        }
      };
    }
  }

  @override
  void dispose() {
    // Note: We don't clear callbacks here as PaymentBridge is a singleton
    // and may be used elsewhere. Callbacks will be cleared when needed.
    // The height listener is this view's own, so it goes.
    final platformViewId = _platformViewId;
    if (platformViewId != null) {
      _paymentBridge.setCardHeightListener(platformViewId, null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Card is ready, show the native view
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // The native view stays at `_heights.native` (see CardFormHeights);
        // only the clipped window over it animates. Its box is also the hit
        // area, so the hidden room below the fields takes no taps.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: _heights.visible),
          duration: _heightAnimationDuration,
          curve: _heightAnimationCurve,
          child: RepaintBoundary(
            child: SizedBox(
              height: _heights.native,
              child: CardNativeView(
                // Native reads its config only when the view is created, so a
                // new session or Remember Me prefill needs a new native view.
                key: ValueKey((widget.paymentConfig, widget.cardConfig)),
                paymentConfig: widget.paymentConfig,
                cardConfig: widget.cardConfig,
                onPlatformViewCreated: _onPlatformViewCreated,
              ),
            ),
          ),
          builder: (context, visibleHeight, nativeView) => ClipRect(
            child: SizedBox(
              height: visibleHeight,
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: _heights.native,
                maxHeight: _heights.native,
                child: nativeView,
              ),
            ),
          ),
        ),

        if (_isFailed)
          SizedBox.shrink()
        // Loader
        else if (!_isReady && widget.loader != null)
          widget.loader!,
      ],
    );
  }
}
