//
//  FWTRequestQueue.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 10/10/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

#import "FWTRequestQueue.h"
#import "NSUserDefaults+FWTNotifiable.h"

#define kRequestQueueBuffer         @"FWTNotifiable_FWTRequestQueue_kRequestQueueBuffer"
#define kRequestQueueAutoSyncronize @"FWTNotifiable_FWTRequestQueue_kRequestQueueAutoSyncronize"
#define kRequestQueueData           @"FWTNotifiable_FWTRequestQueue_kRequestQueueData"

@interface FWTRequestQueue () <NSSecureCoding>

@property (nonatomic, strong) NSMutableArray<NSURLRequest *> *requests;
@property (nonatomic, strong, readonly, nullable) NSString *groupId;

@end

@implementation FWTRequestQueue

#pragma mark - Storage strategy

+ (instancetype)fetchInstanceWithGroupId:(NSString *)groupId {
    NSUserDefaults *userDefaults = [NSUserDefaults userDefaultsWithGroupId:groupId];
    NSData *queueData = (NSData *)[userDefaults objectForKey:kRequestQueueData];
    
    if (queueData == nil) {
        return [[FWTRequestQueue alloc] initWithGroupId:groupId];
    }
    
    NSError *error = nil;
    FWTRequestQueue *requestQueue = nil;
    if (@available(iOS 11.0, *)) {
        requestQueue = [NSKeyedUnarchiver unarchivedObjectOfClass:[FWTRequestQueue class] fromData:queueData error:&error];
    } else {
        requestQueue = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:queueData error:&error];
    }
    
    if (requestQueue == nil || error != nil) {
        return [[FWTRequestQueue alloc] initWithGroupId:groupId];
    }

    requestQueue->_groupId = groupId;
    return requestQueue;
}

- (instancetype)initWithGroupId:(NSString *)groupId {
    self = [super init];
    if (self) {
        self->_requests = [[NSMutableArray alloc] init];
        self->_groupId = [groupId copy];
        self->_autoSyncronize = YES;
    }
    return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    NSArray *unmutableCopy = [[NSArray alloc] initWithArray:self.requests];
    NSNumber *autoSave = [NSNumber numberWithBool:self.autoSyncronize];
    [aCoder encodeObject:unmutableCopy forKey:kRequestQueueBuffer];
    [aCoder encodeObject:autoSave forKey:kRequestQueueAutoSyncronize];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        NSArray *requestArray = (NSArray *)[aDecoder decodeObjectOfClass:[NSArray class] forKey:kRequestQueueBuffer];
        NSNumber *autoSave = (NSNumber *)[aDecoder decodeObjectOfClass:[NSNumber class] forKey:kRequestQueueAutoSyncronize];
        self->_requests = [[NSMutableArray alloc] initWithArray:requestArray];
        self->_autoSyncronize = [autoSave boolValue];
    }
    return self;
}

#pragma mark - Public operation methods

- (NSURLRequest *)fetchFirst {
    return [self.requests firstObject];
}

- (void)addRequest:(NSURLRequest *)request {
    [self.requests addObject:request];
    [self _save];
}

- (void)removeRequest:(NSURLRequest *)request {
    [self.requests removeObject:request];
    [self _save];
}

- (void)moveRequestToEndOfTheQueue:(NSURLRequest *)request {
    [self.requests removeObject:request];
    [self.requests addObject:request];
    [self _save];
}

- (BOOL) syncronize: (NSError * __autoreleasing * _Nullable)error {
    NSError *innerError = nil;
    NSData *data = nil;
    if (@available(iOS 11.0, *)) {
        data = [NSKeyedArchiver archivedDataWithRootObject:self requiringSecureCoding:YES error:&innerError];
    } else {
        data = [NSKeyedArchiver archivedDataWithRootObject:self];
    }
    
    if (innerError != nil) {
        *error = innerError;
        return NO;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults userDefaultsWithGroupId:self.groupId];
    [userDefaults setObject:data forKey:kRequestQueueData];
    [userDefaults synchronize];
    
    return YES;
}

#pragma mark - Private methdos

- (void) _save {
    if (self.autoSyncronize == NO) {
        return;
    }
    
    NSError *error = nil;
    [self syncronize:&error];
    
    if (error != nil && self.logger != nil) {
        [self.logger logError:error];
    }
}

@end
