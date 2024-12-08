#import "YKFOpenPGPError.h"

#import <Foundation/Foundation.h>

@implementation YKFOpenPGPError

static NSDictionary<NSNumber *, NSString *> *errorDomain;
static NSDictionary<NSNumber *, NSString *> *errorCode;

- (instancetype)initWithDomain:(YKFOpenPGPErrorDomain)domain
                          code:(YKFOpenPGPErrorCode)code {
  return [self initWithDomain:domain code:code userInfo:nil];
}

- (instancetype)initWithDomain:(YKFOpenPGPErrorDomain)domain
                          code:(YKFOpenPGPErrorCode)code
                      userInfo:(NSDictionary<NSErrorUserInfoKey, id> *)dict {

  NSString *domainDescription = errorDomain[@(domain)];
  if (domainDescription == nil) {
    domainDescription = @"com.yubico.ykf.openpgp";
  }

  NSString *errorDescription = errorCode[@(code)];
  if (errorDescription == nil) {
    errorDescription = @"An unknown error occurred";
  }

  NSMutableDictionary *userInfo =
      (dict != nil) ? [NSMutableDictionary dictionaryWithDictionary:dict]
                    : [NSMutableDictionary new];
  userInfo[NSLocalizedDescriptionKey] = errorDescription;
  
  return [super initWithDomain:domainDescription
                          code:code
                      userInfo:userInfo];
}

static dispatch_once_t buildErrorMapOnceToken;

+ (instancetype)errorWithDomain:(YKFOpenPGPErrorDomain)domain
                           code:(YKFOpenPGPErrorCode)code {
  return [YKFOpenPGPError errorWithDomain:domain code:code userInfo:nil];
}

+ (instancetype)errorWithDomain:(YKFOpenPGPErrorDomain)domain
                           code:(YKFOpenPGPErrorCode)code
                       userInfo:(NSDictionary<NSErrorUserInfoKey, id> *)dict {

  dispatch_once(&buildErrorMapOnceToken, ^{
    [YKFOpenPGPError buildErrorMap];
  });

  return [[YKFOpenPGPError alloc] initWithDomain:domain
                                            code:code
                                        userInfo:dict];
}

+ (void)buildErrorMap {
  errorDomain = @{
    @(YKFOpenPGPErrorDomainSelectApplication) :
        @"com.yubico.ykf.openpgp-session.select-application",
    @(YKFOpenPGPErrorDomainApplicationRelatedData) :
        @"com.yubico.ykf.openpgp-session.application-related-data",
    @(YKFOpenPGPErrorDomainVerifyPW1CDS) :
        @"com.yubico.ykf.openpgp-session.verify.pw1.cds",
    @(YKFOpenPGPErrorDomainVerifyPW1Other) :
        @"com.yubico.ykf.openpgp-session.verify.pw1.other",
    @(YKFOpenPGPErrorDomainVerifyPW3) :
        @"com.yubico.ykf.openpgp-session.verify.pw3",
    @(YKFOpenPGPErrorDomainImplementationSpecific) :
        @"com.yubico.ykf.openpgp-session.implementation-specific"
  };

  errorCode = @{
    @(YKFOpenPGPErrorCodeSelectedFileInvalidated) : @"Selected file invalidated",
    @(YKFOpenPGPErrorCodeInvalidFCI) :
        @"FCI not formatted according to ISO 7816-4",
    @(YKFOpenPGPErrorCodeNotVerified) : @"Not verified",
    @(YKFOpenPGPErrorCodeSecurityStatusNotSatisfied) :
        @"Security status not satisfied/PW wrong/PW not checked (command not "
        @"allowed)",
    @(YKFOpenPGPErrorCodeAuthenticationMethodBlocked) :
        @"Authentication method blocked/PW blocked (error counter zero)",
    @(YKFOpenPGPErrorCodeInvalidData) :
        @"Incorrect parameter in command data field",
    @(YKFOpenPGPErrorCodeFunctionNotSupported) : @"Function not supported",
    @(YKFOpenPGPErrorCodeFileNotFound) : @"File not found",
    @(YKFOpenPGPErrorCodeIncorrectParameters) : @"Incorrect parameters P1-P2",
    @(YKFOpenPGPErrorCodeInvalidLc) : @"Lc inconsistent with P1-P2",
    @(YKFOpenPGPErrorCodeReferencedDataNotFound) : @"Referenced data not found",
    @(YKFOpenPGPErrorCodeWrongParametersP1P2) : @"Incorrect parameters P1-P2",
    @(YKFOpenPGPErrorCodeInvalidInstruction) :
        @"Instruction not supported or invalid",

    @(YKFOpenPGPErrorCodeSessionCreation) : @"Failed to create OpenPGP session",
    @(YKFOpenPGPErrorCodeSmartCardInterface) :
        @"Failed to create SmartCardInterface",
    @(YKFOpenPGPErrorCodeInvalidAID) : @"Failed parsing AID",
    @(YKFOpenPGPErrorCodeInvalidSerialNumber) : @"Failed parsing serial number",
    @(YKFOpenPGPErrorCodeInvalidVersion) : @"Failed parsing version",
    @(YKFOpenPGPErrorCodeInvalidPinFormat) : @"Failed parsing PIN format",
    @(YKFOpenPGPErrorCodeInvalidMaxChallengeLength) :
        @"Failed parsing maximum challenge length",
    @(YKFOpenPGPErrorCodeUnknownError) : @"An unknown error occurred",
  };
}

@end
