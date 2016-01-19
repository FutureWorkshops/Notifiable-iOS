//
//  FWTRequesterManager.m
//  Pods
//
//  Created by Igor Fereira on 19/01/2016.
//
//

#import "FWTRequesterManager.h"
#import "FWTHTTPRequester.h"
#import "NSError+FWTNotifiable.h"
#import "FWTNotifiableLogger.h"

@interface FWTRequesterManager ()

@property (nonatomic, strong, readonly) FWTHTTPRequester *requester;

@end

@implementation FWTRequesterManager

- (instancetype)initWithRequester:(FWTHTTPRequester *)requester
{
    return [self initWithRequester:requester retryAttempts:3 andRetryDelay:60];
}

- (instancetype)initWithRequester:(FWTHTTPRequester *)requester retryAttempts:(NSInteger)attempts andRetryDelay:(NSTimeInterval)delay
{
    self = [super init];
    if (self) {
        self->_requester = requester;
        self->_retryAttempts = attempts;
        self->_retryDelay = delay;
    }
    return self;
}

@end
