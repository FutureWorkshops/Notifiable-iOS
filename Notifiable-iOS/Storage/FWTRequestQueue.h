//
//  FWTRequestQueue.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 10/10/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FWTNotifiableLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface FWTRequestQueue : NSObject

@property (nonatomic, strong, nullable) id<FWTNotifiableLogger> logger;
@property (nonatomic, assign) BOOL autoSyncronize;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype) fetchInstanceWithGroupId:(NSString * _Nullable)groupId NS_SWIFT_NAME(instance(groupId:));

- (NSURLRequest * _Nullable) fetchFirst;
- (void) removeRequest:(NSURLRequest * _Nonnull)request NS_SWIFT_NAME(remove(_:));
- (void) addRequest:(NSURLRequest * _Nonnull)request NS_SWIFT_NAME(add(_:));
- (BOOL) syncronize: (NSError * __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
