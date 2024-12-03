#import "YKFOpenPGPGetDataAPDU.h"
#import <Foundation/Foundation.h>

@implementation YKFOpenPGPGetDataAPDU

- (instancetype)initWithTag:(id<YKFOpenPGPTLVTagProtocol>)tag {
  return [super
      initWithData:[NSData dataWithBytes:
                               (UInt8[]){
                                   0x00, 0xCA, tag.p1, tag.p2,
                                   /* lc = empty, data = empty, le = 00 */ 0x00}
                                  length:5]];
}

@end
