import CheckoutComponentsSDK
import Flutter
import SwiftUI
import UIKit

final class CardPlatformView: NSObject, FlutterPlatformView {
    private let channel: FlutterMethodChannel
    private let args: [String: Any]
    private let containerView: UIView

    private var hostingController: UIHostingController<AnyView>?
    private var checkoutComponents: CheckoutSDK?
    private var cardComponent: CheckoutActionable?
    private var hasSentReady = false
    private var lastValidationState: Bool?
    private var lastBin: String?

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

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        self.containerView.addGestureRecognizer(tapGesture)

        initializeComponent()
    }

    @objc private func handleBackgroundTap() {
        containerView.endEditing(true)
    }

    func view() -> UIView {
        containerView
    }

    func validateCard() -> Bool {
        cardComponent?.isValid ?? false
    }

    func tokenizeCard(result: @escaping FlutterResult) {
        guard let cardComponent else {
            result(
                FlutterError(
                    code: "CARD_NOT_READY",
                    message: "Card component not initialized",
                    details: nil
                )
            )
            return
        }

        DispatchQueue.main.async {
            cardComponent.tokenize()
            result(["status": "processing"])
        }
    }

    func getSessionData(result: @escaping FlutterResult) {
        guard let cardComponent else {
            result(
                FlutterError(
                    code: "CARD_NOT_READY",
                    message: "Card component not initialized",
                    details: nil
                )
            )
            return
        }

        DispatchQueue.main.async {
            cardComponent.submit()
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
                code: "INIT_ERROR",
                message: "Missing required payment session parameters"
            )
            return
        }

        let paymentSession = CheckoutPaymentSession(
            id: sessionId,
            paymentSessionSecret: sessionSecret
        )
        let appearance = checkoutDesignTokens(from: args)
        let cardConfiguration = checkoutCardConfiguration(from: args)
        let callbacks = CheckoutSDK.Callbacks(
            handleTap: { paymentMethod async -> Bool in
                return true
            },
            onChange: { [weak self] component in
                self?.sendValidationState(isValid: component.isValid)
            },
            onCardBinChanged: { [weak self] metadata in
                self?.sendCardBinChanged(metadata)
                return .accepted
            },
            onTokenized: { [weak self] result in
                self?.sendCardTokenized(result.data)
                if let metadata = result.cardMetadata {
                    self?.sendCardBinChanged(metadata)
                }
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
                    appearance: appearance,
                    callbacks: callbacks,
                )
                let checkout = CheckoutSDK(configuration: configuration)
                let cardConfig = args["cardConfig"] as? [String: Any]
                let showRememberMe = cardConfig?["showRememberMe"] as? Bool ?? false

                let component = try checkout.create(
                    .card(
                        showPayButton: false,
                        paymentButtonAction: .tokenization,
                        cardConfiguration: cardConfiguration,
                        rememberMeConfiguration: showRememberMe
                            ? CheckoutSDK.RememberMeConfiguration(showPayButton: false) : nil
                    )
                )

                guard component.isAvailable else {
                    sendError(
                        code: "CARD_NOT_AVAILABLE",
                        message: "Card payment method is not available"
                    )
                    return
                }

                checkoutComponents = checkout
                cardComponent = component
                embedSwiftUIView(component.render())
                sendCardReadyIfNeeded()
                sendValidationState(isValid: component.isValid)
            } catch let error as CheckoutSDK.Error {
                sendCheckoutError(error, defaultCode: "INIT_ERROR")
            } catch {
                sendError(code: "INIT_ERROR", message: error.localizedDescription)
            }
        }
    }

    @MainActor
    private func embedSwiftUIView(_ view: AnyView) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // Important: Improve layout behavior
        hostingController.view.setContentHuggingPriority(.required, for: .vertical)
        hostingController.view.setContentCompressionResistancePriority(.required, for: .vertical)

        // Container setup
        containerView.clipsToBounds = true
        containerView.addSubview(hostingController.view)

        self.hostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        containerView.layoutIfNeeded()
    }

    // MARK: - Flutter channel senders

    private func sendCardTokenized(_ tokenDetails: CheckoutSDK.TokenDetails) {
        invokeMethod(
            "cardTokenized",
            arguments: ["tokenDetails": checkoutTokenDetailsMap(tokenDetails)]
        )
    }

    private func sendSessionData(_ sessionData: String) {
        invokeMethod("sessionDataReady", arguments: ["sessionData": sessionData])
    }

    private func sendCardReadyIfNeeded() {
        guard !hasSentReady else { return }
        hasSentReady = true
        invokeMethod("cardReady", arguments: nil)
    }

    private func sendValidationState(isValid: Bool) {
        guard lastValidationState != isValid else { return }
        lastValidationState = isValid
        invokeMethod("validationChanged", arguments: ["isValid": isValid])
    }

    private func sendCardBinChanged(_ metadata: CheckoutCardMetadata) {
        guard lastBin != metadata.bin else { return }
        lastBin = metadata.bin
        invokeMethod("cardBinChanged", arguments: checkoutCardMetadataMap(metadata))
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
        if Thread.isMainThread {
            channel.invokeMethod(method, arguments: arguments)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.channel.invokeMethod(method, arguments: arguments)
            }
        }
    }
}
