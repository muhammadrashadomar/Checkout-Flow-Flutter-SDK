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
        .package(url: "https://github.com/checkout/checkout-risk-sdk-ios", from: "4.0.2")
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
                "https://github.com/checkout/checkout-ios-components/releases/download/1.8.0/CheckoutComponentsSDK.xcframework.zip",
            checksum: "e0148b3f16bb2d54a9f4bd36c861961f1c621ba5db3aca8afb7b4e01a802294b"
        ),
    ]
)
