//
//  RSSViewController.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RSSViewController.h"
#import "StoryDetailViewController.h"
#import "ASIHTTPRequest.h"
#import "GDataXMLNode.h"
#import "GDataXMLElement-Extras.h"
#import "NSDate+InternetDateTime.h"
#import "NSArray+Extras.h"
#import "Persistence.h"
#import "FeedsViewController.h"
#import "FeedsTestViewController.h"
#import "Feed.h"
#import "TwitterEngine.h"
#import "MessageUI/MessageUI.h"
#import "FBTestViewController.h"
#import "FBEngine.h"

@interface RSSViewController ()

@end

@implementation RSSViewController

#pragma mark Properties
@synthesize labelCount = _labelCount;
@synthesize toolbar = _toolbar;
@synthesize allEntries = _allEntries;
@synthesize feeds = _feeds;
@synthesize queue = _queue;
@synthesize PM = _PM;
@synthesize labelLastUpdated = _labelLastUpdated;
@synthesize lowerLimitDate;
@synthesize alwaysIncludeCount = _alwaysIncludeCount;
@synthesize outstandingFeedsToParse = _outstandingFeedsToParse;
@synthesize selectedRow = _selectedRow;
@synthesize orderBy = _orderBy;
@synthesize numStoriesToShow = _numStoriesToShow;
@synthesize lastUpdated = _lastUpdated;
@synthesize numDaysToShow = _numDaysToShow;
@synthesize stopLoading = _stopLoading;
@synthesize twitterEngine = _twitterEngine;
@synthesize twitterFeed = _twitterFeed;
@synthesize maxAllowableStoryTimeRead = _maxAllowableStoryTimeRead;
@synthesize oldestStory = _oldestStory;
@synthesize requests = _requests;
@synthesize loadingMoreStories = _loadingMoreStories;
@synthesize facebook = _facebook;
@synthesize fbEngine = _fbEngine;
@synthesize fbFeed = _fbFeed;

#pragma mark View methods
- (void)viewDidLoad
{
    [super viewDidLoad]; 
    
    self.title = @"Stories";
    _allEntries = [NSMutableArray array];
    self.feeds = [NSMutableArray array];
    
    [self updatePromptText];
    self.queue = [[NSOperationQueue alloc] init];
    alwaysIncludeCount = 10;
    PM = [[Persistence alloc] init];
    self.orderBy = 1;
    self.numStoriesToShow = 200;
    self.numDaysToShow = 10;
    hasInitialized = false;
    self.feeds = [PM GetAllFeeds];
    self.maxAllowableStoryTimeRead = 200;  //Seconds
    
    //Twitter Engine Setup
    twitterEngine = [[TwitterEngine alloc] initWithCompletedSelector:@selector(twitterIsDone)];
    
    //FB Engine Setup
    fbEngine = [[FBEngine alloc] init];
    [self InitializeFBFeed];
    fbEngine.caller = self;
    fbEngine.PM = PM;
    fbEngine.methodForAddingStory = @selector(AddFBPostAsStory:);
    feedUtil = [[FeedUtils alloc] init];
    feedUtil.PM = PM;
    storyUtil = [[StoryUtils alloc] init];
    storyUtil.PM = PM;
    
    //RSS Engine Setup
    rssEngine = [[RSSEngine alloc] initWithFeedUtils:feedUtil
                andStoryUtils:storyUtil 
                        andPM:PM 
               andLoadCompSel:@selector(rssIsDone)
             andUpdateProText:@selector(updatePromptText)
                    andCaller:self];
    rssEngine.alwaysIncludeCount = alwaysIncludeCount;
    rssEngine.numDaysToShow = numDaysToShow;
    [rssEngine setFeeds:self.feeds];
    debugMode = true;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    if(hasInitialized)
        return;
    hasInitialized = true;
    [self loadSqlStoriesIntoTable];
}

- (void)viewWillUnload
{
}

