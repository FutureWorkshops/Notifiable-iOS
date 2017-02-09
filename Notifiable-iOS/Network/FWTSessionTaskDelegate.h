//
//  FWTSessionTaskDelegate.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FWTSessionTaskDelegateSuccessBlock)(NSURLSessionTask *task, id _Nullable responseObject);
typedef void(^FWTSessionTaskDelegateFailureBlock)(NSURLSessionTask * _Nullable task, NSError *error);

@interface FWTSessionTaskDelegate : NSObject

@property (nonatomic, strong, readonly, nonnull) NSString *taskDescription;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithTask:(NSURLSessionTask *)task
                 successBlock:(nullable FWTSessionTaskDelegateSuccessBlock)success
                   andFailure:(nullable FWTSessionTaskDelegateFailureBlock)failure;

- (void) appendData:(NSData *)data;
- (void) extractDataFromURL:(NSURL *)contentURL;
- (void) finishTask:(nullable NSURLSessionTask *)task withError:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
