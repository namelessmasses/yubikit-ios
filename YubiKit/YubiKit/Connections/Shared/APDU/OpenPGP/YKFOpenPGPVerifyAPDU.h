#import "Foundation/Foundation.h"
#import "YKFAPDU.h"

@interface YKFOpenPGPVerifyAPDU : YKFAPDU

- (instancetype)initWithPW1:(NSData *)pw1 isMultishot:(BOOL)isMultishot;

- (instancetype)initWithPW3:(NSData *)pw3;

- (instancetype)init NS_UNAVAILABLE;

@end
