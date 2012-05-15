//
//  Feed.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Feed : NSObject {
    NSString *name;
    NSString *url;
    int feedID;
    int type;
    int rank;
    int timesRead;
    NSDate *dateAdded;
    NSString *image;
    
}

@property (retain) NSString *name;
@property (retain) NSString *url;
@property int type;
@property int rank;
@property int timesRead;
@property int feedID;
@property (nonatomic, copy) NSDate *dateAdded;
@property (retain) NSString *image;

- (id)initWithName:(NSString *)newName
               url:(NSString *)newUrl
              type:(int)newType;

- (id)initWithName:(NSString *)newName
               url:(NSString *)newUrl
              type:(int)newType
              rank:(int)newRank;
- (id)initWithName:(NSString *)newName
               url:(NSString *)newUrl
              type:(int)newType
              rank:(int)newRank
         timesRead:(int)newTimesRead
            feedID:(int)newFeedID
             image:(NSString *)newImage;

@end
