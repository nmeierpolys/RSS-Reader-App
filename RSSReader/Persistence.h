//
//  Persistence.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Story.h"
#import "Feed.h"
#import <sqlite3.h>

@interface Persistence : NSObject {
    NSMutableArray *stories;
    NSMutableArray *feeds;
    sqlite3 *database;
    BOOL isInitialized;
}

@property (nonatomic,retain)NSMutableArray *stories;
@property (nonatomic,retain)NSMutableArray *feeds;

- (id)init;
- (void)initializeDatabase;
- (void)createEditableCopyOfDatabaseIfNeeded;
- (Story *)GetLastStory;
- (Story *)GetStoryByID:(int)storyID;
- (const char *)GetSqlStringFromNSString:(NSString *)string;
- (void)initializeDatabaseIfNeeded;
- (void)AddNew;
- (void)AddStory:(Story *)newStory;
- (Story *)AddStoryAndGetNewStory:(Story *)newStory;
- (void)ClearStories;
- (void)shutItDown;
- (bool)StoryExistsInDB:(Story *)testStory;
- (void)MarkStoryAsRead:(int)storyID;
- (bool)initializeDatabaseWithDB:(sqlite3 *)localDB;
- (NSMutableArray *)GetAllStories:(int)order;
- (void)DeleteStory:(Story *)story;
- (int)GetNumFeedStories:(int)feedID;
- (NSDate *)GetEarliestFeedStoryCreatedDate:(int)feedID;

//Feed Stuffs
- (void)AddFeed:(Feed *)newFeed;
- (Feed *)GetLastFeed;
- (Feed *)GetFeedFromStatement:(sqlite3_stmt *)statement;
- (Feed *)GetFeedByID:(int)feedID;
- (Feed *)GetFeedByURLPath:(NSString *)urlPath;
- (void)ClearFeeds;
- (void)DeleteFeed:(Feed *)feed;
- (void)SetFeedRank:(int)feedID toRank:(int)rank;
- (NSMutableArray *)GetAllFeeds;

@end
