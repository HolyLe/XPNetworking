//
//  XPRequestConfiguration.m
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/5/7.
//

#import "XPRequestConfiguration.h"
#if __has_include(<AFNetworking/AFSecurityPolicy.h>)
#import <AFNetworking/AFSecurityPolicy.h>
#else
#import "AFSecurityPolicy.h"
#endif
@implementation XPRequestConfiguration
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup{
    _timeOut = 15.0f;
    _validStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
    _securityPolicy = [AFSecurityPolicy defaultPolicy];
    _canPrintLog = YES;
    _autoTrimInterval = 5.0f;
}
@end