- (void)viewDidUnload
{
    [self setToolbar:nil];
    [self setLabelCount:nil];
    [self setLabelLastUpdated:nil];
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


#pragma mark FB Methods

#pragma mark App Methods

- (void)applicationWillTerminate
{
}

- (void)enteringBackground
{
    [PM shutItDown];
}

- (void)enteringForeground
{
    [PM initializeDatabaseIfNeeded];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark Initialization

- (void)InitializeTwitterFeed
{
    self.twitterFeed = [PM GetFeedByURLPath:@"Twitter"];
    if(self.twitterFeed == nil)
    {
        self.twitterFeed = [[Feed alloc] initWithName:@"Twitter" url:@"Twitter" type:2];
        [PM AddFeed:self.twitterFeed];
        self.twitterFeed = [PM GetLastFeed];
        [feedUtil UpdateFeedRank:self.twitterFeed];
    }
}

- (void)InitializeFBFeed
{
    self.fbFeed = [PM GetFeedByURLPath:@"Facebook"];
    if(self.fbFeed == nil)
    {
        self.fbFeed = [[Feed alloc] initWithName:@"Facebook" url:@"Facebook" type:4];
        [PM AddFeed:self.fbFeed];
        self.fbFeed = [PM GetLastFeed];
        [feedUtil UpdateFeedRank:self.fbFeed];
    }
}

- (void)initialPopulateStephFeeds
{
    [PM ClearFeeds];
    [PM AddFeed:[[Feed alloc] initWithName:@"Apartment Therapy" 
                                       url:@"http://feeds.apartmenttherapy.com/apartmenttherapy/main" 
                                      type:1
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"IKEA Hackers" 
                                       url:@"http://feeds.feedburner.com/Ikeahacker" 
                                      type:1
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Lifehacker" 
                                       url:@"http://lifehacker.com/top/index.xml" 
                                      type:1
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"People.com" 
                                       url:@"http://rss.people.com/web/people/rss/topheadlines/index.xml" 
                                      type:1
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Hacker News Summary"
                                       url:@"http://fulltextrssfeed.com/news.ycombinator.com/rss" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"xkcd" 
                                       url:@"http://xkcd.com/rss.xml" 
                                      type:1
                                      rank:1]];
    self.feeds = [PM GetAllFeeds]; 
    [rssEngine setFeeds:self.feeds];
}

- (void)initialPopulateFeeds
{
    [PM ClearFeeds];
    [self InitializeTwitterFeed];
    
//        [PM AddFeed:[[Feed alloc] initWithName:@"Vikes Geek" 
//                                           url:@"http://vikesgeek.blogspot.com/feeds/posts/default" 
//                                          type:1
//                                          rank:1]];
        [PM AddFeed:[[Feed alloc] initWithName:@"Vegas Chatter" 
                                           url:@"http://feeds.feedburner.com/vegaschatter?format=xml" 
                                          type:1
                                          rank:1]];
        [PM AddFeed:[[Feed alloc] initWithName:@"Ray Wenderlich" 
                                           url:@"http://feeds.feedburner.com/RayWenderlich" 
                                          type:1
                                          rank:1]];
        [PM AddFeed:[[Feed alloc] initWithName:@"Las Vegas Startups" 
                                           url:@"http://feeds.feedburner.com/LasVegasStartups" 
                                          type:1
                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"ThansCorner" 
//                                           url:@"http://www.thanscorner.info/feed" 
//                                          type:1
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Dodgy Coder" 
//                                           url:@"http://www.dodgycoder.net/feeds/posts/default?alt=rss" 
//                                          type:1
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"xkcd" 
//                                           url:@"http://xkcd.com/rss.xml" 
//                                          type:1
//                                          rank:1]];
////        [PM AddFeed:[[Feed alloc] initWithName:@"Engadget" 
////                                           url:@"http://www.engadget.com/rss.xml" 
////                                          type:1
////                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Lifehacker" 
//                                           url:@"http://lifehacker.com/top/index.xml" 
//                                          type:1
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"10x Software Development" 
//                                           url:@"http://feeds.feedburner.com/10xSoftwareDevelopment" 
//                                          type:1 
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Digital Photography School" 
//                                           url:@"http://feeds.feedburner.com/DigitalPhotographySchool" 
//                                          type:1 
//                                            rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Gawker: Valleywag" 
//                                           url:@"http://feeds.gawker.com/valleywag/full" 
//                                          type:1 
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"GraphJam" 
//                                           url:@"http://feeds.feedburner.com/GraphJam" 
//                                          type:1 
//                                          rank:1]];
        [PM AddFeed:[[Feed alloc] initWithName:@"Joel on Software" 
                                           url:@"http://www.joelonsoftware.com/rss.xml" 
                                          type:1 
                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Ars Technica" 
//                                           url:@"http://feeds.arstechnica.com/arstechnica/index/" 
//                                          type:1 
//                                          rank:1]];
        [PM AddFeed:[[Feed alloc] initWithName:@"Geeking with Greg" 
                                           url:@"http://glinden.blogspot.com/feeds/posts/default" 
                                          type:1 
                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Money and Investing" 
//                                           url:@"http://feeds.feedburner.com/MoneyAndInvesting" 
//                                          type:1 
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Official Google Blog" 
//                                           url:@"http://googleblog.blogspot.com/feeds/posts/default" 
//                                          type:1 
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"St. Olaf News Releases" 
//                                           url:@"http://www.stolaf.edu/news/index.cfm?fuseaction=RSS" 
//                                          type:1 
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"TechCrunch" 
//                                           url:@"http://feeds.feedburner.com/Techcrunch" 
//                                          type:1 
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"The Happiness Project" 
//                                           url:@"http://feeds.feedburner.com/TheHappinessProject" 
//                                          type:1 
//                                          rank:1]];
        [PM AddFeed:[[Feed alloc] initWithName:@"The Long Now Blog" 
                                           url:@"http://blog.longnow.org/feed/" 
                                          type:1 
                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Very Small Array" 
//                                           url:@"http://www.verysmallarray.com/?feed=rss2" 
//                                          type:1 
//                                          rank:1]];
    //}
//    [PM AddFeed:[[Feed alloc] initWithName:@"UW Engineering" 
//                                       url:@"http://www.engr.wisc.edu/news/feeds/RR.xml" 
//                                      type:1 
//                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Hacker News Summary"
                                       url:@"http://fulltextrssfeed.com/news.ycombinator.com/rss" 
                                      type:1 
                                      rank:1]];
    self.feeds = [PM GetAllFeeds];
    [rssEngine setFeeds:self.feeds];
}


#pragma mark Twitter

- (void)AddTweetAsStory:(Story *)tweetStory
{
    //Feed *storyFeed = [PM GetFeedByID:tweetStory.feedID];
    Feed *storyFeed = [PM GetFeedByURLPath:tweetStory.author];
    if(storyFeed == nil)
    {
        storyFeed = [[Feed alloc] initWithName:tweetStory.author url:tweetStory.author type:3];
        storyFeed.image = [storyUtil SaveImageAndGetPathFromURLString:tweetStory.imagePath];
        storyFeed = [PM AddFeedAndGetNewFeed:storyFeed];
    }
    
    tweetStory.feedID = storyFeed.feedID;
    
    tweetStory.imagePath = storyFeed.image;
    
    if(![PM StoryExistsInDB:tweetStory])
    {
        [storyUtil UpdateStoryRank:tweetStory];
        tweetStory = [PM AddStoryAndGetNewStory:tweetStory];
        [self insertOrderedStoryWithoutAnimation:tweetStory];
        //[self insertOrderedStoryWithAnimation:tweetStory];
    }
    [self updatePromptText];
//    if(twitterEngine.requestCompleted)
//    {
//        if(self.outstandingFeedsToParse > 0)
//            self.outstandingFeedsToParse--;
//        [self updatePromptText];
//    }
}

- (void)AddFBPostAsStory:(Story *)fbStory
{
    self.outstandingFeedsToParse = 0;
    Feed *storyFeed = [PM GetFeedByURLPath:fbStory.author];
    if(storyFeed == nil)
    {
        storyFeed = [[Feed alloc] initWithName:fbStory.author url:fbStory.author type:4];
        //storyFeed.image = [self SaveImageAndGetPathFromURLString:fbStory.imagePath];
        storyFeed = [PM AddFeedAndGetNewFeed:storyFeed];
    }
    fbStory.feedID = storyFeed.feedID;
    
    //fbStory.imagePath = storyFeed.image;
    
    if(![PM StoryExistsInDB:fbStory])
    {
        [storyUtil UpdateStoryRank:fbStory];
        fbStory = [PM AddStoryAndGetNewStory:fbStory];
        [self insertOrderedStoryWithoutAnimation:fbStory];
    }
    [self updatePromptText];
}

- (void)TweetRetrievalCompleted
{
    [self refreshFacebook];
    [self updatePromptText];
    [self.tableView reloadData];
}


#pragma mark Update Prompt Text

- (void)updatePromptText
{
    int numStories = _allEntries.count;
    self.labelCount.text = [NSString stringWithFormat:@"%i Stories",numStories];
    self.outstandingFeedsToParse = rssEngine.outstandingFeedsToParse;
    if((self.outstandingFeedsToParse < 1) && twitterEngine.requestCompleted)
    {
        [self.pullToReloadHeaderView setLastUpdatedDate: [NSDate date]];
        [self.pullToReloadHeaderView finishReloading:self.tableView animated:YES];
    }
}



#pragma mark Story stream management
- (void)loadSqlStoriesIntoTable
{
    NSMutableArray *entries = [PM GetTopUnreadStories:self.orderBy numStories:self.numStoriesToShow where:@""];
    NSMutableArray *feeds = [PM GetAllFeeds];
    
    bool addStoryViaInsert = false;
    
    if(addStoryViaInsert)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            for (Feed *feed in feeds) {
                [feedUtil UpdateFeedRank:feed];
            }
            
            for (Story *entry in entries) {
                [storyUtil UpdateStoryRank:entry];
            }
            
            for (Story *entry in entries) {
                [self insertOrderedStoryWithAnimation:entry];
            }  
            [self.tableView reloadData];
            [self updatePromptText];
            self.oldestStory = [entries lastObject];
            [self loadingIsCompleted];
        }];
    }
    else 
    {
//        for (Feed *feed in feeds) {
//            [self UpdateFeedRank:feed];
//        }
        
        //for (Story *entry in entries) {
        //    [self UpdateStoryRank:entry];
        //}
        
        _allEntries = entries;
        [self.tableView reloadData];
        [self updatePromptText];
        self.oldestStory = [entries lastObject];
        [self loadingIsCompleted];
    }
}

-(bool)allEntriesContainsStory:(Story *)storyToFind
{
    int storyIDToFind = storyToFind.storyID;
    
    for(Story *testStory in _allEntries)
    {
        if(testStory.storyID == storyIDToFind)
            return true;
    }
    return false;
}

-(void)insertOrderedStoryWithAnimation:(Story *)newStory
{
    if((!self.stopLoading) && 
       (newStory != nil) && 
       (![self allEntriesContainsStory:newStory]))
    {   
        //[self UpdateStoryRank:newStory];
        int insertIdx = [_allEntries indexForInsertingObject:newStory sortedUsingBlock:^(id a, id b) {
            return [self compareStory:(Story *)a withStory:(Story *)b];
        }];     
        [_allEntries insertObject:newStory atIndex:insertIdx];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:insertIdx inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        [self updatePromptText];
        //[self.tableView reloadData];
    }
}

-(void)removeOrderedStoryWithAnimation:(Story *)story atIndexPath:(NSIndexPath *)indexPath
{
    if([_allEntries containsObject:story])
    {
        [_allEntries removeObject:story];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self updatePromptText];
    }
}

-(void)insertOrderedStoryWithoutAnimation:(Story *)newStory
{
    if((!self.stopLoading) && 
       (newStory != nil) && 
       (![self allEntriesContainsStory:newStory]))
    {   
        //[self UpdateStoryRank:newStory];
        int insertIdx = [_allEntries indexForInsertingObject:newStory sortedUsingBlock:^(id a, id b) {
            return [self compareStory:(Story *)a withStory:(Story *)b];
        }];     
        [_allEntries insertObject:newStory atIndex:insertIdx];
        //[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:insertIdx inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        [self updatePromptText];
        [self.tableView reloadData];
    }
}

- (void)sortArray
{
    [_allEntries sortUsingComparator:(NSComparator)^(id a, id b) {
        Story *first = (Story*)a;
        Story *second = (Story*)b;
        NSComparisonResult result = [first compare:second withMode:self.orderBy];
        return result;
    }];
}

- (void)removeReadStories
{
    NSMutableArray *discardedItems = [NSMutableArray array];
    for(Story* thisStory in _allEntries)
    {
        if(thisStory.isRead)
            [discardedItems addObject:thisStory];
    }
    
    [_allEntries removeObjectsInArray:discardedItems];
}

- (NSComparisonResult)compareStory:(Story *)entry1 withStory:(Story *)entry2
{
    NSComparisonResult result;
    
    if(self.orderBy == 0)
    {
        result = [entry1.dateCreated compare:entry2.dateCreated];
    }
    else if(self.orderBy == 1)
    {
        int entry1rank = entry1.rank + [PM GetFeedRankByFeedID:entry1.feedID] + entry1.feedRankModifier;
        int entry2rank = entry2.rank + [PM GetFeedRankByFeedID:entry2.feedID] + entry2.feedRankModifier;
        if(entry1rank > entry2rank)
            result = NSOrderedDescending;
        else if(entry1rank < entry2rank)
            result = NSOrderedAscending;
        else
            result = [entry1.dateCreated compare:entry2.dateCreated];
    }
    else if(self.orderBy == 2)
    {
        result = [entry1.title compare:entry2.title];
    }
    else
    {
        result = NSOrderedAscending;
    }
    
    return result;
}

- (void)updateArrayRanks
{
    int numStories = _allEntries.count;
    Story *thisStory;
    for (int i=0; i<numStories; i++) {
        thisStory = [_allEntries objectAtIndex:i];
        [storyUtil UpdateStoryRank:thisStory];
        [storyUtil SetStoryFeedRank:thisStory];
    }
}

#pragma mark TableView Methods
- (id)initWithStyle:(UITableViewStyle)style
{
    return self;
}

- (int) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_allEntries count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	Story *story = [_allEntries objectAtIndex:indexPath.row];
    
    if([story.source compare:@"Twitter"] == NSOrderedSame)
    {
        return 100;
    }
    else 
    {
        return 100;
    }
}

- (void)StartCellTimerBehavior:(Story *)story atPath:(NSIndexPath *)indexPath
{   
    NSMutableDictionary *infoDict = [[NSMutableDictionary alloc] init];
    [infoDict setValue:story forKey:@"story"];
    [infoDict setValue:indexPath forKey:@"indexPath"];
    [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(CellTimerFired:) userInfo:infoDict repeats:NO];
}

//Fires for every story made visible.  If still visible, flag it so it is marked as read when no longer visible
- (void)CellTimerFired:(NSTimer *)timer {
    NSDictionary *infoDict = [timer userInfo];
    NSIndexPath *indexPath = [infoDict objectForKey:@"indexPath"];
    Story *story = [infoDict objectForKey:@"story"];
    
    bool storyVisible = [self StoryAtIndexPathIsVisible:indexPath];
    if(storyVisible && !story.isRead)
    {
        //It's read - schedule the cleanup loop to mark as read when not visible
        //[NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(SetStoryAsReadIfVisible:) userInfo:infoDict repeats:YES];
        //NMM - disabled for now
    }
}

//If story is not visible, mark as read.  Otherwise recurse and try again.
- (void)SetStoryAsReadIfVisible:(NSTimer *)timer
{
    NSDictionary *infoDict = [timer userInfo];
    NSIndexPath *indexPath = [infoDict objectForKey:@"indexPath"];
    Story *story = [infoDict objectForKey:@"story"];
    
    bool storyVisible = [self StoryAtIndexPathIsVisible:indexPath];
    if(!storyVisible)
    {
        [timer invalidate];
        if(!story.isRead)
            [self MarkStoryAsRead:story atIndexPath:indexPath withOpenedDate:[NSDate dateWithTimeIntervalSinceNow:4] noRankUpdate:NO];
        //[self removeOrderedStoryWithAnimation:story atIndexPath:indexPath];
    }
    
}

- (bool)StoryAtIndexPathIsVisible:(NSIndexPath *)indexPath
{
    if([self.tableView.indexPathsForVisibleRows containsObject:indexPath])
        return true;
    else 
        return false;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
	Story *story = [_allEntries objectAtIndex:indexPath.row];
    UIColor *textColor;
    if(story.isRead)
        textColor = [UIColor grayColor];
    else
        textColor = [UIColor blackColor];
    
    cell.textLabel.textColor = textColor;
    cell.detailTextLabel.textColor = textColor;
    
    if([story.source isEqualToString:@"Twitter"])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"StoryCellTwitter"];
        
        //Actually set the text here
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
        titleLabel.text = story.title;
        titleLabel.text = [titleLabel.text stringByAppendingFormat:@"\n%@",[story GetDateCreatedString]];
        
        UILabel *rankLabel = (UILabel *)[cell viewWithTag:102];
        rankLabel.text = [NSString stringWithFormat:@"%i|%i",story.rank+story.feedRankModifier,[PM GetFeedRankByFeedID:story.feedID]];
        
        UILabel *authorLabel = (UILabel *)[cell viewWithTag:103];
        authorLabel.text = [@"@" stringByAppendingString:story.author];
        
        UILabel *createdLabel = (UILabel *)[cell viewWithTag:104];
        createdLabel.text = [story GetDateCreatedString];
        
        UIImageView *storyImageView = (UIImageView *)[cell viewWithTag:105];
        UIImage *storyImage = [[UIImage alloc] initWithContentsOfFile:story.imagePath];
        storyImageView.image = storyImage;
        
        //Update colors based on isRead
        rankLabel.textColor = textColor;
        titleLabel.textColor = textColor;
        authorLabel.textColor = textColor;
        createdLabel.textColor = textColor;
    }
    else if([story.source isEqualToString:@"Facebook"])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"StoryCellTwitter"];
        
        //Actually set the text here
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
        titleLabel.text = story.title;
        titleLabel.text = [titleLabel.text stringByAppendingFormat:@"\n%@",[story GetDateCreatedString]];
        
        UILabel *rankLabel = (UILabel *)[cell viewWithTag:102];
        rankLabel.text = [NSString stringWithFormat:@"%i|%i",story.rank+story.feedRankModifier,[PM GetFeedRankByFeedID:story.feedID]];
        
        UILabel *authorLabel = (UILabel *)[cell viewWithTag:103];
        authorLabel.text = [@"" stringByAppendingString:story.author];
        
        UILabel *createdLabel = (UILabel *)[cell viewWithTag:104];
        createdLabel.text = [story GetDateCreatedString];
        
        UIImageView *storyImageView = (UIImageView *)[cell viewWithTag:105];
        UIImage *storyImage = [[UIImage alloc] initWithContentsOfFile:story.imagePath];
        storyImageView.image = storyImage;
        
        //Update colors based on isRead
        rankLabel.textColor = textColor;
        titleLabel.textColor = textColor;
        authorLabel.textColor = textColor;
        createdLabel.textColor = textColor;
    }
    else 
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"StoryCellRSS"];
        
        //Actually set the text here
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
        titleLabel.text = [NSString stringWithFormat:@"%@",story.title];
        titleLabel.text = [titleLabel.text stringByAppendingFormat:@"\n%@",[story GetDateCreatedString]];
        
        UILabel *subtitleLabel = (UILabel *)[cell viewWithTag:101];
        subtitleLabel.text = story.source;
        
        UILabel *rankLabel = (UILabel *)[cell viewWithTag:102];
        rankLabel.text = [NSString stringWithFormat:@"%i|%i",story.rank+story.feedRankModifier,[PM GetFeedRankByFeedID:story.feedID]];
        
        UILabel *createdLabel = (UILabel *)[cell viewWithTag:104];
        createdLabel.text = [story GetDateCreatedString];
        
        //UILabel *retrievedLabel = (UILabel *)[cell viewWithTag:104];
        //retrievedLabel.text = [story GetDateRetrievedString];
        
        //UILabel *feedNumReadLabel = (UILabel *)[cell viewWithTag:103];
        //feedNumReadLabel.text = [NSString stringWithFormat:@"%i",numFeedStoriesTotal];
        
        //UILabel *feedNumPerDayLabel = (UILabel *)[cell viewWithTag:104];
        //feedNumPerDayLabel.text =  [NSString stringWithFormat:@"%.2f",numFeedStoriesPerDay];
        //Update colors based on isRead
        rankLabel.textColor = textColor;
        titleLabel.textColor = textColor;
        subtitleLabel.textColor = textColor;
        createdLabel.textColor = textColor;
        //retrievedLabel.textColor = textColor;
    }
    
    UIButton *btnStoryDown = (UIButton *)[cell viewWithTag:106];
    UIButton *btnStoryUp = (UIButton *)[cell viewWithTag:107];
    UIButton *btnStoryInfo = (UIButton *)[cell viewWithTag:108];
    
    btnStoryUp.tag = story.storyID;
    btnStoryDown.tag = story.storyID;
    btnStoryInfo.tag = story.storyID;
    
    [btnStoryUp addTarget:self action:@selector(storyUp:event:) forControlEvents:UIControlEventTouchUpInside];
    [btnStoryDown addTarget:self action:@selector(storyDown:event:) forControlEvents:UIControlEventTouchUpInside];
    [btnStoryInfo addTarget:self action:@selector(storyInfo:event:) forControlEvents:UIControlEventTouchUpInside];
    
    [self StartCellTimerBehavior:story atPath:indexPath];

    
