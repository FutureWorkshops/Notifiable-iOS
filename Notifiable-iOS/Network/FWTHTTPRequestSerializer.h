//
//  FWHTTPRequestSerializer.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FWTHTTPMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface FWTHTTPRequestSerializer : NSObject

- (NSURLRequest *) buildRequestWithBaseURL:(NSURL *)baseURL
                                parameters:(NSDictionary *)parameters
                                andHeaders:(NSDictionary<NSString *, NSString *> *)headers
                                 forMethod:(FWTHTTPMethod)method;

@end

NS_ASSUME_NONNULL_END
