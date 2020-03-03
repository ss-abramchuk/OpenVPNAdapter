// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "OpenVPNAdapter",
    platforms: [
        .iOS("9.0"),
        .macOS("10.11"),
    ],
    products: [
        .library(name: "OpenVPNAdapter", type: .static, targets: ["OpenVPNAdapter"]),
    ],
    targets: [
        .target(
            name: "OpenVPNAdapter",
            dependencies: [
                .target(name: "mbedTLS"),
                .target(name: "OpenVPN3")
            ],
            sources: ["library"],
            cxxSettings: [
                .headerSearchPath("../ASIO/asio/include"),
                .headerSearchPath("../OpenVPN3"),
                .define("ASIO_STANDALONE"),
                .define("ASIO_NO_DEPRECATED"),
                .define("ASIO_HAS_STD_STRING_VIEW"),
                .define("USE_ASIO"),
                .define("USE_ASIO_THREADLOCAL")
            ]
        ),
        .target(
            name: "LZ4",
            sources: ["lib"],
            cSettings: [
                .define("XXH_NAMESPACE", to: "LZ4_")
            ]
        ),
        .target(
            name: "mbedTLS", 
            sources: ["library"],
            cSettings: [
                .define("MBEDTLS_MD4_C"),
                .define("MBEDTLS_RELAXED_X509_DATE"),
                .define("_FILE_OFFSET_BITS", to: "64"),
            ]
        ),
        .target(
            name: "OpenVPN3",
            dependencies: [
                .target(name: "LZ4"),
                .target(name: "mbedTLS")
            ],
            sources: ["library"],
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("../ASIO/asio/include"),
                .define("ASIO_STANDALONE"),
                .define("ASIO_NO_DEPRECATED"),
                .define("ASIO_HAS_STD_STRING_VIEW"),
                .define("USE_ASIO"),
                .define("USE_ASIO_THREADLOCAL"),
                .define("HAVE_LZ4"),
                .define("USE_MBEDTLS"),
                .define("OPENVPN_FORCE_TUN_NULL"),
                .define("USE_TUN_BUILDER")
            ]
        )
    ],
    cxxLanguageStandard: .gnucxx14
)
