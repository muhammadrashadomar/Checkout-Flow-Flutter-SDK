import CheckoutComponentsSDK
import Flutter
import SwiftUI
import UIKit

// MARK: - Apple Pay Error Codes
// These string codes are passed to Flutter via the `paymentError` channel method.
// Keep in sync with `PaymentErrorCode` in payment_error_code.dart.
private enum ApplePayErrorCode {
    /// Required configuration values (session ID, public key, merchant ID) are missing.
    static let invalidConfig = "INVALID_CONFIG"
    /// The CheckoutSDK component failed to initialise.
    static let initializationFailed = "INITIALIZATION_FAILED"
    /// Apple Pay is not available on this device / region.
    static let notAvailable = "APPLEPAY_NOT_AVAILABLE"
    /// The native component is not yet ready to accept a submit call.
    static let notReady = "APPLEPAY_NOT_READY"
    /// The user explicitly cancelled the Apple Pay sheet.
    static let userCanceled = "APPLEPAY_USER_CANCELED"
    /// SDK reported a payment-level error via `onError`.
    static let checkoutError = "CHECKOUT_ERROR"
    /// The `.update(with:)` amount-update call failed.
    static let updateAmountFailed = "UPDATE_AMOUNT_FAILED"
}

final class ApplePayPlatformView: NSObject, FlutterPlatformView {
    private let channel: FlutterMethodChannel
    private let args: [String: Any]
    private let containerView: UIView

    private var hostingController: UIHostingController<AnyView>?
    private var checkoutComponents: CheckoutSDK?
    private var applePayComponent: CheckoutActionable?

    init(
        frame: CGRect,
        viewId: Int64,
        args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        self.args = args as? [String: Any] ?? [:]
        self.channel = FlutterMethodChannel(
            name: CheckoutFlutterBridgeConstants.channelName,
            binaryMessenger: messenger
        )
        self.containerView = UIView(frame: frame)

        super.init()

        initializeComponent()
    }

    func view() -> UIView {
        containerView
    }

    func checkAvailability() -> Bool {
        applePayComponent?.isAvailable ?? false
    }

    func tokenizeApplePay(result: @escaping FlutterResult) {
        guard let applePayComponent else {
            result(
                FlutterError(
                    code: "APPLEPAY_NOT_READY",
                    message: "Apple Pay component not initialized",
                    details: nil
                )
            )
            return
        }

        DispatchQueue.main.async {
            applePayComponent.submit()
            result(["status": "processing"])
        }
    }

