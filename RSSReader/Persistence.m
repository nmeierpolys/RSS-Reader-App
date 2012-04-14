//
//  Persistence.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Persistence.h"
#import "Story.h"
#import "Feed.h"
#import "NSDate+InternetDateTime.h"

@implementation Persistence

@synthesize stories = _stories;
@synthesize feeds = _feeds;

- (id)init
{
    if(self = [super init])
    {
        [self initializeDatabase];
        self.stories = [NSMutableArray array];
        self.feeds = [NSMutableArray array];
    }
    
    return self;
}

static NSString * DatabaseLock = nil;
+ (void)initialize {
    [super initialize];
    DatabaseLock = [[NSString alloc] initWithString:@"Database-Lock"];
}
+ (NSString *)databaseLock {
    return DatabaseLock;
}

- (void)writeToDatabase1 {
    @synchronized ([Persistence databaseLock]) {
        // Code that writes to an sqlite3 database goes here...
    }
}
- (void)writeToDatabase2 {
    @synchronized ([Persistence databaseLock]) {
        // Code that writes to an sqlite3 database goes here...
    }
}

- (void)initializeDatabase 
{
    [self createEditableCopyOfDatabaseIfNeeded];
    NSLog(@"Initializing DB");
    NSMutableArray *storyArray = [[NSMutableArray alloc] init];
    self.stories = storyArray;
    
    
    NSMutableArray *feedsArray = [[NSMutableArray alloc] init];
    self.feeds = feedsArray;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"stories.sqlite"];
    
    if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) {
        isInitialized = true;
        const char *sql = "SELECT storyID FROM story ORDER BY dateCreated";
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
        
        
        sql = "SELECT feedID FROM feed ORDER BY name";
        sqlite3_stmt *statement2;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement2, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement2) == SQLITE_ROW) {
                int primaryKey = sqlite3_column_int(statement2, 0);
                
                Feed *feed = [self GetFeedByID:primaryKey];
                [self.feeds addObject:feed];
            }
        }
        
        sqlite3_finalize(statement2);
    }
    else
    {
        sqlite3_close(database);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
    }
}

- (NSMutableArray *)GetAllUnreadStories:(int)order
{
    return [self GetAllStories:order whereClause:@"isRead=0" numStories:0];
}

- (NSMutableArray *)GetTopUnreadStories:(int)order numStories:(int)numStories
{
    return [self GetAllStories:order whereClause:@"isRead=0" numStories:numStories];
}

- (NSMutableArray *)GetAllStories:(int)order
{
    return [self GetAllStories:order whereClause:@"1" numStories:0];
}

- (NSMutableArray *)GetAllStories:(int)order whereClause:(NSString *)whereString numStories:(int)numStories
{ 
    @synchronized ([Persistence databaseLock]) {
    NSMutableArray *storyArray = [[NSMutableArray alloc] init];
    
    if(whereString == nil)
        whereString = @"1";
        
    NSString *orderString;
    if(order == 0) //Date
        orderString = @"dateCreated DESC";
    else if(order == 1) //Rank
        orderString = @"rank DESC";
    else if(order == 2) //alpha;
        orderString = @"title";
    else if(order == 10) //magic;
        orderString = @"magic";
    else 
        orderString = @"storyID DESC";
        
    NSString *limitString = @"";
    if(numStories > 0)
        limitString = [NSString stringWithFormat:@"LIMIT %i",numStories]; 
    
    NSString *queryStr = [NSString stringWithFormat:@"SELECT storyID FROM story WHERE %@ ORDER BY %@ %@",whereString,orderString,limitString];
        NSLog(queryStr);
    const char *sql = [queryStr UTF8String];
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        
        //const char *temp = [orderString UTF8String];
        //sqlite3_bind_text(statement, 1, temp, -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int primaryKey = sqlite3_column_int(statement, 0);
            
            Story *story = [self GetStoryByID:primaryKey];
            [storyArray addObject:story];
        }
    }
    
    sqlite3_finalize(statement);
    
    return storyArray;
    }
}

