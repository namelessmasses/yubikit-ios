#import "YKFOpenPGPGetChallengeAPDU.h"
#import "YKFAPDU.h"
#import <Foundation/Foundation.h>

@implementation YKFOpenPGPGetChallengeAPDU : YKFAPDU

- (instancetype)initWithShortLe:(UInt8)length {
  // Encode an APDU using the given length
  // - CLA: 00
  // - INS: 84
  // - P1: 00
  // - P2: 00
  // - Lc: 00
  // - Data: <empty>
  // - Le: length

  return [super initWithData:[NSData dataWithBytes:(UInt8[]){0x00, 0x84, 0x00,
                                                             0x00, 0x00, length}
                                            length:6]];
}

- (instancetype)initWithExtendedLe:(UInt16)length {
  // Encode an APDU using the given length
  // - CLA: 00
  // - INS: 84
  // - P1: 00
  // - P2: 00
  // - Lc: 00
  // - Data: <empty>
  // - Le: length

  return [super
      initWithData:[NSData dataWithBytes:(UInt8[]){0x00, 0x84, 0x00, 0x00, 0x00,
                                                   (UInt8)(length >> 8),
                                                   (UInt8)length}
                                  length:7]];
}

@end
