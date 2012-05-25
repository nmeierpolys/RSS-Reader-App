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
@synthesize feedID = _feedID;
@synthesize durationRead = _durationRead;
@synthesize feedRank = _feedRank;
@synthesize feedRankModifier = _feedRankModifier;


- (id)init
{
    if(self = [super init])
    {
        [self PopulateEmptyData];
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
            storyID:(int)newStoryID
             feedID:(int)newFeedID
       durationRead:(int)newDurationRead
   feedRankModifier:(int)newFeedRankModifier
{
    if(self = [super init])
    {
        self.storyID = newStoryID;
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
        self.feedID = newFeedID;
        self.durationRead = newDurationRead;
        self.feedRank = 0;
        self.feedRankModifier = feedRankModifier;
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
    self.storyID = 42;
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
    self.feedID = 0;
    self.durationRead = 0;
    self.feedRank = 0;
    self.feedRankModifier = 0;
}

- (void)PopulateEmptyData
{
    self.storyID = 0;
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
    self.feedID = 0;
    self.durationRead = 0;
    self.feedRank = 0;
    self.feedRankModifier = 0;
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

- (NSString *)IsCompleteStory
{
    NSString *missingData = @"";
    
    if(self.title == nil)
        [missingData stringByAppendingString:@"title nil"];
    if(self.title == @"")
        [missingData stringByAppendingString:@"title"];
    if(self.author == nil)
        [missingData stringByAppendingString:@"author nil"];
    if(self.author == @"")
        [missingData stringByAppendingString:@"author"];
    if(self.body == nil)
        [missingData stringByAppendingString:@"body nil"];
    if(self.body == @"")
        [missingData stringByAppendingString:@"body"];
    if(self.source == nil)
        [missingData stringByAppendingString:@"source nil"];
    if(self.source == @"")
        [missingData stringByAppendingString:@"source"];
    if(self.url == nil)
        [missingData stringByAppendingString:@"url nil"];
    if(self.url == @"")
        [missingData stringByAppendingString:@"url"];
    if(self.dateCreated == nil)
        [missingData stringByAppendingString:@"dateCreated"];
    if(self.dateRetrieved == nil)
        [missingData stringByAppendingString:@"dateRetrieved"];
    if(self.imagePath == nil)
        [missingData stringByAppendingString:@"imagePath"];
    if(self.imagePath == @"")
        [missingData stringByAppendingString:@"imagePath"];
    if(self.storyID < 1)
        [missingData stringByAppendingString:@"storyID"];
    if(self.feedID < 1)
        [missingData stringByAppendingString:@"feedID"];
    
    return missingData;
}

- (void)Print
{
    NSLog(@"%@",[self GetDebugInfo]);
}

- (NSString *)GetDebugInfo
{
    NSString *outString = @"";
    
    outString = [outString stringByAppendingFormat:@"\n    ID: %i",self.storyID];
    outString = [outString stringByAppendingFormat:@"\n    Title: %@",self.title];
    outString = [outString stringByAppendingFormat:@"\n    Author: %@",self.author];
    outString = [outString stringByAppendingFormat:@"\n    Body: %@",self.body];
    outString = [outString stringByAppendingFormat:@"\n    Source: %@",self.source];
    outString = [outString stringByAppendingFormat:@"\n    Url: %@",self.url];
    outString = [outString stringByAppendingFormat:@"\n    Created: %@",[self GetDateCreatedString]];
    outString = [outString stringByAppendingFormat:@"\n    Retrieved: %@",[self GetDateRetrievedString]];
    outString = [outString stringByAppendingFormat:@"\n    Read?: %i",self.isRead];
    outString = [outString stringByAppendingFormat:@"\n    ImagePath: %@",self.imagePath];
    outString = [outString stringByAppendingFormat:@"\n    Favorite?: %i",self.isFavorite];
    outString = [outString stringByAppendingFormat:@"\n    Rank: %i",self.rank];
    outString = [outString stringByAppendingFormat:@"\n    Dirty?: %i",self.isDirty];
    outString = [outString stringByAppendingFormat:@"\n    FeedID: %i",self.feedID];
    outString = [outString stringByAppendingFormat:@"\n    DurationRead: %i",self.durationRead];
    outString = [outString stringByAppendingFormat:@"\n    FeedRankMod: %i",self.feedRankModifier];
    
    return outString;
}
- (NSString *)description
{
    return [self GetDebugInfo];
}

- (NSString *)debugDescription
{
    return [self GetDebugInfo];
}

- (NSComparisonResult)compare:(Story *)otherObject withMode:(int)mode{
    if(mode==0)
    {
        return [self.dateCreated compare:otherObject.dateCreated];
    }
    else if(mode==1)
    {
        return ((self.rank+self.feedRank) < (otherObject.rank + otherObject.feedRank));
    }
    else 
    {
        return NSOrderedAscending;
    }
}

- (NSString *)BodyWithURLsAsLinks:(NSString *)bodyToParse;
{
    if(self.body == nil)
        return nil;
    
    NSString *regexToReplaceRawLinks;
    NSError *error;
    NSRegularExpression *regex;
    NSString *modifiedString;
    
    
    //Replace URLs
    regexToReplaceRawLinks = @"(\\b(https?):\\/\\/[-A-Z0-9+&@#\\/%?=~_|!:,.;]*[-A-Z0-9+&@#\\/%=~_|])";   
    
    error = NULL;
    regex = [NSRegularExpression regularExpressionWithPattern:regexToReplaceRawLinks
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    modifiedString = [regex stringByReplacingMatchesInString:bodyToParse
                                                               options:0
                                                                 range:NSMakeRange(0, [bodyToParse length])
                                                          withTemplate:@"<a href=\"$1\">$1</a>"];
    
    //Replace Twitter users
    regexToReplaceRawLinks = @"@([1-9a-zA-Z_]+)";
    
    
    error = NULL;
    regex = [NSRegularExpression regularExpressionWithPattern:regexToReplaceRawLinks
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:&error];
    
    modifiedString = [regex stringByReplacingMatchesInString:modifiedString
                                                     options:0
                                                       range:NSMakeRange(0, [modifiedString length])
                                                withTemplate:@"<a href=\"http://twitter.com/$1\">@$1</a>"];
    
    
    //Replace Twitter hashtags
    regexToReplaceRawLinks = @"#([1-9a-zA-Z_]+)";  
    
    error = NULL;
    regex = [NSRegularExpression regularExpressionWithPattern:regexToReplaceRawLinks
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:&error];
    
    modifiedString = [regex stringByReplacingMatchesInString:modifiedString
                                                     options:0
                                                       range:NSMakeRange(0, [modifiedString length])
                                                withTemplate:@"<a href=\"http://search.twitter.com/search?q=%23$1\">#$1</a>"];
    
    return modifiedString;
}


@end
