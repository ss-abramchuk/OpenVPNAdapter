#
#  Be sure to run `pod spec lint OpenVPNAdapter.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "OpenVPNAdapter"
  s.version      = "0.1.0"
  s.summary      = "Objective-C wrapper for OpenVPN library. Compatible with iOS and macOS."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
    OpenVPNAdapter is an Objective-C framework that allows to easily configure and establish VPN connection using OpenVPN protocol. It is based on the original openvpn3 library so it has every feature the library has.
    The framework is designed to use in conjunction with NetworkExtension framework and doesn't use any private Apple API. Compatible with iOS and macOS and also Swift friendly
  DESC

  s.homepage     = "http://EXAMPLE/OpenVPNAdapter"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = "AGPLv3"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "Sergey Abramchuk" => "personal@ss-abramchuk.me" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  #  When using multiple platforms
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "file:///Users/ss.abramchuk/Sources.localized/open-source.localized/openvpn-adapter", :branch => "feature/cocoapods" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "Sources/OpenVPNAdapter/*.{h,m,mm}"

  s.public_header_files = "Sources/OpenVPNAdapter/*.h"
  s.private_header_files = "Sources/OpenVPNAdapter/OpenVPNReachabilityTracker.h", "Sources/OpenVPNAdapter/OpenVPNReachability+Internal.h"

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

  s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(TARGETNAME)/openvpn3" }

  # ――― Subspecs ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.subspec 'openvpn3' do |ovpns|
    ovpns.source_files = "Sources/OpenVPNAdapter/Libraries/Vendors/openvpn/client/*.{hpp,cpp}"
    ovpns.preserve_paths = "Sources/OpenVPNAdapter/Libraries/Vendors/openvpn/openvpn"
  end

end
