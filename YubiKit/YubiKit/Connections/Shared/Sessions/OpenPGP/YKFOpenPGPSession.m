#import "YKFOpenPGPSession.h"
#import "../../../SmartCardInterface/YKFSmartCardInterface.h"
#import "../../APDU/OpenPGP/YKFOpenPGPAsn1TLV.h"
#import "../../APDU/OpenPGP/YKFOpenPGPHashAlgorithm.h"
#import "../../APDU/YKFSelectApplicationAPDU.h"
#import "../../YKFVersion.h"
#import <Foundation/Foundation.h>

@interface YKFOpenPGPLimits()

@property (nonatomic, readwrite) NSUInteger maxChallengeLength;

@end

static NSString *const YKFOpenPGPSessionErrorDomain =
    @"com.yubico.ykf.openpgp-session";
    
@interface YKFOpenPGPSession ()

@property(nonatomic, readwrite) YKFOpenPGPLimits *limits;
@property(nonatomic, readwrite) YKFVersion *version;
@property(nonatomic, readwrite) NSString *aid;
@property(nonatomic, readwrite) NSString *serialNumber;
@property(nonatomic, readwrite) YKFOpenPGPPINFormat pinFormat;

@property(nonatomic) id<YKFConnectionControllerProtocol> connectionController;
@property(nonatomic, readwrite) YKFSmartCardInterface *smartCardInterface;

@end

@implementation YKFOpenPGPSession

- (void)completeSelectApplicationResponse:(NSData *)response
                                    error:(NSError *)error {
  if (error) {
    // TODO log error
    return;
  }
}

+ (void)sessionWithConnectionController:
            (id<YKFConnectionControllerProtocol>)connectionController
                             completion:
                                 (YKFOpenPGPSessionCompletion)completion0 {
  YKFOpenPGPSession *session = [YKFOpenPGPSession new];

  if (session == nil) {
    completion0(nil,
                [[NSError alloc]
                    initWithDomain:YKFOpenPGPSessionErrorDomain
                              code:YKFOpenPGPSessionErrorCodeSessionCreation
                          userInfo:@{
                            NSLocalizedDescriptionKey :
                                @"Failed to create OpenPGP session."
                          }]);
    return;
  }

  session.limits = [YKFOpenPGPLimits new];

  session.smartCardInterface = [[YKFSmartCardInterface alloc]
      initWithConnectionController:connectionController];

  YKFSelectApplicationAPDU *selectApplicationAPDU =
      [[YKFSelectApplicationAPDU alloc]
          initWithApplicationName:YKFSelectApplicationAPDUNameOpenPGP];

  // select the OpenPGP application
  [connectionController execute:selectApplicationAPDU
                     completion:^(NSData *_Nullable response,
                                  NSError *_Nullable error, NSTimeInterval ti) {
                       [session completeSelectApplicationResponse:response
                                                            error:error];
                     }];

  // Read application related data

  // Read card capabilities

  // Read card service data

  completion0(session, nil);
}

- (void)verifyPW1:(NSString *)pw1
      isMultishot:(BOOL)isMultishot
       completion:(YKFOpenPGPPINVerifyCompletion)completion {
  // TODO
}

- (void)verifyPW3:(NSString *)pw3
       completion:(YKFOpenPGPPINVerifyCompletion)completion {
  // TODO
}

- (void)computeDigitalSignatureWithData:(NSData *)data
                          hashAlgorithm:(YKFOpenPGPHashAlgorithm)hashAlgorithm
                             completion:(YKFOpenPGPCDSCompletion)completion {
  // TODO
}

- (void)decipherData:(NSData *)data
          completion:(YKFOpenPGPDecipherCompletion)completion {
  // TODO
}

- (void)clearSessionState {
  // TODO
}

@end
