#import "YKFAPDU.h"
#import <Foundation/Foundation.h>

@interface YKFOpenPGPGetChallengeAPDU: YKFAPDU

- (instancetype)initWithShortLe:(UInt8)length;

- (instancetype)initWithExtendedLe:(UInt16)length;

- (instancetype)init NS_UNAVAILABLE;

@end
