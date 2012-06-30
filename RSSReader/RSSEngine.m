//
//  RSSEngine.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RSSEngine.h"

@implementation RSSEngine

@synthesize PM = _PM;
@synthesize stopLoading = _stopLoading;
@synthesize numStoriesToShow = _numStoriesToShow;
@synthesize outstandingFeedsToParse = _outstandingFeedsToParse;
@synthesize alwaysIncludeCount = _alwaysIncludeCount;
@synthesize feedUtils = _feedUtils;
@synthesize storyUtils = _storyUtils;
@synthesize lowerLimitDate = _lowerLimitDate;
@synthesize selectorForLoadingIsCompleted = _selectorForLoadingIsCompleted;
@synthesize selectorForUpdatePromptText = _selectorForUpdatePromptText;
@synthesize caller = _caller;
@synthesize requests = _requests;
@synthesize lastUpdated = _lastUpdated;
@synthesize numDaysToShow = _numDaysToShow;

- (id)init
{
    if(self = [super init])
    {
        self.feedUtils = [[FeedUtils alloc] init];
        self.storyUtils = [[StoryUtils alloc] init];
        _queue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (id)initWithFeedUtils:(FeedUtils *)feedUtils 
          andStoryUtils:(StoryUtils *)storyUtils
                  andPM:(Persistence *)PM
         andLoadCompSel:(SEL)loadCompSel
       andUpdateProText:(SEL)updateProText
              andCaller:(id)caller
{
    if([self init] != nil)
    {
        self.feedUtils = feedUtils;
        self.storyUtils = storyUtils;
        self.PM = PM;
        self.selectorForLoadingIsCompleted = loadCompSel;
        self.selectorForUpdatePromptText = updateProText;
        self.caller = caller;
    }
    return self;
}

- (bool)readyForAction
{
    if(self.feedUtils == nil) return NO;
    if(self.storyUtils == nil) return NO;
    if(self.PM == nil) return NO;
    if(self.selectorForLoadingIsCompleted == nil) return NO;
    if(self.selectorForUpdatePromptText == nil) return NO;
    
    return YES;
}

- (void)refresh {
    
    if(![self readyForAction])
    {
        NSLog(@"Not ready in time for refresh");
        return;
    }
    //Update lastUpdated property
    self.lastUpdated = [NSDate date];
    [self cancelParsing];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //Set earliest date to pick up stories from
        self.lowerLimitDate = [NSDate dateWithTimeIntervalSinceNow:-1*60*60*24*self.numDaysToShow];
        bool nonTwitterFeedsFound = false;
        
        //Kick off request for each feed
        for (Feed *feed in feeds) {
            if(feed.type != 2)
            {
                nonTwitterFeedsFound = true;
                self.outstandingFeedsToParse++;
                NSURL *url = [NSURL URLWithString:feed.url];
                ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
                [request setDelegate:self];
                [self.requests addObject:request];
                [_queue addOperation:request];
            }
        } 
    }];
}

- (void)cancelParsing
{
    for(ASIHTTPRequest *request in self.requests)
    {
        [request cancel];
    }
    self.outstandingFeedsToParse = 0;
    self.stopLoading = false;
    self.requests = [NSMutableArray array];
}

- (void)requestFinished:(ASIHTTPRequest *)request 
{
    int blogID = 1;
    blogID = [self GetFeedIDFromURL:[request url]];
    NSError *error;
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:[request responseData] 
                                                           options:0 error:&error];
    
    if(!self.stopLoading)
    {
        if (doc == nil) {
            //NSLog(@"Failed to parse %@", request.url);
        } else {
            NSMutableArray *entries = [[NSMutableArray alloc] init];
            [self parseFeed:doc.rootElement entries:entries blogID:blogID];                
            
            Feed *thisFeed = [self.PM GetFeedByID:blogID];
            [self UpdateFeedRank:thisFeed];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                for (Story *entry in entries) {
                    
                    [self.caller performSelectorOnMainThread:@selector(insertOrderedStoryWithAnimation:) withObject:entry waitUntilDone:YES];
                    
                    //[self insertOrderedStoryWithAnimation:entry];
                }  
                [self UpdateFeedRank:thisFeed];
            }];
        }
        
        self.outstandingFeedsToParse--;
        
        //if(self.outstandingFeedsToParse < 1)
        //{
//            self.twitterEngine.requestCompleted = false;
//            if(self.loadingMoreStories)
//            {
//                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    [twitterEngine getNextOldestTweets:@selector(AddTweetAsStory:) withCompletionHandler:@selector(TweetRetrievalCompleted) withCaller:self count:50];
//                    self.loadingMoreStories = false;
//                }];
//            }
//            else
//            {
//                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    [self refreshTwitter];
//                }];
//            }
        //}
        //else 
        //{
        [self loadingIsCompleted];
        //}
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    
    //NSError *error = [request error];
    self.outstandingFeedsToParse--;
}

- (void)parseFeed:(GDataXMLElement *)rootElement entries:(NSMutableArray *)entries blogID:(int)blogID {   
    if ([rootElement.name compare:@"rss"] == NSOrderedSame) {
        [self parseRss:rootElement entries:entries blogID:blogID];
    } else if ([rootElement.name compare:@"feed"] == NSOrderedSame) {                       
        [self parseAtom:rootElement entries:entries blogID:blogID];
    } else {
        NSLog(@"Unsupported root element: %@", rootElement.name);
    }    
}

