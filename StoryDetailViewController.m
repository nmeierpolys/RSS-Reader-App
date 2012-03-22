//
//  StoryDetailViewController.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryDetailViewController.h"

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

- (void)viewDidLoad {
    
    if(currentStory == nil)
        currentStory = [[Story alloc] init];
    
    currentStory.title = [currentStory.title stringByAppendingFormat:@"##"];
    labelTitle.text = currentStory.title;
    labelAuthor.text = currentStory.author;
    textBody.text = currentStory.body;
    labelBlogTitle.text = currentStory.source;
    labelDateCreated.text = currentStory.GetDateCreatedString;
    labelDateRetrieved.text = currentStory.GetDateRetrievedString;
    labelURL.text = currentStory.url;
    self.title = currentStory.title;
    
    [webView loadHTMLString:currentStory.body baseURL:nil];
    
    if(currentStory.isRead)
        labelRead.text = @"Read";
    else 
        labelRead.text = @"Unread";
    
    //NSURL *url = [NSURL URLWithString:currentStory.url];    
    //[webView loadRequest:[NSURLRequest requestWithURL:url]];
        
    
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
@end
