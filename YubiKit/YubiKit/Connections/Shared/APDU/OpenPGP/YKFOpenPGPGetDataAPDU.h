#import <Foundation/Foundation.h>

#import "YKFAPDU.h"

@interface YKFOpenPGPGetDataAPDU : YKFAPDU 

- (instancetype)initWithP1:(UInt8)p1 P2:(UInt8)p2 data:(NSData *)data;

- (instancetype)init NS_UNAVAILABLE;

@end