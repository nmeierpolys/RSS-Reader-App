//
//  FeedUtils.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedUtils.h"

@implementation FeedUtils

@synthesize PM = _PM;

- (void)UpdateFeedRank:(Feed *)feed
{
    if(self.PM == nil)
    {
        NSLog((@"%s [Line %d] PM was null"), __PRETTY_FUNCTION__, __LINE__);
        return;
    }
    
    if(feed == nil)
        return;
    
    int rank = 0;
    int numFeedStoriesTotal = 0;
    int numDaysSinceFirstFeedPost = 0;
    float numFeedStoriesPerDay = 0;
    int numReadStories = 0;
    int totalSecondsRead = 0;
    int sumStoryModifiers = 0;
    int avgStoryModifier = 0;
    int rankFromStoryModifier = 0;
    NSDate *earliestDate;
    
    
    if((feed.type == 1) || (feed.type == 2))
    {
        //Total number of feed stories
        numFeedStoriesTotal = [self.PM GetNumFeedStories:feed.feedID limitedToRead:NO];
        
        //Total days since the feed's first post (on record)
        earliestDate = [self.PM GetEarliestFeedStoryCreatedDate:feed.feedID];
        
        //Total number of read stories
        numReadStories = [self.PM GetNumFeedStories:feed.feedID limitedToRead:YES];
        
        totalSecondsRead = [self.PM GetTotalFeedReadTime:feed.feedID];
    }
    else if((feed.type == 3) || (feed.type == 4))
    {
        //Total number of feed stories
        numFeedStoriesTotal = [self.PM GetNumFeedStories:feed.feedID limitedToRead:NO];
        
        //Total days since the feed's first post (on record)
        earliestDate = [self.PM GetEarliestFeedStoryCreatedDate:feed.feedID];
        
        //Total number of read stories
        numReadStories = [self.PM GetNumFeedStories:feed.feedID limitedToRead:YES];
        
        totalSecondsRead = [self.PM GetTotalFeedReadTime:feed.feedID];
    }
    
    numDaysSinceFirstFeedPost = [self NumberOfDaysBetweenDate:earliestDate andSecondDate:[NSDate date]];
    
    if(numFeedStoriesTotal < 1)
        numFeedStoriesTotal = 1;
    
    //Total number of feed stories per day (on average) + 1 to include today's stories
    numFeedStoriesPerDay = (float)numFeedStoriesTotal / (numDaysSinceFirstFeedPost + 1);
    
    int rankFromNumStoriesPerDay = 0;
    if(numFeedStoriesPerDay > 0)
        rankFromNumStoriesPerDay = (int)1/numFeedStoriesPerDay;
    if(rankFromNumStoriesPerDay > 20)
        rankFromNumStoriesPerDay = 20;
    else if((rankFromNumStoriesPerDay < 1) && (rankFromNumStoriesPerDay > 0))
        rankFromNumStoriesPerDay = 1;
    
    float fractionRead;
    if(numFeedStoriesTotal > 0)
        fractionRead = (float)numReadStories / numFeedStoriesTotal;
    int rankFromFractionRead = fractionRead * 20;
    
    //Bonus for lots read
    int rankFromBonusForLotsRead = 0;
    //    if(numReadStories > 0)
    //        rankFromBonusForLotsRead = 5;
    
    //Amount of time spent reading
    int rankFromTotalSecondsRead = (totalSecondsRead / numFeedStoriesTotal) / 5;
    if(rankFromTotalSecondsRead > 50)
        rankFromTotalSecondsRead = 50;
    
    //Story Modifiers
    sumStoryModifiers = [self.PM GetTotalStoryModifiersForFeedByID:feed.feedID]*2;
    if(numFeedStoriesTotal != 0)
    {
        avgStoryModifier = sumStoryModifiers / numFeedStoriesTotal;
        rankFromStoryModifier = avgStoryModifier;
    }
    
    int oldRank = feed.rank;
    
    //Sum up rank
    feed.rank = rank + rankFromNumStoriesPerDay + rankFromFractionRead + rankFromTotalSecondsRead + rankFromStoryModifier;
    
    //Send it down to the database if necessary
    if(oldRank != feed.rank)
    {
        [self.PM SetFeedRank:feed.feedID toRank:feed.rank];
    }
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


@end
