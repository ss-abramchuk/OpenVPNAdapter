//
//  NSError+OpenVPNError.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 17.01.2018.
//

#import "NSError+OpenVPNError.h"

#import <mbedtls/error.h>

#import "OpenVPNError.h"

@implementation NSError (OpenVPNAdapterErrorGeneration)

+ (NSError *)ovpn_errorObjectForAdapterError:(OpenVPNAdapterError)adapterError
                                 description:(NSString *)description
                                     message:(NSString *)message
                                       fatal:(BOOL)fatal
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:@{
        NSLocalizedDescriptionKey: description,
        OpenVPNAdapterErrorFatalKey: @(fatal)
    }];
    
    NSString *errorReason = [NSError ovpn_reasonForAdapterError:adapterError];
    if (errorReason) {
        userInfo[NSLocalizedFailureReasonErrorKey] = errorReason;
    }
    
    if (message.length) {
        userInfo[OpenVPNAdapterErrorMessageKey] = message;
    }
    
    return [NSError errorWithDomain:OpenVPNAdapterErrorDomain code:adapterError userInfo:userInfo];
}

+ (OpenVPNAdapterError)ovpn_adapterErrorByName:(NSString *)errorName {
    NSDictionary *errors = @{
        @"NETWORK_RECV_ERROR": @(OpenVPNAdapterErrorNetworkRecvError),
        @"NETWORK_EOF_ERROR": @(OpenVPNAdapterErrorNetworkEOFError),
        @"NETWORK_SEND_ERROR": @(OpenVPNAdapterErrorNetworkSendError),
        @"NETWORK_UNAVAILABLE": @(OpenVPNAdapterErrorNetworkUnavailable),
        @"DECRYPT_ERROR": @(OpenVPNAdapterErrorDecryptError),
        @"HMAC_ERROR": @(OpenVPNAdapterErrorDecryptError),
        @"REPLAY_ERROR": @(OpenVPNAdapterErrorReplayError),
        @"BUFFER_ERROR": @(OpenVPNAdapterErrorBufferError),
        @"CC_ERROR": @(OpenVPNAdapterErrorCCError),
        @"BAD_SRC_ADDR": @(OpenVPNAdapterErrorBadSrcAddr),
        @"COMPRESS_ERROR": @(OpenVPNAdapterErrorCompressError),
        @"RESOLVE_ERROR": @(OpenVPNAdapterErrorResolveError),
        @"SOCKET_PROTECT_ERROR": @(OpenVPNAdapterErrorSocketProtectError),
        @"TUN_READ_ERROR": @(OpenVPNAdapterErrorTUNReadError),
        @"TUN_WRITE_ERROR": @(OpenVPNAdapterErrorTUNWriteError),
        @"TUN_FRAMING_ERROR": @(OpenVPNAdapterErrorTUNFramingError),
        @"TUN_SETUP_FAILED": @(OpenVPNAdapterErrorTUNSetupFailed),
        @"TUN_IFACE_CREATE": @(OpenVPNAdapterErrorTUNIfaceCreate),
        @"TUN_IFACE_DISABLED": @(OpenVPNAdapterErrorTUNIfaceDisabled),
        @"TUN_ERROR": @(OpenVPNAdapterErrorTUNError),
        @"TUN_REGISTER_RINGS_ERROR": @(OpenVPNAdapterErrorTUNRegisterRingsError),
        @"TAP_NOT_SUPPORTED": @(OpenVPNAdapterErrorTAPNotSupported),
        @"REROUTE_GW_NO_DNS": @(OpenVPNAdapterErrorRerouteGatewayNoDns),
        @"TRANSPORT_ERROR": @(OpenVPNAdapterErrorTransportError),
        @"TCP_OVERFLOW": @(OpenVPNAdapterErrorTCPOverflow),
        @"TCP_SIZE_ERROR": @(OpenVPNAdapterErrorTCPSizeError),
        @"TCP_CONNECT_ERROR": @(OpenVPNAdapterErrorTCPConnectError),
        @"UDP_CONNECT_ERROR": @(OpenVPNAdapterErrorUDPConnectError),
        @"SSL_ERROR": @(OpenVPNAdapterErrorSSLError),
        @"SSL_PARTIAL_WRITE": @(OpenVPNAdapterErrorSSLPartialWrite),
        @"SSL_CA_MD_TOO_WEAK": @(OpenVPNAdapterErrorSSLCaMdTooWeak),
        @"SSL_CA_KEY_TOO_SMALL": @(OpenVPNAdapterErrorSSLCaKeyTooSmall),
        @"SSL_DH_KEY_TOO_SMALL": @(OpenVPNAdapterErrorSSLDhKeyTooSmall),
        @"ENCAPSULATION_ERROR": @(OpenVPNAdapterErrorEncapsulationError),
        @"EPKI_CERT_ERROR": @(OpenVPNAdapterErrorEPKICertError),
        @"EPKI_SIGN_ERROR": @(OpenVPNAdapterErrorEPKISignError),
        @"HANDSHAKE_TIMEOUT": @(OpenVPNAdapterErrorHandshakeTimeout),
        @"KEEPALIVE_TIMEOUT": @(OpenVPNAdapterErrorKeepaliveTimeout),
        @"INACTIVE_TIMEOUT": @(OpenVPNAdapterErrorInactiveTimeout),
        @"CONNECTION_TIMEOUT": @(OpenVPNAdapterErrorConnectionTimeout),
        @"PRIMARY_EXPIRE": @(OpenVPNAdapterErrorPrimaryExpire),
        @"TLS_VERSION_MIN": @(OpenVPNAdapterErrorTLSVersionMin),
        @"TLS_AUTH_FAIL": @(OpenVPNAdapterErrorTLSAuthFail),
        @"TLS_CRYPT_META_FAIL": @(OpenVPNAdapterErrorTLSCryptMetaFail),
        @"CERT_VERIFY_FAIL": @(OpenVPNAdapterErrorCertVerifyFail),
        @"PEM_PASSWORD_FAIL": @(OpenVPNAdapterErrorPEMPasswordFail),
        @"AUTH_FAILED": @(OpenVPNAdapterErrorAuthFailed),
        @"CLIENT_HALT": @(OpenVPNAdapterErrorClientHalt),
        @"CLIENT_RESTART": @(OpenVPNAdapterErrorClientRestart),
        @"TUN_HALT": @(OpenVPNAdapterErrorTUNHalt),
        @"RELAY": @(OpenVPNAdapterErrorRelay),
        @"RELAY_ERROR": @(OpenVPNAdapterErrorRelayError),
        @"N_PAUSE": @(OpenVPNAdapterErrorPauseNumber),
        @"N_RECONNECT": @(OpenVPNAdapterErrorReconnectNumber),
        @"N_KEY_LIMIT_RENEG": @(OpenVPNAdapterErrorKeyLimitRenegNumber),
        @"KEY_STATE_ERROR": @(OpenVPNAdapterErrorKeyStateError),
        @"PROXY_ERROR": @(OpenVPNAdapterErrorProxyError),
        @"PROXY_NEED_CREDS": @(OpenVPNAdapterErrorProxyNeedCreds),
        @"KEV_NEGOTIATE_ERROR": @(OpenVPNAdapterErrorKevNegotiateError),
        @"KEV_PENDING_ERROR": @(OpenVPNAdapterErrorKevPendingError),
        @"N_KEV_EXPIRE": @(OpenVPNAdapterErrorKevExpireNumber),
        @"PKTID_INVALID": @(OpenVPNAdapterErrorPKTIDInvalid),
        @"PKTID_BACKTRACK": @(OpenVPNAdapterErrorPKTIDBacktrack),
        @"PKTID_EXPIRE": @(OpenVPNAdapterErrorPKTIDExpire),
        @"PKTID_REPLAY": @(OpenVPNAdapterErrorPKTIDReplay),
        @"PKTID_TIME_BACKTRACK": @(OpenVPNAdapterErrorPKTIDTimeBacktrack),
        @"DYNAMIC_CHALLENGE": @(OpenVPNAdapterErrorDynamicChallenge),
        @"EPKI_ERROR": @(OpenVPNAdapterErrorEPKIError),
        @"EPKI_INVALID_ALIAS": @(OpenVPNAdapterErrorEPKIInvalidAlias)
    };
    
    OpenVPNAdapterError error = errors[errorName] != nil ?
        (OpenVPNAdapterError)[errors[errorName] integerValue] : OpenVPNAdapterErrorUnknown;
    
    return error;
}

