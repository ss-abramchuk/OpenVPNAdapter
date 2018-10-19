Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "OpenVPNAdapter"
  s.version = "0.1.0"
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

  s.source = { :git => "https://github.com/ss-abramchuk/OpenVPNAdapter.git", :branch => "feature/cocoapods" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  framework_path = "Sources/OpenVPNAdapter"
  vendors_path = "#{framework_path}/Libraries/Vendors"

  lz4_path = "#{vendors_path}/lz4"
  mbedtls_path = "#{vendors_path}/mbedtls"
  asio_path = "#{vendors_path}/asio"
  openvpn_path = "#{vendors_path}/openvpn"

  s.source_files  = "#{framework_path}/*.{h,m,mm}", "#{openvpn_path}/client/*.{hpp,cpp}"

  s.public_header_files = "#{framework_path}/*.h"
  s.private_header_files = [
    "#{framework_path}/*+Internal.h",
    "#{framework_path}/OpenVPNReachabilityTracker.h",
    "#{framework_path}/OpenVPNClient.h",
    "#{framework_path}/OpenVPNNetworkSettingsBuilder.h",
    "#{framework_path}/OpenVPNPacket.h",
    "#{framework_path}/OpenVPNPacketFlowBridge.h",
    "#{framework_path}/NSError+OpenVPNError.h",
    "#{framework_path}/NSArray+OpenVPNAdditions.h",
    "#{openvpn_path}/openvpn/**/*.hpp",
    "#{openvpn_path}/client/*.hpp"
  ]

  s.preserve_paths = [
    "#{lz4_path}/include/*.h",
    "#{mbedtls_path}/include/**/*.h",
    "#{asio_path}/asio/include/**/*.{hpp,ipp}",
    "#{openvpn_path}/openvpn/**/*.hpp"
  ]

  s.module_map = "Configuration/OpenVPNAdapter.modulemap"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.frameworks = "Foundation", "NetworkExtension", "SystemConfiguration", "UIKit"
  s.osx.frameworks = "Foundation", "NetworkExtension", "SystemConfiguration"

  s.ios.vendored_libraries = [
    "#{lz4_path}/lib/ios/liblz4.a",
    "#{mbedtls_path}/lib/ios/libmbedcrypto.a",
    "#{mbedtls_path}/lib/ios/libmbedtls.a",
    "#{mbedtls_path}/lib/ios/libmbedx509.a"
  ]

  s.osx.vendored_libraries = [
    "#{lz4_path}/lib/macos/liblz4.a",
    "#{mbedtls_path}/lib/macos/libmbedcrypto.a",
    "#{mbedtls_path}/lib/macos/libmbedtls.a",
    "#{mbedtls_path}/lib/macos/libmbedx509.a"
  ]

  s.libraries = "lz4", "mbedcrypto", "mbedtls", "mbedx509"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.prefix_header_file = false

  s.xcconfig = {
    "APPLICATION_EXTENSION_API_ONLY" => "YES",
    "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++14",
    "CLANG_CXX_LIBRARY" => "libc++",
    "HEADER_SEARCH_PATHS" => "\"${PODS_TARGET_SRCROOT}/#{lz4_path}/include/**\" \"${PODS_TARGET_SRCROOT}/#{mbedtls_path}/include/**\" \"${PODS_TARGET_SRCROOT}/#{asio_path}/asio/include/**\" \"${PODS_TARGET_SRCROOT}/#{openvpn_path}/**\"",
    "GCC_WARN_64_TO_32_BIT_CONVERSION" => "NO",
    "CLANG_WARN_DOCUMENTATION_COMMENTS" => "NO",
    "OTHER_CPLUSPLUSFLAGS" => "$(OTHER_CFLAGS) -DUSE_ASIO -DUSE_ASIO_THREADLOCAL -DASIO_STANDALONE -DASIO_NO_DEPRECATED -DHAVE_LZ4 -DUSE_MBEDTLS -DOPENVPN_FORCE_TUN_NULL -DUSE_TUN_BUILDER"
  }

end
