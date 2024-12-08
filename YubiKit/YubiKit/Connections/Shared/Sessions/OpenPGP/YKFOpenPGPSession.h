#import "../../APDU/OpenPGP/YKFOpenPGPHashAlgorithm.h"
#import "../../YKFConnectionControllerProtocol.h"
#import "../../YKFVersion.h"
#import "../YKFSessionProtocol+Private.h"

#import <Foundation/Foundation.h>

@class YKFSmartCardInterface;

NS_ASSUME_NONNULL_BEGIN

@interface YKFOpenPGPLimits : NSObject

@property(nonatomic, readonly) NSUInteger maxChallengeLength;

@end

/**
 * @interface YKFOpenPGPSession
 * @brief A session class for handling OpenPGP operations.
 *
 * This class conforms to the YKFVersionProtocol and YKFSessionProtocol
 * protocols.
 */

@interface YKFOpenPGPSession : NSObject <YKFVersionProtocol, YKFSessionProtocol>

/**
 * @enum YKFOpenPGPPINFormat
 * @brief Enumeration for the format of the OpenPGP PIN.
 *
 * This enumeration defines the possible formats for the OpenPGP PIN used on the
 * Yubikey.
 *
 * @constant YKFOpenPGPPINFormatUTF8 The PIN is in _plain_ UTF8 format.
 *
 * @constant YKFOpenPGPPINFormatKDF The PIN is in the _"OpenPGP Key derived
 * format" adhering to
 * https://www.rfc-editor.org/rfc/rfc9580#name-string-to-key-s2k-specifier
 *
 * @constant YKFOpenPGPPINFormatPINBlockFormat2 The PIN is in the _"PIN block
 * 2"_ format. See the OpenPGP card specification 3.4.1 section 7.2.2.
 */
typedef NS_ENUM(NSUInteger, YKFOpenPGPPINFormat) {
  YKFOpenPGPPINFormatUTF8,
  YKFOpenPGPPINFormatKDF,
  YKFOpenPGPPINFormatPINBlockFormat2
} NS_SWIFT_NAME(YKFOpenPGPSession.YKFOpenPGPPINFormat);

@property(nonatomic, readonly) YKFOpenPGPLimits *limits;

@property(nonatomic, readonly) YKFVersion *version;

@property(nonatomic, readonly) NSString *aid;

@property(nonatomic, readonly) NSString *serialNumber;

@property(nonatomic, readonly) YKFOpenPGPPINFormat pinFormat;

@property(nonatomic, readonly) YKFSmartCardInterface *smartCardInterface;

- (instancetype)init NS_UNAVAILABLE;

typedef void (^YKFOpenPGPSessionCompletion)(
    YKFOpenPGPSession *_Nullable session, NSError *_Nullable error);

/**
 * @brief Initialize the session with the connection controller for sending
 * APDUs.
 */
+ (void)sessionWithConnectionController:
            (nonnull id<YKFConnectionControllerProtocol>)connectionController
                             completion:(YKFOpenPGPSessionCompletion _Nonnull)
                                            completion;

- (instancetype)init NS_UNAVAILABLE;

typedef void (^YKFOpenPGPPINVerifyCompletion)(NSError *_Nullable error);

- (void)verifyPW1:(NSString *)pw1
      isMultishot:(BOOL)isMultishot
       completion:(YKFOpenPGPPINVerifyCompletion)completion;

- (void)verifyPW3:(NSString *)pw3
       completion:(YKFOpenPGPPINVerifyCompletion)completion;

typedef void (^YKFOpenPGPCDSCompletion)(NSData *_Nullable data,
                                        NSError *_Nullable error);

- (void)computeDigitalSignatureWithData:(NSData *)data
                          hashAlgorithm:(YKFOpenPGPHashAlgorithm)hashAlgorithm
                             completion:(YKFOpenPGPCDSCompletion)completion;

typedef void (^YKFOpenPGPDecipherCompletion)(NSData *_Nullable data,
                                             NSError *_Nullable error);

- (void)decipherData:(NSData *)data
          completion:(YKFOpenPGPDecipherCompletion)completion;

@end

NS_ASSUME_NONNULL_END
