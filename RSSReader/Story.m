//
//  Story.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"

@implementation Story

@synthesize title = _title;
@synthesize author = _author;
@synthesize body = _body;
@synthesize source = _source;
@synthesize url = _url;
@synthesize dateCreated = _dateCreated;
@synthesize dateRetrieved = _dateRetrieved;
@synthesize isRead = _isRead;
@synthesize storyID = _storyID;
@synthesize imagePath = _imagePath;
@synthesize isFavorite = _isFavorite;
@synthesize rank = _rank;
@synthesize isDirty = _isDirty;


- (id)init
{
    if(self = [super init])
    {
        [self PopulateDummyData];
    }
    
    return self;
}

- (id)initWithTitle:(NSString *)newTitle 
             author:(NSString *)newAuthor 
               body:(NSString *)newBody 
             source:(NSString *)newSource 
                url:(NSString *)newUrl 
        dateCreated:(NSDate *)newDateCreated
      dateRetrieved:(NSDate *)newDateRetrieved
             isRead:(bool)newIsRead
          imagePath:(NSString *)newImagePath
         isFavorite:(bool)newIsFavorite
               rank:(int)newRank
            isDirty:(bool)newIsDirty
{
    if(self = [super init])
    {
        self.title = newTitle;
        self.author = newAuthor;
        self.body = newBody;
        self.source = newSource;
        self.url = newUrl;
        self.dateCreated = newDateCreated;
        self.dateRetrieved = newDateRetrieved;
        self.isRead = newIsRead;
        self.imagePath = newImagePath;
        self.isFavorite = newIsFavorite;
        self.rank = newRank;
        self.isDirty = newIsDirty;
    }
    
    return self;
}

- (id)initWithID:(int)newStoryID 
           title:(NSString *)newTitle 
{
    if(self = [super init])
    {
        [self PopulateEmptyData];
        self.storyID = newStoryID;
        self.title = newTitle;
    }
    
    return self;
}

- (id)initWithEmpty
{
    if(self = [super init])
    {
        [self PopulateEmptyData];
    }
    
    return self;
}

- (id)initWithDummyInfo
{
    if(self = [super init])
    {
        [self PopulateDummyData];
    }
    
    return self;
}

- (void)PopulateDummyData
{
    self.title = @"My dummy title";
    self.author = @"Me";
    self.body = @"This is the story...";
    self.source = @"ThansCorner";
    self.url = @"http://www.thanscorner.info";
    self.body = @"This is my awesome blog post";
    self.dateCreated = [NSDate date];
    self.dateRetrieved = [[NSDate alloc] init];
    self.isRead = YES;
    self.imagePath = @"http://awesome.jpg";
    self.isFavorite = YES;
    self.rank = 15;
    self.isDirty = YES;
}

- (void)PopulateEmptyData
{
    self.title = @"";
    self.author = @"";
    self.body = @"";
    self.source = @"";
    self.url = @"";
    self.body = @"";
    self.dateCreated = [[NSDate alloc] init];
    self.dateRetrieved = [[NSDate alloc] init];
    self.isRead = NO;
    self.imagePath = @"";
    self.isFavorite = NO;
    self.rank = 0;
    self.isDirty = NO;
}

- (NSString *)GetDateCreatedString
{
    
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    return [dateFormatter stringFromDate:self.dateCreated];
}

- (NSString *)GetDateRetrievedString
{
    
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    return [dateFormatter stringFromDate:self.dateRetrieved];
}

@end
