# OpenVPNAdapter

![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS-lightgrey.svg)
![iOS Versions](https://img.shields.io/badge/iOS-9.0+-yellow.svg)
![macOS Versions](https://img.shields.io/badge/macOS-10.11+-yellow.svg)
![Xcode Version](https://img.shields.io/badge/Xcode-11.0+-yellow.svg)
![Carthage Compatible](https://img.shields.io/badge/Carthage-Compatible-4BC51D.svg?style=flat)
![Cocoapods Compatible](https://img.shields.io/badge/Cocoapods-Compatible-4BC51D.svg?style=flat)
![Swift Package Manager Compatible](https://img.shields.io/badge/Swift%20Package%20Manager-Compatible-4BC51D.svg?style=flat)
![License](https://img.shields.io/badge/License-AGPLv3-lightgrey.svg)

## Overview
OpenVPNAdapter is an Objective-C framework that allows to easily configure and establish VPN connection using OpenVPN protocol. It is based on the original [openvpn3](https://github.com/OpenVPN/openvpn3) library so it has every feature the library has.

The framework is designed to use in conjunction with [`NetworkExtension`](https://developer.apple.com/documentation/networkextension) framework and doesn't use any private Apple API. Compatible with iOS and macOS and also Swift friendly.

## Installation

### Requirements
- iOS 9.0+ or macOS 10.11+
- Xcode 11.0+

### Carthage
To install OpenVPNAdapter with Carthage, add the following line to your `Cartfile`.

```
github "ss-abramchuk/OpenVPNAdapter"
```

Then run `$ carthage update` command. For details of the installation and usage of Carthage, visit [its project page](https://github.com/Carthage/Carthage).

### Cocoapods
To install OpenVPNAdapter with Cocoapods, add the following lines to your `Podfile`.

```ruby
target 'Your Target Name' do
  use_frameworks!
  pod 'OpenVPNAdapter', :git => 'https://github.com/ss-abramchuk/OpenVPNAdapter.git', :tag => '0.7.0'
end
```

And run `$ pod install`.

### Swift Package Manager
Add `OpenVPNAdapter` package to your project using File > Swift Packages > Add Package Dependency menu. Xcode 11 will automatically retrieve all necessary dependencies. In addition to that you need to add `SystemConfiguration` framework to the Frameworks and Libraries. If you work on iOS project add `UIKit` as well.

## Usage
At first, you need to add a Packet Tunnel Provider extension to the project and configure provision profiles for both the container app and the extension. There are official documentation and many tutorials describing how to do it so we won't dwell on this in detail.

Before you can configure and establish VPN connection don't forget to import [`NetworkExtension`](https://developer.apple.com/documentation/networkextension).

```swift
import NetworkExtension
```

Then we need to create or load a VPN profile. [`NETunnelProviderManager`](https://developer.apple.com/documentation/networkextension/netunnelprovidermanager) is used to configure and control  VPN connections provided by a Tunnel Provider extension. Each instance corresponds to a single VPN configuration stored in the Network Extension preferences. ￼Call the following method to load all existing VPN profiles from the system preferences. For the sake of simplicity, we will use only one instance of [`NETunnelProviderManager`](https://developer.apple.com/documentation/networkextension/netunnelprovidermanager) assuming that our object has a property named `providerManager`.

```swift
NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
    guard error == nil else {
        // Handle an occurred error
        return
    }

    self.providerManager = managers?.first ?? NETunnelProviderManager()
}
```
The next step is to provide VPN settings to the instance of [`NETunnelProviderManager`](https://developer.apple.com/documentation/networkextension/netunnelprovidermanager). Setup the [`NETunnelProviderProtocol`](https://developer.apple.com/documentation/networkextension/netunnelproviderprotocol) object with appropriate values and save it in preferences.

```swift
self.providerManager?.loadFromPreferences(completionHandler: { (error) in
    guard error == nil else {
        // Handle an occurred error
        return
    }

    // Assuming the app bundle contains a configuration file named 'client.ovpn' lets get its
    // Data representation
    guard
        let configurationFileURL = Bundle.main.url(forResource: "client", withExtension: "ovpn"),
        let configurationFileContent = try? Data(contentsOf: configurationFileURL)
    else {
        fatalError()
    }

    let tunnelProtocol = NETunnelProviderProtocol()

    // If the ovpn file doesn't contain server address you can use this property
    // to provide it. Or just set an empty string value because `serverAddress`
    // property must be set to a non-nil string in either case.
    tunnelProtocol.serverAddress = ""

    // The most important field which MUST be the bundle ID of our custom network
    // extension target.
    tunnelProtocol.providerBundleIdentifier = "com.example.openvpn-client.tunnel-provider"

    // Use `providerConfiguration` to save content of the ovpn file.
    tunnelProtocol.providerConfiguration = ["ovpn": configurationFileContent]

    // Provide user credentials if needed. It is highly recommended to use
    // keychain to store a password.
    tunnelProtocol.username = "username"
    tunnelProtocol.passwordReference = ... // A persistent keychain reference to an item containing the password

    // Finish configuration by assigning tunnel protocol to `protocolConfiguration`
    // property of `providerManager` and by setting description.
    self.providerManager?.protocolConfiguration = tunnelProtocol
    self.providerManager?.localizedDescription = "OpenVPN Client"

    self.providerManager?.isEnabled = true

    // Save configuration in the Network Extension preferences
    self.providerManager?.saveToPreferences(completionHandler: { (error) in
        if let error = error  {
            // Handle an occurred error
        }
    })
}
```

Start VPN by calling the following code.

```swift
self.providerManager?.loadFromPreferences(completionHandler: { (error) in
    guard error == nil else {
        // Handle an occurred error
        return
    }

    do {
        try self.providerManager?.connection.startVPNTunnel()
    } catch {
        // Handle an occurred error
    }
}
```

Packet Tunnel Provider extension uses [`NEPacketTunnelProvider`](https://developer.apple.com/documentation/networkextension/nepackettunnelprovider) subclass to configure and establish VPN connection. Therefore, that class is the right place to configure OpenVPNAdapter. The following example shows how you can setup it:

```swift
import NetworkExtension
import OpenVPNAdapter

// Extend NEPacketTunnelFlow to adopt OpenVPNAdapterPacketFlow protocol so that
// `self.packetFlow` could be sent to `completionHandler` callback of OpenVPNAdapterDelegate
// method openVPNAdapter(openVPNAdapter:configureTunnelWithNetworkSettings:completionHandler).
extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow {}

class PacketTunnelProvider: NEPacketTunnelProvider {

    lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self

        return adapter
    }()

    let vpnReachability = OpenVPNReachability()

    var startHandler: ((Error?) -> Void)?
    var stopHandler: (() -> Void)?

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // There are many ways to provide OpenVPN settings to the tunnel provider. For instance,
        // you can use `options` argument of `startTunnel(options:completionHandler:)` method or get
        // settings from `protocolConfiguration.providerConfiguration` property of `NEPacketTunnelProvider`
        // class. Also you may provide just content of a ovpn file or use key:value pairs
        // that may be provided exclusively or in addition to file content.

        // In our case we need providerConfiguration dictionary to retrieve content
        // of the OpenVPN configuration file. Other options related to the tunnel
        // provider also can be stored there.
        guard
            let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
            let providerConfiguration = protocolConfiguration.providerConfiguration
        else {
            fatalError()
        }

        guard let ovpnFileContent: Data = providerConfiguration["ovpn"] as? Data else {
            fatalError()
        }

        let configuration = OpenVPNConfiguration()
        configuration.fileContent = ovpnFileContent
        configuration.settings = [
            // Additional parameters as key:value pairs may be provided here
        ]

        // Uncomment this line if you want to keep TUN interface active during pauses or reconnections
        // configuration.tunPersist = true

        // Apply OpenVPN configuration
        let evaluation: OpenVPNConfigurationEvaluation
        do {
            evaluation = try vpnAdapter.apply(configuration: configuration)
        } catch {
            completionHandler(error)
            return
        }

        // Provide credentials if needed
        if !evaluation.autologin {
            // If your VPN configuration requires user credentials you can provide them by
            // `protocolConfiguration.username` and `protocolConfiguration.passwordReference`
            // properties. It is recommended to use persistent keychain reference to a keychain
            // item containing the password.

            guard let username: String = protocolConfiguration.username else {
                fatalError()
            }

            // Retrieve a password from the keychain
            guard let password: String = ... {
                fatalError()
            }

            let credentials = OpenVPNCredentials()
            credentials.username = username
            credentials.password = password

            do {
                try vpnAdapter.provide(credentials: credentials)
            } catch {
                completionHandler(error)
                return
            }
        }

        // Checking reachability. In some cases after switching from cellular to
        // WiFi the adapter still uses cellular data. Changing reachability forces
        // reconnection so the adapter will use actual connection.
        vpnReachability.startTracking { [weak self] status in
            guard status == .reachableViaWiFi else { return }
            self?.vpnAdapter.reconnect(interval: 5)
        }

        // Establish connection and wait for .connected event
        startHandler = completionHandler
        vpnAdapter.connect(using: packetFlow)
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopHandler = completionHandler

        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }

        vpnAdapter.disconnect()
    }

}

extension PacketTunnelProvider: OpenVPNAdapterDelegate {

    // OpenVPNAdapter calls this delegate method to configure a VPN tunnel.
    // `completionHandler` callback requires an object conforming to `OpenVPNAdapterPacketFlow`
    // protocol if the tunnel is configured without errors. Otherwise send nil.
    // `OpenVPNAdapterPacketFlow` method signatures are similar to `NEPacketTunnelFlow` so
    // you can just extend that class to adopt `OpenVPNAdapterPacketFlow` protocol and
    // send `self.packetFlow` to `completionHandler` callback.
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?, completionHandler: @escaping (Error?) -> Void) {
        // In order to direct all DNS queries first to the VPN DNS servers before the primary DNS servers
        // send empty string to NEDNSSettings.matchDomains  
        networkSettings?.dnsSettings?.matchDomains = [""]

        // Set the network settings for the current tunneling session.
        setTunnelNetworkSettings(networkSettings, completionHandler: completionHandler)
    }

    // Process events returned by the OpenVPN library
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message: String?) {
        switch event {
        case .connected:
            if reasserting {
                reasserting = false
            }

            guard let startHandler = startHandler else { return }

            startHandler(nil)
            self.startHandler = nil

        case .disconnected:
            guard let stopHandler = stopHandler else { return }

            if vpnReachability.isTracking {
                vpnReachability.stopTracking()
            }

            stopHandler()
            self.stopHandler = nil

        case .reconnecting:
            reasserting = true

        default:
            break
        }
    }

    // Handle errors thrown by the OpenVPN library
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
        // Handle only fatal errors
        guard let fatal = (error as NSError).userInfo[OpenVPNAdapterErrorFatalKey] as? Bool, fatal == true else {
            return
        }

        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }

        if let startHandler = startHandler {
            startHandler(error)
            self.startHandler = nil
        } else {
            cancelTunnelWithError(error)
        }
    }

    // Use this method to process any log message returned by OpenVPN library.
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
        // Handle log messages
    }

}
```

## Contributing
Any contributions and suggestions are welcome! But before creating a PR or an issue please read the [Contribution Guide](CONTRIBUTING.md).

## Acknowledgments
Special thanks goes to [@JonathanDowning](https://github.com/JonathanDowning) for great help in development of this project and bug fixing.

## License
OpenVPNAdapter is available under the AGPLv3 license. See the [LICENSE](LICENSE) file for more info. Also this project has a few dependencies:
- [openvpn3](https://github.com/OpenVPN/openvpn3)
- [asio](https://github.com/chriskohlhoff/asio)
- [lz4](https://github.com/lz4/lz4)
- [mbedtls](https://github.com/ARMmbed/mbedtls)

See the [NOTICE](NOTICE) file for more info about their licenses and copyrights.
