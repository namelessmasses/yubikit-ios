//
//  YKFOpenPGPErrorTests.m
//  YubiKitTests
//
//  Created by Michael Ngarimu on 12/14/24.
//  Copyright © 2024 Yubico. All rights reserved.
//


#import "YKFOpenPGPError.h"
#import "YKFTestCase.h"
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>

@interface YKFOpenPGPErrorTest : YKFTestCase

@end


@implementation YKFOpenPGPErrorTest

- (void)testErrorWithDomainAndCode {
    YKFOpenPGPError *error = [YKFOpenPGPError errorWithDomain:YKFOpenPGPErrorDomainSelectApplication code:YKFOpenPGPErrorCodeSelectedFileInvalidated];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, @"com.yubico.ykf.openpgp-session.select-application");
    XCTAssertEqual(error.code, YKFOpenPGPErrorCodeSelectedFileInvalidated);
    XCTAssertEqualObjects(error.localizedDescription, @"Selected file invalidated");
}

- (void)testErrorWithUnknownDomain {
    YKFOpenPGPError *error = [YKFOpenPGPError errorWithDomain:999 code:YKFOpenPGPErrorCodeUnknownError];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, @"com.yubico.ykf.openpgp");
    XCTAssertEqual(error.code, YKFOpenPGPErrorCodeUnknownError);
    XCTAssertEqualObjects(error.localizedDescription, @"An unknown error occurred");
}

- (void)testErrorWithCustomUserInfo {
    NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: @"Custom failure reason"};
    YKFOpenPGPError *error = [YKFOpenPGPError errorWithDomain:YKFOpenPGPErrorDomainVerifyPW1CDS code:YKFOpenPGPErrorCodeInvalidPinFormat userInfo:userInfo];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, @"com.yubico.ykf.openpgp-session.verify.pw1.cds");
    XCTAssertEqual(error.code, YKFOpenPGPErrorCodeInvalidPinFormat);
    XCTAssertEqualObjects(error.localizedDescription, @"Failed parsing PIN format");
    XCTAssertEqualObjects(error.userInfo[NSLocalizedFailureReasonErrorKey], @"Custom failure reason");
}

@end