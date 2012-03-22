//
//  Persistence.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Persistence.h"
#import "Story.h"

@implementation Persistence

@synthesize stories = _stories;

- (id)init
{
    if(self = [super init])
    {
        [self initializeDatabase];
        stories = [NSMutableArray array];
        isInitialized = NO;
    }
    
    return self;
}

- (void)initializeDatabase 
{
    NSLog(@"Initializing DB");
    NSMutableArray *storyArray = [[NSMutableArray alloc] init];
    self.stories = storyArray;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"stories.sqlite"];
    
    if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) {
        isInitialized = true;
        const char *sql = "SELECT storyID FROM story";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int primaryKey = sqlite3_column_int(statement, 0);
                
                Story *story = [self GetStoryByID:primaryKey];
                [self.stories addObject:story];
            }
        }
        
        sqlite3_finalize(statement);
    }
    else
    {
        sqlite3_close(database);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
    }
}

- (void)createEditableCopyOfDatabaseIfNeeded 
{
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"todo.sqlite"];
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success)
        return;
    
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"todo.sqlite"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success)
    {
        NSAssert(0,@"Failed to create writable database file with message...");
    }
}

- (Story *)GetLastStory
{
    [self initializeDatabaseIfNeeded];
    
    Story *story = nil;
    const char *sql = "SELECT storyID FROM story ORDER BY storyID DESC LIMIT 1";
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        if(sqlite3_step(statement) == SQLITE_ROW)
        {
            int primaryKey = sqlite3_column_int(statement, 0);
            
            story = [self GetStoryByID:primaryKey];
        }
    }
    
    sqlite3_finalize(statement);
    
    return story;
}

- (Story *)GetStoryByID:(int)storyID
{
    [self initializeDatabaseIfNeeded];
    
    Story *story;
    
    if(!storyID)
        return [[Story alloc] initWithEmpty];
    
    story = nil;
    
    NSString *sqlStr = [NSString stringWithFormat:
                        @"select storyID,title,author,body,source,dateCreated,dateRetrieved,isRead,imagePath,isFavorite,rank,isDirty from story where storyID = %i",
                        storyID];
    
    const char *sql = [self GetSqlStringFromNSString:sqlStr];
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        if(sqlite3_step(statement) == SQLITE_ROW)
        {
            int primaryKey = sqlite3_column_int(statement, 0);
            NSString *title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
            NSString *author = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)];
            NSString *body = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
            NSString *source = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 4)];
            NSString *dateCreated = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 5)];
            NSString *dateRetrieved = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 6)];
            int isRead = sqlite3_column_int(statement, 7);
            NSString *imagePath = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 8)];
            int isFavorite = sqlite3_column_int(statement, 9);
            int rank = sqlite3_column_int(statement, 10);
            int isDirty = sqlite3_column_int(statement, 11);
            
            story = [[Story alloc] initWithTitle:title 
                                          author:author 
                                            body:body 
                                          source:source 
                                             url:@"" 
                                     dateCreated:[NSDate date]
                                   dateRetrieved:[NSDate date] 
                                          isRead:isRead 
                                       imagePath:imagePath 
                                      isFavorite:isFavorite 
                                            rank:rank 
                                         isDirty:isDirty];
        }
    }
    
    sqlite3_finalize(statement);
    
    return story;
}

- (void)AddStory:(Story *)newStory
{
    NSString *sqlStr = [NSString stringWithFormat:
                        @"insert into story(title,author,body,source,dateCreated,dateRetrieved,isRead,imagePath,isFavorite,rank,isDirty) VALUES('%@','%@','%@','%@','%@','%@',%i,'%@',%i,%i,%i)",
                        newStory.title,
                        newStory.author,
                        @"This is a test of the automated alert system. Beep Beep Beep",
                        newStory.source,
                        newStory.GetDateCreatedString,
                        newStory.GetDateRetrievedString,
                        newStory.isRead,
                        newStory.imagePath,
                        newStory.isFavorite,
                        newStory.rank,
                        newStory.isDirty];
    
    const char *sql = [self GetSqlStringFromNSString:sqlStr];
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        sqlite3_exec(database, sql, nil, nil, nil);
    }
    
    sqlite3_finalize(statement);
    
    newStory = [self GetLastStory];
    if(newStory != nil)
        [self.stories addObject:newStory];
    
    NSLog([NSString stringWithFormat:@"%i",self.stories.count]);
}

- (void)ClearDB
{
    NSString *sqlStr = @"delete from story";
    
    const char *sql = [self GetSqlStringFromNSString:sqlStr];
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        sqlite3_exec(database, sql, nil, nil, nil);
    }
    
    sqlite3_finalize(statement);
    
    stories = [NSMutableArray array];
}


- (void)AddNew
{
    Story *newStory = [[Story alloc] initWithEmpty];
    newStory.title = @"AAAA";
    newStory.author = @"BBB";
    newStory.isRead = 1;
    [self AddStory:newStory];
}

- (const char *)GetSqlStringFromNSString:(NSString *)string
{
    const char *sql = [string cStringUsingEncoding:NSUTF8StringEncoding];
    return sql;
}

- (void)initializeDatabaseIfNeeded
{
    if(!isInitialized)
        [self initializeDatabase];
}









@end