//    cell.tag = indexPath.row;
//    UISwipeGestureRecognizer* gestureR;
//    gestureR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRTL:)];
//    gestureR.direction = UISwipeGestureRecognizerDirectionLeft;
//    [cell addGestureRecognizer:gestureR];
//    
//    gestureR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLTR:)];
//    gestureR.direction = UISwipeGestureRecognizerDirectionRight; // default
//    [cell addGestureRecognizer:gestureR];
    return cell;
}

- (Story *)GetStoryForTouchEvent:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    if(indexPath == nil)
        return nil;
    return [_allEntries objectAtIndex:indexPath.row];
}

- (void)storyUp:(id)sender event:(id)event
{
    Story *tappedStory = [self GetStoryForTouchEvent:event];
    if (tappedStory != nil)
    {
        tappedStory.feedRankModifier += 5;
        [PM SetStoryFeedRankModifier:tappedStory.storyID toValue:tappedStory.feedRankModifier];
        
        [feedUtil UpdateFeedRank:[PM GetFeedByID:tappedStory.feedID]];
        [self.tableView reloadData];
    }
}

- (void)storyDown:(id)sender event:(id)event
{
    Story *tappedStory = [self GetStoryForTouchEvent:event];
    if (tappedStory != nil)
    {
        tappedStory.feedRankModifier -= 5;
        [PM SetStoryFeedRankModifier:tappedStory.storyID toValue:tappedStory.feedRankModifier];
        
        [feedUtil UpdateFeedRank:[PM GetFeedByID:tappedStory.feedID]];
        [self.tableView reloadData];
    }
}

