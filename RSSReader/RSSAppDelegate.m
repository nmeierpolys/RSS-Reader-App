//
//  RSSAppDelegate.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RSSAppDelegate.h"
#import "FlurryAnalytics.h"
#import "Appirater.h"
#import "FBConnect.h"

@implementation RSSAppDelegate

@synthesize window = _window;
@synthesize facebook = _facebook;

void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught" message:[exception name] exception:exception];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Set up exception handler
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    //Start Flurry session
    [FlurryAnalytics startSession:@"3MX1HFVU2NZQA2GUSK96"];
    
    //Attach Flurry to log page views on the navigation controller
    UINavigationController *navigationController = (UINavigationController *)_window.rootViewController;
    [FlurryAnalytics logAllPageViews:navigationController];
    
    
    //UITabBarController *tabController =  (UITabBarController *)[navigationController topViewController];
    
    //rootViewController = tabController.viewControllers.lastObject;
    
    [self loadFacebook];
    
    [Appirater appLaunched:YES];
    return YES;
}

- (void)loadFacebook
{
    facebook = [[Facebook alloc] initWithAppId:@"209696695817827" andDelegate:self];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"] 
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
    
    if (![facebook isSessionValid]) {
        NSArray *permissions = [[NSArray alloc] initWithObjects:
                                @"user_likes", 
                                @"read_stream",
                                nil];
        [facebook authorize:permissions];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [facebook handleOpenURL:url]; 
}

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    //[rootViewController enteringBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //[rootViewController enteringForeground];
    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
    UINavigationController *navigationController = (UINavigationController *)_window.rootViewController;
    UITabBarController *tabController =  (UITabBarController *)[navigationController topViewController];
    
    rootViewController = tabController.viewControllers.lastObject;
    [rootViewController applicationWillTerminate];
    NSLog(@"Terminating");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