- (NSMutableArray *)GetAllFeeds
{ 
    @synchronized ([Persistence databaseLock]) {
    NSMutableArray *feedArray = [[NSMutableArray alloc] init];
    
    NSString *queryStr = @"SELECT feedID FROM feed";
    const char *sql = [queryStr UTF8String];
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int primaryKey = sqlite3_column_int(statement, 0);
            
            Feed *feed = [self GetFeedByID:primaryKey];
            [feedArray addObject:feed];
        }
    }
    
    sqlite3_finalize(statement);
    
    return feedArray;
    }
}

- (int)GetNumFeedStories:(int)feedID limitedToRead:(bool)isRead
{ 
    @synchronized ([Persistence databaseLock]) {
        NSString *queryStr;
        if(isRead)
            queryStr = @"SELECT count(storyID) FROM story JOIN feed ON story.feedID = ? WHERE isRead=1";
        else
            queryStr = @"SELECT count(storyID) FROM story WHERE feedID = ?";
        
        const char *sql = [queryStr UTF8String];
        sqlite3_stmt *statement;
        
        int numStories = 0;
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            sqlite3_bind_int(statement, 1, feedID);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                numStories = sqlite3_column_int(statement, 0);
            }
        }
        
        sqlite3_finalize(statement);
        
        return numStories;
    }
}

- (NSDate *)GetEarliestFeedStoryCreatedDate:(int)feedID
{ 
    @synchronized ([Persistence databaseLock]) {
    NSMutableArray *storyArray = [[NSMutableArray alloc] init];
    
    NSString *queryStr = [NSString stringWithFormat:@"SELECT dateCreated FROM story WHERE feedID = ? ORDER BY dateCreated LIMIT 1"];
    const char *sql = [queryStr UTF8String];
    sqlite3_stmt *statement;
    
    NSDate *earliestDate;
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        sqlite3_bind_int(statement, 1, feedID);
        
        if (sqlite3_step(statement) == SQLITE_ROW) {
            char *temp = sqlite3_column_text(statement, 0);
            NSString *dateRetrievedString = [NSString stringWithUTF8String:temp];
            
            earliestDate = [self dateFromSQLDateString:dateRetrievedString];
        }
    }
    
    sqlite3_finalize(statement);
    
    return earliestDate;
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
    @synchronized ([Persistence databaseLock]) {
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
}

- (Story *)GetStoryByID:(int)storyID
{
    @synchronized ([Persistence databaseLock]) {
        [self initializeDatabaseIfNeeded];
        
        Story *story = nil;
        
        if(!storyID)
            return nil;
        
        NSString *sqlStr = @"select storyID,title,author,body,source,dateCreated,dateRetrieved,isRead,imagePath,isFavorite,rank,isDirty,feedID from story where storyID = ?";
        
        const char *sql = [self GetSqlStringFromNSString:sqlStr];
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            sqlite3_bind_int(statement, 1, storyID);
            story = [self GetStoryFromStatement:statement];
        }
        
        return story;
    }
}

- (Feed *)GetFeedFromStatement:(sqlite3_stmt *)statement
{
    @synchronized ([Persistence databaseLock]) {
    Feed *feed;
    
    if(sqlite3_step(statement) == SQLITE_ROW)
    {
        feed = [[Feed alloc] init];
        feed.feedID = sqlite3_column_int(statement, 0);
        
        char *temp = (char *)sqlite3_column_text(statement, 1);
        if(temp != nil)
            feed.name = [NSString stringWithUTF8String:temp];
        
        temp = (char *)sqlite3_column_text(statement, 2);
        if(temp != nil)
            feed.url = [NSString stringWithUTF8String:temp];
        
        feed.type = sqlite3_column_int(statement, 3);
        feed.rank = sqlite3_column_int(statement, 4);
        feed.timesRead = sqlite3_column_int(statement, 5);
        
        temp = (char *)sqlite3_column_text(statement, 6);
        if(temp != nil)
        {
            NSString *dateAddedString = [NSString stringWithUTF8String:temp];
            feed.dateAdded = [self dateFromSQLDateString:dateAddedString];
        }
    }
    
    sqlite3_finalize(statement);
    
    return feed;
    }
}

