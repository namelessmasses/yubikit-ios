#import "../../APDU/YKFOpenPGPHashAlgorithm.h"
#import "../../YKFVersion.h"
#import "../../YKFConnectionControllerProtocol.h"

@interface YKFOpenPGPLimits

@property(nonatomic, readonly) NSUInteger maxChallengeLength;

@end

@interface YKFOpenPGPSession : NSObject

typedef NS_ENUM(NSUInteger, YKFOpenPGPPINFormat) {
  YKFOpenPGPPINFormatUTF8,
  YKFOpenPGPPINFormatKDF,
  YKFOpenPGPPINFormatPINBlockFormat2
} NS_SWIFT_NAME(YKFOpenPGPSession.YKFOpenPGPPINFormat);

typedef NS_ENUM(NSUInteger, YKFOpenPGPPINSelector) {
  YKFOpenPGPPW1,
  YKFOpenPGPPW3,
  YKFOpenPGPPW1ResetCode,
} NS_SWIFT_NAME(YKFOpenPGPSession.YKFOpenPGPPINSelector);

@property(nonatomic, readonly) YKFOpenPGPLimits *limits;

@property(nonatomic, readonly) YKFVersion *version;

@property(nonatomic, readonly) NSString *aid;

@property(nonatomic, readonly) NSString *serialNumber;

@property(nonatomic, readonly) YKFOpenPGPPINFormat pinFormat;

typedef void (^YKFOpenPGPSessionCompletion)(
    YKFOpenPGPSession *_Nullable session, NSError *_Nullable error);

/**
 * @brief Initialize the session with the connection controller for sending
 * APDUs.
 */
- (instancetype)
    initWithConnectionController:
        (nonnull id<YKFConnectionControllerProtocol>)connectionController
                      completion:
                          (YKFOpenPGPSessionCompletion _Nonnull)completion;

- (instancetype)init NS_UNAVAILABLE;

typedef void (^YKFOpenPGPPINVerifyCompletion)(NSError *_Nullable error);

- (void)verifyPW1:(NSString *)pw1
      isMultishot:(BOOL)isMultishot
       completion:(YKFOpenPGPPINVerifyCompletion)completion;

- (void)verifyPW3:(NSString *)pw3 completion:(YKFPINVerifyCompletion)completion;

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