- (void)storyInfo:(id)sender event:(id)event
{
    Story *tappedStory = [self GetStoryForTouchEvent:event];
    if (tappedStory != nil)
    {
        [self ShowAlertMsg:[tappedStory GetDebugInfo] withTitle:[NSString stringWithFormat:@"Story Info:%i", tappedStory.storyID]];
    }
}

- (void)ShowAlertMsg:(NSString *)msg withTitle:(NSString *)title
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK" 
                                          otherButtonTitles:nil];
    [alert show];  
}
- (void)ShowDebugAlert
{
    NSString *debugMsg = @"";
    int numStories = _allEntries.count;
    int numRows = [self.tableView numberOfRowsInSection:0];
    int oldestStoryRank = self.oldestStory.rank;
    int numDaysToShowLoc = self.numDaysToShow;
    int numStoriesToShowLoc = self.numStoriesToShow;
    int numFeeds = self.feeds.count;
    int outstandingFeedsToParseLoc = rssEngine.outstandingFeedsToParse;
    int numPMStories = [PM GetNumFeedStories:0 limitedToRead:0];
    int numReadPMStories = [PM GetNumFeedStories:0 limitedToRead:1];
    int numMyStories = [PM GetNumFeedStories:2 limitedToRead:0];
    int numTwitterStories = [PM GetNumFeedStoriesBySource:@"Twitter" limitedToRead:0];
    int numFBStories = [PM GetNumFeedStoriesBySource:@"Facebook" limitedToRead:0];
    
    
    debugMsg = [debugMsg stringByAppendingFormat:@"NumStories: %i\n",numStories];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumRows:   %i\n",numRows];
    debugMsg = [debugMsg stringByAppendingFormat:@"OldestRank: %i\n",oldestStoryRank];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumDays:   %i\n",numDaysToShowLoc];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumShowStories: %i\n",numStoriesToShowLoc];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumFeeds:   %i\n",numFeeds];
    debugMsg = [debugMsg stringByAppendingFormat:@"outFeeds:   %i\n",outstandingFeedsToParseLoc];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumPMStories:  %i\n",numPMStories];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumRPMStories: %i\n",numReadPMStories];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumMyStories: %i\n",numMyStories];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumTwitter: %i\n",numTwitterStories];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumFB:    %i\n",numFBStories];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debug info" 
                                                    message:debugMsg
                                                   delegate:self
                                          cancelButtonTitle:@"OK" 
                                          otherButtonTitles: @"Feeds",nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == 0)
    {
        NSLog(@"OK");
    }
    else
    {
        NSString *debugMsg = @"";
        for(Feed *feed in [PM GetAllFeeds])
        {
            int feedID = feed.feedID;
            
            NSString *feedName = feed.name;
            if(feedName.length > 10)
                feedName = [feedName substringToIndex:10];
            
            int numFeedStories = [PM GetNumFeedStories:feedID limitedToRead:0];
            int feedRank = [PM GetFeedRankByFeedID:feedID];
            
            debugMsg = [debugMsg stringByAppendingFormat:@"%i:%@:#=%i:R=%i\n",feedID,feedName,numFeedStories,feedRank];
            
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Feed info" 
                                                        message:debugMsg
                                                       delegate:nil
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark Helper methods

-(void)sendStoryViaEmail:(Story *)storyToSend 
{
    if(storyToSend == nil)
        return;
    
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    mailer.mailComposeDelegate = (MFMailComposeViewController *)self;
    
    [mailer setSubject:[NSString stringWithFormat:@"Read this: %@",storyToSend.title]];
    
    NSArray *toRecipients = [NSArray arrayWithObjects:@"nmeierpolys@gmail.com", nil];
    [mailer setToRecipients:toRecipients];
    
    // Fill out the email body text
    NSString *header = @"\n\nSent from ReadFeeder on iPhone.";
    NSString *emailBody = [NSString stringWithFormat:@"%@\n\n<br><br><b><a href=\"%@\">%@</a></b><br>%@\n\n<br><br>%@",header,storyToSend.url,storyToSend.title,[storyToSend GetDateCreatedString],storyToSend.body];
    
    //[NSString stringWithFormat:@"%@\n\n&lt;h3&gt;Sent from &lt;a href = '%@'&gt;ReadFeeder&lt;/a&gt; on iPhone. &lt;a href = '%@'&gt;Download&lt;/a&gt; yours from AppStore now!&lt;/h3&gt;", content, pageLink, iTunesLink];
    
    [mailer setMessageBody:emailBody isHTML:YES]; // depends. Mostly YES, unless you want to send it as plain text (boring)
    
    mailer.navigationBar.barStyle = UIBarStyleBlack; // choose your style, unfortunately, Translucent colors behave quirky.
    
    [self presentModalViewController:mailer animated:YES];    
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
    NSString *message;
	switch (result)
	{
		case MFMailComposeResultCancelled:
			message = @"Cancelled";
			break;
		case MFMailComposeResultSaved:
			message = @"Saved";
			break;
		case MFMailComposeResultSent:
			message = @"Sent";
			break;
		case MFMailComposeResultFailed:
			message = @"Failed";
			break;
		default:
			message = @"Sent";
			break;
	}
    
	[self dismissModalViewControllerAnimated:YES];
}

//Send the cell-specific information to the detail view in a Story object
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NSString *segueIdentifier = [segue identifier];
    if([segueIdentifier isEqualToString:@"StoryDetail"] ||
       [segueIdentifier isEqualToString:@"StoryDetailTwitter"]){
        
        //Get a reference to the detail view we're loading
        StoryDetailViewController *detailView = (StoryDetailViewController *)[segue destinationViewController];
        
        [self UpdateSelectedRowValue];
        Story *detailStory = [self GetSelectedStory];  
        
        if (detailStory == nil)
            return;
        
        [self.tableView reloadData];
        
        //Set the story object on the detail view
        detailView.currentStory = detailStory;
        detailView.parentTableView = self;
    }
    else if ([segueIdentifier isEqualToString:@"FeedManagement"]) {
        FeedsTestViewController *feedView = (FeedsTestViewController *)[segue destinationViewController];
        
        feedView.feeds = self.feeds;
        feedView.parentTableView = self;
        feedView.PM = PM;
    }
    else if ([segueIdentifier isEqualToString:@"openFacebook"]) {
         FBTestViewController *feedView = (FBTestViewController *)[segue destinationViewController];
        
        feedView.facebook = self.facebook;
        feedView.PM = PM;
    }
}
- (void)MarkCurrentStoryAsReadWithOpenedDate:(NSDate *)openedDate
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.selectedRow inSection:0];
    [self MarkStoryAsRead:[self GetSelectedStory] atIndexPath:indexPath withOpenedDate:openedDate noRankUpdate:false];
}
     
