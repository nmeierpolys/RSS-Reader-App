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
- (NSMutableArray *)GetAllStories:(int)order whereClause:(NSString *)whereString;
- (NSMutableArray *)GetAllStories:(int)order;
- (NSMutableArray *)GetAllUnreadStories:(int)order;
- (NSMutableArray *)GetTopUnreadStories:(int)order numStories:(int)numStories where:(NSString *)whereClause;
- (void)DeleteStory:(Story *)story;
- (int)GetNumFeedStories:(int)feedID limitedToRead:(bool)isRead;
- (int)GetNumFeedStoriesByUrl:(NSString *)url limitedToRead:(bool)isRead;
- (int)GetNumFeedStoriesBySource:(NSString *)source limitedToRead:(bool)isRead;
- (int)GetTotalFeedReadTime:(int)feedID;
- (int)GetTotalFeedReadTimeByUrl:(NSString *)url;
- (NSDate *)GetEarliestFeedStoryCreatedDate:(int)feedID;
- (NSDate *)GetEarliestFeedStoryCreatedDateByUrl:(NSString *)url;
- (void)SetStoryRank:(int)storyID toRank:(int)rank;

//Feed Stuffs
- (void)AddFeed:(Feed *)newFeed;
- (Feed *)GetLastFeed;
- (Feed *)GetFeedFromStatement:(sqlite3_stmt *)statement;
- (Feed *)GetFeedByID:(int)feedID;
- (Feed *)GetFeedByURLPath:(NSString *)urlPath;
- (int)GetFeedRankByFeedID:(int)feedID;
- (void)ClearFeeds;
- (void)DeleteFeed:(Feed *)feed;
- (void)SetFeedRank:(int)feedID toRank:(int)rank;
- (void)SetStoryDurationRead:(int)storyID toDuration:(int)duration;
- (NSMutableArray *)GetAllFeeds;

@end
