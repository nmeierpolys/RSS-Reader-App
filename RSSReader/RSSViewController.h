//
//  RSSViewController.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story.h"

@interface RSSViewController : UITableViewController {
    Story *tempStory;
    NSMutableArray *allEntries;
    NSOperationQueue *_queue;
    NSArray *_feeds;
}

@property (weak, nonatomic) IBOutlet UIView *btnGET;
@property (weak, nonatomic) IBOutlet UITextView *textBody;
@property (weak, nonatomic) IBOutlet UITextField *textTitle;

@property (retain) NSMutableArray *allEntries;
@property (retain) NSOperationQueue *queue;
@property (retain) NSArray *feeds;

- (IBAction)btnGetPressed:(id)sender;
- (void)testPopulate;
@end
