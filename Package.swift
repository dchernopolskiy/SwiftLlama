// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftLlama",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "SwiftLlama", targets: ["SwiftLlama"]),
    ],
    targets: [
        .target(
            name: "llama",
            dependencies: [],
            path: "Sources/llama",
            exclude: [], // We rely on the provided sources
            sources: ["src"],
            publicHeadersPath: "include",
            cSettings: [
                .define("GGML_USE_ACCELERATE"),
                .define("ACCELERATE_NEW_LAPACK"),
                .define("ACCELERATE_LAPACK_ILP64"),
                .define("GGML_USE_METAL"),
                .define("GGML_USE_CPU"),
                .headerSearchPath("src"),
                .unsafeFlags(["-O3", "-fno-objc-arc"]) // -fno-objc-arc might be needed for .m files if they are not ARC compliant (ggml-metal often is manual ref counting or C-like)
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("Foundation")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SwiftLlama",
            dependencies: ["llama"]
        ),
        .testTarget(
            name: "SwiftLlamaTests",
            dependencies: ["SwiftLlama"]
        ),
    ]
)
