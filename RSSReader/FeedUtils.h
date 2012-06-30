//
//  FeedUtils.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Persistence.h"

@interface FeedUtils : NSObject
{
    
}

//Properties
@property (weak, nonatomic) Persistence *PM;

//Methods
- (void)UpdateFeedRank:(Feed *)feed;
- (int)NumberOfDaysBetweenDate:(NSDate *)firstDate 
                 andSecondDate:(NSDate *)secondDate;

@end
