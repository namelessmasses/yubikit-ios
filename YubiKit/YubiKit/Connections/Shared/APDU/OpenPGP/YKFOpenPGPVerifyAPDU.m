#import "YKFOpenPGPVerifyAPDU.h"

@implementation YKFOpenPGPVerifyAPDU

- (instancetype)initWithPW1:(NSData *)pw1 isMultishot:(BOOL)isMultishot {
    return [super initWithCla:0x00 ins:0x20 p1:0x00 p2:(isMultishot ? 0x82 : 0x81) data:pw1 type:YKFAPDUTypeShort];
}

- (instancetype)initWithPW3:(NSData *)pw3 {
    return [super initWithCla:0x00 ins:0x20 p1:0x00 p2:0x83 data:pw3 type:YKFAPDUTypeShort];
}

@end