#import "YKFOpenPGPDecipherAPDU.h"
#import "YKFAPDU.h"
#import <Foundation/Foundation.h>

@implementation YKFOpenPGPDecipherAPDU

- (instancetype)initWithData:(NSData *)data {
    return [super initWithCla:0x00 ins:0x2A p1:0x80 p2:0x86 data:data type:YKFAPDUTypeShort];
}

@end
