Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "OpenVPNAdapter"
  s.version = "0.2.0"
  s.summary   = "Objective-C wrapper for OpenVPN library. Compatible with iOS and macOS."
  s.description = <<-DESC
    OpenVPNAdapter is an Objective-C framework that allows to easily configure and establish VPN connection using OpenVPN protocol.
    It is based on the original openvpn3 library so it has every feature the library has. The framework is designed to use in conjunction
    with NetworkExtension framework and doesn't use any private Apple API. Compatible with iOS and macOS and also Swift friendly.
  DESC

  s.homepage = "https://github.com/ss-abramchuk/OpenVPNAdapter"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license = "AGPLv3"


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author = { "Sergey Abramchuk" => "personal@ss-abramchuk.me" }


  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source = { :git => "https://github.com/ss-abramchuk/OpenVPNAdapter.git", :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  framework_path = "Sources/OpenVPNAdapter"
  vendors_path = "#{framework_path}/Libraries/Vendors"

  s.source_files  = "#{framework_path}/*.{h,m,mm}"

  s.public_header_files = "#{framework_path}/*.h"
  s.private_header_files = [
    "#{framework_path}/*+Internal.h",
    "#{framework_path}/OpenVPNReachabilityTracker.h",
    "#{framework_path}/OpenVPNClient.h",
    "#{framework_path}/OpenVPNNetworkSettingsBuilder.h",
    "#{framework_path}/OpenVPNPacket.h",
    "#{framework_path}/OpenVPNPacketFlowBridge.h",
    "#{framework_path}/NSError+OpenVPNError.h",
    "#{framework_path}/NSArray+OpenVPNAdditions.h"
  ]

  s.module_map = "Configuration/OpenVPNAdapter.modulemap"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.frameworks = "Foundation", "NetworkExtension", "SystemConfiguration", "UIKit"
  s.osx.frameworks = "Foundation", "NetworkExtension", "SystemConfiguration"

  s.libraries = "lz4", "mbedcrypto", "mbedtls", "mbedx509"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.prefix_header_file = false

  s.xcconfig = {
    "APPLICATION_EXTENSION_API_ONLY" => "YES",
    "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++14",
    "CLANG_CXX_LIBRARY" => "libc++",
    "GCC_WARN_64_TO_32_BIT_CONVERSION" => "NO",
    "CLANG_WARN_DOCUMENTATION_COMMENTS" => "NO"
  }


  # ――― Subspecs ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.subspec "lz4" do |lz4|
    lz4_path = "#{vendors_path}/lz4"

    lz4.preserve_paths = "#{lz4_path}/include/*.h"

    lz4.ios.vendored_libraries = [
      "#{lz4_path}/lib/ios/liblz4.a"
    ]

    lz4.osx.vendored_libraries = [
      "#{lz4_path}/lib/macos/liblz4.a"
    ]

    lz4.xcconfig = {
      "HEADER_SEARCH_PATHS" => "${PODS_TARGET_SRCROOT}/#{lz4_path}/include/**"
    }
  end

  s.subspec "mbedtls" do |mbedtls|
    mbedtls_path = "#{vendors_path}/mbedtls"

    mbedtls.preserve_paths = "#{mbedtls_path}/include/**/*.h"

    mbedtls.ios.vendored_libraries = [
      "#{mbedtls_path}/lib/ios/libmbedcrypto.a",
      "#{mbedtls_path}/lib/ios/libmbedtls.a",
      "#{mbedtls_path}/lib/ios/libmbedx509.a"
    ]

    mbedtls.osx.vendored_libraries = [
      "#{mbedtls_path}/lib/macos/libmbedcrypto.a",
      "#{mbedtls_path}/lib/macos/libmbedtls.a",
      "#{mbedtls_path}/lib/macos/libmbedx509.a"
    ]

    mbedtls.xcconfig = {
      "HEADER_SEARCH_PATHS" => "${PODS_TARGET_SRCROOT}/#{mbedtls_path}/include/**"
    }
  end

  s.subspec "asio" do |asio|
    asio_path = "#{vendors_path}/asio"

    asio.preserve_paths = "#{asio_path}/asio/include/**/*.{hpp,ipp}"

    asio.xcconfig = {
      "HEADER_SEARCH_PATHS" => "${PODS_TARGET_SRCROOT}/#{asio_path}/asio/include/**"
    }
  end

  s.subspec "openvpn" do |openvpn|
    openvpn_path = "#{vendors_path}/openvpn"

    openvpn.source_files = "#{openvpn_path}/client/*.{hpp,cpp}"
    openvpn.private_header_files = "#{openvpn_path}/client/*.hpp"

    openvpn.preserve_paths = "#{openvpn_path}/openvpn/**/*.hpp"

    openvpn.compiler_flags = "-x objective-c++"

    openvpn.xcconfig = {
      "HEADER_SEARCH_PATHS" => "${PODS_TARGET_SRCROOT}/#{openvpn_path}/**",
      "OTHER_CPLUSPLUSFLAGS" => "$(OTHER_CFLAGS) -DUSE_ASIO -DUSE_ASIO_THREADLOCAL -DASIO_STANDALONE -DASIO_NO_DEPRECATED -DASIO_HAS_STD_STRING_VIEW -DHAVE_LZ4 -DUSE_MBEDTLS -DOPENVPN_FORCE_TUN_NULL -DUSE_TUN_BUILDER"
    }
  end

end
