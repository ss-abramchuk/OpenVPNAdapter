# OpenVPNAdapter

![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS-lightgrey.svg)
![iOS Versions](https://img.shields.io/badge/iOS-9.0+-yellow.svg)
![macOS Versions](https://img.shields.io/badge/macOS-10.11+-yellow.svg)
![Xcode Version](https://img.shields.io/badge/Xcode-9.0+-yellow.svg)
![Carthage Compatible](https://img.shields.io/badge/Carthage-Compatible-4BC51D.svg?style=flat)
![License](https://img.shields.io/badge/License-AGPLv3-lightgrey.svg)

## Overview
## Installation
### Requirements
- iOS 9.0+ or macOS 10.11+
- Xcode 9.0+

### Carthage
To install OpenVPNAdapter with Carthage, add the following line to your `Cartfile`.

```
github "ss-abramchuk/OpenVPNAdapter"
```

Then run `carthage update` command. For details of the installation and usage of Carthage, visit [its project page](https://github.com/Carthage/Carthage).

## Usage
OpenVPNAdapter is designed to use in conjunction with [`NetworkExtension`](https://developer.apple.com/documentation/networkextension) framework. So at first, you need to add a Packet Tunnel Provider extension to the project and configure provision profiles for both the container app and the extension. There are official documentation and many tutorials describing how to do it so we won't dwell on this in detail.

Packet Tunnel Provider extension uses [`NEPacketTunnelProvider`](https://developer.apple.com/documentation/networkextension/nepackettunnelprovider) subclass to configure and establish VPN connection. Therefore, that class is the right place to configure OpenVPNAdapter. The following example shows how you can setup it:

```swift
import NetworkExtension
import OpenVPNAdapter

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
        let ovpnFileContent: NSData = ... // Retrieve content of a ovpn file
        let ovpnSettings: [String : String] = ... // Retrieve settings as key:value pairs

        let configuration = OpenVPNConfiguration()
        configuration.fileContent = ovpnFileContent
        configuration.settings = ovpnSettings

        let properties: OpenVPNProperties
        do {
            properties = try vpnAdapter.apply(configuration: configuration)
        } catch {
            completionHandler(error)
            return
        }

        if !properties.autologin {
            let username: String = ... // Retrieve a username
            let password: String = ... // Retrieve a password

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

        vpnReachability.startTracking { [weak self] status in
            guard status != .notReachable else { return }
            self?.vpnAdapter.reconnect(interval: 5)
        }

        startHandler = completionHandler
        vpnAdapter.connect()
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

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings, completionHandler: @escaping (OpenVPNAdapterPacketFlow?) -> Void) {
        setTunnelNetworkSettings(settings) { (error) in
            completionHandler(error == nil ? self.packetFlow : nil)
        }
    }

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

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
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

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {

    }

}

extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow {}
```

## Contributing
## Acknowledgments
## License
OpenVPNAdapter is available under the AGPLv3 license. See the LICENSE file for more info. Also this project has a few dependencies:
- [openvpn3](https://github.com/OpenVPN/openvpn3)
- [asio](https://github.com/chriskohlhoff/asio)
- [lz4](https://github.com/lz4/lz4)
- [mbedtls](https://github.com/ARMmbed/mbedtls)

See NOTICE file for more info about their licenses and copyrights.
