//
//  FBEngine.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import "Persistence.h"
#import "Facebook.h"

@interface FBEngine : NSObject <FBSessionDelegate, FBRequestDelegate>
{
    Facebook *facebook;
    int offset;
    NSString *lastDate;
    Persistence *PM;
    SEL methodForAddingStory;
    id caller;
}


@property (nonatomic, retain) Facebook *facebook;
@property (nonatomic) int offset;
@property (nonatomic, retain) NSString *lastDate;
@property (nonatomic, retain) Persistence *PM;
@property SEL methodForAddingStory;
@property (nonatomic, retain) id caller;

- (void)loadFacebookStories;

@end
