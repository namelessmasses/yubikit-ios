#import "YKFOpenPGPAsn1TLV.h"

#import <Foundation/Foundation.h>

@interface YKFOpenPGPSimpleTLVTag ()

@property(nonatomic, readwrite) NSData *encodedBytes;

@end

@implementation YKFOpenPGPSimpleTLVTag

- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  if (encodedBytes.length < 1) {
    return nil;
  }

  self.encodedBytes = [encodedBytes subdataWithRange:NSMakeRange(0, 1)];

  return self;
}

- (instancetype)initWithValue:(UInt8)value {
  self = [super init];
  if (self) {
    self.encodedBytes = [NSData dataWithBytes:&value length:1];
  }
  return self;
}

- (UInt64)tagNumber {
  UInt8 v;
  [self.encodedBytes getBytes:&v length:sizeof(v)];
  return v;
}

- (UInt64)decodedTag {
  UInt64 dt = 0;
  for (int i = 0; i < self.encodedBytes.length; ++i) {
    dt = (dt << 8) | ((UInt8 *)self.encodedBytes.bytes)[i];
  }

  return dt;
}

- (UInt8)p1 {
  return 0x00;
}

- (UInt8)p2 {
  return self.tagNumber;
}

- (void)getParametersP1:(UInt8 *)p1 P2:(UInt8 *)p2 {
  if (p1 == nil && p2 == nil) {
    return;
  }

  *p1 = self.p1;
  *p2 = self.p2;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<SIMPLE-TAG>%u", self.p2];
}

@end

@interface YKFOpenPGPBERTLVTag ()

@property(nonatomic, readwrite) NSData *encodedBytes;

@end

@implementation YKFOpenPGPBERTLVTag

typedef struct {
  UInt64 tagNumber;
  UInt64 consumedByteCount;
} TagNumberResult;

+ (TagNumberResult)tagNumberFromEncodedBytes:(NSData *)encodedBytes {
  UInt8 const *bytes = encodedBytes.bytes;

  // Check for single byte tag
  if (encodedBytes.length == 1 && (bytes[0] & 0x1F) < 0x1F) {
    TagNumberResult result = {bytes[0] & 0x1F, 1};
    return result;
  }

  // Check for multi-byte tag
  TagNumberResult result = {0, 0};

  for (int i = 0; i < encodedBytes.length; ++i) {
    result.tagNumber = (result.tagNumber << 7) | (bytes[i] & 0x7F);
    if ((bytes[i] & 0x80) == 0) {
      result.consumedByteCount = i + 1;
      return result;
    }
  }

  // Reached the end of the bytes without an end byte of the length
  result.tagNumber = 0;
  result.consumedByteCount = 0;

  return result;
}

- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  if (encodedBytes.length == 0) {
    return nil;
  }

  UInt8 const *bytes = encodedBytes.bytes;

  // Check for single byte tag
  if ((bytes[0] & 0x1F) < 0x1F) {
    self.encodedBytes = [encodedBytes subdataWithRange:NSMakeRange(0, 1)];
    return self;
  }

  // Try parsing a tag number from the encoded bytes
  TagNumberResult parsedTagNumber =
      [YKFOpenPGPBERTLVTag tagNumberFromEncodedBytes:encodedBytes];

  if (parsedTagNumber.tagNumber == 0) {
    return nil;
  }

  self.encodedBytes = [encodedBytes
      subdataWithRange:NSMakeRange(0, parsedTagNumber.consumedByteCount)];

  return self;
}

