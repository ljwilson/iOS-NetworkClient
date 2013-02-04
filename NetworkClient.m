/*
 NetworkClient.m
 
 Created by LJ Wilson on 2/3/12.
 Copyright (c) 2012 LJ Wilson. All rights reserved.
 License:
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
 and associated documentation files (the "Software"), to deal in the Software without restriction, 
 including without limitation the rights to use, copy, modify, merge, publish, distribute, 
 sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or 
 substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
 NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
 OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "NetworkClient.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

#warning Set APIKey or set to nil
NSString * const APIKey = @"YourAPIKEYGoesHere";

@implementation NetworkClient

+(void)processURLRequestWithURL:(NSString *)url
                      andParams:(NSDictionary *)params
                          block:(void (^)(id obj))block {
    
    [self processURLRequestWithURL:url andParams:params syncRequest:NO alertUserOnFailure:NO block:^(id obj) {
        block(obj);
    }];
}

+(void)processURLRequestWithURL:(NSString *)url
                      andParams:(NSDictionary *)params
                    syncRequest:(BOOL)syncRequest
                          block:(void (^)(id obj))block {
    [self processURLRequestWithURL:url andParams:params syncRequest:syncRequest alertUserOnFailure:NO block:^(id obj) {
        block(obj);
    }];
}


+(void)processURLRequestWithURL:(NSString *)url
                      andParams:(NSDictionary *)params
                    syncRequest:(BOOL)syncRequest
             alertUserOnFailure:(BOOL)alertUserOnFailure
                          block:(void (^)(id obj))block {
    
    
    
    [self processURLRequestWithURL:url andParams:params syncRequest:syncRequest alertUserOnFailure:NO customAPIKey:APIKey  block:^(id obj) {
        block(obj);
    }];
    
}

+(void)processURLRequestWithURL:(NSString *)url
                      andParams:(NSDictionary *)params
                    syncRequest:(BOOL)syncRequest
             alertUserOnFailure:(BOOL)alertUserOnFailure
                   customAPIKey:(NSString *)customAPIKey
                          block:(void (^)(id obj))block {
#warning Replace with your web service form (this class uses POST only)
    // Default url goes here, pass in a nil to use it
    if (url == nil) {
        url = @"WebServiceFormNameGoesHere";
    }
    NSMutableDictionary *newParams = [[NSMutableDictionary alloc] initWithDictionary:params];;
    
    // Check to make sure the user did in fact include an APIKey, if not - use the default
    if (customAPIKey == nil) {
        [newParams setValue:APIKey forKey:@"APIKey"];
    } else {
        [newParams setValue:customAPIKey forKey:@"APIKey"];
    }
    
#warning Replace with the base URL to your web service (using a secure connection is best for security reasons)
    NSURL *requestURL = [NSURL URLWithString:@"https://YourURLGoesHere"];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:requestURL];
    
    NSMutableURLRequest *theRequest = [httpClient requestWithMethod:@"POST" path:url parameters:newParams];
    
    AFHTTPRequestOperation *_operation = [[AFHTTPRequestOperation alloc] initWithRequest:theRequest];
    __weak AFHTTPRequestOperation *operation = _operation;
    
    [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *responseData = [operation responseData];
     	id retObj;
        NSError *error = nil;
    
        @try {
            retObj = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
        }
        @finally {
            
        }    
        
        // Check for invalid response (No Access)
        if ([retObj isKindOfClass:[NSDictionary class]]) {
            if ([[(NSDictionary *)retObj valueForKey:@"Message"] isEqualToString:@"No Access"]) {
                block(nil);
                [self handleNoAccessWithReason:[(NSDictionary *)retObj valueForKey:@"Reason"]];
            }
        } else if ([retObj isKindOfClass:[NSArray class]]) {
            if ([(NSArray *)retObj count] > 0) {
                NSDictionary *dict = [(NSArray *)retObj objectAtIndex:0];
                if ([[dict valueForKey:@"Message"] isEqualToString:@"No Access"]) {
                    block(nil);
                    [self handleNoAccessWithReason:[(NSDictionary *)retObj valueForKey:@"Reason"]];
                }
            }
        }
        block(retObj);
    }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          NSLog(@"Failed with error = %@", [NSString stringWithFormat:@"[Error]:%@",error]);
                                          block(nil);
                                          if (alertUserOnFailure) {
                                              // Let the user know something went wrong
                                              [self handleNetworkErrorWithError:operation.error];
                                          }
                                          
                                      }];
    
    [operation start];
    
    if (syncRequest) {
        // Process the request syncronously
        [operation waitUntilFinished];
    }
}

+(void)handleNetworkErrorWithError:(NSError *)error {
    NSString *errorString = [NSString stringWithFormat:@"[Error]:%@",error];
    
    // Standard UIAlert Syntax
    UIAlertView *myAlert = [[UIAlertView alloc]
                            initWithTitle:@"Connection Error"
                            message:errorString
                            delegate:nil
                            cancelButtonTitle:@"OK"
                            otherButtonTitles:nil, nil];
    
    [myAlert show];
    
}

+(void)handleNoAccessWithReason:(NSString *)reason {
    // Standard UIAlert Syntax
    UIAlertView *myAlert = [[UIAlertView alloc]
                            initWithTitle:@"No Access"
                            message:reason
                            delegate:nil
                            cancelButtonTitle:@"OK"
                            otherButtonTitles:nil, nil];
    
    [myAlert show];
    
}

@end