- (void)MarkStoryAsRead:(Story *)story atIndexPath:(NSIndexPath *)indexPath withOpenedDate:(NSDate *)openedDate noRankUpdate:(bool)noRankUpdate
{
    //Mark as read
    [PM MarkStoryAsRead:story.storyID];
    story.isRead = true;
    
    if(!noRankUpdate)
    {
        //Update Feed rank
        Feed *storyFeed = [PM GetFeedByID:story.feedID];
        storyFeed.timesRead++;
        [feedUtil UpdateFeedRank:storyFeed];
        
        //Set duration read
        if(openedDate != nil)
        {
            NSTimeInterval diff = [openedDate timeIntervalSinceDate:[NSDate date]];
            int durationRead = -(int)diff;
            if(durationRead > self.maxAllowableStoryTimeRead)
                durationRead = self.maxAllowableStoryTimeRead;
            
            [PM SetStoryDurationRead:story.storyID toDuration:durationRead];
            story.durationRead = durationRead;
        }
        
        //Update Story rank
        //[self UpdateStoryRank:story];
        //[PM SetStoryRank:story.storyID toRank:story.rank];
    }
    [self.tableView reloadData];
    
}

- (void)MarkSelectedStoryAsRead
{
    Story *selectedStory = [self GetSelectedStory];
    if(selectedStory != nil)
        selectedStory.isRead = YES;
}

