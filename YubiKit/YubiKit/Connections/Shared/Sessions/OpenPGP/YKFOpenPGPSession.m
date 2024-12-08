#import "YKFOpenPGPSession.h"
#import "../../../SmartCardInterface/YKFSmartCardInterface.h"
#import "../../APDU/OpenPGP/YKFOpenPGPAsn1TLV.h"
#import "../../APDU/OpenPGP/YKFOpenPGPGetDataAPDU.h"
#import "../../APDU/OpenPGP/YKFOpenPGPHashAlgorithm.h"
#import "../../APDU/YKFSelectApplicationAPDU.h"
#import "../../Errors/YKFOpenPGPError.h"
#import "../../YKFVersion.h"
#import <Foundation/Foundation.h>

/**
 *
 */
typedef struct __attribute__((packed)) {
  UInt8 SecureMessagingSupported : 1;
  UInt8 GetChallengeSupported : 1;
  UInt8 KeyImportSupported : 1;
  UInt8 PWStatusChangeable : 1;
  UInt8 PrivateDOsSupported : 1;
  UInt8 AlgorithmAttributesChangeable : 1;
  UInt8 PSO_ENC_DEC_WithAES : 1;
  UInt8 KDF_DO_Available : 1;
  UInt8 SecureMessagingAlgorithm;
  UInt16 GetChallengeMaxLength;
  UInt16 CardholderCertificateMaxLength;
  UInt16 SpecialDOsMaxLength;
  UInt8 PinBlock2FormatSupported;
  UInt8 MSESupported;
} YKFOpenPGPExtendedCapabilities;

@interface YKFOpenPGPLimits ()

@property(nonatomic, readwrite) NSUInteger maxChallengeLength;

@end

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

/**
 * The KDF-DO does not return with the tag=F9,length=xx,value=xx.
 * The KDF-DO returns starting with the first field.
 */
- (void)completeKDFResponse:(NSData *)encodedBytes
                 completion:(YKFOpenPGPSessionCompletion)completion {

  YKFOpenPGPBERTLV *kdfField = [YKFOpenPGPBERTLV withEncodedBytes:encodedBytes];
  if (kdfField == nil) {
    completion(nil,
               [YKFOpenPGPError errorWithDomain:YKFOpenPGPErrorDomainKDF
                                           code:YFKOpenPGPErrorCodeParseError
                                       userInfo:@{
                                         @"rawData" : encodedBytes,
                                         @"message" : @"Invalid KDF-DO"
                                       }]);
    return;
  }

  if (kdfField.length.integerValue == 0) {
    self.pinFormat = YKFOpenPGPPINFormatUTF8;
    return;
  }

  UInt8 const *valueBytes = (UInt8 *)kdfField.value.bytes;

  switch (kdfField.tag.tagNumber) {
  case 1:
    if (kdfField.value.length != 1) {
      completion(
          nil, [YKFOpenPGPError
                   errorWithDomain:YKFOpenPGPErrorDomainKDF
                              code:YFKOpenPGPErrorCodeParseError
                          userInfo:@{
                            @"rawData" : kdfField.value,
                            @"field" : kdfField,
                            @"message" : [NSString
                                stringWithFormat:@"Expected length 1, got %lu",
                                                 kdfField.value.length]
                          }]);
    }

    if (valueBytes[0] == 0x00) {
      self.pinFormat = YKFOpenPGPPINFormatUTF8;
    } else if (valueBytes[0] == 0x03) {
      self.pinFormat = YKFOpenPGPPINFormatKDF;
    } else {
      completion(nil, [YKFOpenPGPError
                          errorWithDomain:YKFOpenPGPErrorDomainKDF
                                     code:YFKOpenPGPErrorCodeParseError
                                 userInfo:@{
                                   @"rawData" : kdfField.value,
                                   @"field" : kdfField,
                                   @"message" : [NSString
                                       stringWithFormat:
                                           @"Expected 0x00 or 0x03, got 0x%02x",
                                           valueBytes[0]]
                                 }]);
    }
    break;

  case 2:
    // TODO: Implement KDF hash algorithm type - 1 byte
    break;

  case 3:
    // TODO: Implement KDF iteration count - 4 bytes big-endian
    break;

  case 4:
    // TODO: LV Salt - PW1
    break;

  case 5:
    // TODO: LV Salt - Resetting code (PW1)
    break;

  case 6:
    // TODO: LV Salt - PW3
    break;

  case 7:
    // TODO: LV initial password hash - PW1
    break;

  case 8:
    // TODO: LV initial password hash - PW3
    break;

  default:
    completion(nil, [YKFOpenPGPError
                        errorWithDomain:YKFOpenPGPErrorDomainKDF
                                   code:YFKOpenPGPErrorCodeParseError
                               userInfo:@{
                                 @"rawData" : kdfField.value,
                                 @"field" : kdfField,
                                 @"message" : [NSString
                                     stringWithFormat:@"Unknown tag %@",
                                                      kdfField.tag.description]
                               }]);
    break;
  }
}

