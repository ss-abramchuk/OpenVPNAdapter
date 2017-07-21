//
//  OpenVPNError.h
//  OpenVPN iOS Client
//
//  Created by Sergey Abramchuk on 11.02.17.
//
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * __nonnull const OpenVPNAdapterErrorDomain;

FOUNDATION_EXPORT NSString * __nonnull const OpenVPNAdapterErrorFatalKey;
FOUNDATION_EXPORT NSString * __nonnull const OpenVPNAdapterErrorMessageKey;

/**
 OpenVPN error codes
 */
typedef NS_ENUM(NSInteger, OpenVPNError) {
    OpenVPNErrorConfigurationFailure = 1,
    OpenVPNErrorCredentialsFailure,
    OpenVPNErrorNetworkRecvError,
    OpenVPNErrorNetworkEOFError,
    OpenVPNErrorNetworkSendError,
    OpenVPNErrorNetworkUnavailable,
    OpenVPNErrorDecryptError,
    OpenVPNErrorHMACError,
    OpenVPNErrorReplayError,
    OpenVPNErrorBufferError,
    OpenVPNErrorCCError,
    OpenVPNErrorBadSrcAddr,
    OpenVPNErrorCompressError,
    OpenVPNErrorResolveError,
    OpenVPNErrorSocketProtectError,
    OpenVPNErrorTUNReadError,
    OpenVPNErrorTUNWriteError,
    OpenVPNErrorTUNFramingError,
    OpenVPNErrorTUNSetupFailed,
    OpenVPNErrorTUNIfaceCreate,
    OpenVPNErrorTUNIfaceDisabled,
    OpenVPNErrorTUNError,
    OpenVPNErrorTAPNotSupported,
    OpenVPNErrorRerouteGatewayNoDns,
    OpenVPNErrorTransportError,
    OpenVPNErrorTCPOverflow,
    OpenVPNErrorTCPSizeError,
    OpenVPNErrorTCPConnectError,
    OpenVPNErrorUDPConnectError,
    OpenVPNErrorSSLError,
    OpenVPNErrorSSLPartialWrite,
    OpenVPNErrorEncapsulationError,
    OpenVPNErrorEPKICertError,
    OpenVPNErrorEPKISignError,
    OpenVPNErrorHandshakeTimeout,
    OpenVPNErrorKeepaliveTimeout,
    OpenVPNErrorInactiveTimeout,
    OpenVPNErrorConnectionTimeout,
    OpenVPNErrorPrimaryExpire,
    OpenVPNErrorTLSVersionMin,
    OpenVPNErrorTLSAuthFail,
    OpenVPNErrorCertVerifyFail,
    OpenVPNErrorPEMPasswordFail,
    OpenVPNErrorAuthFailed,
    OpenVPNErrorClientHalt,
    OpenVPNErrorClientRestart,
    OpenVPNErrorRelay,
    OpenVPNErrorRelayError,
    OpenVPNErrorPauseNumber,
    OpenVPNErrorReconnectNumber,
    OpenVPNErrorKeyLimitRenegNumber,
    OpenVPNErrorKeyStateError,
    OpenVPNErrorProxyError,
    OpenVPNErrorProxyNeedCreds,
    OpenVPNErrorKevNegotiateError,
    OpenVPNErrorKevPendingError,
    OpenVPNErrorKevExpireNumber,
    OpenVPNErrorPKTIDInvalid,
    OpenVPNErrorPKTIDBacktrack,
    OpenVPNErrorPKTIDExpire,
    OpenVPNErrorPKTIDReplay,
    OpenVPNErrorPKTIDTimeBacktrack,
    OpenVPNErrorDynamicChallenge,
    OpenVPNErrorEPKIError,
    OpenVPNErrorEPKIInvalidAlias,
    OpenVPNErrorUnknown
};
