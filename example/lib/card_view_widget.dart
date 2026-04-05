import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';
import 'package:flutter/material.dart';

class CheckoutCardView extends StatefulWidget {
  const CheckoutCardView({
    super.key,
    required this.paymentConfig,
    this.onReady,
    this.onTokenized,
    this.onFetchedSessionData,
    this.onValidInput,
    this.onError,
  });

  final PaymentConfig paymentConfig;
  final void Function()? onReady;
  final void Function(CardTokenResult)? onTokenized;
  final void Function(String)? onFetchedSessionData;
  final void Function(bool)? onValidInput;
  final void Function(PaymentErrorResult)? onError;

  @override
  State<CheckoutCardView> createState() => _CheckoutCardViewState();
}

class _CheckoutCardViewState extends State<CheckoutCardView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: CheckoutFlowCardView(
        paymentConfig: widget.paymentConfig,
        loader: const Center(child: CircularProgressIndicator()),
        onReady: () {
          widget.onReady?.call();
        },
        onValidInput: (bool valid) {
          // Note: This may not fire in real-time due to SDK limitations
          widget.onValidInput?.call(valid);
        },
        onCardBinChanged: (CardMetadata bin) {
          ConsoleLogger.success(
            '[Flow-Card] Card bin changed: ${bin.toString()}',
          );
        },
        // onCardTokenized: (CardTokenResult result) {
        //   ConsoleLogger.success(
        //     '[Flow-Card] Card tokenized: ${result.token}',
        //   );
        //   widget.onTokenized?.call(result);
        // },
      ),
    );
  }
}

// Card View in Bottom sheet -------------------------------------------------
void kShowAddNewCardBottomSheet(
  BuildContext context, {
  required PaymentConfig paymentConfig,
  Function(bool)? canPay,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: _AddCardViewBody(paymentConfig: paymentConfig, canPay: canPay),
    ),
  );
}

class _AddCardViewBody extends StatefulWidget {
  const _AddCardViewBody({required this.canPay, required this.paymentConfig});

  final Function(bool)? canPay;
  final PaymentConfig paymentConfig;

  @override
  State<_AddCardViewBody> createState() => _AddCardViewBodyState();
}

class _AddCardViewBodyState extends State<_AddCardViewBody> {
  // bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CheckoutCardView(paymentConfig: widget.paymentConfig),
        ElevatedButton(
          onPressed: () async {
            // setState(() => _isLoading = true);
            final result = await PaymentBridge().tokenizeCard();

            ConsoleLogger.success("Tokenized: ${result.token}");
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
          ),
          child: Text('Add Card'),
        ),
      ],
    );
  }
}