- (void)completeSelectApplicationResponse:(NSData *)response
                               completion:
                                   (YKFOpenPGPSessionCompletion)completion {

  YKFOpenPGPBERTLV *applicationRelatedData =
      [YKFOpenPGPBERTLV withEncodedBytes:response];
  if (applicationRelatedData == nil) {
    completion(nil, [YKFOpenPGPError
                        errorWithDomain:YKFOpenPGPErrorDomainSelectApplication
                                   code:YFKOpenPGPErrorCodeParseError
                               userInfo:@{@"rawData" : response}]);
    return;
  }

  NSData *nextDO = applicationRelatedData.value;
  while (nextDO != nil) {
    YKFOpenPGPBERTLV *doTLV = [YKFOpenPGPBERTLV withEncodedBytes:nextDO];
    if (doTLV == nil) {
      completion(nil, [YKFOpenPGPError
                          errorWithDomain:YKFOpenPGPErrorDomainSelectApplication
                                     code:YFKOpenPGPErrorCodeParseError
                                 userInfo:@{@"rawData" : nextDO}]);
      return;
    }

    UInt8 const *valueBytes = (UInt8 *)doTLV.value.bytes;

    switch (doTLV.tag.decodedTag) {
    case YKFOpenPGPTagApplicationIdentifier:
      self.aid = [[NSString alloc] initWithBytes:doTLV.value.bytes
                                          length:doTLV.value.length
                                        encoding:NSUTF8StringEncoding];

      self.version = [[YKFVersion alloc] initWithBytes:valueBytes[6]
                                                 minor:valueBytes[7]
                                                 micro:0];

      // serialNumber is the bytes 10-13 of the AID interpreted as directly
      // encoded so the bytes 12 34 56 78 are the serial number "12345678".
      self.serialNumber = [NSString
          stringWithFormat:@"%02x%02x%02x%02x", valueBytes[10], valueBytes[11],
                           valueBytes[12], valueBytes[13]];
      break;

    case YKFOpenPGPTagDiscretionaryDataObjects:
      nextDO = doTLV.value;
      break;

    case YKFOpenPGPTagExtendedCapabilities: {
      YKFOpenPGPExtendedCapabilities *extendedCapabilities =
          (YKFOpenPGPExtendedCapabilities *)doTLV.value.bytes;
      self.limits = [YKFOpenPGPLimits new];
      self.limits.maxChallengeLength =
          extendedCapabilities->GetChallengeMaxLength;

      if (extendedCapabilities->KDF_DO_Available) {
        YKFOpenPGPBERTLVTag *tag = [[YKFOpenPGPBERTLVTag alloc]
            initWithEncodedBytes:[NSData
                                     dataWithBytes:(UInt8[]){
                                                       (UInt8)YKFOpenPGPTagKDF}
                                            length:1]];

        YKFOpenPGPGetDataAPDU *getDataAPDU =
            [[YKFOpenPGPGetDataAPDU alloc] initWithTag:tag];

        [self.smartCardInterface
            executeCommand:getDataAPDU
                completion:^(NSData *_Nullable response,
                             NSError *_Nullable error) {
                  if (error) {
                    completion(nil, [YKFOpenPGPError
                                        errorWithDomain:YKFOpenPGPErrorDomainKDF
                                                   code:error.code]);
                    return;
                  }

                  [self completeKDFResponse:response completion:completion];
                }];
      } else {
        self.pinFormat = YKFOpenPGPPINFormatUTF8;
      }
      break;
    }
    default:
      // Skip other tags
      break;
    }

    nextDO = [nextDO subdataWithRange:NSMakeRange(doTLV.length.integerValue,
                                                  nextDO.length)];
  }
}

+ (void)sessionWithConnectionController:
            (id<YKFConnectionControllerProtocol>)connectionController
                             completion:
                                 (YKFOpenPGPSessionCompletion)completion0 {
  YKFOpenPGPSession *session = [YKFOpenPGPSession new];

  if (session == nil) {
    completion0(nil,
                [YKFOpenPGPError
                    errorWithDomain:YKFOpenPGPErrorDomainImplementationSpecific
                               code:YKFOpenPGPErrorCodeSessionCreation]);
    return;
  }

  session.smartCardInterface = [[YKFSmartCardInterface alloc]
      initWithConnectionController:connectionController];
  if (session.smartCardInterface == nil) {
    completion0(nil,
                [YKFOpenPGPError
                    errorWithDomain:YKFOpenPGPErrorDomainImplementationSpecific
                               code:YKFOpenPGPErrorCodeSmartCardInterface]);
    return;
  }

  YKFSelectApplicationAPDU *selectApplicationAPDU =
      [[YKFSelectApplicationAPDU alloc]
          initWithApplicationName:YKFSelectApplicationAPDUNameOpenPGP];

  // select the OpenPGP application
  [session.smartCardInterface
      executeCommand:selectApplicationAPDU
          completion:^(NSData *_Nullable response, NSError *_Nullable error) {
            if (error) {
              completion0(
                  nil,
                  [YKFOpenPGPError
                      errorWithDomain:YKFOpenPGPErrorDomainSelectApplication
                                 code:error.code]);
              return;
            }
            [session completeSelectApplicationResponse:response
                                            completion:completion0];
          }];

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