- (void)UpdateSelectedRowValue
{
    NSIndexPath *myIndexPath = [self.tableView indexPathForSelectedRow];
    
    if(myIndexPath == nil)
        self.selectedRow = 0;
    else
        self.selectedRow = [myIndexPath row];
}

- (Story *)GetSelectedStory
{   
    Story *selectedStory = [_allEntries objectAtIndex:self.selectedRow];
    
    return selectedStory;
}


- (void)SwitchToPreviousStory
{   
    [self MarkSelectedStoryAsRead];
    int previousRow;
    if(self.selectedRow < 1)
        previousRow = self.selectedRow;
    else
        previousRow = self.selectedRow - 1;  
    self.selectedRow = previousRow;    
}

- (void)SwitchToNextStory
{   
    [self MarkSelectedStoryAsRead];
    int nextRow;
    if((self.selectedRow + 2) > (_allEntries.count))
        nextRow = self.selectedRow;
    else
        nextRow = self.selectedRow + 1;   
    self.selectedRow = nextRow;
}


- (void)StoryRetrievalComplete
{
    [self updatePromptText];
    [self loadSqlStoriesIntoTable];
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


- (void)refresh {
    [rssEngine refresh];
    return;
    //Update lastUpdated property
    self.lastUpdated = [NSDate date];
    [self cancelParsing];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //Set earliest date to pick up stories from
        lowerLimitDate = [NSDate dateWithTimeIntervalSinceNow:-1*60*60*24*self.numDaysToShow];
        bool nonTwitterFeedsFound = false;
        
        //Kick off request for each feed
        for (Feed *feed in _feeds) {
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
        if(!nonTwitterFeedsFound)
        {
            [self refreshTwitter];
        }
    }];
}

