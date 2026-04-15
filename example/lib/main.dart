import 'dart:io';

import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';
import 'package:example/apple_pay_button.dart';
import 'package:example/card_view_widget.dart';
import 'package:example/dismiss_keyboard.dart';
import 'package:example/google_pay_button.dart';
import 'package:flutter/material.dart';

// Google Pay Configuration
const String paymentSessionId = 'ps_3COMpx7thYiH0NXH03bwdk30LxP';
const String paymentSessionSecret = 'pss_7d8388ea-57be-4cf2-a3ac-0b17b55424b1';
const String publicKey = 'pk_sbox_fjizign6afqbt3btt3ialiku74s';

// Payment configuration
final _paymentConfig = PaymentConfig(
  paymentSessionId: paymentSessionId,
  paymentSessionSecret: paymentSessionSecret,
  publicKey: publicKey,
  environment: PaymentEnvironment.sandbox,

  appearance: AppearanceConfig(
    borderRadius: 8,
    colorTokens: ColorTokens(
      colorAction: 0XFF00639E,
      colorPrimary: 0XFF111111,
      colorBorder: 0XFFCCCCCC,
      colorFormBorder: 0XFFCCCCCC,
    ),
  ),
);

//* Create a new payment session every time the open the card sheet

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Payment Integration',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        builder: (context, child) {
          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          );
        },
        home: const PaymentScreen(),
      ),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  var currentPaymentType = CurrentPaymentType.card;
  bool _isBottomSheetOpen = false;

  final PaymentBridge _paymentBridge = PaymentBridge();

  @override
  void initState() {
    super.initState();
    _setupPaymentBridge();
  }

  void _setupPaymentBridge() {
    _paymentBridge.initialize();
  }

  /// Convert technical error codes to user-friendly messages
  // ignore: unused_element
  String _getUserFriendlyErrorMessage(
    String errorCode,
    String technicalMessage,
  ) {
    switch (errorCode) {
      case 'INVALID_CONFIG':
        return 'Payment configuration error. Please contact support.';
      case 'GOOGLEPAY_UNAVAILABLE':
      case 'GOOGLEPAY_NOT_AVAILABLE':
        return 'Google Pay is not available on this device. Please use another payment method.';
      case 'INITIALIZATION_FAILED':
      case 'INIT_ERROR':
        return 'Failed to initialize payment. Please try again.';
      case 'TOKENIZATION_FAILED':
      case 'TOKENIZATION_ERROR':
        return 'Payment processing failed. Please try again or use another payment method.';
      case 'TIMEOUT':
        return 'Payment request timed out. Please check your connection and try again.';
      case 'INVALID_STATE':
        return 'Payment system not ready. Please wait a moment and try again.';
      case 'PAYMENT_ERROR':
        return 'Payment failed: $technicalMessage';
      default:
        return 'An error occurred: $technicalMessage';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Integration Demo'),
        elevation: 2,
      ),
      // bottomSheet: PaymentBottomSheet(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          // Title
          const Center(
            child: Text(
              'Choose Payment Method',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          ElevatedButton(
            onPressed: () {
              setState(() => _isBottomSheetOpen = true);
              kShowAddNewCardBottomSheet(
                context,
                paymentConfig: _paymentConfig,
              ).whenComplete(() async {
                await Future.delayed(const Duration(milliseconds: 200));
                if (mounted) {
                  setState(() => _isBottomSheetOpen = false);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
            ),
            child: Text('Add New Card'),
          ),

          SizedBox(height: 200),
          ElevatedButton(
            onPressed: () async {
              // if (!_canPay) return;
              // Payment will be triggered
              // If card is invalid, onError will be called
              final bridge = PaymentBridge();
              final result = await bridge.submit(CurrentPaymentType.card);

              ConsoleLogger.success("SessionData: ${result.sessionData}");
            },
            style: ElevatedButton.styleFrom(
              fixedSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.blueGrey[700],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
            ),
            child: Text('Pay Now'),
          ),
          Spacer(),

          Opacity(
            opacity: _isBottomSheetOpen ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: _isBottomSheetOpen,
              child: const PaymentBtn(),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentBtn extends StatelessWidget {
  const PaymentBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 320,
      padding: EdgeInsetsGeometry.all(20),
      child: (Platform.isIOS)
          ? CheckoutApplePayView(paymentConfig: _paymentConfig)
          : CheckoutGooglePayView(paymentConfig: _paymentConfig),
    );
  }
}
