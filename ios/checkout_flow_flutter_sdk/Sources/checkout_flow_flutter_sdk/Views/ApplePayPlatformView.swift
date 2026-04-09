import CheckoutComponentsSDK
import Flutter
import PassKit
import SwiftUI
import UIKit

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
        applePayComponent?.isAvailable ?? PKPaymentAuthorizationController.canMakePayments()
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

    func getSessionData(result: @escaping FlutterResult) {
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
                code: "INVALID_CONFIG",
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
                code: "INVALID_CONFIG",
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
            handleSubmit: { [weak self] sessionData in
                self?.sendSessionData(sessionData)
                return .failure
            },
            onSuccess: { [weak self] _, paymentId in
                self?.sendPaymentSuccess(paymentId)
            },
            onError: { [weak self] error in
                self?.sendCheckoutError(error, defaultCode: "CHECKOUT_ERROR")
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
                        showPayButton: true
                    )
                )

                guard component.isAvailable else {
                    sendError(
                        code: "APPLEPAY_NOT_AVAILABLE",
                        message: "Apple Pay is not available on this device"
                    )
                    return
                }

                checkoutComponents = checkout
                applePayComponent = component

                embedSwiftUIView(component.render())
            } catch let error as CheckoutSDK.Error {
                sendCheckoutError(error, defaultCode: "INITIALIZATION_FAILED")
            } catch {
                sendError(code: "INITIALIZATION_FAILED", message: error.localizedDescription)
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
        invokeMethod("paymentSuccess", arguments: paymentId)
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
        DispatchQueue.main.async { [channel] in
            channel.invokeMethod(method, arguments: arguments)
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
            sendError(code: "INVALID_CONFIG", message: "Missing amount in applePayConfig")
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
                code: "UPDATE_AMOUNT_FAILED",
                message: "Failed to update Apple Pay amount: \(error.localizedDescription)"
            )
        }
    }

}
