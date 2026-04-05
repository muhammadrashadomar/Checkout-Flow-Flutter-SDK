import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';
import 'package:flutter/material.dart';

class CheckoutApplePayView extends StatelessWidget {
  const CheckoutApplePayView({super.key, required this.paymentConfig});

  final PaymentConfig paymentConfig;

  static const ApplePayConfig _applePayConfig = ApplePayConfig(
    merchantIdentifier: '01234567890123456789',
    merchantName: 'Demo Store',
    countryCode: 'US',
    currencyCode: 'USD',
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      children: [
        CheckoutFlowApplePayView(
          paymentConfig: paymentConfig,
          applePayConfig: _applePayConfig,
          loader: const Center(child: CircularProgressIndicator()),
          onReady: () {
            ConsoleLogger.success("Ready");
          },
          onCardTokenized: (CardTokenResult result) {
            ConsoleLogger.success(
              '[Flow-Card] Card tokenized: ${result.token}',
            );
          },

          onSessionData: (String sessionData) {
            ConsoleLogger.success('[Flow-Card] Session data ready');
          },
          onError: (PaymentErrorResult error) {
            // Example: Using the error type enum for better error handling
            ConsoleLogger.error(
              '[Flow-GPay] ${error.errorType.name}: ${error.errorMessage}',
            );

            // Type-safe error handling
            String errorTitle = 'Payment Error';
            String errorMessage = error.errorMessage;
            Color backgroundColor = Colors.red;

            // Categorize errors using the enum
            if (error.isApplePayError) {
              errorTitle = 'Apple Pay Error';
              backgroundColor = Colors.orange;
            } else if (error.isInitializationError) {
              errorTitle = 'Initialization Error';
              errorMessage = 'Failed to initialize payment. Please try again.';
            } else if (error.isRetryable) {
              errorMessage += '\nPlease try again.';
            }

            // Show error to user with enhanced information
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        errorTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(errorMessage),
                    ],
                  ),
                  backgroundColor: backgroundColor,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
