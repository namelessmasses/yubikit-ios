#include "YKFOpenPGPHashAlgorithm.h"
#import <Foundation/Foundation.h>

/**
 * @struct YKFOpenPGPTLV
 * @brief A structure representing a TLV (Tag-Length-Value) element used in
 * OpenPGP.
 *
 * This structure is used to represent a TLV element where:
 * - 1-byte `tag`
 * - 1-byte `length` simple length. Does not support ASN.1 endcoded length.
 * - `value` is a flexible array member that holds the actual data.
 *
 * The structure is packed to ensure there is no padding between the fields.
 *
 * @note Not related to ASN.1 SIMPLE-TLV.
 */
typedef struct __attribute__((__packed__)) {
  UInt8 tag;
  UInt8 length;
  UInt8 value[0];
} YKFOpenPGPTLV;

typedef NS_ENUM(NSUInteger, YKFOpenPGPTag) {
  YKFOpenPGPTagOptionalDO = 0x0100,
  YKFOpenPGPTagOptionalDO1 = 0x0101,
  YKFOpenPGPTagOptionalDO2 = 0x0102,
  YKFOpenPGPTagOptionalDO3 = 0x0103,
  YKFOpenPGPTagOptionalDO4 = 0x0104,
  YKFOpenPGPTagApplicationIdentifier = 0x4f,
  YKFOpenPGPTagName = 0x5b,
  YKFOpenPGPTagLoginData = 0x5e,
  YKFOpenPGPTagLanguage = 0x5f2d,
  YKFOpenPGPTagSex = 0x5f35,
  YKFOpenPGPTagCardholderRelatedData = 0x65,
  YKFOpenPGPTagApplicationRelatedData = 0x6e,
  YKFOpenPGPTagURL = 0x5f50,
  YKFOpenPGPTagHistoricalBytes = 0x5f52,
  YKFOpenPGPTagSecuritySupport = 0x7a,
  YKFOpenPGPTagDigitalSignatureCounter = 0x93,
  YKFOpenPGPTagCardholderCertificate = 0x7f21,
  YKFOpenPGPTagExtendedLengthInformation = 0x7f66,
  YKFOpenPGPTagGeneralFeatureInformation = 0x7f74,
  YKFOpenPGPTagDiscretionaryDataObjects = 0x0073,
  YKFOpenPGPTagExtendedCapabilities = 0xc0,
  YKGOpenPGPTagAlgorithmAttributesSignature = 0xc1,
  YKFOpenPGPTagAlgorithmAttributesDecryption = 0xc2,
  YKFOpenPGPTagAlgorithmAttributesAuthentication = 0xc3,
  YKFOpenPGPTagPWStatusBytes = 0xc4,
  YKFOpenPGPTagFingerprints = 0xc5,
  YKFOpenPGPTagCAFingerprints = 0xc6,
  YKFOpenPGPTagKeyGenerationDateTimes = 0xcd,
  YKFOpenPGPTagKeyInformation = 0xde,
  YKFOpenPGPTagUserInteractionFlagCDS = 0xd6,
  YKFOpenPGPTagUserInteractionFlagDEC = 0xd7,
  YKFOpenPGPTagUserInteractionFlagAUT = 0xd8,
  YKFOpenPGPTagUserInteractionFlagATT = 0xd9,
  YKFOpenPGPTagAttestationAlgorithmAttributes = 0xda,
  YKFOpenPGPTagAttestationFingerprint = 0xdb,
  YKFOpenPGPTagAttestationCAFingerprint = 0xdc,
  YKFOpenPGPTagAttestationKeyGenerationDateTimes = 0xdd,
  YKFOpenPGPTagKDF = 0xf9,
  YKFOpenPGPTagAlgorithmInformation = 0xfa,
  YKFOpenPGPTagSMSCP11b = 0xfb,
  YKFOpenPGPTagAttestationCertificate = 0xfc
};

/**
 * @brief Tag used commonly in OpenPGP commands and responses.
 *
 * Provides an abstraction across SIMPLE-TLV and BER-TLV tags.
 */
@protocol YKFOpenPGPTLVTagProtocol <NSObject>

/**
 * @brief Bytes of an encoded tag. Allows multi-byte tags.
 */
@property(nonatomic, readonly) NSData *encodedBytes;

/**
 * @brief Tag number from a decoded tag
 */
@property(nonatomic, readonly) UInt64 tagNumber;

/**
 * @brief Extract the byte of the tag when passing P1 in a command APDU.
 */
