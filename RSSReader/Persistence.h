//
//  Persistence.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Story.h"
#import <sqlite3.h>

@interface Persistence : NSObject {
    NSMutableArray *stories;
    sqlite3 *database;
    BOOL isInitialized;
}

@property (nonatomic,retain)NSMutableArray *stories;

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
- (void)ClearDB;
- (void)shutItDown;
- (bool)StoryExistsInDB:(Story *)testStory;
- (void)MarkStoryAsRead:(int)storyID;
- (bool)initializeDatabaseWithDB:(sqlite3 *)localDB;

@end