- (Story *)GetStoryFromStatement:(sqlite3_stmt *)statement
{
    Story *story;
    
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
            
            story.dateCreated = [self dateFromSQLDateString:dateCreatedString];
        }
        
        temp = (char *)sqlite3_column_text(statement, 6);
        if(temp != nil)
        {
            NSString *dateRetrievedString = [NSString stringWithUTF8String:temp];
            
            story.dateRetrieved = [self dateFromSQLDateString:dateRetrievedString];
        }
        
        story.isRead = sqlite3_column_int(statement, 7);
        
        temp = (char *)sqlite3_column_text(statement, 8);
        if(temp != nil)
            story.imagePath = [NSString stringWithUTF8String:temp];
        
        story.isFavorite = sqlite3_column_int(statement, 9);
        story.rank = sqlite3_column_int(statement, 10);
        story.isDirty = sqlite3_column_int(statement, 11);
        story.feedID = sqlite3_column_int(statement, 12);
    }
    
    sqlite3_finalize(statement);
    
    return story;
}

- (NSDate *)dateFromSQLDateString:(NSString *)dateString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"]; 
    return [formatter dateFromString:dateString];
}

- (Feed *)GetFeedByURLPath:(NSString *)urlPath
{
    @synchronized ([Persistence databaseLock]) {
        [self initializeDatabaseIfNeeded];
        
        Feed *feed = nil;
        
        if(!urlPath)
            return nil;
        
        NSString *sqlStr = @"select feedID,name,url,type,rank,timesRead from feed where url = ?";
        
        const char *sql = [self GetSqlStringFromNSString:sqlStr];
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            const char *temp = [urlPath UTF8String];
            sqlite3_bind_text(statement, 1, temp, -1, SQLITE_TRANSIENT);
            feed = [self GetFeedFromStatement:statement];
        }
        
        return feed;
    }
}


- (Feed *)GetFeedByID:(int)feedID
{
    @synchronized ([Persistence databaseLock]) {
    [self initializeDatabaseIfNeeded];
    
    Feed *feed = nil;
    
    if(!feedID)
        return nil;
    
    NSString *sqlStr = @"select feedID,name,url,type,rank,timesRead from feed where feedID = ?";
    
    const char *sql = [self GetSqlStringFromNSString:sqlStr];
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        sqlite3_bind_int(statement, 1, feedID);
        feed = [self GetFeedFromStatement:statement];
    }
    
    return feed;
    }
}


- (void)AddFeed:(Feed *)newFeed
{
    
    @synchronized ([Persistence databaseLock]) {
        [self initializeDatabaseIfNeeded];
        
        NSString *sqlStr = @"insert into feed(name,url,type,rank,timesRead,dateAdded) VALUES(?,?,?,?,?,?)";
        
        const char *sql = [self GetSqlStringFromNSString:sqlStr];
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            const char *temp;
            
            //Name
            temp = [newFeed.name UTF8String];
            sqlite3_bind_text(statement, 1, temp, -1, SQLITE_TRANSIENT);
            
            //URL
            temp = [newFeed.url UTF8String];
            sqlite3_bind_text(statement, 2, temp, -1, SQLITE_TRANSIENT);
            
            //Type
            sqlite3_bind_int(statement, 3, newFeed.type);
            
            //Rank
            sqlite3_bind_int(statement, 4, newFeed.rank);
            
            //TimesRead
            sqlite3_bind_int(statement, 5, newFeed.timesRead);
            
            //DateAdded
            if(newFeed.dateAdded == nil)
                temp = "(null)";
            else
            {
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                NSString *dateString=[dateFormat stringFromDate:newFeed.dateAdded];
                temp = [dateString UTF8String];
            }
            sqlite3_bind_text(statement, 6, temp, -1, SQLITE_TRANSIENT);
            
            sqlite3_step(statement);
        }
        
        sqlite3_finalize(statement);
        
        newFeed = [self GetLastFeed];
        if(newFeed != nil)
            [self.feeds addObject:newFeed];
    }
}