- (instancetype)initWithClass:(YKFOpenPGPBERTLVTagClass)class
                         type:(YKFOpenPGPBERTLVTagType)type
                    tagNumber:(UInt64)tagNumber {

  self = [super init];
  if (self == nil) {
    return nil;
  }

  UInt8 leadingByte = (class << 6) | (type << 5);

  // tagNumbers 1-30 encode as a single byte
  if (tagNumber < 0x1F) {
    leadingByte |= tagNumber;
    self.encodedBytes = [NSData dataWithBytes:&leadingByte length:1];
    return self;
  }

  // tagNumbers > 30 encode with the leading byte B5-B1 set to 1 and the tag
  // number encoded in the subsequent bytes. The last byte has the most
  // significant bit set to 0.
  NSMutableData *encodedBytes = [[NSMutableData alloc] init];
  leadingByte |= 0x1F;
  [encodedBytes appendBytes:&leadingByte length:1];

  // The tag number is encoded in big-endian order.
  UInt32 subsequentByteCount = tagNumber / 0x7F;

  while ((tagNumber >> (subsequentByteCount * 7)) > 0) {
    UInt8 subsequentByte =
        0x80 | (tagNumber >> (subsequentByteCount * 7)) & 0x7F;
    [encodedBytes appendBytes:&subsequentByte length:1];
    --subsequentByteCount;
  }

  // The last byte has the most significant bit set to 0.
  ((UInt8 *)encodedBytes.mutableBytes)[encodedBytes.length - 1] &= 0x7F;

  self.encodedBytes = encodedBytes;

  return self;
}

- (UInt64)tagNumber {
  return [YKFOpenPGPBERTLVTag tagNumberFromEncodedBytes:self.encodedBytes]
      .tagNumber;
}

- (UInt64)decodedTag {
  UInt64 dt = 0;
  for (int i = 0; i < self.encodedBytes.length; ++i) {
    dt = (dt << 8) | ((UInt8 *)self.encodedBytes.bytes)[i];
  }

  return dt;
}

- (UInt8)p1 {
  UInt16 tag;
  [self.encodedBytes getBytes:&tag length:sizeof(tag)];
  return (UInt8)((tag >> 8) & 0xFF);
}

- (UInt8)p2 {
  UInt16 tag;
  [self.encodedBytes getBytes:&tag length:sizeof(tag)];
  return (UInt8)(tag & 0xFF);
}

- (void)getParametersP1:(UInt8 *)p1 P2:(UInt8 *)p2 {
  if (p1 == nil && p2 == nil) {
    return;
  }

  *p1 = self.p1;
  *p2 = self.p2;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<BER-TAG>%llu", self.tagNumber];
}

@end

@interface YKFOpenPGPSimpleTLVLength ()

@property(nonatomic, readwrite) NSData *encodedBytes;

@end

@implementation YKFOpenPGPSimpleTLVLength

- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  if (encodedBytes.length > 3) {
    return nil;
  }

  UInt8 const *bytes = encodedBytes.bytes;

  // Check for 1-byte length
  if (bytes[0] < 0xFF) {
    return nil;
  }

  // Check for 3-byte length
  if (encodedBytes.length < 3) {
    return nil;
  }

  // 3-byte length; 1st byte is FF, 2nd and 3rd bytes are the length
  self.encodedBytes = [encodedBytes subdataWithRange:NSMakeRange(0, 3)];

  return self;
}

- (instancetype)initWithInteger:(uint16_t)i {
  self = [super init];
  if (self) {
    if (i < 0x80) {
      UInt8 i2 = i;
      self.encodedBytes = [NSData dataWithBytes:&i2 length:1];
    } else if (i <= 0xff) {
      self.encodedBytes = [NSData dataWithBytes:(UInt8[]){0x81, i} length:2];
    } else {
      NSMutableData *data = [NSMutableData alloc];
      [data appendBytes:(UInt8[]){0x82} length:1];

      uint16_t i2 = htons(i);
      [data appendBytes:&i2 length:sizeof(i2)];

      self.encodedBytes = data;
    }
  }
  return self;
}

- (uint16_t)integerValue {
  uint16_t iv;
  [self.encodedBytes getBytes:&iv length:sizeof(iv)];
  return ntohs(iv);
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<SIMPLE-LENGTH>%u", self.integerValue];
}

@end

@interface YKFOpenPGPBERTLVLength ()

