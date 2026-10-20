import CheckoutComponentsSDK
import Flutter
import SwiftUI
import UIKit

final class CardPlatformView: NSObject, FlutterPlatformView {
    /// Height reports go out at most once per this interval while the form
    /// animates (Remember Me expanding, for example). The first change goes
    /// out at once, so Flutter starts following it on the next frame, and the
    /// last height always goes out.
    private static let heightReportInterval: TimeInterval = 0.05

    private let channel: FlutterMethodChannel
    private let args: [String: Any]
    private let viewId: Int64
    private let containerView: UIView

    private var hostingController: UIHostingController<AnyView>?
    private var checkoutComponents: CheckoutSDK?
    private var cardComponent: CheckoutActionable?
    private var hasSentReady = false
    private var lastValidationState: Bool?
    private var lastBin: String?
    private var lastReportedHeight: CGFloat = 0
    private var pendingHeight: CGFloat?
    private var isHeightReportScheduled = false
    private var lastHeightReportTime: CFTimeInterval = 0

    init(
        frame: CGRect,
        viewId: Int64,
        args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        self.args = args as? [String: Any] ?? [:]
        self.viewId = viewId
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
                // Optional since Checkout 1.8.3. There's no bin to report without
                // it, but forget the last one so the same bin is sent again later.
                if let metadata {
                    self?.sendCardBinChanged(metadata)
                } else {
                    self?.lastBin = nil
                }
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
                // handleSubmit returns .failure on purpose (the app's backend
                // completes the payment), and the SDK reports that as an error
                // right after the session data. It isn't a failure.
                if error.errorCode == .merchantHandleSubmitCallbackFailed { return }
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

                let component = try checkout.create(
                    .card(
                        showPayButton: false,
                        paymentButtonAction: .tokenization,
                        cardConfiguration: cardConfiguration,
                        rememberMeConfiguration: checkoutRememberMeConfiguration(from: args)
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
        let measuredView = MeasuredCardView(content: view) { [weak self] height in
            DispatchQueue.main.async { self?.scheduleHeightReport(height) }
        }
        let hostingController = UIHostingController(rootView: AnyView(measuredView))
        hostingController.view.backgroundColor = .clear
        // Flutter owns this view's frame and the keyboard handling, so safe-area
        // and keyboard insets would only push the fields down or up inside it.
        // (iOS 15.0-16.3 has no `safeAreaRegions`.)
        if #available(iOS 16.4, *) {
            hostingController.safeAreaRegions = []
        }
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // Flutter sets the container's height and MeasuredCardView reports the
        // natural one, so the hosting view just fills the container. Required
        // hugging/compression would fight the edge pins whenever the two
        // heights differ (until Flutter applies the reported height).
        hostingController.view.setContentHuggingPriority(.defaultLow, for: .vertical)
        hostingController.view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

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

    // MARK: - Height

    private func scheduleHeightReport(_ height: CGFloat) {
        pendingHeight = height
        guard !isHeightReportScheduled else { return }

        isHeightReportScheduled = true
        let sinceLastReport = CACurrentMediaTime() - lastHeightReportTime
        let delay = max(0, Self.heightReportInterval - sinceLastReport)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.isHeightReportScheduled = false
            guard let height = self.pendingHeight else { return }
            self.pendingHeight = nil
            self.lastHeightReportTime = CACurrentMediaTime()
            self.sendHeight(height)
        }
    }

    private func sendHeight(_ height: CGFloat) {
        let roundedHeight = height.rounded(.up)
        guard roundedHeight > 0, abs(roundedHeight - lastReportedHeight) >= 1 else { return }
        lastReportedHeight = roundedHeight
        invokeMethod(
            "heightChanged",
            arguments: ["height": Double(roundedHeight), "viewId": viewId]
        )
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

/// Lays the Checkout card component out at its natural height, pinned to the
/// top of the platform view, and reports that height as it changes. Without
/// it the component fills Flutter's frame and centres its fields in it.
///
/// Event-driven: SwiftUI re-runs the preference only on layout changes, so
/// nothing polls. (The earlier per-frame CADisplayLink check was removed for
/// that cost, and it also kept the view alive.)
private struct MeasuredCardView: View {
    /// Checkout 2.x draws its fields edge to edge, and a field border is
    /// stroked on the field's edge, half outside it. The container clips to
    /// its bounds (native drawing outside the frame lands on top of Flutter
    /// UI), so without this inset the side borders show at half width.
    private static let edgeInset: CGFloat = 1

    let content: AnyView
    let onHeightChange: (CGFloat) -> Void

    var body: some View {
        content
            .padding(.horizontal, Self.edgeInset)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: CardContentHeightKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(CardContentHeightKey.self, perform: onHeightChange)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct CardContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
