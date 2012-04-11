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
    
    return self;
}

- (id)initWithName:(NSString *)newName
               url:(NSString *)newUrl
              type:(int)newType
              rank:(int)newRank
         timesRead:(int)newTimesRead
            feedID:(int)newFeedID
{
    self = [self init];
    
    self.name = newName;
    self.url = newUrl;
    self.type = newType;
    self.rank = newRank;
    self.timesRead = newTimesRead;
    self.feedID = newFeedID;
    
    return self;
}
@end
