//
//  RSSEngine.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequest.h"
#import "GDataXMLNode.h"
#import "GDataXMLElement-Extras.h"
#import "NSDate+InternetDateTime.h"
#import "Persistence.h"
#import "Feed.h"
#import "Story.h"
#import "FeedUtils.h"
#import "StoryUtils.h"

@interface RSSEngine : NSObject {
    NSMutableArray *feeds;
    NSOperationQueue *_queue;
}

//Properties
@property (weak, nonatomic) Persistence *PM;
@property bool stopLoading;
@property int numStoriesToShow;
@property int outstandingFeedsToParse;
@property int alwaysIncludeCount;
@property (weak, nonatomic) FeedUtils *feedUtils;
@property (weak, nonatomic) StoryUtils *storyUtils;
@property (retain) NSMutableArray *requests;
@property (retain) NSDate *lowerLimitDate;
@property int numDaysToShow;
//Callback properties
@property SEL selectorForLoadingIsCompleted;
@property SEL selectorForUpdatePromptText;
@property (nonatomic, retain) id caller;
@property (retain) NSDate *lastUpdated;

//Initialization + State
- (id)init;
- (id)initWithFeedUtils:(FeedUtils *)feedUtils 
          andStoryUtils:(StoryUtils *)storyUtils
                  andPM:(Persistence *)PM
         andLoadCompSel:(SEL)loadCompSel
       andUpdateProText:(SEL)updateProText
              andCaller:(id)caller;
- (bool)readyForAction;
- (void)setFeeds:(NSMutableArray *)feedsToSet;

//Asynchronous request
- (void)refresh;
- (void)requestFinished:(ASIHTTPRequest *)request;
- (void)requestFailed:(ASIHTTPRequest *)request;

//Manage feeds
- (void)addFeed:(Feed *)feed;
- (int)numFeeds;

//Ranks
- (void)UpdateFeedRank:(Feed *)feedToUpdate;
- (void)UpdateStoryRank:(Story *)storyToUpdate;

//Callbacks
- (void)updatePromptText;
- (void)loadingIsCompleted;

//Helpers
- (int)GetFeedIDFromURL:(NSURL *)url;


@end
