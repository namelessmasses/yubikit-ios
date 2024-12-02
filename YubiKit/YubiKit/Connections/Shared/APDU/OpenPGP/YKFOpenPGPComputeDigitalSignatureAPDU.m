#import "YKFOpenPGPComputeDigitalSignatureAPDU.h"
#import "YKFNSDataAdditions.h"
#import "YKFOpenPGPHashAlgorithm.h"
#import "YKFOpenPGPAsn1TLV.h"
#import <Foundation/Foundation.h>

typedef struct __attribute__((__packed__)) {
  YKFOpenPGPTLV tag30_outer; // 30 xx
  YKFOpenPGPTLV tag30_inner; // 30 0d
  YKFOpenPGPTLV tag06;       // 06 09
  uint8_t tag06Value[9];
  YKFOpenPGPTLV tag05; // 05 00
  YKFOpenPGPTLV tag04; // 04 xx
} YKFOpenPGPDigestInfo;

@implementation YKFOpenPGPComputeDigitalSignatureAPDU

- (instancetype)initWithData:(NSData *)data
               hashAlgorithm:(YKFOpenPGPHashAlgorithm)hashAlgorithm {

  // Allocate the digestInfo buffer with the maximum size for SHA512
  NSMutableData *dataField =
      [NSMutableData dataWithLength:sizeof(YKFOpenPGPDigestInfo) + 64];

  YKFOpenPGPDigestInfo *digestInfo =
      (YKFOpenPGPDigestInfo *)dataField.mutableBytes;
  digestInfo->tag30_outer.tag = 0x30;
  digestInfo->tag30_outer.length = 0x51;
  digestInfo->tag30_inner.tag = 0x30;
  digestInfo->tag30_inner.length = 0x0d;
  digestInfo->tag06.tag = 0x06;
  digestInfo->tag06.length = 0x09;
  digestInfo->tag05.tag = 0x05;
  digestInfo->tag05.length = 0x00;
  digestInfo->tag04.tag = 0x04;

  switch (hashAlgorithm) {

  case YKFOpenPGPHashAlgorithmSHA256: {

    uint8_t const tag06Value[] = {0x60, 0x86, 0x48, 0x01, 0x65,
                                  0x03, 0x04, 0x02, 0x01};

    memcpy(&digestInfo->tag06.value, tag06Value, sizeof(tag06Value));

    NSData *hash = [data ykf_SHA256];
    NSAssert(hash.length == 32, @"Invalid hash length");

    digestInfo->tag04.length = hash.length;
    [hash getBytes:&digestInfo->tag04.value length:hash.length];

    break;
  }

  case YKFOpenPGPHashAlgorithmSHA384: {
    uint8_t const tag06Value[] = {0x60, 0x86, 0x48, 0x01, 0x65,
                                  0x03, 0x04, 0x02, 0x02};

    memcpy(&digestInfo->tag06.value, tag06Value, sizeof(tag06Value));
    NSData *hash = [data ykf_SHA384];
    NSAssert(hash.length == 48, @"Invalid hash length");

    digestInfo->tag04.length = hash.length;
    [hash getBytes:&digestInfo->tag04.value length:hash.length];

    break;
  }

  case YKFOpenPGPHashAlgorithmSHA512: {
    uint8_t const tag06Value[] = {0x60, 0x86, 0x48, 0x01, 0x65,
                                  0x03, 0x04, 0x02, 0x03};

    memcpy(&digestInfo->tag06.value, tag06Value, sizeof(tag06Value));
    NSData *hash = [data ykf_SHA512];
    NSAssert(hash.length == 64, @"Invalid hash length");

    digestInfo->tag04.length = hash.length;
    [hash getBytes:&digestInfo->tag04.value length:hash.length];

    break;
  }

  case YKFOpenPGPHashAlgorithmECDSA:
  default: {

    // Raise an error if the hash algorithm is not supported
    @throw [NSException
        exceptionWithName:NSInvalidArgumentException
                   reason:[NSString stringWithFormat:
                                        @"Unsupported hash algorithm: %ld",
                                        (long)hashAlgorithm]
                 userInfo:nil];
    break;
  }
  }

  return [super initWithCla:0x00
                        ins:0x24
                         p1:0x9e
                         p2:0x9a
                       data:dataField
                       type:YKFAPDUTypeShort];
}

@end
