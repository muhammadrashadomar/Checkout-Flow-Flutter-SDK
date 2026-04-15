import Flutter
import PassKit

public class CheckoutFlutterBridgePlugin: NSObject, FlutterPlugin {
    private weak var cardPlatformView: CardPlatformView?
    private weak var applePayPlatformView: ApplePayPlatformView?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: CheckoutFlutterBridgeConstants.channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = CheckoutFlutterBridgePlugin()

        registrar.addMethodCallDelegate(instance, channel: channel)

        registrar.register(
            CardViewFactory(messenger: registrar.messenger()) { [weak instance] view in
                instance?.cardPlatformView = view
            },
            withId: CheckoutFlutterBridgeConstants.cardViewType
        )

        registrar.register(
            ApplePayViewFactory(messenger: registrar.messenger()) { [weak instance] view in
                instance?.applePayPlatformView = view
            },
            withId: CheckoutFlutterBridgeConstants.applePayViewType
        )
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initCardView", "initStoredCardView", "initApplePay":
            result(true)

        case "validateCard":
            guard let cardPlatformView else {
                result(
                    FlutterError(
                        code: "CARD_NOT_READY",
                        message: "Card view not initialized",
                        details: nil
                    )
                )
                return
            }

            result(cardPlatformView.validateCard())

        case "tokenizeCard":
            guard let cardPlatformView else {
                result(
                    FlutterError(
                        code: "CARD_NOT_READY",
                        message: "Card view not initialized",
                        details: nil
                    )
                )
                return
            }

            cardPlatformView.tokenizeCard(result: result)

        case "getSessionData":
            guard let cardPlatformView else {
                result(
                    FlutterError(
                        code: "CARD_NOT_READY",
                        message: "Card view not initialized",
                        details: nil
                    )
                )
                return
            }

            cardPlatformView.getSessionData(result: result)

        case "checkApplePayAvailability":
            if let applePayPlatformView {
                result(applePayPlatformView.checkAvailability())
            } else {
                result(PKPaymentAuthorizationController.canMakePayments())
            }

        // Apple Pay is self-contained: the button triggers the payment sheet,
        // the Checkout SDK handles the payment flow automatically, and the
        // sheet returns success via the onSuccess callback.

        case "tokenizeApplePay":
            guard let applePayPlatformView else {
                result(
                    FlutterError(
                        code: "APPLEPAY_NOT_READY",
                        message: "Apple Pay view not initialized",
                        details: nil
                    )
                )
                return
            }

            applePayPlatformView.tokenizeApplePay(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
