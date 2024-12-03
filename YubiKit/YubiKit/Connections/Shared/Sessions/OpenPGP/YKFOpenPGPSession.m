#import "YKFOpenPGPSession.h"
#import "../../APDU/OpenPGP/YKFOpenPGPAsn1TLV.h"
#import "../../APDU/YKFSelectApplicationAPDU.h"
#import <Foundation/Foundation.h>

@interface YKFOpenPGPSession ()

@property(nonatomic, readwrite) YKFOpenPGPLimits *limits;
@property(nonatomic, readwrite) YKFVersion *version;
@property(nonatomic, readwrite) NSString *aid;
@property(nonatomic, readwrite) NSString *serialNumber;
@property(nonatomic, readwrite) YKFOpenPGPPINFormat pinFormat;

@property(nonatomic) id<YKFConnectionControllerProtocol> connectionController;

@end

@implementation YKFOpenPGPSession

- (void)requestApplicationData {
  YKFOpenPGPApplicationRelatedDataAPDU *apdu =
      [[YKFOpenPGPApplicationRelatedDataAPDU alloc] init];

  [self execute:apdu
      completion:^(NSData *response, NSError *error) {
        if (error) {
          return;
        }

        [self parseApplicationDataResponse:response];
      }];
}

- (void)parseApplicationDataResponse:(NSData *)response {
  // Parse the application data from the response bytes.
  YKFOpenPGPBERTLV *applicationRelatedData =
      [[YKFOpenPGPBERTLV alloc] initWithData:response];

  YKFOpenPGPBERTLV *firstDO =
      [[YKFOpenPGPBERTLV alloc] initWithData:applicationRelatedData.value];
      
}

- (void)readApplicationRelatedDataWithCompletion:^(NSData *response,
                                                   NSError *error)completion {
}

- (instancetype)initWithConnectionController:
                    (id<YKFConnectionControllerProtocol>)connectionController
                                  completion:
                                      (YKFOpenPGPSessionCompletion)completion {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  self.connectionController = connectionController;

  YKFSelectApplicationAPDU *selectApplicationAPDU =
      [[YKFSelectApplicationAPDU alloc]
          initWithApplicationName:YKFSelectApplicationAPDUNameOpenPGP];

  // select the OpenPGP application
  [connectionController execute:YKFSelectApplicationAPDU
                     completion:^(NSData *response, NSError *error) {
                       if (error) {
                         return;
                       }
                     }];

  // Read application related data
  [self requestApplicationData];

  // Read card capabilities

  // Read card service data

  return nil;
}
