//
//  Persistence.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Persistence.h"
#import "Story.h"
#import "NSDate+InternetDateTime.h"

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
    [self createEditableCopyOfDatabaseIfNeeded];
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
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"stories.sqlite"];
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success)
        return;
    
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"stories.sqlite"];
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

- (Story *)GetStoryFromSqlString:(NSString *)sqlStr
{
    if(sqlStr == nil)
        return nil;
    
    Story *story;
    const char *sql = [self GetSqlStringFromNSString:sqlStr];
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        if(sqlite3_step(statement) == SQLITE_ROW)
        {
            story = [[Story alloc] init];
            story.storyID = sqlite3_column_int(statement, 0);
            
            char *temp = (char *)sqlite3_column_text(statement, 1);
            if(temp != nil)
                story.title = [NSString stringWithUTF8String:temp];
            
            temp = (char *)sqlite3_column_text(statement, 2);
            if(temp != nil)
                story.author = [NSString stringWithUTF8String:temp];
            
            temp = (char *)sqlite3_column_text(statement, 3);
            if(temp != nil)
                story.body = [NSString stringWithUTF8String:temp];
            
            temp = (char *)sqlite3_column_text(statement, 4);
            if(temp != nil)
                story.source = [NSString stringWithUTF8String:temp];
            
            
            temp = (char *)sqlite3_column_text(statement, 5);
            if(temp != nil)
            {
                NSString *dateCreatedString = [NSString stringWithUTF8String:temp];
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"M dd, yyyy HH:mm:ss a"]; 
                story.dateCreated = [formatter dateFromString:dateCreatedString];
            }
            
            temp = (char *)sqlite3_column_text(statement, 6);
            if(temp != nil)
            {
                NSString *dateRetrievedString = [NSString stringWithUTF8String:temp];
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"M dd, yyyy HH:mm:ss a"]; 
                story.dateRetrieved = [formatter dateFromString:dateRetrievedString];
            }
            
            temp = (char *)sqlite3_column_text(statement, 7);
            if(temp != nil)
                story.dateRetrieved = [NSString stringWithUTF8String:temp];
            
            story.isRead = sqlite3_column_int(statement, 8);
            
            temp = (char *)sqlite3_column_text(statement, 9);
            if(temp != nil)
                story.imagePath = [NSString stringWithUTF8String:temp];
            
            story.isFavorite = sqlite3_column_int(statement, 10);
            story.rank = sqlite3_column_int(statement, 11);
            story.isDirty = sqlite3_column_int(statement, 12);
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
    
    return [self GetStoryFromSqlString:sqlStr];
}

- (bool)StoryExistsInDB:(Story *)testStory
{   
    [self initializeDatabaseIfNeeded];
    
    Story *foundStory = nil;
    
    NSString *sqlStr = [NSString stringWithFormat:
                        @"select storyID,title,author,body,source,dateCreated,dateRetrieved,isRead,imagePath,isFavorite,rank,isDirty from story where title='%@' and author='%@' and source='%@' and dateCreated = '%@'",
                        testStory.title,
                        testStory.author,
                        testStory.source,
                        testStory.GetDateCreatedString];
    
    foundStory = [self GetStoryFromSqlString:sqlStr];
    
    bool storyExists = (foundStory != nil);
    return storyExists;
}

- (void)AddStory:(Story *)newStory
{
    [self initializeDatabaseIfNeeded];
    
    NSString *sqlStr = [NSString stringWithFormat:
                        @"insert into story(title,author,body,source,dateCreated,dateRetrieved,isRead,imagePath,isFavorite,rank,isDirty) VALUES('%@','%@',?,'%@','%@','%@',%i,'%@',%i,%i,%i)",
                        newStory.title,
                        newStory.author,
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
        
        sqlite3_bind_text(statement, 1, [newStory.body UTF8String], -1, nil);
        sqlite3_step(statement);
    }
    
    sqlite3_finalize(statement);
    
    newStory = [self GetLastStory];
    if(newStory != nil)
        [self.stories addObject:newStory];
}

- (void)ClearDB
{
    [self initializeDatabaseIfNeeded];
    
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

- (void)shutItDown
{
    NSLog(@"Closing DB Connection");
    sqlite3_close(database);
    isInitialized = NO;
}








@end