- (void)parseRss:(GDataXMLElement *)rootElement 
         entries:(NSMutableArray *)entries 
          blogID:(int)blogID{
    
    NSArray *channels = [rootElement elementsForName:@"channel"];
    for (GDataXMLElement *channel in channels) {            
        //NSLog(@"--%i",blogID);
        NSString *blogTitle = [channel valueForChild:@"title"];                    
        
        NSArray *items = [channel elementsForName:@"item"];
        int storyCount = 0;
        for (GDataXMLElement *item in items) {
            storyCount++;
            Story *entry = [self parseItemToStory:item 
                                    withBlogTitle:blogTitle 
                                         itemType:1 
                                    alwaysInclude:(storyCount < self.alwaysIncludeCount)
                                           blogID:blogID];
            if(entry == nil)
                return;
            
            bool storyExists = [self.PM StoryExistsInDB:entry];
            
            if(!storyExists)
            {
                [self UpdateStoryRank:entry];
                entry = [self.PM AddStoryAndGetNewStory:entry];
                if(entry != nil)
                    [entries addObject:entry];
            }
        }      
    }
    
}

- (void)parseAtom:(GDataXMLElement *)rootElement 
          entries:(NSMutableArray *)entries 
           blogID:(int)blogID
{
    
    NSString *blogTitle = [rootElement valueForChild:@"title"];                    
    
    NSArray *items = [rootElement elementsForName:@"entry"];
    int storyCount = 0;
    for (GDataXMLElement *item in items) {
        storyCount++;
        Story *entry = [self parseItemToStory:item 
                                withBlogTitle:blogTitle 
                                     itemType:2 
                                alwaysInclude:(storyCount < self.alwaysIncludeCount)
                                       blogID:blogID];
        if(entry == nil)
            return;
        
        bool storyExists = [self.PM StoryExistsInDB:entry];
        if(!storyExists)
        {
            entry = [self.PM AddStoryAndGetNewStory:entry];
        }
        
    }      
    
}

- (Story *)parseItemToStory:(GDataXMLElement *)item 
              withBlogTitle:(NSString *)blogTitle 
                   itemType:(int)type
              alwaysInclude:(bool)alwaysInclude
                     blogID:(int)blogID
{
    //Type is an enumaration:  1 => RSS  2 => Atom
    
    //Date Created
    NSString *articleDateString;
    if(type == 1)
        articleDateString = [item valueForChild:@"pubDate"];
    else
        articleDateString = [item valueForChild:@"updated"];  
    NSDate *articleDate = [NSDate dateFromInternetDateTimeString:articleDateString formatHint:DateFormatHintRFC822];
    if(articleDate == nil)
        articleDate = [NSDate dateWithTimeIntervalSinceNow:-1*60*60*24];
    
    //Quit if the article is too early
    if(!alwaysInclude)
    {
        if([articleDate compare:self.lowerLimitDate] == NSOrderedAscending)
            return nil;
    }
    
    //Title
    NSString *articleTitle = [item valueForChild:@"title"];
    
    //Author
    NSString *articleAuthor = [item valueForChild:@"dc:creator"];
    
    //URL
    NSString *articleUrl;
    if(type == 1)
        articleUrl = [item valueForChild:@"link"];    
    else  
    {
        NSArray *links = [item elementsForName:@"link"];        
        for(GDataXMLElement *link in links) {
            NSString *rel = [[link attributeForName:@"rel"] stringValue];
            NSString *type = [[link attributeForName:@"type"] stringValue]; 
            if ([rel compare:@"alternate"] == NSOrderedSame && 
                [type compare:@"text/html"] == NSOrderedSame) {
                articleUrl = [[link attributeForName:@"href"] stringValue];
            }
        }
    }
    
    //Content
    NSString *articleContent = [item valueForChild:@"content"];
    if(articleContent == nil)
        articleContent = [item valueForChild:@"content:encoded"];
    if(articleContent == nil)
        articleContent = [item valueForChild:@"description"];
    
    Story *entry = [[Story alloc] initWithTitle:articleTitle
                                         author:articleAuthor
                                           body:articleContent
                                         source:blogTitle
                                            url:articleUrl
                                    dateCreated:articleDate
                                  dateRetrieved:[NSDate date] 
                                         isRead:NO 
                                      imagePath:@"" 
                                     isFavorite:NO 
                                           rank:0
                                        isDirty:NO
                                        storyID:0
                                         feedID:blogID
                                   durationRead:0
                               feedRankModifier:0];
    entry.imagePath = @"n/a";
    
    return entry;
}

- (int)GetFeedIDFromURL:(NSURL *)url
{
    NSString *urlString = url.absoluteString;
    Feed *feed  = [self.PM GetFeedByURLPath:urlString];
    return feed.feedID;
}

- (void)setFeeds:(NSMutableArray *)feedsToSet
{
    feeds = feedsToSet;
}

- (void)loadingIsCompleted
{
    [self.caller performSelector:self.selectorForLoadingIsCompleted];
}

- (void)updatePromptText
{
    [self.caller performSelector:self.selectorForUpdatePromptText];
}

- (void)UpdateFeedRank:(Feed *)feedToUpdate
{
    [self.feedUtils UpdateFeedRank:feedToUpdate];
}

- (void)UpdateStoryRank:(Story *)storyToUpdate
{
    [self.storyUtils UpdateStoryRank:storyToUpdate];    
}


@end
