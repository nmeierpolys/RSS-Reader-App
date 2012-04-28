//
//  TwitterEngine.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "Story.h"

@interface TwitterEngine : NSObject {
    double newestTweetID;
    double oldestTweetID;
    bool requestCompleted;
}

@property (strong, nonatomic) ACAccountStore *accountStore; 
@property (strong, nonatomic) NSArray *accounts;
@property (strong, nonatomic) id timeline;
@property bool requestCompleted;

- (id)init;
- (void)fetchData;
- (void)fetchPosts;
- (void)fetchPostsWithSelector:(SEL)selector withCaller:(id)caller count:(int)count maxID:(double)maxID;
- (void)fetchDataWithSelector:(SEL)selector withCaller:(id)caller;
- (void)fetchDataWithSelector:(SEL)selector withCaller:(id)caller count:(int)count maxID:(double)maxID;
- (void)fetchDataWithSelector:(SEL)selector withCaller:(id)caller count:(int)count;
- (void)getNextOldestTweets:(SEL)selector withCaller:(id)caller count:(int)count;
- (Story *)GetStoryFromTweet:(id)tweet;
@end
