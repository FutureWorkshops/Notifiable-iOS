//
//  FWTSessionTaskDelegate.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import "FWTSessionTaskDelegate.h"

@interface FWTSessionTaskDelegate ()

@property (nonatomic, copy, readonly, nullable) FWTSessionTaskDelegateSuccessBlock success;
@property (nonatomic, copy, readonly, nullable) FWTSessionTaskDelegateFailureBlock failure;
@property (nonatomic, strong) NSMutableData *bufferData;

@end

@implementation FWTSessionTaskDelegate

@synthesize taskDescription = _taskDescription;
@synthesize success = _success;
@synthesize failure = _failure;

- (instancetype) initWithTask:(NSURLSessionTask *)task
                 successBlock:(nullable FWTSessionTaskDelegateSuccessBlock)success
                   andFailure:(nullable FWTSessionTaskDelegateFailureBlock)failure
{
    self = [super init];
    if (self) {
        self->_failure = failure;
        self->_success = success;
        task.taskDescription = self.taskDescription;
    }
    return self;
}

- (NSString *)taskDescription
{
    if (self->_taskDescription == nil) {
        self->_taskDescription = [NSString stringWithFormat:@"%p", self];
    }
    return self->_taskDescription;
}

- (void) appendData:(NSData *)data
{
    if (self.bufferData == nil) {
        self.bufferData = [[NSMutableData alloc] init];
    }
    
    [self.bufferData appendData:data];
}

- (void) extractDataFromURL:(NSURL *)contentURL
{
    NSData *data = [NSData dataWithContentsOfURL:contentURL];
    [self.bufferData setData:data];
}

- (void) finishTask:(NSURLSessionTask *)task withError:(NSError *)error
{
    NSData *fullData = [NSData dataWithData:self.bufferData];
    [self _resetData];
    if (error) {
        self.success(task, fullData);
    } else {
        self.failure(task, error);
    }
}

- (void) _resetData
{
    self.bufferData = nil;
}

@end
