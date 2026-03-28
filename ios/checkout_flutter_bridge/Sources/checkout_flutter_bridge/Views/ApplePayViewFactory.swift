import Flutter
import UIKit

final class ApplePayViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private let onViewCreated: ((ApplePayPlatformView) -> Void)?

    init(
        messenger: FlutterBinaryMessenger,
        onViewCreated: ((ApplePayPlatformView) -> Void)? = nil
    ) {
        self.messenger = messenger
        self.onViewCreated = onViewCreated
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let view = ApplePayPlatformView(
            frame: frame,
            viewId: viewId,
            args: args,
            messenger: messenger
        )
        onViewCreated?(view)
        return view
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}
