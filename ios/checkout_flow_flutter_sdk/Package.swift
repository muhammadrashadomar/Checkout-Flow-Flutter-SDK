// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "checkout_flow_flutter_sdk",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(
            name: "checkout-flow-flutter-sdk",
            targets: ["checkout_flow_flutter_sdk"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/checkout/checkout-risk-sdk-ios", exact: "6.0.1")
    ],
    targets: [
        .target(
            name: "CheckoutComponentsShim",
            dependencies: [
                .product(name: "Risk", package: "checkout-risk-sdk-ios"),
                .target(name: "CheckoutComponentsSDK"),
            ]
        ),
        .target(
            name: "checkout_flow_flutter_sdk",
            dependencies: [
                .target(name: "CheckoutComponentsShim"),
                .target(name: "CheckoutComponentsSDK"),
            ]
        ),
        .binaryTarget(
            name: "CheckoutComponentsSDK",
            url:
                "https://github.com/checkout/checkout-ios-components/releases/download/2.9.0/CheckoutComponentsSDK.xcframework.zip",
            checksum: "bd5e60571bfc3d9560a4823f0720463ab720ae9303cb28ac0f7f9b676645c6cd"
        ),
    ]
)
