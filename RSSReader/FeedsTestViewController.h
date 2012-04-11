//
//  FeedsViewController.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSSViewController.h"
#import "Feed.h"

@interface FeedsTestViewController : UITableViewController {
    NSMutableArray *feeds;
    RSSViewController *parentTableView;
    Persistence *PM;
}

@property (retain) NSMutableArray *feeds;
@property (nonatomic, retain) RSSViewController *parentTableView;
@property (nonatomic, retain) Persistence *PM;
- (void) addFeed:(Feed *)newFeed;
- (IBAction)btnEdit:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnEditOutlet;

- (void) addFeed:(Feed *)newFeed;

@end
