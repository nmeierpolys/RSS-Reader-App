//
//  FeedDetailViewController.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"
#import "FeedsViewController.h"

@interface FeedDetailViewController : UIViewController {
    Feed *detailFeed;
    FeedsViewController *parentTableView;
}

@property (retain)Feed *detailFeed;
@property (retain)FeedsViewController *parentTableView;
- (IBAction)btnAdd:(id)sender;
- (IBAction)btnClose:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *textName;
@property (weak, nonatomic) IBOutlet UITextField *textURL;
@end
