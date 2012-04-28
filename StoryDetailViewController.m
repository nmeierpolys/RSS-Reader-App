//
//  StoryDetailViewController.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryDetailViewController.h"
#import "RSSViewController.h"

@implementation StoryDetailViewController
@synthesize labelTitle;
@synthesize labelAuthor;
@synthesize textBody;
@synthesize webView;
@synthesize labelBlogTitle;
@synthesize labelDateCreated;
@synthesize labelDateRetrieved;
@synthesize labelRead;
@synthesize labelURL;
@synthesize currentStory;
@synthesize parentTableView;
@synthesize openedInstant;

- (void)viewDidLoad {
    
    if(currentStory == nil)
        currentStory = [[Story alloc] init];
    [self loadStoryToView];
    //NSURL *url = [NSURL URLWithString:currentStory.url];    
    //[webView loadRequest:[NSURLRequest requestWithURL:url]];
        
    
}

- (void)loadStoryToView
{
    currentStory.title = currentStory.title;
    labelTitle.text = currentStory.title;
    labelAuthor.text = currentStory.author;
    textBody.text = currentStory.body;
    labelBlogTitle.text = currentStory.source;
    labelDateCreated.text = currentStory.GetDateCreatedString;
    labelDateRetrieved.text = currentStory.GetDateRetrievedString;
    labelURL.text = currentStory.url;
    self.title = currentStory.source;
    
    [webView loadHTMLString:currentStory.body baseURL:nil];
    self.openedInstant = [NSDate date];
}

- (void)viewDidUnload {
    [self setLabelTitle:nil];
    [self setLabelAuthor:nil];
    [self setTextBody:nil];
    [self setLabelBlogTitle:nil];
    [self setLabelDateCreated:nil];
    [self setLabelDateRetrieved:nil];
    [self setLabelRead:nil];
    [self setLabelURL:nil];
    [self setWebView:nil];
    [super viewDidUnload];
}

- (void)viewWillUnload {
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.parentTableView MarkCurrentStoryAsReadWithOpenedDate:self.openedInstant];
}

- (void)viewDidDisappear:(BOOL)animated
{
    
}

- (IBAction)btnPrevious:(id)sender 
{    
    if(self.parentTableView == nil)
        return;
    
    [self.parentTableView MarkCurrentStoryAsReadWithOpenedDate:self.openedInstant];
    [self.parentTableView SwitchToPreviousStory];
    currentStory = [self.parentTableView GetSelectedStory];
    [self loadStoryToView];
}

- (IBAction)btnNext:(id)sender 
{
    if(self.parentTableView == nil)
        return;
    
    [self.parentTableView MarkCurrentStoryAsReadWithOpenedDate:self.openedInstant];
    [parentTableView SwitchToNextStory];
    currentStory = [self.parentTableView GetSelectedStory];
    [self loadStoryToView];
}

- (IBAction)btnSend:(id)sender {
    [parentTableView sendStoryViaEmail:currentStory];
}
@end
