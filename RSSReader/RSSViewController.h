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

@interface RSSViewController : UITableViewController {
    Story *tempStory;
    NSMutableArray *allEntries;
    NSMutableArray *_feeds;
    NSOperationQueue *_queue;
    Persistence *PM;
    NSDate *lowerLimitDate;
    int alwaysIncludeCount;
    int outstandingFeedsToParse;
    int selectedRow;
}

@property (weak, nonatomic) IBOutlet UIView *btnGET;
@property (weak, nonatomic) IBOutlet UITextView *textBody;
@property (weak, nonatomic) IBOutlet UITextField *textTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelCount;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;
- (IBAction)btnRefresh:(id)sender;
@property (weak, nonatomic) IBOutlet UINavigationItem *toolbar;
- (IBAction)btnRefresh:(id)sender;
- (IBAction)btnClear:(id)sender;
@property (weak, nonatomic) Persistence *PM;

@property (retain) NSMutableArray *allEntries;
@property (retain) NSMutableArray *feeds;
@property (retain) NSOperationQueue *queue;
@property (retain) NSDate *lowerLimitDate;
@property int alwaysIncludeCount;
@property int outstandingFeedsToParse;
@property int selectedRow;

- (IBAction)btnGetPressed:(id)sender;
- (void)testPopulate;
- (void)testPrint:(GDataXMLDocument *)doc;
- (void)enteringBackground;
- (void)enteringForeground;
- (Story *)GetSelectedStory;
- (void)SwitchToPreviousStory;
- (void)SwitchToNextStory;
@end
