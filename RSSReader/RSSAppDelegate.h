//
//  RSSAppDelegate.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSSViewController.h"

@interface RSSAppDelegate : UIResponder <UIApplicationDelegate>{
    
    RSSViewController *rootViewController;
}

@property (strong, nonatomic) UIWindow *window;

@end