- (void)loadingIsCompleted
{
    //[self refreshTwitter];
    //[self SortTableView];
}

- (void)twitterIsDone
{
    //[self refreshFacebook];
    //[self loadingIsCompleted];
}

- (void)facebookIsDone
{
    //[self refreshFacebook];
    //[self loadingIsCompleted];
}

- (void)rssIsDone
{
    //[self refreshFacebook];
    //[self loadingIsCompleted];
}

- (void)refreshTwitter
{
    //[self UpdateFeedRank:self.twitterFeed];
    
    [twitterEngine fetchDataWithSelector:@selector(AddTweetAsStory:) withCompletionHandler:@selector(TweetRetrievalCompleted) withCaller:self count:50];
    
    //Update story count and 'Loading' string labels
    [self updatePromptText];
}

- (void)refreshFacebook
{
    [fbEngine loadFacebookStories];
    //Update story count and 'Loading' string labels
    [self updatePromptText];
}

- (void)refreshRSS
{
    [rssEngine refresh];
}

- (int)GetFeedIDFromURL:(NSURL *)url
{
    NSString *urlString = url.absoluteString;
    Feed *feed  = [PM GetFeedByURLPath:urlString];
    return feed.feedID;
}



#pragma mark Buttons

- (IBAction)btnClear:(id)sender {
    [PM ClearStories];
    _allEntries = [NSMutableArray array];
    [self.tableView reloadData];
    [self updatePromptText];
    self.numDaysToShow = 3;
    
}

