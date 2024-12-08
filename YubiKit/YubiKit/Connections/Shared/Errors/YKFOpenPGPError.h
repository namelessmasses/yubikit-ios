#import <Foundation/Foundation.h>

/**
 * @enum YKFOpenPGPErrorDomain
 *
 * @brief Error domains for OpenPGP are based on the ISO7816-4 status CLA, INS,
 * P1, and P2.
 */
typedef NS_ENUM(NSUInteger, YKFOpenPGPErrorDomain) {
  YKFOpenPGPErrorDomainSelectApplication = 0x00A44000,
  YKFOpenPGPErrorDomainApplicationRelatedData = 0x00CA006E,
  YKFOpenPGPErrorDomainKDF = 0x00CA00F9,
  YKFOpenPGPErrorDomainVerifyPW1CDS = 0x00200081,
  YKFOpenPGPErrorDomainVerifyPW1Other = 0x00200082,
  YKFOpenPGPErrorDomainVerifyPW3 = 0x00200083,
  YKFOpenPGPErrorDomainImplementationSpecific = 0xfffffffff
};

/**
 * @enum YKFOpenPGPErrorCode
 *
 * @brief Error codes for OpenPGP are based on the ISO7816-4 status words, and
 * incorporates other from the implementation.
 *
 * @details Codes where bytes 1 and 2 are 0x0000 are the ISO7816-4 status words.
 * Codes where bytes 1 and 2 are non-zero are implementation specific.
 */
typedef NS_ENUM(NSUInteger, YKFOpenPGPErrorCode) {
  YKFOpenPGPErrorCodeSelectedFileInvalidated = 0x6283,
  YKFOpenPGPErrorCodeInvalidFCI = 0x6284,
  YKFOpenPGPErrorCodeNotVerified = 0x6300,
  YKFOpenPGPErrorCodeSecurityStatusNotSatisfied = 0x6982,
  YKFOpenPGPErrorCodeAuthenticationMethodBlocked = 0x6983,
  YKFOpenPGPErrorCodeInvalidData = 0x6a80,
  YKFOpenPGPErrorCodeFunctionNotSupported = 0x6a81,
  YKFOpenPGPErrorCodeFileNotFound = 0x6a82,
  YKFOpenPGPErrorCodeIncorrectParameters = 0x6a86,
  YKFOpenPGPErrorCodeInvalidLc = 0x6a87,
  YKFOpenPGPErrorCodeReferencedDataNotFound = 0x6a88,
  YKFOpenPGPErrorCodeWrongParametersP1P2 = 0x6b00,
  YKFOpenPGPErrorCodeInvalidInstruction = 0x6d00,

  YKFOpenPGPErrorCodeSessionCreation = 0x00010000,
  YKFOpenPGPErrorCodeSmartCardInterface = 0x00020000,
  YKFOpenPGPErrorCodeInvalidAID = 0x00030000,
  YKFOpenPGPErrorCodeInvalidSerialNumber = 0x00040000,
  YKFOpenPGPErrorCodeInvalidVersion = 0x00050000,
  YKFOpenPGPErrorCodeInvalidPinFormat = 0x00060000,
  YKFOpenPGPErrorCodeInvalidMaxChallengeLength = 0x00070000,
  YFKOpenPGPErrorCodeParseError = 0xfffe0000,
  YKFOpenPGPErrorCodeUnknownError = 0xffff0000
};

@interface YKFOpenPGPError : NSError

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDomain:(YKFOpenPGPErrorDomain)domain
                          code:(YKFOpenPGPErrorCode)code;

- (instancetype)initWithDomain:(YKFOpenPGPErrorDomain)domain
                          code:(YKFOpenPGPErrorCode)code
                      userInfo:(NSDictionary<NSErrorUserInfoKey, id> *)dict;

+ (instancetype)errorWithDomain:(YKFOpenPGPErrorDomain)domain
                           code:(YKFOpenPGPErrorCode)code;

+ (void)buildErrorMap;

@end
