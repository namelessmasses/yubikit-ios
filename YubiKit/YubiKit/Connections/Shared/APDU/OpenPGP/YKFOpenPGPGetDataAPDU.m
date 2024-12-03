#import "YKFOpenPGPGetDataAPDU.h"
#import <Foundation/Foundation.h>

@implementation YKFOpenPGPGetDataAPDU

- (instancetype)initWithP1:(UInt8)p1 P2:(UInt8)p2 data:(NSData *)data {
    return [super initWithCla:0x00 ins:0xCA p1:p1 p2:p2 data:data type:YKFAPDUTypeShort];
}

@end
