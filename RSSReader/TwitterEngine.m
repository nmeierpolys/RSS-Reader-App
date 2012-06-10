//
//  TwitterEngine.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "TwitterEngine.h"

@interface TwitterEngine ()
@property (strong, nonatomic) NSCache *usernameCache;
@property (strong, nonatomic) NSCache *imageCache;
@property (strong, nonatomic) ACAccount *account;

@end

@implementation TwitterEngine

@synthesize accounts = _accounts;
@synthesize account = _account;
@synthesize accountStore = _accountStore;
@synthesize timeline = _timeline;

@synthesize imageCache = _imageCache;
@synthesize usernameCache = _usernameCache;

@synthesize requestCompleted = _requestCompleted;
@synthesize oldestTweetID = _oldestTweetID;
@synthesize completedSelector = _completedSelector;

- (id)init
{
    if(self = [super init])
    {
        _usernameCache = [[NSCache alloc] init];
        [_usernameCache setName:@"TWUsernameCache"];
        //[self fetchData];
    }
    
    return self;
}

- (id)initWithCompletedSelector:(SEL)selector
{
    if(self = [super init])
    {
        self = [self init];
        self.completedSelector = selector;
        //[self fetchData];
    }
    
    return self;
}

- (void)fetchData
{
    if (_accounts == nil) {
        if (_accountStore == nil) {
            self.accountStore = [[ACAccountStore alloc] init];
        }
        ACAccountType *accountTypeTwitter =
        [self.accountStore
         accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [self.accountStore requestAccessToAccountsWithType:accountTypeTwitter
                                     withCompletionHandler:^(BOOL granted, NSError *error) {
                                         if(granted) {
                                             dispatch_sync(dispatch_get_main_queue(), ^{
                                                 self.accounts = [self.accountStore
                                                                  accountsWithAccountType:accountTypeTwitter];
                                                 self.account = [self.accounts objectAtIndex:0];
                                                 [self fetchPosts];
                                             });
                                         }
                                     }];
    }
    else 
    {
        self.account = [self.accounts objectAtIndex:0];
        [self fetchPosts];
    }
    
}

- (void)getNextOldestTweets:(SEL)selector withCompletionHandler:(SEL)complSelector withCaller:(id)caller count:(int)count
{
    [self fetchDataWithSelector:selector withCompletionHandler:complSelector withCaller:caller count:count maxID:self.oldestTweetID];
}

- (void)fetchDataWithSelector:(SEL)selector withCompletionHandler:(SEL)complSelector withCaller:(id)caller
{
    [self fetchDataWithSelector:selector withCompletionHandler:complSelector withCaller:caller count:10 maxID:20];
}

- (void)fetchDataWithSelector:(SEL)selector withCompletionHandler:(SEL)complSelector withCaller:(id)caller count:(int)count
{
    [self fetchDataWithSelector:selector withCompletionHandler:complSelector withCaller:caller count:count maxID:0];
}

- (void)fetchDataWithSelector:(SEL)selector withCompletionHandler:(SEL)complSelector withCaller:(id)caller count:(int)count maxID:(double)maxID
{
    self.requestCompleted = false;
    if (_accounts == nil) {
        if (_accountStore == nil) {
            self.accountStore = [[ACAccountStore alloc] init];
        }
        ACAccountType *accountTypeTwitter =
        [self.accountStore
         accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [self.accountStore requestAccessToAccountsWithType:accountTypeTwitter
                                     withCompletionHandler:^(BOOL granted, NSError *error) {
                                         if(granted) {
                                             dispatch_sync(dispatch_get_main_queue(), ^{
                                                 self.accounts = [self.accountStore
                                                                  accountsWithAccountType:accountTypeTwitter];
                                                 self.account = [self.accounts objectAtIndex:0];
                                                 [self fetchPostsWithSelector:selector withCompletionHandler:complSelector withCaller:caller count:count maxID:maxID];
                                                 [caller performSelector:complSelector];
                                             });
                                         }
                                     }];
    }
    else 
    {
        self.account = [self.accounts objectAtIndex:0];
        [self fetchPostsWithSelector:selector withCompletionHandler:complSelector withCaller:caller count:count maxID:maxID];
    }
}

- (void)fetchPosts
{
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/home_timeline.json"];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"35" forKey:@"count"];
    [params setObject:@"1" forKey:@"include_rts"];
    
    TWRequest *request = [[TWRequest alloc] initWithURL:url 
                                             parameters:nil 
                                          requestMethod:TWRequestMethodGET];
    [request setAccount:self.account];    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if ([urlResponse statusCode] == 200) {
            NSError *jsonError = nil;
            id jsonResult = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
            if (jsonResult != nil) {
                self.timeline = jsonResult;
                for (int i=0; i<[self.timeline count]; i++) {
                    [self actOnTweet:[self.timeline objectAtIndex:i] count:i];
                }         
                self.requestCompleted = true;
            }
            else {
                NSString *message = [NSString stringWithFormat:@"Could not parse your timeline: %@", [jsonError localizedDescription]];
                [[[UIAlertView alloc] initWithTitle:@"Error" 
                                            message:message
                                           delegate:nil 
                                  cancelButtonTitle:@"Cancel" 
                                  otherButtonTitles:nil] show];
                self.requestCompleted = true;
            }
        }
    }];
    
}

