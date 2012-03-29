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
}

@property (retain) NSMutableArray *feeds;
@property (nonatomic, retain) RSSViewController *parentTableView;
- (IBAction)btnClose:(id)sender;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
- (void) addFeed:(Feed *)newFeed;
- (IBAction)btnEdit:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnEditOutlet;

- (void) addFeed:(Feed *)newFeed;

@end
