//
//  RSSAppDelegate.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSSViewController.h"
#import "FBConnect.h"

@interface RSSAppDelegate : UIResponder <UIApplicationDelegate, FBSessionDelegate>{
    
    RSSViewController *rootViewController;
    Facebook *facebook;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) Facebook *facebook;


@end