- (IBAction)btnReFeed:(id)sender {
    [PM ClearFeeds];
    [self initialPopulateStephFeeds];
}

- (IBAction)btnLoadMoreStories:(id)sender {
    [self cancelParsing];
    NSString *whereClause = @"";
    NSString *oldestDateCreatedStr = @"";
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    oldestDateCreatedStr=[dateFormat stringFromDate:self.oldestStory.dateCreated];
    
    if(self.oldestStory != nil)
    {
        int oldestStoryFeedRank = [PM GetFeedRankByFeedID:self.oldestStory.feedID];
        whereClause = [NSString stringWithFormat:@"(story.rank+feed.rank)<=%i and dateCreated<'%@'",self.oldestStory.rank+self.oldestStory.feedRankModifier+oldestStoryFeedRank, oldestDateCreatedStr];
    }

    //Pull another batch from SQL
    NSMutableArray *entries = [PM GetTopUnreadStories:self.orderBy numStories:self.numStoriesToShow where:whereClause];
    
    self.oldestStory = [entries lastObject];
    
    for (Story *entry in entries) {
        [storyUtil UpdateStoryRank:entry];
        [self insertOrderedStoryWithAnimation:entry];
    }
    
    [self updatePromptText];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        bool nonTwitterFeedsFound = false;
        self.loadingMoreStories = true;
        //Load new ones
        self.numDaysToShow = self.numDaysToShow + 3;
        self.lowerLimitDate = [NSDate dateWithTimeIntervalSinceNow:-1*60*60*24*self.numDaysToShow];
        
        //Kick off request for each feed
        for (Feed *feed in _feeds) {
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
        if(!nonTwitterFeedsFound)
        {
            [self refreshTwitter];
        }   
    }];
    
//    self.outstandingFeedsToParse--;
//    
//    [twitterEngine getNextOldestTweets:@selector(AddTweetAsStory:) withCaller:self count:50];
//    
    //Update story count and 'Loading' string labels
    [self updatePromptText];
}

//- (IBAction)btnCancelLoad:(id)sender {
//    self.stopLoading = true;
//    [self cancelParsing];
//    [self.pullToReloadHeaderView setLastUpdatedDate: [NSDate date]];
//    [self.pullToReloadHeaderView finishReloading:self.tableView animated:YES];
//}

- (void)SortTableView
{
    [self removeReadStories];
    [self updateArrayRanks];
    [self sortArray];
    [self.tableView reloadData];
    [self updatePromptText];
}

- (IBAction)btnSort:(id)sender {
    [self SortTableView];
}

- (IBAction)btnSend:(id)sender {
}

- (IBAction)btnRefresh:(id)sender {
    [self.tableView reloadData];
    self.stopLoading = true;
    [self cancelParsing];
    [self.pullToReloadHeaderView setLastUpdatedDate: [NSDate date]];
    [self.pullToReloadHeaderView finishReloading:self.tableView animated:YES];
}


#pragma mark Other Actions
//- (IBAction)swipeCellLeft:(id)sender {
//    
//}
//
//- (void)handleSwipeRTL:(UISwipeGestureRecognizer *)recognizer {
//    //    if((recognizer == nil) || (recognizer.view.tag < 1))
//    //        return;
//    //    int rowIndex = recognizer.view.tag;
//    //    Story *swipedStory = [_allEntries objectAtIndex:rowIndex];
//    //    NSLog(@"%@",swipedStory.title);
//    //    
//    //    [self MarkStoryAsRead:swipedStory withOpenedDate:[NSDate date] noRankUpdate:true];
//    //    
//    //    NSLog(@"Before: %i",_allEntries.count);
//    //    [_allEntries removeObjectAtIndex:rowIndex];
//    //    NSLog(@"After: %i",_allEntries.count);
//    //    [self.tableView reloadData];
//}
//
//- (void)handleSwipeLTR:(UISwipeGestureRecognizer *)recognizer {  
//    //    NSLog(@"%d = %d |%i",recognizer.direction,recognizer.state,recognizer.view.tag);
//}

-(void) pullDownToReloadAction {	
    [self performSelector:@selector(refresh)];
}


- (IBAction)btnDebugInfo:(id)sender {
    [self ShowDebugAlert];
}

- (IBAction)btnTwitter:(id)sender {
    [self refreshTwitter];
}

- (IBAction)btnFB:(id)sender {
    [self refreshFacebook];
}

- (IBAction)btnRSS:(id)sender {
    [self refreshRSS];
}

@end
