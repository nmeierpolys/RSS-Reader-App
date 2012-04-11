//
//  FeedDetailViewController.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"
#import "FeedsTestViewController.h"

@interface FeedDetailViewController : UIViewController {
    Feed *detailFeed;
    FeedsTestViewController *parentTableView;
    Persistence *PM;
}

@property (retain)Feed *detailFeed;
@property (retain)FeedsTestViewController *parentTableView;
@property (retain)Persistence *PM;
- (IBAction)btnClose:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *textName;
@property (weak, nonatomic) IBOutlet UITextField *textURL;
@end
