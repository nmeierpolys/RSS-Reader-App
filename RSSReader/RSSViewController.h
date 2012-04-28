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
}

@property (weak, nonatomic) IBOutlet UIView *btnGET;
@property (weak, nonatomic) IBOutlet UITextView *textBody;
@property (weak, nonatomic) IBOutlet UITextField *textTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelCount;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;
@property (weak, nonatomic) IBOutlet UILabel *labelLastUpdated;
@property (weak, nonatomic) IBOutlet UINavigationItem *toolbar;
- (IBAction)btnRefresh:(id)sender;
- (IBAction)btnRefresh:(id)sender;
- (IBAction)btnClear:(id)sender;
- (IBAction)btnReFeed:(id)sender;
- (IBAction)btnLoadMoreStories:(id)sender;
- (IBAction)btnCancelLoad:(id)sender;
- (IBAction)btnSort:(id)sender;
- (IBAction)btnSend:(id)sender;
@property (weak, nonatomic) Persistence *PM;
@property (strong, nonatomic) Feed *twitterFeed;
@property (weak, nonatomic) TwitterEngine *twitterEngine;

@property (retain) NSMutableArray *allEntries;
@property (retain) NSMutableArray *feeds;
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
@property bool stopLoading;

- (IBAction)btnGetPressed:(id)sender;
- (void)testPopulate;
- (void)testPrint:(GDataXMLDocument *)doc;
- (void)enteringBackground;
- (void)enteringForeground;
- (Story *)GetSelectedStory;
- (void)SwitchToPreviousStory;
- (void)SwitchToNextStory;
- (int)GetFeedIDFromURL:(NSURL *)url;
- (void)InitializeTwitterFeed;
- (void)sortArray;
- (void)updateArrayRanks;

- (void)requestSucceeded:(NSString *)requestIdentifier;
- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error;
- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier;
- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)identifier;
- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)identifier;
- (void)applicationWillTerminate;
- (void)MarkStoryAsRead:(Story *)story withOpenedDate:(NSDate *)openedDate;
- (void)MarkCurrentStoryAsReadWithOpenedDate:(NSDate *)openedDate;
-(void)sendStoryViaEmail:(Story *)storyToSend;
@end