@property(nonatomic, readonly) UInt8 p1;

/**
 * @brief Extract te byte of the tage when passing P2 in a command APDU.
 */
@property(nonatomic, readonly) UInt8 p2;

/**
 * @brief Get the tag as command parameters P1 and P2 simultaneously.
 *
 * *p1 and *p2 will be unchanged under the following error conditions:
 * - The tag is longer than 2 bytes.
 * - The both of the out parameters are nil.
 *
 * @param p1 out-param of p1
 * @param p2 out-param of p2
 */
- (void)getParametersP1:(UInt8 *)p1 P2:(UInt8 *)p2;

@end

/**
 * @brief Tag with a single byte value.
 */
@interface YKFOpenPGPSimpleTLVTag : NSObject <YKFOpenPGPTLVTagProtocol>

/**
 * @brief Parses the encoded bytes to ensure they correctly encode a SIMPLE-TLV
 * tag.
 */
- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes;

/**
 * @brief Initialize with the given tag value.
 */
- (instancetype)initWithValue:(UInt8)value;

- (instancetype)init NS_UNAVAILABLE;

@end

/**
 * @brief Tag encoded with ASN.1 Basic Encoding Rules (BER) formt.
 *
 * @see ISO-7816 Part 4 Annex D.
 *
 * Leading byte:
 * - B8 B7: class
 *   - 00: universal
 *   - 01: application
 *   - 10: context-specific
 *   - 11: private
 * - B6: type
 *   - 0: primitive
 *   - 1: constructed
 * - B5-B1:
 *   - 0b00000 - 0b11110: tag number
 *   - 0b11111: tag number continues on one or more subsequent bytes.
 *
 * Subequent bytes:
 * - B8 of each subsequent byte: 1, unless last byte.
 * - B7-B1 of the first subsequent byte shall not be 0.
 * - B7-B1 of each subsequent byte, including the last, encode an integer
 *   equal to the tag number.
 */
@interface YKFOpenPGPBERTLVTag : NSObject <YKFOpenPGPTLVTagProtocol>

typedef NS_ENUM(NSUInteger, YKFOpenPGPBERTLVTagClass) {
  YKFOpenPGPBERTLVTagClassUniversal = 0x00,
  YKFOpenPGPBERTLVTagClassApplication = 0x01,
  YKFOpenPGPBERTLVTagClassContextSpecific = 0x02,
  YKFOpenPGPBERTLVTagClassPrivate = 0x03
} NS_SWIFT_NAME(YKFOpenPGPBERTLVTag.Class);

typedef NS_ENUM(NSUInteger, YKFOpenPGPBERTLVTagType) {
  YKFOpenPGPBERTLVTagTypePrimitive = 0x00,
  YKFOpenPGPBERTLVTagTypeConstructed = 0x01
} NS_SWIFT_NAME(YKFOpenPGPBERTLVTag.Type);

/**
 * @brief Initialize with the given encoded bytes.
 *
 * @param encodedBytes parsed to check for correctness according to the BER
 * format.
 */
- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes;

/**
 * @brief Initialize and encode the given class, type, and tag number.
 */
- (instancetype)initWithClass:(YKFOpenPGPBERTLVTagClass)class
                         type:(YKFOpenPGPBERTLVTagType)type
                    tagNumber:(UInt64)tagNumber;

- (instancetype)init NS_UNAVAILABLE;

@end

/**
 * @brief Encoded length. Handles values up to 65535.
 */
@protocol YKFOpenPGPTLVLengthProtocol

/**
 * @brief Encoded bytes
 */
@property(nonatomic, readonly) NSData *encodedBytes;

/**
 * @brief length as a simple integer value.
 */
@property(nonatomic, readonly) uint16_t integerValue;

@end

/**
 * @brief Length encoded to ISO-7816 Part 4 section 5.4.4.
 */
@interface YKFOpenPGPSimpleTLVLength : NSObject <YKFOpenPGPTLVLengthProtocol>

/**
 * @brief Initialize with pre-encoded bytes.
 *
 * Encoded bytes are checked for correctness according to the ISO-7816 Part 4
 * section 5.4.4.
 *
 * @param encodedBytes If the leading byte is the range ['0x00', '0xFE'], then
 * the length field is a single byte encoding an integer L valued from 0 to 254.
 * If the leading byte is `FF`, then the length field continues on the two
 * subsequent bytes which encodes a big-endian integer, L, with a value of 0 to
 * 65535.
 */
- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes;

/**
 * @brief Encodes the integer according to ISO-7816 Part 4 section 5.4.4.
 *
 * @param i encodes the integer into 1 or 3 bytes. 0 <= i < 255 encodes as `i`.
 * 255 <= i < 65536 encodes as `FF ii ii`.
 */
- (instancetype)initWithInteger:(uint16_t)length;

- (instancetype)init NS_UNAVAILABLE;

@end

/**
 * @brief Length encoded to ISO-7816 Part 4 Annex D.
 */
@interface YKFOpenPGPBERTLVLength : NSObject <YKFOpenPGPTLVLengthProtocol>

typedef NS_ENUM(NSUInteger, YKFOpenPGPBERTLVLengthForm) {
  YKFOpenPGPBERTLVLengthFormShort,
  YKFOpenPGPBERTLVLengthFormLong,
} NS_SWIFT_NAME(YKFOpenPGPBERTLVLength.Form);

/**
 * @brief Initialize with pre-encoded bytes.
 *
 * Encoded bytes are checked for correctness according to the ISO-7816 Part 4
 * Annex D.
 *
 * @param encodedBytes If the leading byte is in the range ['0x00', '0x7F'],
 * then the length field is a single byte encoding an integer L valued from 0 to
 * 127. If the leading byte is `0x81`, then the length field continues on the
 * following byte which encodes an integer L valued from 0 to 255. If the
 * leading byte is `0x82`, then the length field continues on the two subsequent
 * bytes which encodes a big-endian integer, L, with a value of 0 to 65535.
 */
- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes;

/**
 * @brief Initialize with a simple integer length.
 *
 * @param length If length is in the range [0, 255], then the length field is a
 * single byte encoding an integer L valued from 0 to 127. If length is in the
 * range [256, 65535], then the length field is three bytes encoding an integer
 * L valued from 0 to 65535.
 *
 * @param form attempts to use this form to encode the length.
 *
 * @return nil if the length is out of range for the form.
 */
- (instancetype)initWithInteger:(UInt16)length
                           form:(YKFOpenPGPBERTLVLengthForm)form;

@end

/**
 * @brief A common abstraction used across `SIMPLE-TLV` and `BER-TLV`.
 */
@protocol YKFOpenPGPTLVProtocol <NSObject>

@property(nonatomic, readonly) NSData *encodedBytes;

@property(nonatomic, readonly) id<YKFOpenPGPTLVTagProtocol> tag;

@property(nonatomic, readonly) id<YKFOpenPGPTLVLengthProtocol> length;

/**
 * @brief value.length == length.asInteger
 */
@property(nonatomic, readonly) NSData *value;

@end

/**
 * @brief Representation of `SIMPLE-TLV`.
 *
 * Enforces 1-byte tag.
 */
@interface YKFOpenPGPSimpleTLV : NSObject <YKFOpenPGPTLVProtocol>

/**
 * @brief Initialize with pre-encoded bytes.
 *
 * @param encodedBytes Parse for the tag, length, and value. Each checked for
 * correctness.
 */
- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes;

/**
 * @brief Initialize with existing tag, length, and value.
 *
 * Encodes the tag, length, and value into `encodedBytes`.
 *
 * @param value checked for length matching `length.integerValue`.
 */
- (instancetype)initWithTag:(YKFOpenPGPSimpleTLVTag *)tag
                     length:(YKFOpenPGPSimpleTLVLength *)length
                      value:(NSData *)value;

- (instancetype)init NS_UNAVAILABLE;

@end

/**
 * @brief Representation of `BER-TLV`.
 *
 * Allows multi-byte tags.
 */
@interface YKFOpenPGPBERTLV : NSObject <YKFOpenPGPTLVProtocol>

+ (instancytype) withEncodedBytes:(NSData *)encodedBytes;

/**
 * @brief Initialize with pre-encoded bytes.
 *
 * @param encodedBytes Parse tag, length, and value. Each checked for
 * correctness.
 */
- (instancetype)initWithEncodedBytes:(NSData *)encodedBytes;

/**
 * @brief Initialize with existing tag, length, and value.
 *
 * @param tag Allows multi-byte tags.
 * @param length Parses  */
- (instancetype)initWithTag:(YKFOpenPGPBERTLVTag *)tag
                     length:(YKFOpenPGPBERTLVLength *)length
                      value:(NSData *)value;

- (instancetype)init NS_UNAVAILABLE;

@end
