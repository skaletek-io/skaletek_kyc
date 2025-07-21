// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "camera_avfoundation", path: "/Users/apple/.pub-cache/hosted/pub.dev/camera_avfoundation-0.9.20+3/ios/camera_avfoundation"),
        .package(name: "device_info_plus", path: "/Users/apple/.pub-cache/hosted/pub.dev/device_info_plus-11.5.0/ios/device_info_plus"),
        .package(name: "face_liveness_detector", path: "/Users/apple/.pub-cache/hosted/pub.dev/face_liveness_detector-0.2.7/ios/face_liveness_detector"),
        .package(name: "file_picker", path: "/Users/apple/.pub-cache/hosted/pub.dev/file_picker-10.2.0/ios/file_picker"),
        .package(name: "image_picker_ios", path: "/Users/apple/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.12+2/ios/image_picker_ios"),
        .package(name: "package_info_plus", path: "/Users/apple/.pub-cache/hosted/pub.dev/package_info_plus-8.3.0/ios/package_info_plus"),
        .package(name: "path_provider_foundation", path: "/Users/apple/.pub-cache/hosted/pub.dev/path_provider_foundation-2.4.1/darwin/path_provider_foundation"),
        .package(name: "shared_preferences_foundation", path: "/Users/apple/.pub-cache/hosted/pub.dev/shared_preferences_foundation-2.5.4/darwin/shared_preferences_foundation")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "camera-avfoundation", package: "camera_avfoundation"),
                .product(name: "device-info-plus", package: "device_info_plus"),
                .product(name: "face-liveness-detector", package: "face_liveness_detector"),
                .product(name: "file-picker", package: "file_picker"),
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation")
            ]
        )
    ]
)