+ (NSString *)ovpn_reasonForAdapterError:(OpenVPNAdapterError)error {
    switch (error) {
        case OpenVPNAdapterErrorConfigurationFailure: return @"See OpenVPN error message for more details.";
        case OpenVPNAdapterErrorCredentialsFailure: return @"See OpenVPN error message for more details.";
        case OpenVPNAdapterErrorNetworkRecvError: return @"Errors receiving on network socket.";
        case OpenVPNAdapterErrorNetworkEOFError: return @"EOF received on TCP network socket.";
        case OpenVPNAdapterErrorNetworkSendError: return @"Errors sending on network socket";
        case OpenVPNAdapterErrorNetworkUnavailable: return @"Network unavailable.";
        case OpenVPNAdapterErrorDecryptError: return @"Data channel encrypt/decrypt error.";
        case OpenVPNAdapterErrorHMACError: return @"HMAC verification failure.";
        case OpenVPNAdapterErrorReplayError: return @"Error from PacketIDReceive.";
        case OpenVPNAdapterErrorBufferError: return @"Exception thrown in Buffer methods.";
        case OpenVPNAdapterErrorCCError: return @"General control channel errors.";
        case OpenVPNAdapterErrorBadSrcAddr: return @"Packet from unknown source address.";
        case OpenVPNAdapterErrorCompressError: return @"Compress/Decompress errors on data channel.";
        case OpenVPNAdapterErrorResolveError: return @"DNS resolution error.";
        case OpenVPNAdapterErrorSocketSetupFailed: return nil;
        case OpenVPNAdapterErrorSocketProtectError: return @"Error calling protect() method on socket.";
        case OpenVPNAdapterErrorTUNReadError: return @"Read errors on TUN/TAP interface.";
        case OpenVPNAdapterErrorTUNWriteError: return @"Write errors on TUN/TAP interface.";
        case OpenVPNAdapterErrorTUNFramingError: return @"Error with tun PF_INET/PF_INET6 prefix.";
        case OpenVPNAdapterErrorTUNSetupFailed: return @"Error setting up TUN/TAP interface.";
        case OpenVPNAdapterErrorTUNIfaceCreate: return @"Error creating TUN/TAP interface.";
        case OpenVPNAdapterErrorTUNIfaceDisabled: return @"TUN/TAP interface is disabled.";
        case OpenVPNAdapterErrorTUNError: return @"General tun error.";
        case OpenVPNAdapterErrorTUNRegisterRingsError: return @"Error registering ring buffers with wintun.";
        case OpenVPNAdapterErrorTAPNotSupported: return @"Dev TAP is present in profile but not supported.";
        case OpenVPNAdapterErrorRerouteGatewayNoDns: return @"redirect-gateway specified without alt DNS servers.";
        case OpenVPNAdapterErrorTransportError: return @"General transport error";
        case OpenVPNAdapterErrorTCPOverflow: return @"TCP output queue overflow.";
        case OpenVPNAdapterErrorTCPSizeError: return @"Bad embedded uint16_t TCP packet size.";
        case OpenVPNAdapterErrorTCPConnectError: return @"Client error on TCP connect.";
        case OpenVPNAdapterErrorUDPConnectError: return @"Client error on UDP connect.";
        case OpenVPNAdapterErrorSSLError: return @"Errors resulting from read/write on SSL object.";
        case OpenVPNAdapterErrorSSLPartialWrite: return @"SSL object did not process all written cleartext.";
        case OpenVPNAdapterErrorSSLCaMdTooWeak: return @"CA message digest is too weak";
        case OpenVPNAdapterErrorSSLCaKeyTooSmall: return @"CA key is too small";
        case OpenVPNAdapterErrorSSLDhKeyTooSmall: return @"DH key is too small";
        case OpenVPNAdapterErrorEncapsulationError: return @"Exceptions thrown during packet encapsulation.";
        case OpenVPNAdapterErrorEPKICertError: return @"Error obtaining certificate from External PKI provider.";
        case OpenVPNAdapterErrorEPKISignError: return @"Error obtaining RSA signature from External PKI provider.";
        case OpenVPNAdapterErrorHandshakeTimeout: return @"Handshake failed to complete within given time frame.";
        case OpenVPNAdapterErrorKeepaliveTimeout: return @"Lost contact with peer.";
        case OpenVPNAdapterErrorInactiveTimeout: return @"Disconnected due to inactive timer.";
        case OpenVPNAdapterErrorConnectionTimeout: return @"Connection failed to establish within given time.";
        case OpenVPNAdapterErrorPrimaryExpire: return @"Primary key context expired.";
        case OpenVPNAdapterErrorTLSVersionMin: return @"Peer cannot handshake at our minimum required TLS version.";
        case OpenVPNAdapterErrorTLSAuthFail: return @"tls-auth HMAC verification failed.";
        case OpenVPNAdapterErrorTLSCryptMetaFail: return @"tls-crypt-v2 metadata verification failed.";
        case OpenVPNAdapterErrorCertVerifyFail: return @"Peer certificate verification failure.";
        case OpenVPNAdapterErrorPEMPasswordFail: return @"Incorrect or missing PEM private key decryption password.";
        case OpenVPNAdapterErrorAuthFailed: return @"General authentication failure";
        case OpenVPNAdapterErrorClientHalt: return @"HALT message from server received.";
        case OpenVPNAdapterErrorClientRestart: return @"RESTART message from server received.";
        case OpenVPNAdapterErrorTUNHalt: return @"Halt command from tun interface";
        case OpenVPNAdapterErrorRelay: return @"RELAY message from server received.";
        case OpenVPNAdapterErrorRelayError: return @"RELAY error.";
        case OpenVPNAdapterErrorPauseNumber: return nil;
        case OpenVPNAdapterErrorReconnectNumber: return nil;
        case OpenVPNAdapterErrorKeyLimitRenegNumber: return nil;
        case OpenVPNAdapterErrorKeyStateError: return @"Received packet didn't match expected key state.";
        case OpenVPNAdapterErrorProxyError: return @"HTTP proxy error.";
        case OpenVPNAdapterErrorProxyNeedCreds: return @"HTTP proxy needs credentials.";
        case OpenVPNAdapterErrorKevNegotiateError: return nil;
        case OpenVPNAdapterErrorKevPendingError: return nil;
        case OpenVPNAdapterErrorKevExpireNumber: return nil;
        case OpenVPNAdapterErrorPKTIDInvalid: return nil;
        case OpenVPNAdapterErrorPKTIDBacktrack: return nil;
        case OpenVPNAdapterErrorPKTIDExpire: return nil;
        case OpenVPNAdapterErrorPKTIDReplay: return nil;
        case OpenVPNAdapterErrorPKTIDTimeBacktrack: return nil;
        case OpenVPNAdapterErrorDynamicChallenge: return nil;
        case OpenVPNAdapterErrorEPKIError: return nil;
        case OpenVPNAdapterErrorEPKIInvalidAlias: return nil;
        case OpenVPNAdapterErrorUnknown: return @"Unknown error.";
    }
}

@end

@implementation NSError (OpenVPNMbedTLSErrorGeneration)

+ (NSError *)ovpn_errorObjectForMbedTLSError:(NSInteger)errorCode description:(NSString *)description {
    size_t length = 1024;
    char *buffer = malloc(length);
    
    mbedtls_strerror(errorCode, buffer, length);
    
    NSString *reason = [NSString stringWithUTF8String:buffer];
    
    free(buffer);
    
    return [NSError errorWithDomain:OpenVPNIdentityErrorDomain code:errorCode userInfo:@{
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: reason
    }];
}

@end
