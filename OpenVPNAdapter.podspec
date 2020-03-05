Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "OpenVPNAdapter"
  s.version = "0.4.0"
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


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.frameworks = "Foundation", "NetworkExtension", "SystemConfiguration", "UIKit"
  s.osx.frameworks = "Foundation", "NetworkExtension", "SystemConfiguration"


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

  s.subspec "OpenVPNAdapter" do |adapter|
    adapter_path = "Sources/OpenVPNAdapter"

    adapter.source_files  = "#{adapter_path}/library/*.{h,m,mm}"
    adapter.public_header_files = "#{adapter_path}/include/*.h"

    adapter.compiler_flags = "-DUSE_ASIO"
  end

  s.subspec "ASIO" do |asio|
    asio_path = "Sources/ASIO"

    asio.public_header_files = "#{asio_path}/asio/include/**/*.{hpp,ipp}"
  end

  s.subspec "LZ4" do |lz4|
    lz4_path = "Sources/LZ4"

    lz4.source_files  = "#{lz4_path}/lib/*.{h,c}"
    lz4.public_header_files = "#{lz4_path}/include/*.h"

    lz4.compiler_flags = "-DXXH_NAMESPACE=LZ4_"
  end

  s.subspec "mbedTLS" do |mbedtls|
    mbedtls_path = "Sources/mbedTLS"

    mbedtls.source_files  = "#{mbedtls_path}/library/*.{c}"
    mbedtls.public_header_files = "#{mbedtls_path}/include/*.h"

    mbedtls.compiler_flags = "-DMBEDTLS_MD4_C", "-DMBEDTLS_RELAXED_X509_DATE", "-D_FILE_OFFSET_BITS=64"
  end

  s.subspec "OpenVPN3" do |openvpn|
    openvpn_path = "Sources/OpenVPN3"

    openvpn.public_header_files = "#{openvpn_path}/openvpn/**/*.hpp"
    openvpn.preserve_paths = "#{openvpn_path}/client/*.{hpp,cpp}"
  end

  s.subspec "OpenVPNClient" do |client|
    client_path = "Sources/OpenVPNClient"

    client.source_files  = "#{client_path}/library/*.{mm}"
    client.public_header_files = "#{client_path}/include/*.h"

    client.compiler_flags = "-DUSE_ASIO", "-DUSE_ASIO_THREADLOCAL", "-DASIO_STANDALONE", "-DASIO_NO_DEPRECATED", "-DASIO_HAS_STD_STRING_VIEW", "-DHAVE_LZ4", "-DUSE_MBEDTLS", "-DOPENVPN_FORCE_TUN_NULL", "-DUSE_TUN_BUILDER"
  end

end
