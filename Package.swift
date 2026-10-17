// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RelationshipCompass",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "RelationshipCompass",
            path: "Sources/RelationshipCompass",
            swiftSettings: [.unsafeFlags(["-enable-testing"])]
        ),
        .executableTarget(
            name: "RelationshipCompassApp",
            dependencies: ["RelationshipCompass"],
            path: "Sources/RelationshipCompassApp"
        ),
        .executableTarget(
            name: "RelationshipCompassTests",
            dependencies: ["RelationshipCompass"],
            path: "Tests/RelationshipCompassTests"
        )
    ]
)