-(Feed *)GetLastFeed
{
    @synchronized ([Persistence databaseLock]) {
        [self initializeDatabaseIfNeeded];
        
        Feed *feed = nil;
        const char *sql = "SELECT feedID FROM feed ORDER BY feedID DESC LIMIT 1";
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            if(sqlite3_step(statement) == SQLITE_ROW)
            {
                int primaryKey = sqlite3_column_int(statement, 0);
                
                feed = [self GetFeedByID:primaryKey];
            }
        }
        
        sqlite3_finalize(statement);
        
        return feed;
    }
}


- (bool)StoryExistsInDB:(Story *)testStory
{   
    
    @synchronized ([Persistence databaseLock]) {
    [self initializeDatabaseIfNeeded];
    
    Story *foundStory = nil;
    
    NSString *sqlStr = @"select storyID,title,author,body,source,dateCreated,dateRetrieved,isRead,imagePath,isFavorite,rank,isDirty,feedID from story where title=? and author=? and source=?";
    
    
    const char *sql = [self GetSqlStringFromNSString:sqlStr];
    
    sqlite3_stmt *statement = nil;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        const char *authorString;
        
        if(testStory.author == nil)
            authorString = "(null)";
        else 
            authorString = [testStory.author UTF8String];
        
        sqlite3_bind_text(statement, 1, [testStory.title UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, authorString, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [testStory.source UTF8String], -1, SQLITE_TRANSIENT);
        
        foundStory = [self GetStoryFromStatement:statement];
    }
    
    bool storyExists = (foundStory != nil);
    return storyExists;
    }
}

- (void)AddStory:(Story *)newStory
{
    
    @synchronized ([Persistence databaseLock]) {
    [self initializeDatabaseIfNeeded];
    
    NSString *sqlStr = @"insert into story(title,author,body,source,dateCreated,dateRetrieved,isRead,imagePath,isFavorite,rank,isDirty,feedID) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)";
    
    const char *sql = [self GetSqlStringFromNSString:sqlStr];
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        const char *temp;
        
        //Title
        temp = [newStory.title UTF8String];
        sqlite3_bind_text(statement, 1, temp, -1, SQLITE_TRANSIENT);
        
        //Author
        if(newStory.author == nil)
            temp = "(null)";
        else
            temp = [newStory.author UTF8String];
        sqlite3_bind_text(statement, 2, temp, -1, SQLITE_TRANSIENT);
        
        //Body
        temp = [newStory.body UTF8String];
        sqlite3_bind_text(statement, 3, temp, -1, SQLITE_TRANSIENT);
        
        //Source
        temp = [newStory.source UTF8String];
        sqlite3_bind_text(statement, 4, temp, -1, SQLITE_TRANSIENT);
        
        //CreatedDate
        if(newStory.GetDateCreatedString == nil)
            temp = "(null)";
        else
        {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSString *dateString=[dateFormat stringFromDate:newStory.dateCreated];
            temp = [dateString UTF8String];
        }
        //Format: 2012-04-07 20:53:32  or  yyyy-MM-dd HH:mm:ss
        sqlite3_bind_text(statement, 5, temp, -1, SQLITE_TRANSIENT);
        
        //RetreivedDate
        if(newStory.GetDateRetrievedString == nil)
            temp = "(null)";
        else
        {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSString *dateString=[dateFormat stringFromDate:newStory.dateRetrieved];
            temp = [dateString UTF8String];
        }
        sqlite3_bind_text(statement, 6, temp, -1, SQLITE_TRANSIENT);
        
        //IsRead
        sqlite3_bind_int(statement, 7, newStory.isRead);
        
        //ImagePath
        temp = [newStory.title UTF8String];
        sqlite3_bind_text(statement, 8, temp, -1, SQLITE_TRANSIENT);
        
        //IsFavorite
        sqlite3_bind_int(statement, 9, newStory.isFavorite);
        
        //Rank
        sqlite3_bind_int(statement, 10, newStory.rank);
        
        //IsDirty
        sqlite3_bind_int(statement, 11, newStory.isDirty);
        
        //FeedID
        sqlite3_bind_int(statement, 12, newStory.feedID);
        
        sqlite3_step(statement);
    }
    
    sqlite3_finalize(statement);
    
    newStory = [self GetLastStory];
    if(newStory != nil)
        [self.stories addObject:newStory];
    }
}

