// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Whiteboard",
    platforms: [.iOS(.v10)],
    products: [
        .library(
            name: "Whiteboard",
            targets: ["Whiteboard"]),
    ],
    dependencies: [
        .package(name: "DSBridge-IOS", url: "https://github.com/netless-io/DSBridge-IOS.git", from: .init(3, 1, 1)),
        .package(name: "YYModel", url: "https://github.com/vince-hz/YYModel.git", from: .init(1, 1, 0))
    ],
    targets: [
        .target(name: "Whiteboard",
                dependencies: ["YYModel", "DSBridge-IOS"],
                path: "Whiteboard",
                exclude: [
                    "Classes/Model-YYKit",
                    "Classes/include/cpScript.sh",
                    "Classes/fpa"
                ],
                sources: ["Classes"],
                resources: [
                    .process("Resource")
                ],
                publicHeadersPath: "Classes/include",
                cSettings: .headers
               )
    ]
)

extension Array where Element == CSetting {
    static var headers: [Element] {
        [
            .headerSearchPath("Classes/Converter"),
            .headerSearchPath("Classes/Displayer"),
            .headerSearchPath("Classes/Model"),
            .headerSearchPath("Classes/NativeReplayer"),
            .headerSearchPath("Classes/Object"),
            .headerSearchPath("Classes/Replayer"),
            .headerSearchPath("Classes/Room"),
            .headerSearchPath("Classes/SDK")
        ]
    }
}
