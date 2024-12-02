#import <Foundation/Foundation.h>
#import "YKFOpenPGPHashAlgorithm.h"
#import "YKFAPDU.h"

@interface YKFOpenPGPComputeDigitalSignatureAPDU: YKFAPDU

- (instancetype)initWithData:(NSData *)data hashAlgorithm:(YKFOpenPGPHashAlgorithm)hashAlgorithm;

- (instancetype)init NS_UNAVAILABLE;

@end