- (Story *)AddStoryAndGetNewStory:(Story *)newStory
{
    [self AddStory:newStory];
    return [self GetLastStory];
}

- (void)MarkStoryAsRead:(int)storyID
{
    
    @synchronized ([Persistence databaseLock]) {
    [self initializeDatabaseIfNeeded];
    
    NSString *sqlStr = [@"update story set isRead=1 where storyID=" stringByAppendingFormat:@"%i",storyID];
    
    const char *sql = [self GetSqlStringFromNSString:sqlStr];
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        sqlite3_exec(database, sql, nil, nil, nil);
    }
    
    sqlite3_finalize(statement);
    }
}

- (void)SetFeedRank:(int)feedID toRank:(int)rank
{
    //NSLog(@"Feed %i to rank %i",feedID,rank);
    
    @synchronized ([Persistence databaseLock]) {
        [self initializeDatabaseIfNeeded];
        
        NSString *sqlStr = [NSString stringWithFormat:@"update feed set rank=%i where feedID=%i",rank,feedID];
        
        const char *sql = [self GetSqlStringFromNSString:sqlStr];
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            //sqlite3_bind_int(statement, 1, rank);
            //sqlite3_bind_int(statement, 2, feedID);
            sqlite3_exec(database, sql, nil, nil, nil);
        }
        
        sqlite3_finalize(statement);
    }
}

- (void)SetStoryRank:(int)storyID toRank:(int)rank
{
    @synchronized ([Persistence databaseLock]) {
        [self initializeDatabaseIfNeeded];
        
        NSString *sqlStr = [NSString stringWithFormat:@"update story set rank=%i where storyID=%i",rank,storyID];
        
        const char *sql = [self GetSqlStringFromNSString:sqlStr];
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            sqlite3_exec(database, sql, nil, nil, nil);
        }
        
        sqlite3_finalize(statement);
    }
}

- (void)ClearStories
{
    @synchronized ([Persistence databaseLock]) {
        [self initializeDatabaseIfNeeded];
        
        NSString *sqlStr = @"delete from story";
        
        const char *sql = [self GetSqlStringFromNSString:sqlStr];
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            sqlite3_exec(database, sql, nil, nil, nil);
        }
        
        sqlite3_finalize(statement);
        
        self.stories = [NSMutableArray array];
    }
}

- (void)ClearFeeds
{
    @synchronized ([Persistence databaseLock]) {
        [self initializeDatabaseIfNeeded];
        
        NSString *sqlStr = @"delete from feed";
        
        const char *sql = [self GetSqlStringFromNSString:sqlStr];
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            sqlite3_exec(database, sql, nil, nil, nil);
        }
        
        sqlite3_finalize(statement);
        
        self.feeds = [NSMutableArray array];
    }
}

- (void)DeleteFeed:(Feed *)feed
{
    @synchronized ([Persistence databaseLock]) {
        [self initializeDatabaseIfNeeded];
        
        NSString *sqlStr = @"delete from feed where feedID = ?";
        
        const char *sql = [self GetSqlStringFromNSString:sqlStr];
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            sqlite3_bind_int(statement, 0, feed.feedID);
            sqlite3_exec(database, sql, nil, nil, nil);
        }
        
        sqlite3_finalize(statement);
        
        [self.feeds removeObject:feed];
    }
}

- (void)DeleteStory:(Story *)story
{
    @synchronized ([Persistence databaseLock]) {
        [self initializeDatabaseIfNeeded];
        
        NSString *sqlStr = @"delete from story where storyID = ?";
        
        const char *sql = [self GetSqlStringFromNSString:sqlStr];
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
        {
            sqlite3_bind_int(statement, 0, story.storyID);
            sqlite3_exec(database, sql, nil, nil, nil);
        }
        
        sqlite3_finalize(statement);
        
        [self.stories removeObject:story];
    }
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
