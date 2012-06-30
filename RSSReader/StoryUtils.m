//
//  StoryUtils.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryUtils.h"

@implementation StoryUtils

@synthesize PM = _PM;


- (void)UpdateStoryRank:(Story *)story
{   
    if(story == nil)
    {
        NSLog((@"%s [Line %d] story was null"), __PRETTY_FUNCTION__, __LINE__);
        return;
    }
    
    //Total number of feed stories
    //int numFeedStoriesTotal = [PM GetNumFeedStories:story.feedID limitedToRead:NO];
    
    //Total days since the feed's first post (on record)
    //NSDate *earliestDate = [PM GetEarliestFeedStoryCreatedDate:story.feedID];
    //int numDaysSinceFirstFeedPost = [self NumberOfDaysBetweenDate:earliestDate andSecondDate:[N SDate date]];
    
    //Total number of feed stories per day (on average) + 1 to include today's stories
    //float numFeedStoriesPerDay = (float)numFeedStoriesTotal / (numDaysSinceFirstFeedPost + 1);
    
    
    int rankFromNumDateIntervalUnitsSinceCreated;
    
    if([story.source compare:@"Twitter"] == NSOrderedSame)
    {
        int numHoursSinceCreated = [self NumberOfHoursBetweenDate:story.dateCreated andSecondDate:[NSDate date]];
        
        numHoursSinceCreated = abs(numHoursSinceCreated * 2);
        
        if(numHoursSinceCreated > 10)
            numHoursSinceCreated = 10;
        
        rankFromNumDateIntervalUnitsSinceCreated = 10-numHoursSinceCreated;
        //NSLog(@"Story: %i:%i\n%@:%@",numHoursSinceCreated,rankFromNumDateIntervalUnitsSinceCreated,story.dateCreated,[NSDate date]);
    }
    if([story.source compare:@"Facebook"] == NSOrderedSame)
    {
        int numHoursSinceCreated = [self NumberOfHoursBetweenDate:story.dateCreated andSecondDate:[NSDate date]];
        
        numHoursSinceCreated = abs(numHoursSinceCreated * 2);
        
        if(numHoursSinceCreated > 10)
            numHoursSinceCreated = 10;
        
        rankFromNumDateIntervalUnitsSinceCreated = 10-numHoursSinceCreated;
        //NSLog(@"Story: %i:%i\n%@:%@",numHoursSinceCreated,rankFromNumDateIntervalUnitsSinceCreated,story.dateCreated,[NSDate date]);
    }
    else
    {
        int numDaysSinceCreated = abs([self NumberOfDaysBetweenDate:story.dateCreated andSecondDate:[NSDate date]]);
        
        if(numDaysSinceCreated > 10)
            numDaysSinceCreated = 10;
        
        rankFromNumDateIntervalUnitsSinceCreated = 10-numDaysSinceCreated;
    }
    
    //Days since created
    //int numDaysSinceCreated = [self NumberOfDaysBetweenDate:story.dateCreated andSecondDate:[NSDate date]];
    
    story.rank = rankFromNumDateIntervalUnitsSinceCreated*2;
}

- (void)SetStoryFeedRank:(Story *)story
{
    story.feedRank = [self.PM GetFeedRankByFeedID:story.feedID];
}

- (int)NumberOfHoursBetweenDate:(NSDate *)firstDate 
                  andSecondDate:(NSDate *)secondDate
{
    NSDate *fromDate;
    NSDate *toDate;
    
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSHourCalendarUnit startDate:&fromDate
                 interval:NULL forDate:firstDate];
    [calendar rangeOfUnit:NSHourCalendarUnit startDate:&toDate
                 interval:NULL forDate:secondDate];
    
    NSDateComponents *difference = [calendar components:NSHourCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference hour];
}

- (int)NumberOfDaysBetweenDate:(NSDate *)firstDate 
                 andSecondDate:(NSDate *)secondDate
{
    NSDate *fromDate;
    NSDate *toDate;
    
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:firstDate];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:secondDate];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

- (NSString *)SaveImageAndGetPathFromURLString:(NSString *)urlStr
{
    NSURL  *url = [NSURL URLWithString:urlStr];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    NSString *filePath = @"";
    NSRange rangeOfDelimiter = [urlStr rangeOfString:@"/" options:NSBackwardsSearch];
    NSString *fileName = [urlStr substringFromIndex:rangeOfDelimiter.location+1];
    if (urlData)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];  
        //NSString *
        filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,fileName];
        [urlData writeToFile:filePath atomically:YES];
    }
    return filePath;
}


@end
