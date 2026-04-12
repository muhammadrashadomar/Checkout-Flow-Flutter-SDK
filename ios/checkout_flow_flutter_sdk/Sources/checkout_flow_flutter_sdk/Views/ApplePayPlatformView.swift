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
            onReady: { [weak self] _ in
                Task { @MainActor in
                    self?.handleOnReady()
                }
            },
            onSubmit: { [weak self] _ in
                self?.sendOnSubmit()
            },
            onTokenized: { [weak self] result in
                self?.sendTokenizationResult(result.data)
                return .accepted
            },
            onSuccess: { [weak self] _, paymentId in
                self?.sendPaymentSuccess(paymentId)
            },
            onError: { [weak self] error in
                print("[ApplePayPlatformView] Checkout error: \(error.localizedDescription)")
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

    // Calling .update(with:) function just updates the UI,
    // for updating the payment session you have to provide handleSubmit callback.
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
