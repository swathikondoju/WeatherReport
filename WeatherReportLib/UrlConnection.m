//
//  UrlConnection.m
//  ImageSearch
//
//  Created by Swathi Kondoju on 1/18/15.
//  Copyright (c) 2015 Swathi Kondoju. All rights reserved.
//

#import "UrlConnection.h"

@implementation UrlConnection

@synthesize searchUrl, completionBlock;

-(UrlConnection *) initWithQuery:(NSString *)query withCompletionBlock:(urlCompletionBlock)block
{
    self = [super init];
    
    if(self)
    {
        completionBlock = block;
        searchUrl = [NSURL URLWithString:query];
    }
    
    return self;
}

-(void) executeQuery
{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:searchUrl];
    urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    [urlConnection start];
}

#pragma mark - NSURLConnectionDelegate methods

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    responseData = [[NSMutableData alloc] init];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];

    if(responseDict)
    {
        completionBlock(YES, nil, responseDict);
        return;
    }
    completionBlock(NO, nil, nil);
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    completionBlock(NO, error, nil);
}

@end
