//
//  FWHTTPMethod.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#ifndef FWTHTTPMethod_h
#define FWTHTTPMethod_h

typedef NS_ENUM(NSUInteger, FWTHTTPMethod) {
    FWTHTTPMethodDELETE,
    FWTHTTPMethodGET,
    FWTHTTPMethodPATCH,
    FWTHTTPMethodPUT,
    FWTHTTPMethodPOST,
};

static inline NSString * FWTHTTPMethodString(FWTHTTPMethod method)
{
    switch (method) {
        case FWTHTTPMethodDELETE:
            return @"DELETE";
        case FWTHTTPMethodGET:
            return @"GET";
        case FWTHTTPMethodPATCH:
            return @"PATCH";
        case FWTHTTPMethodPUT:
            return @"PUT";
        case FWTHTTPMethodPOST:
            return @"POST";
    }
}

#endif /* FWHTTPMethod_h */
