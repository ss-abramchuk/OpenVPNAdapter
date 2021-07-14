# Changelog

## 0.8.0
- **Added**: Configuration properties to override tls-cipher and tls-ciphersuites.
- **Updated**: openvpn3 library to 3.6.1 version, ASIO library to 1.16.1 version.
- **Fixed**: Broken support ot the SPM.

## 0.7.0
- **Added**: An option to evaluate configuration without creating an instance of `OpenVPNAdapter`.
- **Updated**: Class `OpenVPNProperties` renamed to `OpenVPNConfigurationEvaluation`.
- **Updated**: openvpn3 library to 3.5.6 version, mbedTLS library to 2.7.13 version.

## 0.6.0
- **Updated**: Slightly changed API of the framework.
- **Fixed**: Reading packets issue affecting connection when network interface is changed.

## 0.5.0
- **Added**: Swift Package Manager support.
- **Updated**: openvpn3 library to 3.5.4 version.
- **Fixed**: Network issue when adapter used in macOS projects.
