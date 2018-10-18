Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name         = "OpenVPNAdapter"
  s.version      = "0.1.0"
  s.summary      = "Objective-C wrapper for OpenVPN library. Compatible with iOS and macOS."
  s.description  = <<-DESC
    OpenVPNAdapter is an Objective-C framework that allows to easily configure and establish VPN connection using OpenVPN protocol. It is based on the original openvpn3 library so it has every feature the library has.
    The framework is designed to use in conjunction with NetworkExtension framework and doesn't use any private Apple API. Compatible with iOS and macOS and also Swift friendly
  DESC

  s.homepage     = "https://github.com/ss-abramchuk/OpenVPNAdapter"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license      = "AGPLv3"


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author             = { "Sergey Abramchuk" => "personal@ss-abramchuk.me" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source       = { :git => "https://github.com/ss-abramchuk/OpenVPNAdapter.git", :branch => "develop" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "Sources/OpenVPNAdapter/*.{h,m,mm}"

  s.public_header_files = "Sources/OpenVPNAdapter/*.h"
  s.private_header_files = [
      "Sources/OpenVPNAdapter/*+Internal.h",
      "Sources/OpenVPNAdapter/OpenVPNReachabilityTracker.h",
      "Sources/OpenVPNAdapter/OpenVPNClient.h",
      "Sources/OpenVPNAdapter/OpenVPNNetworkSettingsBuilder.h",
      "Sources/OpenVPNAdapter/OpenVPNPacket.h",
      "Sources/OpenVPNAdapter/OpenVPNPacketFlowBridge.h",
      "Sources/OpenVPNAdapter/NSError+OpenVPNError.h",
      "Sources/OpenVPNAdapter/NSArray+OpenVPNAdditions.h"
  ]

  s.module_map = "Configuration/OpenVPNAdapter.modulemap"

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  s.ios.frameworks = "UIKit", "NetworkExtension", "SystemConfiguration"
  s.osx.frameworks = "NetworkExtension", "SystemConfiguration"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  s.requires_arc = true

  s.xcconfig = {
      "APPLICATION_EXTENSION_API_ONLY" => "YES",
      "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++14",
      "CLANG_CXX_LIBRARY" => "libc++",
      "GCC_WARN_64_TO_32_BIT_CONVERSION" => "NO"
  }

  # ――― Subspecs ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  vendors_path = "Sources/OpenVPNAdapter/Libraries/Vendors"

  # s.subspec 'lz4' do |lz4|
  #   lz4.ios.vendored_library = "Sources/OpenVPNAdapter/Libraries/Vendors/lz4/lib/ios/liblz4.a"
  #   lz4.osx.vendored_library = "Sources/OpenVPNAdapter/Libraries/Vendors/lz4/lib/macos/liblz4.a"
  # end
  #
  # s.subspec 'mbedtls' do |mbedtls|
  #   mbedtls.preserve_paths = "Sources/OpenVPNAdapter/Libraries/Vendors/mbedtls/include/mbedtls/*.h"
  #   mbedtls.ios.vendored_libraries = [
  #     "Sources/OpenVPNAdapter/Libraries/Vendors/mbedtls/lib/ios/libmbedcrypto.a",
  #     "Sources/OpenVPNAdapter/Libraries/Vendors/mbedtls/lib/ios/libmbedtls.a",
  #     "Sources/OpenVPNAdapter/Libraries/Vendors/mbedtls/lib/ios/libmbedx509.a"
  #   ]
  #   mbedtls.osx.vendored_libraries = [
  #     "Sources/OpenVPNAdapter/Libraries/Vendors/mbedtls/lib/macos/libmbedcrypto.a",
  #     "Sources/OpenVPNAdapter/Libraries/Vendors/mbedtls/lib/macos/libmbedtls.a",
  #     "Sources/OpenVPNAdapter/Libraries/Vendors/mbedtls/lib/macos/libmbedx509.a"
  #   ]
  # end

  s.subspec 'asio' do |asio|
    asio_path = "#{vendors_path}/asio"

    asio.preserve_paths = "#{asio_path}/asio/include/**/*.{hpp,ipp}"
    asio.xcconfig = { "HEADER_SEARCH_PATHS" => "${PODS_ROOT}/#{s.name}/#{asio_path}/asio/include/**" }
  end

  s.subspec 'openvpn3' do |openvpn|
    openvpn_path = "#{vendors_path}/openvpn"

    openvpn.source_files = "#{openvpn_path}/client/*.{hpp,cpp}"
    openvpn.preserve_paths = "#{openvpn_path}/openvpn/**/*.hpp"

    openvpn.xcconfig = {
        "HEADER_SEARCH_PATHS" => "${PODS_ROOT}/#{s.name}/#{openvpn_path}/**",
        "OTHER_CPLUSPLUSFLAGS" => "$(OTHER_CFLAGS) -DUSE_ASIO -DUSE_ASIO_THREADLOCAL -DASIO_STANDALONE -DASIO_NO_DEPRECATED -DHAVE_LZ4 -DUSE_MBEDTLS -DOPENVPN_FORCE_TUN_NULL -DUSE_TUN_BUILDER"
    }
  end

end
