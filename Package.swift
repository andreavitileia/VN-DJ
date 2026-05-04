// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VN-DJ",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "VN-DJ", targets: ["VN-DJ"])
    ],
    targets: [
        .executableTarget(
            name: "VN-DJ",
            path: "VN-DJ"
        )
    ]
)
