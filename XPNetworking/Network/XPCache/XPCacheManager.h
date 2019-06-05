//
//  XPCacheManager.h
//  XPRequestNetWork
//
//  Created by 麻小亮 on 2018/6/6.
//

#import <Foundation/Foundation.h>
#define Weak  __weak __typeof(self) weakSelf = self
typedef NS_ENUM(NSUInteger, XPCacheType) {
    XPCacheDisk = 1,
    XPCacheMemory
};

typedef NS_OPTIONS(NSUInteger,XPCacheResultStatus) {
    XPCacheResultNever         = 0,
    XPCacheResultNormarl       = 1 << 0,
    XPCacheResultMemoryTimeOut = 1 << 1,
    XPCacheResultDiskTimeOut   = 1 << 2,
    XPCacheResultAll           = ~0UL
};

typedef NS_ENUM(NSInteger,XPDataPosition) {
    XPDataNonContain = 0,
    XPDataMemoryContain,
    XPDataDiskContain
};
typedef void(^XPCacheResultBlock)(XPCacheResultStatus status, id data);
typedef void(^XPCacheManagerResultBlock)(XPCacheResultStatus status, NSInteger tag);
@interface XPCacheObject : NSObject<NSCoding>
@property (nonatomic, assign) XPCacheType  cacheType;
@property (nonatomic, assign) BOOL  isClearWhenDiskTimeOut;
@property (nonatomic, assign) NSTimeInterval  memoryTime;
@property (nonatomic, assign) NSTimeInterval  diskTime;
@end
@protocol XPCacheManagerDelegate <NSObject>
- (void)xp_cacheWillRemoveFromMemory:(NSString *)key;
- (void)xp_cacheWillRemoveFromDisk:(NSString *)key;
- (void)xp_cacheWillSaveMemoryIn:(NSString *)key data:(id)data;
- (void)xp_cacheWillSaveDiskIn:(NSString *)key data:(id)data;
- (void)xp_cacheUpdata;
- (void)xp_cacheRemoveAllDiskCache;
- (void)xp_cacheRemoveAllMemoryCache;
@end

@interface XPCacheManager : NSObject

@property (nonatomic, weak) id <XPCacheManagerDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableDictionary <NSString *, XPCacheObject *> * diskData;
- (void)start;
- (void)addObject:(XPCacheObject *)object withKey:(NSString *)key data:(id <NSCoding>)data;
- (void)removeObjectForKey:(NSString *)key;

/**
 返回状态

 @param key 键值
 @param cacheResult 查询的状态
 @return 0：都不包含 1.从memory取  2.从disk取并添加至memory
 */
- (XPDataPosition)objectForKey:(NSString *)key cacheResult:(XPCacheResultStatus)cacheResult;

- (void)objectForKey:(NSString *)key resultBlock:(XPCacheManagerResultBlock)block;

- (XPDataPosition)objectForKey:(NSString *)key newObject:(XPCacheObject *)object cacheResult:(XPCacheResultStatus)cacheResult result:(void (^)(XPCacheResultStatus))status;

- (BOOL)containObjectKey:(NSString *)key resultStatus:(XPCacheResultStatus)status;

- (void)removeAllCache;
@end
