//
//  OpenVPNError.h
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * __nonnull const OpenVPNAdapterErrorDomain;
FOUNDATION_EXPORT NSString * __nonnull const OpenVPNIdentityErrorDomain;

FOUNDATION_EXPORT NSString * __nonnull const OpenVPNAdapterErrorFatalKey;
FOUNDATION_EXPORT NSString * __nonnull const OpenVPNAdapterErrorMessageKey;

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