- (void)fetchPostsWithSelector:(SEL)selector withCompletionHandler:(SEL)complSelector withCaller:(id)caller count:(int)count maxID:(double)maxID
{   
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/home_timeline.json"];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if(count > 0)
        [params setObject:[NSString stringWithFormat:@"%i",count] forKey:@"count"];
    if(maxID > 0)
        [params setObject:[NSString stringWithFormat:@"%.0f",maxID] forKey:@"max_id"];
        
    [params setObject:@"1" forKey:@"include_rts"];
    
    TWRequest *request = [[TWRequest alloc] initWithURL:url 
                                             parameters:params 
                                          requestMethod:TWRequestMethodGET];
    [request setAccount:self.account];    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if ([urlResponse statusCode] == 200) {
            NSError *jsonError = nil;
            id jsonResult = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
            if (jsonResult != nil) {
                self.timeline = jsonResult;
                
                self.requestCompleted = false;
                for (int i=0; i<[self.timeline count]; i++) {
                    if(i==[self.timeline count]-1)
                        self.requestCompleted = true;
                    
                    Story *tweetStory = [self GetStoryFromTweet:[self.timeline objectAtIndex:i]];
                    [caller performSelector:selector withObject:tweetStory];
                }
            }
            else {
                NSString *message = [NSString stringWithFormat:@"Could not parse your timeline: %@", [jsonError localizedDescription]];
                [[[UIAlertView alloc] initWithTitle:@"Error" 
                                            message:message
                                           delegate:nil 
                                  cancelButtonTitle:@"Cancel" 
                                  otherButtonTitles:nil] show];
            }
        }
        [caller performSelector:complSelector];
        self.requestCompleted = true;
    }];
}

- (void)actOnTweet:(id)tweet count:(int)count
{
//    NSString *text = [tweet objectForKey:@"text"];
//    NSString *username = [tweet valueForKeyPath:@"user.name"];
}

- (Story *)GetStoryFromTweet:(id)tweet
{
    NSString *tweetIDRaw = [tweet valueForKey:@"id"];
    double tweetID = [tweetIDRaw doubleValue];
    
    if(tweetID > newestTweetID)
        newestTweetID = tweetID;
    
    if((tweetID < self.oldestTweetID) || (oldestTweetID == 0))
        self.oldestTweetID = tweetID;
    
    NSString *body = [tweet objectForKey:@"text"];
    //NSString *username = [tweet valueForKeyPath:@"user.name"];
    NSString *userScreenName = [tweet valueForKeyPath:@"user.screen_name"];
    NSString *createdDate = [tweet valueForKey:@"created_at"];
    NSString *userImage = [tweet valueForKeyPath:@"user.profile_image_url"];
    NSString *url = [NSString stringWithFormat:@"http://twitter.com/%@/status/%@",userScreenName,tweetIDRaw];
    
    
    Story *newTweetStory = [[Story alloc] initWithEmpty];
    newTweetStory.body = [newTweetStory BodyWithURLsAsLinks:body];
    newTweetStory.author = userScreenName;
    newTweetStory.title =  body;
    newTweetStory.source = @"Twitter";
    newTweetStory.url = url;
    newTweetStory.imagePath = userImage;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
    NSDate *date = [df dateFromString:createdDate];
    newTweetStory.dateCreated = date;
    newTweetStory.dateRetrieved = [NSDate date];
    return newTweetStory;
}

@end