@property(nonatomic, readwrite) NSData *encodedBytes;

@end

@implementation YKFOpenPGPBERTLVLength

- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  if (encodedBytes.length == 0) {
    return nil;
  }

  UInt8 const *bytes = encodedBytes.bytes;

  // Check for short form length
  if (encodedBytes.length == 1 && bytes[0] < 0x80) {
    self.encodedBytes = [encodedBytes subdataWithRange:NSMakeRange(0, 1)];
    return self;
  }

  // Check for long form length
  UInt8 lengthLength = bytes[0] & 0x7F;
  if (lengthLength > encodedBytes.length - 1) {
    return nil;
  }

  self.encodedBytes =
      [encodedBytes subdataWithRange:NSMakeRange(0, lengthLength)];

  return self;
}

- (instancetype)initWithInteger:(UInt16)lengthValue
                           form:(YKFOpenPGPBERTLVLengthForm)form {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  if (form == YKFOpenPGPBERTLVLengthFormShort) {
    if (lengthValue >= 0x80) {
      return nil;
    }

    self.encodedBytes = [NSData dataWithBytes:&lengthValue length:1];

  } else if (form == YKFOpenPGPBERTLVLengthFormLong) {
    if (lengthValue < 0x80) {
      return nil;
    }

    if (lengthValue <= 0xFF) {
      self.encodedBytes = [NSData dataWithBytes:(UInt8[]){0x81, lengthValue}
                                         length:2];
    } else if (lengthValue <= 0xFFFF) {
      uint16_t lengthValueBigEndian = htons(lengthValue);
      self.encodedBytes =
          [NSData dataWithBytes:(UInt8[]){0x82, lengthValueBigEndian} length:3];
    } else {
      return nil;
    }
  }

  return self;
}

- (uint16_t)integerValue {
  UInt8 const *bytes = self.encodedBytes.bytes;

  // 1-byte length
  if (bytes[0] < 0x80) {
    return bytes[0];
  }

  // Multi-byte length
  UInt8 lengthLength = bytes[0] & 0x7F;

  // Null
  if (lengthLength == 0) {
    return 0;
  }

  uint16_t iv = 0;
  for (int i = 1; i <= lengthLength; ++i) {
    iv = (iv << 8) | bytes[i];
  }

  return iv;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<BER-LENGTH>%u", self.integerValue];
}

@end

@interface YKFOpenPGPSimpleTLV ()

/**
 * Allow `encodedBytes` to be set internally.
 */
@property(nonatomic, readwrite) NSData *encodedBytes;
@property(nonatomic, readwrite) YKFOpenPGPSimpleTLVTag *tag;
@property(nonatomic, readwrite) YKFOpenPGPSimpleTLVLength *length;
@property(nonatomic, readwrite) NSData *value;

@end

@implementation YKFOpenPGPSimpleTLV

- (instancetype)initWithTag:(YKFOpenPGPSimpleTLVTag *)tag
                     length:(YKFOpenPGPSimpleTLVLength *)length
                      value:(NSData *)value {

  if (length.integerValue != value.length) {
    return nil;
  }

  self = [super init];
  if (self == nil) {
    return nil;
  }

  self.tag = tag;
  self.length = length;
  self.value = value;

  NSMutableData *encodedBytes = [[NSMutableData alloc] init];
  [encodedBytes appendData:self.tag.encodedBytes];
  [encodedBytes appendData:self.length.encodedBytes];
  [encodedBytes appendData:self.value];

  return self;
}

- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  UInt64 consumedByteCount = 0;

  // Parse the tag
  self.tag = [[YKFOpenPGPSimpleTLVTag alloc] initWithEncodedBytes:encodedBytes];
  if (self.tag == nil) {
    return nil;
  }

  NSMutableData *destEncodedBytes =
      [NSMutableData dataWithCapacity:encodedBytes.length];
  [destEncodedBytes appendData:self.tag.encodedBytes];
  consumedByteCount += self.tag.encodedBytes.length;

  // Parse the length
  self.length = [[YKFOpenPGPSimpleTLVLength alloc]
      initWithEncodedBytes:[encodedBytes
                               subdataWithRange:NSMakeRange(
                                                    consumedByteCount,
                                                    encodedBytes.length)]];

  if (self.length == nil) {
    self.value = nil;
    return self;
  }

  [destEncodedBytes appendData:self.length.encodedBytes];
  consumedByteCount += self.length.encodedBytes.length;

  self.value = [encodedBytes
      subdataWithRange:NSMakeRange(consumedByteCount, encodedBytes.length)];
  consumedByteCount += self.value.length;

  if (consumedByteCount != encodedBytes.length) {
    return nil;
  }

  self.encodedBytes = destEncodedBytes;

  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<SIMPLE-TLV>%@ %@ %@",
                                    self.tag.description, self.length.description, self.value];
}

@end

@interface YKFOpenPGPBERTLV ()

@property(nonatomic, readwrite) NSData *encodedBytes;
@property(nonatomic, readwrite) YKFOpenPGPBERTLVTag *tag;
@property(nonatomic, readwrite) YKFOpenPGPBERTLVLength *length;
@property(nonatomic, readwrite) NSData *value;

@end

@implementation YKFOpenPGPBERTLV

+ (instancetype) withEncodedBytes:(NSData *)encodedBytes {
  return [[YKFOpenPGPBERTLV alloc] initWithEncodedBytes:encodedBytes];
}

- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  UInt64 consumedByteCount = 0;

  // Parse the tag
  self.tag = [[YKFOpenPGPBERTLVTag alloc] initWithEncodedBytes:encodedBytes];
  if (self.tag == nil) {
    return nil;
  }

  NSMutableData *destEncodedBytes =
      [NSMutableData dataWithCapacity:encodedBytes.length];
  [destEncodedBytes appendData:self.tag.encodedBytes];
  consumedByteCount += self.tag.encodedBytes.length;

  // Parse the length
  self.length = [[YKFOpenPGPBERTLVLength alloc]
      initWithEncodedBytes:[encodedBytes
                               subdataWithRange:NSMakeRange(
                                                    consumedByteCount,
                                                    encodedBytes.length)]];

  if (self.length == nil) {
    self.value = nil;
    return self;
  }

  [destEncodedBytes appendData:self.length.encodedBytes];
  consumedByteCount += self.length.encodedBytes.length;

  self.value = [encodedBytes
      subdataWithRange:NSMakeRange(consumedByteCount, encodedBytes.length)];

  consumedByteCount += self.value.length;

  if (consumedByteCount != encodedBytes.length) {
    return nil;
  }

  self.encodedBytes = destEncodedBytes;

  return self;
}

- (instancetype)initWithTag:(YKFOpenPGPBERTLVTag *)tag
                     length:(YKFOpenPGPBERTLVLength *)length
                      value:(NSData *)value {

  if (tag == nil) {
    return nil;
  }

  if (length == nil && value != nil) {
    return nil;
  }

  if (length.integerValue != value.length) {
    return nil;
  }

  self = [super init];
  if (self == nil) {
    return nil;
  }

  self.tag = tag;
  self.length = length;
  self.value = value;

  NSMutableData *encodedBytes = [[NSMutableData alloc] init];
  [encodedBytes appendData:self.tag.encodedBytes];
  [encodedBytes appendData:self.length.encodedBytes];
  [encodedBytes appendData:self.value];

  self.encodedBytes = encodedBytes;

  return self;
}

- (NSData *)encodedBytes {
  NSMutableData *encodedBytes = [[NSMutableData alloc] init];
  [encodedBytes appendData:self.tag.encodedBytes];
  [encodedBytes appendData:self.length.encodedBytes];
  [encodedBytes appendData:self.value];
  return encodedBytes;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<BER-TLV>%@ %@ %@",
                                    self.tag.description, self.length.description, self.value];
}

@end
