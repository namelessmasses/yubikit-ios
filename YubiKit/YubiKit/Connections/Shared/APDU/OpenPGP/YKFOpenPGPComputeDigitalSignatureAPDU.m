#import "YKFOpenPGPComputeDigitalSignatureAPDU.h"
#import "YKFOpenPGPHashAlgorithm.h"
#import "YKFNSDataAdditions.h"
#import <Foundation/Foundation.h>

typedef struct __attribute__((__packed__)) {
  uint8_t tag;
  uint8_t length;
  uint8_t value[0];
} YKFOpenPGPTLV;

typedef struct __attribute__((__packed__)) {
  YKFOpenPGPTLV tag30_outer; // 30 xx
  YKFOpenPGPTLV tag30_inner; // 30 0d
  YKFOpenPGPTLV tag06;       // 06 09
  uint8_t tag06Value[9];
  YKFOpenPGPTLV tag05; // 05 00
  YKFOpenPGPTLV tag04; // 04 xx
} YKFOpenPGPDigestInfoBase;

typedef struct __attribute__((__packed__)) {
  YKFOpenPGPDigestInfoBase base;
  uint8_t hash[32]; // 32 bytes for SHA-256 hash
} YKFOpenPGPDigestInfoSHA256;

typedef struct __attribute__((__packed__)) {
  YKFOpenPGPDigestInfoBase base;
  uint8_t hash[48]; // 48 bytes for SHA-384 hash
} YKFOpenPGPDigestInfoSHA384;

typedef struct __attribute__((__packed__)) {
  YKFOpenPGPDigestInfoBase base;
  uint8_t hash[64]; // 64 bytes for SHA-512 hash
} YKFOpenPGPDigestInfoSHA512;

@implementation YKFOpenPGPComputeDigitalSignatureAPDU

- (instancetype)initWithData:(NSData *)data
               hashAlgorithm:(YKFOpenPGPHashAlgorithm)hashAlgorithm {

  NSMutableData *digestInfo = nil;
  NSData *hash = nil;
  switch (hashAlgorithm) {
  case YKFOpenPGPHashAlgorithmSHA256:
    digestInfo = [NSMutableData dataWithLength:sizeof(YKFOpenPGPDigestInfoSHA256)];
    YKFOpenPGPDigestInfoSHA256 *digestInfoSHA256 = (YKFOpenPGPDigestInfoSHA256 *)digestInfo.mutableBytes;
    digestInfoSHA256->base.tag30_outer.tag = 0x30;
    digestInfoSHA256->base.tag30_outer.length = 0x31;
    digestInfoSHA256->base.tag30_inner.tag = 0x30;
    digestInfoSHA256->base.tag30_inner.length = 0x0d;
    digestInfoSHA256->base.tag06.tag = 0x06;
    digestInfoSHA256->base.tag06.length = 0x09;
    digestInfoSHA256->base.tag06.value[0] = 0x60;
    digestInfoSHA256->base.tag06.value[1] = 0x86;
    digestInfoSHA256->base.tag06.value[2] = 0x48;
    digestInfoSHA256->base.tag06.value[3] = 0x01;
    digestInfoSHA256->base.tag06.value[4] = 0x65;
    digestInfoSHA256->base.tag06.value[5] = 0x03;
    digestInfoSHA256->base.tag06.value[6] = 0x04;
    digestInfoSHA256->base.tag06.value[7] = 0x02;
    digestInfoSHA256->base.tag06.value[8] = 0x01;
    digestInfoSHA256->base.tag05.tag = 0x05;
    digestInfoSHA256->base.tag05.length = 0x00;
    digestInfoSHA256->base.tag04.tag = 0x04;
    digestInfoSHA256->base.tag04.length = 0x20;
    hash = [data ykf_SHA256];

    // Assert that the hash is 32 bytes long
    NSAssert(hash.length == 32, @"Invalid hash length");
    [hash getBytes:digestInfoSHA256->hash length:hash.length];
    break;

    case YKFOpenPGPHashAlgorithmSHA384:
    break;

    case YKFOpenPGPHashAlgorithmSHA512:
    break;

    case YKFOpenPGPHashAlgorithmECDSA:
    break;

    default:
    break;
  }

  return [super initWithCla:0x00 ins:0x24 p1:0x9e p2:0x9a data:digestInfo type:YKFAPDUTypeShort];
}

@end
