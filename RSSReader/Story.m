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
@synthesize read = _read;

- (id)init
{
    if(self = [super init])
    {
        [self PopulateDummyData];
        //[self PopulateEmptyData];
    }
    
    return self;
}

- (id)initWithTitle:(NSString *)newTitle 
             author:(NSString *)newAuthor 
               body:(NSString *)newBody 
             source:(NSString *)newSource 
                url:(NSString *)newUrl 
        dateCreated:(NSDate *)newDateCreated
               read:(bool)newRead
{
    if(self = [super init])
    {
        self.title = newTitle;
        self.author = newAuthor;
        self.body = newBody;
        self.source = newSource;
        self.url = newUrl;
        self.dateCreated = newDateCreated;
        self.dateRetrieved = [[NSDate alloc] init];
        self.read = newRead;
    }
    
    return self;
}

- (void)PopulateDummyData
{
    self.title = @"My title";
    self.author = @"Me";
    self.body = @"This is the story...";
    self.source = @"ThansCorner";
    self.url = @"http://www.thanscorner.info";
    self.dateCreated = [[NSDate alloc] init];
    self.dateRetrieved = [[NSDate alloc] init];
    self.read = NO;
}

- (void)PopulateEmptyData
{
    self.title = @"";
    self.author = @"";
    self.body = @"";
    self.source = @"";
    self.url = @"";
    self.dateCreated = [[NSDate alloc] init];
    self.dateRetrieved = [[NSDate alloc] init];
    self.read = NO;
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
