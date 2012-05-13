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

@interface RSSViewController : UIPullToReloadTableViewController {
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
    NSDate *currentRangeEarliest;
    NSDate *lastUpdated;
    int currentRangeLowestRank;
    Feed *twitterFeed;
    
    TwitterEngine *twitterEngine;
    bool insertStoryLocked;
    bool hasInitialized;
    int maxAllowableStoryTimeRead;
    Story *oldestStory;
    
    bool loadingMoreStories;
}

//IBOutlets
@property (weak, nonatomic) IBOutlet UIView *btnGET;
@property (weak, nonatomic) IBOutlet UITextView *textBody;
@property (weak, nonatomic) IBOutlet UITextField *textTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelCount;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;
@property (weak, nonatomic) IBOutlet UILabel *labelLastUpdated;
@property (weak, nonatomic) IBOutlet UINavigationItem *toolbar;

//Buttons
- (IBAction)btnRefresh:(id)sender;
- (IBAction)btnRefresh:(id)sender;
- (IBAction)btnClear:(id)sender;
- (IBAction)btnReFeed:(id)sender;
- (IBAction)btnLoadMoreStories:(id)sender;
- (IBAction)btnCancelLoad:(id)sender;
- (IBAction)btnSort:(id)sender;
- (IBAction)btnSend:(id)sender;
- (IBAction)btnGetPressed:(id)sender;
- (IBAction)btnDebugInfo:(id)sender;

//Other actions
- (IBAction)swipeCellLeft:(id)sender;

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
@property (retain) NSDate *currentRangeEarliest;
@property (retain) NSDate *lastUpdated;
@property int alwaysIncludeCount;
@property int outstandingFeedsToParse;
@property int selectedRow;
@property int orderBy;
@property int numStoriesToShow;
@property int currentRangeLowestRank;
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
- (void)MarkStoryAsRead:(Story *)story withOpenedDate:(NSDate *)openedDate noRankUpdate:(bool)noRankUpdate;
- (void)MarkCurrentStoryAsReadWithOpenedDate:(NSDate *)openedDate;
- (void)sendStoryViaEmail:(Story *)storyToSend;
- (void)twitterIsDone;

//Miscellaneous methods
- (void)testPopulate;
- (void)testPrint:(GDataXMLDocument *)doc;
- (void)InitializeTwitterFeed;
- (void)sortArray;
- (void)updateArrayRanks;
- (Story *)GetSelectedStory;
- (int)GetFeedIDFromURL:(NSURL *)url;

//Asynchronous request
- (void)requestSucceeded:(NSString *)requestIdentifier;
- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error;

//- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier;
//- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)identifier;
//- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)identifier;

@end















