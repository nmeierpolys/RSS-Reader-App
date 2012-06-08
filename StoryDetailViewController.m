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
@synthesize btnDoSomething;
@synthesize labelTitle;
@synthesize labelAuthor;
@synthesize textBody;
@synthesize webView;
@synthesize btnBack;
@synthesize btnForward;
@synthesize labelBlogTitle;
@synthesize labelDateCreated;
@synthesize labelDateRetrieved;
@synthesize labelRead;
@synthesize labelURL;
@synthesize currentStory;
@synthesize parentTableView;
@synthesize openedInstant;
@synthesize interceptLinks;
@synthesize onLocalResource;
@synthesize otherSiteVisited;
@synthesize initialURLPressed;

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
    
    [self DisplayLocalResource];
    self.openedInstant = [NSDate date];
    [self UpdateButtons];
    btnBack.enabled = true;
    btnForward.enabled = true;
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
    [self setBtnBack:nil];
    [self setBtnForward:nil];
    [self setBtnDoSomething:nil];
    [super viewDidUnload];
}

- (void)viewWillUnload {
    
}

- (void)DisplayLocalResource
{
    onLocalResource = YES;
    [webView loadHTMLString:currentStory.body baseURL:nil];
}

-(bool) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    bool returnVal = YES;
    if (self.interceptLinks) {
        //NSURL *url = request.URL;
        //This launches your custom ViewController, replace it with your initialization-code
        //[webView openBrowserWithUrl:url]; 
        initialURLPressed = request;
        onLocalResource = NO;
        otherSiteVisited = YES;
        returnVal = YES;
    }
    else {
        self.interceptLinks = TRUE;
        returnVal = YES;
    }
    
    return returnVal;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self UpdateButtons];
}

- (void)UpdateButtons
{
    return;
    if(webView.canGoBack || (!webView.canGoBack && !onLocalResource))
        btnBack.enabled = true;
    else
        btnBack.enabled = false;
    
    if(webView.canGoForward || (onLocalResource && otherSiteVisited))
        btnForward.enabled = true;
    else
        btnForward.enabled = false;
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
    [self UpdateButtons];
}

- (IBAction)btnNext:(id)sender 
{
    if(self.parentTableView == nil)
        return;
    
    [self.parentTableView MarkCurrentStoryAsReadWithOpenedDate:self.openedInstant];
    [parentTableView SwitchToNextStory];
    currentStory = [self.parentTableView GetSelectedStory];
    [self loadStoryToView];
    [self UpdateButtons];
}

- (IBAction)btnSend:(id)sender {
    [parentTableView sendStoryViaEmail:currentStory];
}

- (IBAction)btnActBack:(id)sender {
    if ([webView canGoBack]) {
        // There's a valid webpage to go back to, so go there
        [webView goBack];
    } else {
        // You've reached the end of the line, so reload your own data
        //[webView goBack];
        [self DisplayLocalResource];
    }
    [self UpdateButtons];
}

- (IBAction)btnActForward:(id)sender {
    if([webView canGoBack])
    {
        [webView goForward];
    } else {
        [webView loadRequest:initialURLPressed];
    }
    //[webView goForward];
    [self UpdateButtons];
}
@end
