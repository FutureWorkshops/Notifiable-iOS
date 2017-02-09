//
//  FWHTTPMethod.h
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#ifndef FWHTTPMethod_h
#define FWHTTPMethod_h

typedef NS_ENUM(NSUInteger, FWHTTPMethod) {
    FWHTTPMethodDELETE,
    FWHTTPMethodGET,
    FWHTTPMethodPATCH,
    FWHTTPMethodPUT,
    FWHTTPMethodPOST,
};

static inline NSString * FWHTTPMethodString(FWHTTPMethod method)
{
    switch (method) {
        case FWHTTPMethodDELETE:
            return @"DELETE";
        case FWHTTPMethodGET:
            return @"GET";
        case FWHTTPMethodPATCH:
            return @"PATCH";
        case FWHTTPMethodPUT:
            return @"PUT";
        case FWHTTPMethodPOST:
            return @"POST";
    }
}

#endif /* FWHTTPMethod_h */
