#import <Foundation/Foundation.h>
#import "YKFOpenPGPAsn1TLV.h"
#import "YKFAPDU.h"

@interface YKFOpenPGPGetDataAPDU : YKFAPDU 

- (instancetype)initWithTag:(id<YKFOpenPGPTLVTagProtocol>)tag;

- (instancetype)init NS_UNAVAILABLE;

@end