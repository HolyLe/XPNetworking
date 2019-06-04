//
//  ViewController.m
//  XPNetworking
//
//  Created by 麻小亮 on 2019/6/4.
//  Copyright © 2019 麻小亮. All rights reserved.
//

#import "ViewController.h"
#import "XPBaseRequest.h"
#import "XPBatchRequest.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    XPBaseRequest *request = [XPBaseRequest new];
    request.route = @"xx";
    request.path = @"xx";
    request.baseUrl = @"http://www.xx.com:8080";
    request.requestTimeOut = 10;
    request.diskCacheTime = 100;
    request.cacheType = XPCacheDisk | XPCacheMemory;
    request.memoryCacheTime = 100;
    
    [request startCompletionBlockWithSuccess:^(XPBaseRequest * _Nonnull request) {
        
    } failure:^(XPBaseRequest * _Nonnull request) {
        
    }];
    XPBatchRequest *batch = [[XPBatchRequest alloc] initWithRequest:@[request]];
    [batch startCompletionBlockWithSuccess:^(XPBatchRequest *batchRequest) {
        
    }]; 
    // Do any additional setup after loading the view.
}


@end
