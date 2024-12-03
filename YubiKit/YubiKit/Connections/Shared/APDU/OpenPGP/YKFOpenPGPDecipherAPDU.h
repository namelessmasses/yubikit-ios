#import <Foundation/Foundation.h>
#import "YKFAPDU.h"

@interface YKFOpenPGPDecipherAPDU: YKFAPDU

- (instancetype)initWithData:(NSData *)data;

- (instancetype)init NS_UNAVAILABLE;

@end
