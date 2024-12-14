//
//  YKFOpenPGPAsn1Tests.m
//  YubiKit
//
//  Created by Michael Ngarimu on 12/14/24.
//  Copyright © 2024 Yubico. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "YKFTestCase.h"

#import "YKFOpenPGPAsn1TLV.h"

@interface YKFOpenPGPAsn11TagTests : YKFTestCase

- (void)testSimpleTagParseFromEmptyData;
- (void)testSimpleTagParseFromData;
- (void)testSimpleTagParseFromDataWithExtraBytes;
- (void)testSimpleTagFromIntegerValue;

@end
@implementation YKFOpenPGPAsn11TagTests

- (void)testSimpleTagParseFromEmptyData {
  NSData *data = [NSData data];
  YKFOpenPGPSimpleTLVTag *tag =
      [[YKFOpenPGPSimpleTLVTag alloc] initWithEncodedBytes:data];
  XCTAssertNil(tag, @"TLV should be nil for empty data");
}

- (void)testSimpleTagParseFromData {
  uint8_t bytes[] = {0x01};
  NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
  YKFOpenPGPSimpleTLVTag *tag =
      [[YKFOpenPGPSimpleTLVTag alloc] initWithEncodedBytes:data];
  XCTAssertNotNil(tag, @"TLV should not be nil for valid data");
  XCTAssertEqual(tag.tagNumber, 0x01, @"Tag should be 0x01");
  XCTAssertEqual(tag.decodedTag, 0x01, @"DecodedTag should be 0x02");
  XCTAssertEqual(tag.p1, 0x00, @"p1 should be 0x00");
  XCTAssertEqual(tag.p2, 0x01, @"p2 should be 0x01");

  UInt8 p1 = 0xff, p2 = 0xff;
  [tag getParametersP1:&p1 P2:&p2];
  XCTAssertEqual(p1, 0x00, @"p1 should be 0x00");
  XCTAssertEqual(p2, 0x01, @"p2 should be 0x01");
}

- (void)testSimpleTagParseFromDataWithExtraBytes {
  uint8_t bytes[] = {0x01, 0x02, 0x03, 0x04};
  NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
  YKFOpenPGPSimpleTLVTag *tag =
      [[YKFOpenPGPSimpleTLVTag alloc] initWithEncodedBytes:data];
  XCTAssertNotNil(tag,
                  @"Tag should not be nil for valid data with extra bytes");
  XCTAssertEqual(tag.tagNumber, 0x01, @"Tag should be 0x01");
  XCTAssertEqual(tag.decodedTag, 0x01, @"Length should be 0x01");
  XCTAssertEqual(tag.p1, 0x00, @"p1 should be 0x00");
  XCTAssertEqual(tag.p2, 0x01, @"p2 should be 0x01");

  UInt8 p1 = 0xff, p2 = 0xff;
  [tag getParametersP1:&p1 P2:&p2];
  XCTAssertEqual(p1, 0x00, @"p1 should be 0x01");
  XCTAssertEqual(p2, 0x01, @"p2 should be 0x02");
}

- (void)testTagParseFromInvalidData {
  // ISO-7816-4 states that tag values 0x00 and 0xFF will never be used.
  YKFOpenPGPSimpleTLVTag *tag00 =
      [[YKFOpenPGPSimpleTLVTag alloc] initWithValue:0x00];
  XCTAssertNil(tag00, @"TLV should be nil for invalid data (0x00)");

  YKFOpenPGPSimpleTLVTag *tagFF =
      [[YKFOpenPGPSimpleTLVTag alloc] initWithValue:0xFF];
  XCTAssertNil(tagFF, @"TLV should be nil for invalid data (0xFF)");
}

- (void)testSimpleTagFromIntegerValue {
  NSInteger value = 123;
  YKFOpenPGPSimpleTLVTag *tag =
      [[YKFOpenPGPSimpleTLVTag alloc] initWithValue:value];
  XCTAssertNotNil(tag, @"TLV should not be nil for integer value");
  XCTAssertEqual(tag.p1, 0x00, @"p1 should be 0x00");
  XCTAssertEqual(tag.p2, 123, @"p2 should be 123");

  UInt8 p1 = 0xff, p2 = 0xff;
  [tag getParametersP1:&p1 P2:&p2];
  XCTAssertEqual(p1, 0x00, @"p1 should be 0x00");
  XCTAssertEqual(p2, 123, @"p2 should be 123");
}

- (void)testBERTagParseFromEmptyData {
  NSData *data = [NSData data];
  YKFOpenPGPBERTLVTag *tag =
      [[YKFOpenPGPBERTLVTag alloc] initWithEncodedBytes:data];
  XCTAssertNil(tag, @"Tag should be nil for empty data");
}

- (void)testBERTagParseSimpleTagFromData {
  uint8_t bytes[] = {0x01};
  NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
  YKFOpenPGPBERTLVTag *tag =
      [[YKFOpenPGPBERTLVTag alloc] initWithEncodedBytes:data];
  XCTAssertNotNil(tag, @"Tag should not be nil for valid data");
  XCTAssertEqual(tag.tagNumber, 0x01, @"Tag should be 0x01");
  XCTAssertEqual(tag.decodedTag, 0x01, @"DecodedTag should be 0x01");
  XCTAssertEqual(tag.p1, 0x00, @"p1 should be 0x00");
  XCTAssertEqual(tag.p2, 0x01, @"p2 should be 0x01");

  UInt8 p1 = 0xff, p2 = 0xff;
  [tag getParametersP1:&p1 P2:&p2];
  XCTAssertEqual(p1, 0x00, @"p1 should be 0x00");
  XCTAssertEqual(p2, 0x01, @"p2 should be 0x01");

    XCTAssertEqual(tag.tagClass, YKFOpenPGPBERTLVTagClassUniversal,
                 @"Tag class should be Universal");
    XCTAssertEqual(tag.tagType, YKFOpenPGPBERTLVTagTypePrimitive,
                 @"Tag type should be Primitive");
}

@end
