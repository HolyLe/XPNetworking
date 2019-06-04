//
//  XPBatchRequestManager.h
//  WisdomMember
//
//  Created by 麻小亮 on 2018/7/6.
//  Copyright © 2018年 ABLE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XPBatchRequest, XPChainRequest;
@interface XPBatchRequestManager : NSObject
+ (XPBatchRequestManager *)shareManager;
- (void)addBatchRequest:(XPBatchRequest *)request;
- (void)removeRequest:(XPBatchRequest *)request;
@end
@interface XPChainRequestManager : NSObject
+ (XPChainRequestManager *)shareManager;
- (void)addChainRequest:(XPChainRequest *)request;
- (void)removeRequest:(XPChainRequest *)request;
@end
