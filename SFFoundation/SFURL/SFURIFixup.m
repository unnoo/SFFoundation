//
//  SFURIFixup.m
//  SFFoundation
//
//  Created by v on 2019/11/4.
//  Copyright © 2019 lvv. All rights reserved.
//

#import "SFURIFixup.h"

static NSURL *punycodedURL(NSString *string) {
    if (string.length == 0) {
        return nil;
    }

    NSURLComponents *components = [NSURLComponents componentsWithString:string];

    return components.URL;
}

static NSString *replaceBrackets(NSString *url) {
    return [[url stringByReplacingOccurrencesOfString:@"[" withString:@"%5B"] stringByReplacingOccurrencesOfString:@"]" withString:@"%5D"];
}

@implementation NSCharacterSet (SFURL)

+ (instancetype)sf_URLAllowedCharacterSet {
    return [self characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=%"];
}

@end

@implementation SFURIFixup

+ (NSURL *)getURL:(NSString *)entry {
    if (entry.length == 0) {
        return nil;
    }

    NSURL *url = [NSURL URLWithString:entry];
    if (url) {
        return url;
    }

    NSString *trimmed = [entry stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *escaped = [trimmed stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.sf_URLAllowedCharacterSet];
    if (escaped.length == 0) {
        return nil;
    }

    escaped = replaceBrackets(escaped);
    url = punycodedURL(escaped);
    if (url.scheme) {
        return url;
    }

    if ([trimmed rangeOfString:@"."].length == 0) {
        return nil;
    }

    if ([trimmed rangeOfString:@" "].length > 0) {
        return nil;
    }

    url = punycodedURL([@"http://" stringByAppendingString:escaped]);
    if (!url.host) {
        return nil;
    }

    // reformat query string
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSArray<NSURLQueryItem *> *queryItems = components.queryItems;
    NSUInteger queryCount = queryItems.count;
    if (queryCount > 0) {
        NSMutableString *percentEncodedQuery = NSMutableString.string;
        for (NSUInteger i = 0; i < queryCount; i++) {
            if (i > 0) [percentEncodedQuery appendString:@"&"];

            NSURLQueryItem *queryItem = queryItems[i];
            NSString *name = [queryItem.name stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
            NSString *value = queryItem.value;
            if (value) {
                value = [queryItem.value stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
                [percentEncodedQuery appendFormat:@"%@=%@", name, value];
            } else {
                [percentEncodedQuery appendString:name];
            }
        }

        components.query = nil;
        components.percentEncodedQuery = percentEncodedQuery;
    }

    url = components.URL;

    return url;
}

@end
