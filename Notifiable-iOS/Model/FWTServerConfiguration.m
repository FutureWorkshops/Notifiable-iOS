//
//  FWTServerConfiguration.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 12/09/2018.
//  Copyright © 2018 Future Workshops. All rights reserved.
//

#import "FWTServerConfiguration.h"

#define kFWTServerURLKey @"kFWTServerURLKey"
#define kFWTServerAccessIdKey @"kFWTServerAccessIdKey"
#define kFWTServerSecretKeyKey @"kFWTServerSecretKeyKey"

@interface FWTServerConfiguration () <NSSecureCoding>
@end

@implementation FWTServerConfiguration

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype) initWithServerURL:(NSURL *)url
                          accessId:(NSString *)accessId
                      andSecretKey:(NSString *)secretKey {
    self = [super init];
    if (self) {
        self->_serverURL = url;
        self->_serverAccessId = accessId;
        self->_serverSecretKey = secretKey;
    }
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.serverURL forKey:kFWTServerURLKey];
    [aCoder encodeObject:self.serverAccessId forKey:kFWTServerAccessIdKey];
    [aCoder encodeObject:self.serverSecretKey forKey:kFWTServerSecretKeyKey];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    NSURL *serverURL = (NSURL *)[aDecoder decodeObjectOfClass:[NSURL class] forKey:kFWTServerURLKey];
    NSString *serverAccessId = (NSString *)[aDecoder decodeObjectOfClass:[NSString class] forKey:kFWTServerAccessIdKey];
    NSString *serverSecretKey = (NSString *)[aDecoder decodeObjectOfClass:[NSString class] forKey:kFWTServerSecretKeyKey];
    return [self initWithServerURL:serverURL accessId:serverAccessId andSecretKey:serverSecretKey];
}

@end