    private func initializeComponent() {
        guard
            let sessionId = args["paymentSessionID"] as? String,
            !sessionId.isEmpty,
            let sessionSecret = args["paymentSessionSecret"] as? String,
            !sessionSecret.isEmpty,
            let publicKey = args["publicKey"] as? String,
            !publicKey.isEmpty
        else {
            sendError(
                code: ApplePayErrorCode.invalidConfig,
                message: "Missing required payment session parameters"
            )
            return
        }

        let applePayConfig = args["applePayConfig"] as? [String: Any]
        guard
            let merchantIdentifier = applePayConfig?["merchantIdentifier"] as? String,
            !merchantIdentifier.isEmpty
        else {
            sendError(
                code: ApplePayErrorCode.invalidConfig,
                message: "Apple Pay merchant identifier is required"
            )
            return
        }

        let paymentSession = CheckoutPaymentSession(
            id: sessionId,
            paymentSessionSecret: sessionSecret
        )
        let callbacks = CheckoutSDK.Callbacks(
            /// Fires when the component is ready to be rendered and the Apple Pay button is available.
            onReady: { [weak self] _ in
                print("[ApplePayPlatformView] onReady: Component is ready")
                Task { @MainActor in
                    self?.handleOnReady()
                }
            },
            /// Fires immediately when the user taps the Apple Pay button.
            /// Use this for tracking or showing a loading state.
            onSubmit: { [weak self] _ in
                print("[ApplePayPlatformView] onSubmit: User tapped the Pay button")
                self?.sendOnSubmit()
            },
            /// Fires after the user has authorized the payment (TouchID/FaceID)
            /// and the SDK has received tokenized payment data from Apple.
            onTokenized: { [weak self] result in
                print("[ApplePayPlatformView] onTokenized: Payment authorized and tokenized")
                self?.sendTokenizationResult(result.data)
                return .accepted
            },
            /// Fires when the SDK has prepared the final payment session data.
            /// Returning .failure here pauses the native SDK progression, allowing
            /// the Flutter application to handle the payment submission manually via onSessionData.
            handleSubmit: { [weak self] sessionData in
                print(
                    "[ApplePayPlatformView] handleSubmit: Session data ready, forwarding to Flutter"
                )
                self?.sendSessionData(sessionData)

                // Return a dummy success to the SDK to trigger the Apple Pay success checkmark.
                // The actual payment processing is handled asynchronously by the backend.
                return .success(
                    CheckoutSDK.PaymentSessionSubmissionResult(
                        id: "manual_\(UUID().uuidString)",
                        status: "Authorized",
                        type: "card"
                    )
                )
            },
            /// Fires when the payment has been successfully processed by the SDK's self-contained flow.
            onSuccess: { [weak self] _, paymentId in
                print("[ApplePayPlatformView] onSuccess: Payment successful, ID: \(paymentId)")
                self?.sendPaymentSuccess(paymentId)
            },
            /// Fires when an error occurs, including user cancellation of the Apple Pay sheet.
            onError: { [weak self] error in
                print("[ApplePayPlatformView] onError: \(error.localizedDescription)")
                self?.sendCheckoutError(error, defaultCode: ApplePayErrorCode.checkoutError)
            }
        )

        Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let configuration = try await CheckoutSDK.Configuration(
                    paymentSession: paymentSession,
                    publicKey: publicKey,
                    environment: checkoutEnvironment(from: args["environment"] as? String),
                    appearance: checkoutDesignTokens(from: args),
                    callbacks: callbacks
                )
                let checkout = CheckoutSDK(configuration: configuration)

                let component = try checkout.create(
                    .applePay(
                        merchantIdentifier: merchantIdentifier,
                        showPayButton: true,
                        applePayConfiguration: .init()
                    )
                )

                guard component.isAvailable else {
                    sendError(
                        code: ApplePayErrorCode.notAvailable,
                        message: "Apple Pay is not available on this device"
                    )
                    return
                }

                checkoutComponents = checkout
                applePayComponent = component

                embedSwiftUIView(component.render())
            } catch let error as CheckoutSDK.Error {
                sendCheckoutError(error, defaultCode: ApplePayErrorCode.initializationFailed)
            } catch {
                sendError(
                    code: ApplePayErrorCode.initializationFailed,
                    message: error.localizedDescription)
            }
        }
    }

    @MainActor
    private func embedSwiftUIView(_ view: AnyView) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = containerView.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        containerView.addSubview(hostingController.view)
        self.hostingController = hostingController
    }

    private func sendTokenizationResult(_ tokenDetails: CheckoutSDK.TokenDetails) {
        invokeMethod(
            "cardTokenized",
            arguments: ["tokenDetails": checkoutTokenDetailsMap(tokenDetails)]
        )
    }

    private func sendSessionData(_ sessionData: String) {
        invokeMethod("sessionDataReady", arguments: ["sessionData": sessionData])
    }

    private func sendPaymentSuccess(_ paymentId: String) {
        // Wrap in a map so the Flutter `PaymentSuccessResult.fromMap` deserialiser
        // can unpack `paymentId` correctly.  Sending a raw String caused a crash
        // when the Flutter model tried to call `.from(data as Map)`.
        invokeMethod("paymentSuccess", arguments: ["paymentId": paymentId])
    }

    private func sendCheckoutError(_ error: CheckoutSDK.Error, defaultCode: String) {
        invokeMethod(
            "paymentError",
            arguments: checkoutErrorPayload(from: error, code: defaultCode)
        )
    }

    private func sendError(code: String, message: String) {
        invokeMethod(
            "paymentError",
            arguments: checkoutErrorPayload(code: code, message: message)
        )
    }

    private func invokeMethod(_ method: String, arguments: Any?) {
        if Thread.isMainThread {
            channel.invokeMethod(method, arguments: arguments)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.channel.invokeMethod(method, arguments: arguments)
            }
        }
    }

    private func sendApplePayReady() {
        invokeMethod("applePayReady", arguments: nil)
    }

    private func sendOnSubmit() {
        invokeMethod("onSubmit", arguments: nil)
    }

    @MainActor
    private func handleOnReady() {
        sendApplePayReady()

        let applePayConfig = args["applePayConfig"] as? [String: Any]
        guard let amount = applePayConfig?["amount"] as? Int else {
            sendError(
                code: ApplePayErrorCode.invalidConfig,
                message: "Missing amount in applePayConfig"
            )
            return
        }
        updatePaymentAmount(amount: amount)
    }

    // Calling .update(with:) function updates the payment amount displayed on the Apple Pay sheet.
    // The Checkout SDK handles session updates and payment processing automatically.
    /// Updates the payment amount in the SDK to reflect on the Apple Pay sheet.
    /// - Parameter amount: The amount in cents.
    @MainActor
    private func updatePaymentAmount(amount: Int) {
        do {
            let updateDetails = CheckoutSDK.UpdateDetails(amount: amount)
            try checkoutComponents?.update(with: updateDetails)
        } catch {
            sendError(
                code: ApplePayErrorCode.updateAmountFailed,
                message: "Failed to update Apple Pay amount: \(error.localizedDescription)"
            )
        }
    }

}
