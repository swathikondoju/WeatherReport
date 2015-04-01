//
//  UrlConnection.h
//  ImageSearch
//
//  Created by Swathi Kondoju on 1/18/15.
//  Copyright (c) 2015 Swathi Kondoju. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^urlCompletionBlock)(BOOL success, NSError *error, NSDictionary *responseDict);


@interface UrlConnection : NSObject <NSURLConnectionDataDelegate>
{
    NSURLConnection *urlConnection;
    NSMutableData *responseData;
}

@property (nonatomic, strong) NSURL *searchUrl;
@property(nonatomic, strong) urlCompletionBlock completionBlock;

-(UrlConnection *) initWithQuery:(NSString *)query withCompletionBlock:(urlCompletionBlock)completionBlock;
-(void) executeQuery;

@end
