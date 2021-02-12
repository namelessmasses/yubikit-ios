// Copyright 2018-2021 Yubico AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import "YKFPIVSession.h"
#import "YKFPIVSession+Private.h"
#import "YKFSmartCardInterface.h"
#import "YKFSelectApplicationAPDU.h"

@interface YKFPIVSession()

@property (nonatomic, readwrite) YKFSmartCardInterface *smartCardInterface;
@property (nonatomic, readonly) BOOL isValid;

@end


@implementation YKFPIVSession

+ (void)sessionWithConnectionController:(nonnull id<YKFConnectionControllerProtocol>)connectionController
                             completion:(YKFPIVSessionCompletion _Nonnull)completion {
    YKFPIVSession *session = [YKFPIVSession new];
    session.smartCardInterface = [[YKFSmartCardInterface alloc] initWithConnectionController:connectionController];
    
    YKFSelectApplicationAPDU *apdu = [[YKFSelectApplicationAPDU alloc] initWithApplicationName:YKFSelectApplicationAPDUNamePIV];
    [session.smartCardInterface selectApplication:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            completion(session, nil);
        }
    }];
}

- (void)clearSessionState {
    // Do nothing for now
}

- (void)verifyPin:(nonnull NSString *)pin completion:(nonnull YKFPIVSessionCompletionBlock)completion {
    
    NSMutableData *mutableData = [[pin dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    UInt8 padding = 0xff;
    for (int i = 0; i <= 8 - mutableData.length; i++) {
        [mutableData appendBytes:&padding length:1];
    }
    
    YKFAPDU *apdu = [[YKFAPDU alloc] initWithCla:0 ins:0x20 p1:0 p2:0x80 data:mutableData type:YKFAPDUTypeExtended];
    [self.smartCardInterface executeCommand:apdu completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        completion(error);
    }];
}

@end