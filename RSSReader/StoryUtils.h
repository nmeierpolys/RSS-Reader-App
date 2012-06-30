//
//  StoryUtils.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Persistence.h"

@interface StoryUtils : NSObject
{
    
}

//Properties
@property (weak, nonatomic) Persistence *PM;

//Methods
- (void)UpdateStoryRank:(Story *)story;
- (int)NumberOfHoursBetweenDate:(NSDate *)firstDate
                  andSecondDate:(NSDate *)secondDate;
- (int)NumberOfDaysBetweenDate:(NSDate *)firstDate 
                 andSecondDate:(NSDate *)secondDate;
- (void)SetStoryFeedRank:(Story *)story;
- (NSString *)SaveImageAndGetPathFromURLString:(NSString *)urlStr;

@end
