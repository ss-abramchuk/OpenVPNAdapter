//
//  OpenVPNError.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const OpenVPNAdapterErrorDomain;
FOUNDATION_EXPORT NSString *const OpenVPNIdentityErrorDomain;

FOUNDATION_EXPORT NSString *const OpenVPNAdapterErrorFatalKey;
FOUNDATION_EXPORT NSString *const OpenVPNAdapterErrorMessageKey;

NS_ASSUME_NONNULL_END

/**
 OpenVPN error codes
 */
typedef NS_ERROR_ENUM(OpenVPNAdapterErrorDomain, OpenVPNAdapterError) {
    OpenVPNAdapterErrorConfigurationFailure = 1,
    OpenVPNAdapterErrorCredentialsFailure,
    OpenVPNAdapterErrorNetworkRecvError,
    OpenVPNAdapterErrorNetworkEOFError,
    OpenVPNAdapterErrorNetworkSendError,
    OpenVPNAdapterErrorNetworkUnavailable,
    OpenVPNAdapterErrorDecryptError,
    OpenVPNAdapterErrorHMACError,
    OpenVPNAdapterErrorReplayError,
    OpenVPNAdapterErrorBufferError,
    OpenVPNAdapterErrorCCError,
    OpenVPNAdapterErrorBadSrcAddr,
    OpenVPNAdapterErrorCompressError,
    OpenVPNAdapterErrorResolveError,
    OpenVPNAdapterErrorSocketSetupFailed,
    OpenVPNAdapterErrorSocketProtectError,
    OpenVPNAdapterErrorTUNReadError,
    OpenVPNAdapterErrorTUNWriteError,
    OpenVPNAdapterErrorTUNFramingError,
    OpenVPNAdapterErrorTUNSetupFailed,
    OpenVPNAdapterErrorTUNIfaceCreate,
    OpenVPNAdapterErrorTUNIfaceDisabled,
    OpenVPNAdapterErrorTUNError,
    OpenVPNAdapterErrorTAPNotSupported,
    OpenVPNAdapterErrorRerouteGatewayNoDns,
    OpenVPNAdapterErrorTransportError,
    OpenVPNAdapterErrorTCPOverflow,
    OpenVPNAdapterErrorTCPSizeError,
    OpenVPNAdapterErrorTCPConnectError,
    OpenVPNAdapterErrorUDPConnectError,
    OpenVPNAdapterErrorSSLError,
    OpenVPNAdapterErrorSSLPartialWrite,
    OpenVPNAdapterErrorEncapsulationError,
    OpenVPNAdapterErrorEPKICertError,
    OpenVPNAdapterErrorEPKISignError,
    OpenVPNAdapterErrorHandshakeTimeout,
    OpenVPNAdapterErrorKeepaliveTimeout,
    OpenVPNAdapterErrorInactiveTimeout,
    OpenVPNAdapterErrorConnectionTimeout,
    OpenVPNAdapterErrorPrimaryExpire,
    OpenVPNAdapterErrorTLSVersionMin,
    OpenVPNAdapterErrorTLSAuthFail,
    OpenVPNAdapterErrorCertVerifyFail,
    OpenVPNAdapterErrorPEMPasswordFail,
    OpenVPNAdapterErrorAuthFailed,
    OpenVPNAdapterErrorClientHalt,
    OpenVPNAdapterErrorClientRestart,
    OpenVPNAdapterErrorRelay,
    OpenVPNAdapterErrorRelayError,
    OpenVPNAdapterErrorPauseNumber,
    OpenVPNAdapterErrorReconnectNumber,
    OpenVPNAdapterErrorKeyLimitRenegNumber,
    OpenVPNAdapterErrorKeyStateError,
    OpenVPNAdapterErrorProxyError,
    OpenVPNAdapterErrorProxyNeedCreds,
    OpenVPNAdapterErrorKevNegotiateError,
    OpenVPNAdapterErrorKevPendingError,
    OpenVPNAdapterErrorKevExpireNumber,
    OpenVPNAdapterErrorPKTIDInvalid,
    OpenVPNAdapterErrorPKTIDBacktrack,
    OpenVPNAdapterErrorPKTIDExpire,
    OpenVPNAdapterErrorPKTIDReplay,
    OpenVPNAdapterErrorPKTIDTimeBacktrack,
    OpenVPNAdapterErrorDynamicChallenge,
    OpenVPNAdapterErrorEPKIError,
    OpenVPNAdapterErrorEPKIInvalidAlias,
    OpenVPNAdapterErrorUnknown
};
