//
//  StoryDetailViewController.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story.h"
#import "RSSViewController.h"

@interface StoryDetailViewController : UIViewController {
    Story *currentStory;
    RSSViewController *parentTableView;
    NSDate *openedInstant;
    bool interceptLinks;
    bool onLocalResource;
    bool otherSiteVisited;
    NSURLRequest *initialURLPressed;
}
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnDoSomething;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelAuthor;
@property (weak, nonatomic) IBOutlet UILabel *labelBlogTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelDateCreated;
@property (weak, nonatomic) IBOutlet UILabel *labelDateRetrieved;
@property (weak, nonatomic) IBOutlet UILabel *labelRead;
@property (weak, nonatomic) IBOutlet UILabel *labelURL;
@property (weak, nonatomic) IBOutlet UITextView *textBody;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UIButton *btnForward;

- (IBAction)btnPrevious:(id)sender;
- (IBAction)btnNext:(id)sender;
- (IBAction)btnSend:(id)sender;
- (IBAction)btnActBack:(id)sender;
- (IBAction)btnActForward:(id)sender;

@property (nonatomic, strong) Story *currentStory;
@property (nonatomic, retain) RSSViewController *parentTableView;
@property (nonatomic, retain) NSDate *openedInstant;
@property bool interceptLinks;
@property bool onLocalResource;
@property bool otherSiteVisited;
@property (nonatomic, retain) NSURLRequest *initialURLPressed;

@end
