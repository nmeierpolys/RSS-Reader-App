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

- (id)init
{
    if(self = [super init])
    {
        self.name = @"";
        self.url = @"";
        self.type = 0;
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
    
    return self;
}
@end
