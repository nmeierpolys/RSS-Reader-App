//
//  RSSViewController.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story.h"
#import "GDataXMLNode.h"
#import "Persistence.h"
#import "UIPullToReloadTableViewController.h"
#import "TwitterEngine.h"
#import "FBConnect.h"
#import "ASIHTTPRequest.h"

@interface RSSViewController : UIPullToReloadTableViewController <FBSessionDelegate> {
    Story *tempStory;
    NSMutableArray *allEntries;
    NSMutableArray *_feeds;
    NSMutableArray *requests;
    NSOperationQueue *_queue;
    Persistence *PM;
    NSDate *lowerLimitDate;
    int alwaysIncludeCount;
    int outstandingFeedsToParse;
    int selectedRow;
    int orderBy;
    int numStoriesToShow;
    int numDaysToShow;
    bool stopLoading;
    NSDate *lastUpdated;
    int currentRangeLowestRank;
    Feed *twitterFeed;
    
    TwitterEngine *twitterEngine;
    bool insertStoryLocked;
    bool hasInitialized;
    int maxAllowableStoryTimeRead;
    Story *oldestStory;
    
    bool loadingMoreStories;
    Facebook *facebook;
}

//IBOutlets
@property (weak, nonatomic) IBOutlet UILabel *labelCount;
@property (weak, nonatomic) IBOutlet UILabel *labelLastUpdated;
@property (weak, nonatomic) IBOutlet UINavigationItem *toolbar;
@property (nonatomic, retain) Facebook *facebook;

//Buttons
- (IBAction)btnRefresh:(id)sender;
- (IBAction)btnClear:(id)sender;
- (IBAction)btnReFeed:(id)sender;
- (IBAction)btnLoadMoreStories:(id)sender;
- (IBAction)btnSort:(id)sender;
- (IBAction)btnSend:(id)sender;
- (IBAction)btnDebugInfo:(id)sender;

//Other actions
//- (IBAction)swipeCellLeft:(id)sender;

//Properties
@property (strong, nonatomic) Feed *twitterFeed;
@property (weak, nonatomic) Persistence *PM;
@property (weak, nonatomic) TwitterEngine *twitterEngine;
@property (weak, nonatomic) Story *oldestStory;
@property (retain) NSMutableArray *allEntries;
@property (retain) NSMutableArray *feeds;
@property (retain) NSMutableArray *requests;
@property (retain) NSOperationQueue *queue;
@property (retain) NSDate *lowerLimitDate;
@property (retain) NSDate *lastUpdated;
@property int alwaysIncludeCount;
@property int outstandingFeedsToParse;
@property int selectedRow;
@property int orderBy;
@property int numStoriesToShow;
@property int numDaysToShow;
@property int maxAllowableStoryTimeRead;
@property bool stopLoading;
@property bool loadingMoreStories;

//Events
- (void)enteringBackground;
- (void)enteringForeground;
- (void)applicationWillTerminate;

//Story management
- (void)SwitchToPreviousStory;
- (void)SwitchToNextStory;
- (void)MarkStoryAsRead:(Story *)story atIndexPath:(NSIndexPath *)indexPath withOpenedDate:(NSDate *)openedDate noRankUpdate:(bool)noRankUpdate;
- (void)MarkCurrentStoryAsReadWithOpenedDate:(NSDate *)openedDate;
- (void)sendStoryViaEmail:(Story *)storyToSend;
- (void)twitterIsDone;

//Miscellaneous methods
- (void)InitializeTwitterFeed;
- (void)sortArray;
- (void)updateArrayRanks;
- (Story *)GetSelectedStory;
- (int)GetFeedIDFromURL:(NSURL *)url;

//Asynchronous request
- (void)requestFinished:(ASIHTTPRequest *)request;
- (void)requestFailed:(ASIHTTPRequest *)request;

@end















