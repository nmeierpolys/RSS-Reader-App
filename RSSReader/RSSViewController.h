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
    NSOperationQueue *_queue;
    NSArray *_feeds;
    Persistence *PM;
    NSDate *lowerLimitDate;
    int alwaysIncludeCount;
}

@property (weak, nonatomic) IBOutlet UIView *btnGET;
@property (weak, nonatomic) IBOutlet UITextView *textBody;
@property (weak, nonatomic) IBOutlet UITextField *textTitle;
- (IBAction)btnRefresh:(id)sender;
@property (weak, nonatomic) IBOutlet UINavigationItem *toolbar;
@property (weak, nonatomic) Persistence *PM;

@property (retain) NSMutableArray *allEntries;
@property (retain) NSOperationQueue *queue;
@property (retain) NSArray *feeds;
@property (retain) NSDate *lowerLimitDate;
@property int alwaysIncludeCount;

- (IBAction)btnGetPressed:(id)sender;
- (void)testPopulate;
- (void)testPrint:(GDataXMLDocument *)doc;
- (void)enteringBackground;
- (void)enteringForeground;
@end
