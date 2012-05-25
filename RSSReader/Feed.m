//
//  Feed.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Feed.h"

@implementation Feed

@synthesize name = _name;
@synthesize url = _url;
@synthesize type = _type;
@synthesize rank = _rank;
@synthesize timesRead = _timesRead;
@synthesize feedID = _feedID;
@synthesize dateAdded = _dateAdded;
@synthesize image = _image;


- (id)init
{
    if(self = [super init])
    {
        self.name = @"";
        self.url = @"";
        self.type = 0;
        self.rank = 0;
        self.timesRead = 0;
        self.feedID = 0;
        self.dateAdded = [[NSDate alloc] init];
        self.image = @"";
    }
    
    return self;
}

- (id)initWithName:(NSString *)newName
               url:(NSString *)newUrl
              type:(int)newType
{
    self = [self init];
    
    self.name = newName;
    self.url = newUrl;
    self.type = newType;
    self.rank = 0;
    self.timesRead = 0;
    self.feedID = 0;
    self.dateAdded = [NSDate date];
    self.image = @"";
    
    return self;
}

- (id)initWithName:(NSString *)newName
               url:(NSString *)newUrl
              type:(int)newType
              rank:(int)newRank
{
    self = [self init];
    
    self.name = newName;
    self.url = newUrl;
    self.type = newType;
    self.rank = newRank;
    self.timesRead = 0;
    self.feedID = 0;
    self.dateAdded = [NSDate date];
    self.image = @"";
    
    return self;
}

- (id)initWithName:(NSString *)newName
               url:(NSString *)newUrl
              type:(int)newType
              rank:(int)newRank
         timesRead:(int)newTimesRead
            feedID:(int)newFeedID
             image:(NSString *)newImage;
{
    self = [self init];
    
    self.name = newName;
    self.url = newUrl;
    self.type = newType;
    self.rank = newRank;
    self.timesRead = newTimesRead;
    self.feedID = newFeedID;
    self.dateAdded = [NSDate date];
    self.image = newImage;
    
    return self;
}

- (NSString *)GetDebugInfo
{
    NSString *outString = @"";
    
    outString = [outString stringByAppendingFormat:@"\n    ID: %i",self.feedID];
    outString = [outString stringByAppendingFormat:@"\n    Name: %i",self.name];
    outString = [outString stringByAppendingFormat:@"\n    Url: %i",self.url];
    outString = [outString stringByAppendingFormat:@"\n    type: %i",self.type];
    outString = [outString stringByAppendingFormat:@"\n    Rank: %i",self.rank];
    outString = [outString stringByAppendingFormat:@"\n    TimesRead: %i",self.timesRead];
    outString = [outString stringByAppendingFormat:@"\n    DateAdded: %i",self.dateAdded];
    outString = [outString stringByAppendingFormat:@"\n    Image: %i",self.image];
    
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
@end
