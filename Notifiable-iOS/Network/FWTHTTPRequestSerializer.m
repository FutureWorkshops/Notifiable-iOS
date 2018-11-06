//
//  FWHTTPRequestSerializer.m
//  Notifiable-iOS
//
//  Created by Igor Fereira on 09/02/2017.
//  Copyright © 2017 Future Workshops. All rights reserved.
//

#import "FWTHTTPRequestSerializer.h"

NSString * const FWHTTPRequestSerializerQueryRegex = @"\\?([\\w-]+(=[\\w-]*)?(&[\\w-]+(=[\\w-]*)?)*)?$";

@implementation FWTHTTPRequestSerializer

- (NSURLRequest *) buildRequestWithBaseURL:(NSURL *)baseURL
                                parameters:(NSDictionary *)parameters
                                andHeaders:(NSDictionary<NSString *, NSString *> *)headers
                                 forMethod:(FWTHTTPMethod)method
{
    NSURL *finalURL = method == FWTHTTPMethodGET ? [self _getCompleteURL:baseURL withParameters:parameters] : baseURL;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:finalURL
                                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                            timeoutInterval:5000];
    [request setHTTPMethod:FWTHTTPMethodString(method)];
    [request setAllHTTPHeaderFields:headers];
    
    if (![request valueForHTTPHeaderField:@"Accept"]) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }
    
    if (parameters && parameters.allKeys.count > 0 && method != FWTHTTPMethodGET) {
        if (![request valueForHTTPHeaderField:@"Content-Type"]) {
            [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        }
        
        NSData *parameterData = [self _bodyDataForParameters:parameters];
        [request setHTTPBody:parameterData];
    }
    
    return [request copy];
}

- (nullable NSData *) _bodyDataForParameters:(NSDictionary *)parameters
{
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:parameters
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    
    if (error) {
        return nil;
    } else {
        return data;
    }
}

- (nonnull NSURL *) _getCompleteURL:(nonnull NSURL *)baseURL withParameters:(NSDictionary *)parameters
{
    NSString *queryString = [self _buildQueryStringParameter:parameters];
    if (queryString.length == 0) {
        return baseURL;
    }
    
    NSString *urlString = [baseURL absoluteString];
    NSString *junctionString = [self _junctionStringForURL:urlString];
    urlString = [urlString stringByAppendingFormat:@"%@%@",junctionString,queryString];
    
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

- (nonnull NSString *) _junctionStringForURL:(nonnull NSString *)url
{
    NSError *error = nil;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:FWHTTPRequestSerializerQueryRegex
                                                                      options:NSRegularExpressionCaseInsensitive
                                                                        error:&error];
    
    if (error) {
        return @"?";
    }
    
    NSTextCheckingResult *match = [regex firstMatchInString:url
                                                    options:NSMatchingReportCompletion
                                                      range:NSMakeRange(0, url.length)];
    if (match) {
        return @"&";
    } else {
        return @"?";
    }
    
}

- (nullable NSString *) _buildQueryStringParameter:(NSDictionary *)parameters
{
    if (parameters == nil || parameters.allKeys.count == 0) {
        return nil;
    }
    
    NSMutableArray<NSString *> *elements = [[NSMutableArray alloc] initWithCapacity:parameters.count];
    
    for (NSString *key in parameters) {
        id value = parameters[key];
        if (![value isKindOfClass:[NSString class]]) {
            continue;
        }
        
        NSString *fieldValue = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *fieldKey = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (fieldKey.length == 0 || fieldKey.length == 0) {
            continue;
        }
        
        fieldKey = [fieldKey stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        fieldValue = [fieldValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        NSString *finalString = [NSString stringWithFormat:@"%@=%@",fieldKey, fieldValue];
        [elements addObject:finalString];
    }
    
    if (elements.count == 0) {
        return nil;
    }
    
    NSString *query = [elements componentsJoinedByString:@"&"];
    return query;
}

@end
