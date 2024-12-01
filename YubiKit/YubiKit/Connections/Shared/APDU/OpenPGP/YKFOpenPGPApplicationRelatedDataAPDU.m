#import "YKFOpenPGPApplicationRelatedDataAPDU.h"
#import "YKFAPDU.h"

@implementation YKFOpenPGPApplicationRelatedDataAPDU

- (instancetype)init {
    self = [super initWithData:[NSData dataWithBytes:(const UInt8[5]){0x00, 0xCA, 0x00, 0x6E, 0x00} length:5]];
    return self;
}

@end