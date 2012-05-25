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

@interface RSSViewController ()

@end

@implementation RSSViewController

#pragma mark Properties
@synthesize labelStatus = _labelStatus;
@synthesize btnGET = _btnGET;
@synthesize textBody = _textBody;
@synthesize textTitle = _textTitle;
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
@synthesize currentRangeLowestRank = _currentRangeLowestRank;
@synthesize currentRangeEarliest = _currentRangeEarliest;
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

#pragma mark View methods
- (void)viewDidLoad
{
    [super viewDidLoad]; 
    [self loadFacebook];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"Stories";
    _allEntries = [NSMutableArray array];
    self.feeds = [NSMutableArray array];
    [self updatePromptText];
    self.queue = [[NSOperationQueue alloc] init];
    alwaysIncludeCount = 10;
    PM = [[Persistence alloc] init];
    self.orderBy = 1;
    self.numStoriesToShow = 50;
    self.numDaysToShow = 3;
    twitterEngine = [[TwitterEngine alloc] initWithCompletedSelector:@selector(twitterIsDone)];
    hasInitialized = false;
    self.feeds = [PM GetAllFeeds];
    self.maxAllowableStoryTimeRead = 200;  //Seconds
    //[self InitializeTwitterFeed];
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
    //    NSLog(@"viewWillUnload");
    //    for (Story *entry in _allEntries) {
    //        [self UpdateStoryRank:entry];
    //        [PM SetStoryRank:entry.storyID toRank:entry.rank];
    //    }
}

- (void)viewDidUnload
{
    [self setBtnGET:nil];
    [self setTextBody:nil];
    [self setToolbar:nil];
    [self setLabelStatus:nil];
    [self setLabelCount:nil];
    [self setLabelLastUpdated:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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

- (void)loadFacebook
{
    self.facebook = [[Facebook alloc] initWithAppId:@"209696695817827" andDelegate:self];
    
    bool checkEveryTime = false;
    if(!checkEveryTime)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"FBAccessTokenKey"] 
            && [defaults objectForKey:@"FBExpirationDateKey"]) {
            self.facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
            self.facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
        }
    }
    
    if (![self.facebook isSessionValid]) {
        NSArray *permissions = [[NSArray alloc] initWithObjects:
                                @"user_likes", 
                                @"read_stream",
                                nil];
        [self.facebook authorize:permissions];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [self.facebook handleOpenURL:url]; 
}

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[self.facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    
}



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
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
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
        [self UpdateFeedRank:self.twitterFeed];
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
}

- (void)initialPopulateFeeds
{
    [PM ClearFeeds];
    [self InitializeTwitterFeed];
    bool showTwitterOnly = false;
    if(!showTwitterOnly)
    {
        [PM AddFeed:[[Feed alloc] initWithName:@"Vikes Geek" 
                                           url:@"http://vikesgeek.blogspot.com/feeds/posts/default" 
                                          type:1
                                          rank:1]];
        [PM AddFeed:[[Feed alloc] initWithName:@"Vegas Chatter" 
                                           url:@"http://feeds.feedburner.com/vegaschatter?format=xml" 
                                          type:1
                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Ray Wenderlich" 
//                                           url:@"http://feeds.feedburner.com/RayWenderlich" 
//                                          type:1
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Las Vegas Startups" 
//                                           url:@"http://feeds.feedburner.com/LasVegasStartups" 
//                                          type:1
//                                          rank:1]];
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
//        [PM AddFeed:[[Feed alloc] initWithName:@"Joel on Software" 
//                                           url:@"http://www.joelonsoftware.com/rss.xml" 
//                                          type:1 
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Ars Technica" 
//                                           url:@"http://feeds.arstechnica.com/arstechnica/index/" 
//                                          type:1 
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Geeking with Greg" 
//                                           url:@"http://glinden.blogspot.com/feeds/posts/default" 
//                                          type:1 
//                                          rank:1]];
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
//        [PM AddFeed:[[Feed alloc] initWithName:@"The Long Now Blog" 
//                                           url:@"http://blog.longnow.org/feed/" 
//                                          type:1 
//                                          rank:1]];
//        [PM AddFeed:[[Feed alloc] initWithName:@"Very Small Array" 
//                                           url:@"http://www.verysmallarray.com/?feed=rss2" 
//                                          type:1 
//                                          rank:1]];
    }
////    [PM AddFeed:[[Feed alloc] initWithName:@"UW Engineering" 
////                                       url:@"http://www.engr.wisc.edu/news/feeds/RR.xml" 
////                                      type:1 
////                                      rank:1]];
//    [PM AddFeed:[[Feed alloc] initWithName:@"Hacker News Summary"
//                                       url:@"http://fulltextrssfeed.com/news.ycombinator.com/rss" 
//                                      type:1 
//                                      rank:1]];
    self.feeds = [PM GetAllFeeds];
}


#pragma mark Twitter

- (NSString *)SaveImageAndGetPathFromURLString:(NSString *)urlStr
{
    NSURL  *url = [NSURL URLWithString:urlStr];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    NSString *filePath = @"";
    NSRange rangeOfDelimiter = [urlStr rangeOfString:@"/" options:NSBackwardsSearch];
    NSString *fileName = [urlStr substringFromIndex:rangeOfDelimiter.location+1];
    if (urlData)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];  
        //NSString *
        filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,fileName];
        [urlData writeToFile:filePath atomically:YES];
    }
    return filePath;
}

- (void)AddTweetAsStory:(Story *)tweetStory
{
    //Feed *storyFeed = [PM GetFeedByID:tweetStory.feedID];
    Feed *storyFeed = [PM GetFeedByURLPath:tweetStory.author];
    if(storyFeed == nil)
    {
        storyFeed = [[Feed alloc] initWithName:tweetStory.author url:tweetStory.author type:3];
        storyFeed.image = [self SaveImageAndGetPathFromURLString:tweetStory.imagePath];
        storyFeed = [PM AddFeedAndGetNewFeed:storyFeed];
    }
    
    tweetStory.feedID = storyFeed.feedID;
    
    tweetStory.imagePath = storyFeed.image;
    
    if(![PM StoryExistsInDB:tweetStory])
    {
        [self UpdateStoryRank:tweetStory];
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

- (void)TweetRetrievalCompleted
{
    [self updatePromptText];
}


#pragma mark Update Prompt Text

- (void)updatePromptText
{
    int numStories = _allEntries.count;
    self.labelCount.text = [NSString stringWithFormat:@"%i Stories",numStories];

    if((self.outstandingFeedsToParse < 1) && twitterEngine.requestCompleted)
    {
        self.labelStatus.text = @"";
        [self.pullToReloadHeaderView setLastUpdatedDate: [NSDate date]];
        [self.pullToReloadHeaderView finishReloading:self.tableView animated:YES];
    }
    else 
    {
        self.labelStatus.text = @"Loading..";
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
                [self UpdateFeedRank:feed];
            }
            
            for (Story *entry in entries) {
                [self UpdateStoryRank:entry];
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

#pragma mark Rank
- (void)UpdateFeedRank:(Feed *)feed
{
    if(feed == nil)
        return;
    
    int rank = 0;
    int numFeedStoriesTotal = 0;
    int numDaysSinceFirstFeedPost = 0;
    float numFeedStoriesPerDay = 0;
    int numReadStories = 0;
    int totalSecondsRead = 0;
    int sumStoryModifiers = 0;
    int avgStoryModifier = 0;
    int rankFromStoryModifier = 0;
    NSDate *earliestDate;
    
    
    if((feed.type == 1) || (feed.type == 2))
    {
        //Total number of feed stories
        numFeedStoriesTotal = [PM GetNumFeedStories:feed.feedID limitedToRead:NO];
        
        //Total days since the feed's first post (on record)
        earliestDate = [PM GetEarliestFeedStoryCreatedDate:feed.feedID];
        
        //Total number of read stories
        numReadStories = [PM GetNumFeedStories:feed.feedID limitedToRead:YES];
        
        totalSecondsRead = [PM GetTotalFeedReadTime:feed.feedID];
    }
    else if((feed.type == 3) || (feed.type == 2))
    {
        //Total number of feed stories
        numFeedStoriesTotal = [PM GetNumFeedStories:feed.feedID limitedToRead:NO];
        
        //Total days since the feed's first post (on record)
        earliestDate = [PM GetEarliestFeedStoryCreatedDate:feed.feedID];
        
        //Total number of read stories
        numReadStories = [PM GetNumFeedStories:feed.feedID limitedToRead:YES];
        
        totalSecondsRead = [PM GetTotalFeedReadTime:feed.feedID];
    }
    
    numDaysSinceFirstFeedPost = [self NumberOfDaysBetweenDate:earliestDate andSecondDate:[NSDate date]];
    
    if(numFeedStoriesTotal < 1)
        numFeedStoriesTotal = 1;
    
    //Total number of feed stories per day (on average) + 1 to include today's stories
    numFeedStoriesPerDay = (float)numFeedStoriesTotal / (numDaysSinceFirstFeedPost + 1);
    
    int rankFromNumStoriesPerDay = 0;
    if(numFeedStoriesPerDay > 0)
        rankFromNumStoriesPerDay = (int)1/numFeedStoriesPerDay;
    if(rankFromNumStoriesPerDay > 10)
        rankFromNumStoriesPerDay = 10;
    else if((rankFromNumStoriesPerDay < 1) && (rankFromNumStoriesPerDay > 0))
        rankFromNumStoriesPerDay = 1;
    
    float fractionRead;
    if(numFeedStoriesTotal > 0)
        fractionRead = (float)numReadStories / numFeedStoriesTotal;
    int rankFromFractionRead = fractionRead * 20;
    
    //Bonus for lots read
    int rankFromBonusForLotsRead = 0;
    if(numReadStories > 10)
        rankFromBonusForLotsRead = 5;
    
    //Amount of time spent reading
    int rankFromTotalSecondsRead = (totalSecondsRead / numFeedStoriesTotal) / 5;
    if(rankFromTotalSecondsRead > 50)
        rankFromTotalSecondsRead = 50;
    
    //Story Modifiers
    sumStoryModifiers = [PM GetTotalStoryModifiersForFeedByID:feed.feedID]*2;
    if(numFeedStoriesTotal != 0)
    {
        avgStoryModifier = sumStoryModifiers / numFeedStoriesTotal;
        rankFromStoryModifier = avgStoryModifier;
    }
    
    int oldRank = feed.rank;
    
    //Sum up rank
    feed.rank = rank + rankFromNumStoriesPerDay + rankFromFractionRead + rankFromTotalSecondsRead + rankFromStoryModifier;
    
    //Send it down to the database if necessary
    if(oldRank != feed.rank)
    {
        [PM SetFeedRank:feed.feedID toRank:feed.rank];
    }
}

- (void)UpdateStoryRank:(Story *)story
{   
    //Total number of feed stories
    //int numFeedStoriesTotal = [PM GetNumFeedStories:story.feedID limitedToRead:NO];
    
    //Total days since the feed's first post (on record)
    //NSDate *earliestDate = [PM GetEarliestFeedStoryCreatedDate:story.feedID];
    //int numDaysSinceFirstFeedPost = [self NumberOfDaysBetweenDate:earliestDate andSecondDate:[N SDate date]];
    
    //Total number of feed stories per day (on average) + 1 to include today's stories
    //float numFeedStoriesPerDay = (float)numFeedStoriesTotal / (numDaysSinceFirstFeedPost + 1);
    
    
    int rankFromNumDateIntervalUnitsSinceCreated;
    
    if([story.source compare:@"Twitter"] == NSOrderedSame)
    {
        int numHoursSinceCreated = [self NumberOfHoursBetweenDate:story.dateCreated andSecondDate:[NSDate date]];
        
        numHoursSinceCreated = abs(numHoursSinceCreated * 2);
        
        if(numHoursSinceCreated > 10)
            numHoursSinceCreated = 10;
        
        rankFromNumDateIntervalUnitsSinceCreated = 10-numHoursSinceCreated;
        //NSLog(@"Story: %i:%i\n%@:%@",numHoursSinceCreated,rankFromNumDateIntervalUnitsSinceCreated,story.dateCreated,[NSDate date]);
    }
    else
    {
        int numDaysSinceCreated = abs([self NumberOfDaysBetweenDate:story.dateCreated andSecondDate:[NSDate date]]);
        
        if(numDaysSinceCreated > 10)
            numDaysSinceCreated = 10;
        
        rankFromNumDateIntervalUnitsSinceCreated = 10-numDaysSinceCreated;
    }
    
    //Days since created
    //int numDaysSinceCreated = [self NumberOfDaysBetweenDate:story.dateCreated andSecondDate:[NSDate date]];
    
    story.rank = rankFromNumDateIntervalUnitsSinceCreated*2;
}

- (void)updateArrayRanks
{
    int numStories = _allEntries.count;
    Story *thisStory;
    for (int i=0; i<numStories; i++) {
        thisStory = [_allEntries objectAtIndex:i];
        [self UpdateStoryRank:thisStory];
        [self SetStoryFeedRank:thisStory];
    }
}

- (void)SetStoryFeedRank:(Story *)story
{
    story.feedRank = [PM GetFeedRankByFeedID:story.feedID];
}


- (void)testPrint:(GDataXMLDocument *)doc
{
    NSArray *userElements = [doc.rootElement elementsForName:@"entry"];
    
    for (GDataXMLElement *userEl in userElements) {
        
        // Name
        NSArray *titles = [userEl elementsForName:@"content "];
        if (titles.count > 0) {
            GDataXMLElement *title = (GDataXMLElement *) [titles objectAtIndex:0];
            
        }
    }
}


#pragma mark Parse Feed

- (void)requestFinished:(ASIHTTPRequest *)request {
//    [self performSelectorInBackground: @selector (requestFinishedBackgroundWorker:) withObject:request];
//}
//- (void)requestFinishedBackgroundWorker:(ASIHTTPRequest *)request {
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
            
            Feed *thisFeed = [PM GetFeedByID:blogID];
            [self UpdateFeedRank:thisFeed];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                for (Story *entry in entries) {
                    [self performSelectorOnMainThread:@selector(insertOrderedStoryWithAnimation:) withObject:entry waitUntilDone:YES];
                    
                    //[self insertOrderedStoryWithAnimation:entry];
                }  
                [self UpdateFeedRank:thisFeed];
            }];
        }
        
        self.outstandingFeedsToParse--;
        if(self.outstandingFeedsToParse < 1)
        {
            self.twitterEngine.requestCompleted = false;
            if(self.loadingMoreStories)
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [twitterEngine getNextOldestTweets:@selector(AddTweetAsStory:) withCompletionHandler:@selector(TweetRetrievalCompleted) withCaller:self count:50];
                    self.loadingMoreStories = false;
                }];
            }
            else
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self refreshTwitter];
                }];
            }
        }
        else 
        {
            [self loadingIsCompleted];
        }
         
        [self updatePromptText];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    
    NSError *error = [request error];
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
                                    alwaysInclude:(storyCount < alwaysIncludeCount)
                            blogID:blogID];
            if(entry == nil)
                return;
            
            bool storyExists = [PM StoryExistsInDB:entry];
            
            if(!storyExists)
            {
                [self UpdateStoryRank:entry];
                entry = [PM AddStoryAndGetNewStory:entry];
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
                                alwaysInclude:(storyCount == alwaysIncludeCount)
                                       blogID:blogID];
        if(entry == nil)
            return;
        
        bool storyExists = [PM StoryExistsInDB:entry];
        if(!storyExists)
        {
            entry = [PM AddStoryAndGetNewStory:entry];
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
        if([articleDate compare:lowerLimitDate] == NSOrderedAscending)
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
        [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(SetStoryAsReadIfVisible:) userInfo:infoDict repeats:YES];
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
    if([story.source compare:@"Twitter"] == NSOrderedSame)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"StoryCellTwitter"];
        UIColor *textColor;
        if(story.isRead)
            textColor = [UIColor grayColor];
        else
            textColor = [UIColor blackColor];
        
        cell.textLabel.textColor = textColor;
        cell.detailTextLabel.textColor = textColor;
        
        //Actually set the text here
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
        titleLabel.text = story.title;
        
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
    else 
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"StoryCellRSS"];
        UIColor *textColor;
        if(story.isRead)
            textColor = [UIColor grayColor];
        else
            textColor = [UIColor blackColor];
        
        cell.textLabel.textColor = textColor;
        cell.detailTextLabel.textColor = textColor;
        
        //Actually set the text here
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
        titleLabel.text = [NSString stringWithFormat:@"%@",story.title];
        
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
        tappedStory.feedRankModifier++;
        [PM SetStoryFeedRankModifier:tappedStory.storyID toValue:tappedStory.feedRankModifier];
        
        [self UpdateFeedRank:[PM GetFeedByID:tappedStory.feedID]];
        [self.tableView reloadData];
    }
}

- (void)storyDown:(id)sender event:(id)event
{
    Story *tappedStory = [self GetStoryForTouchEvent:event];
    if (tappedStory != nil)
    {
        tappedStory.feedRankModifier--;
        [PM SetStoryFeedRankModifier:tappedStory.storyID toValue:tappedStory.feedRankModifier];
        
        [self UpdateFeedRank:[PM GetFeedByID:tappedStory.feedID]];
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
    int numDaysToShow = self.numDaysToShow;
    int numStoriesToShow = self.numStoriesToShow;
    int numFeeds = self.feeds.count;
    int outstandingFeedsToParse = self.outstandingFeedsToParse;
    int numPMStories = [PM GetNumFeedStories:0 limitedToRead:0];
    int numReadPMStories = [PM GetNumFeedStories:0 limitedToRead:1];
    int numMyStories = [PM GetNumFeedStories:2 limitedToRead:0];
    int numTwitterStories = [PM GetNumFeedStoriesBySource:@"Twitter" limitedToRead:0];
    
    
    debugMsg = [debugMsg stringByAppendingFormat:@"NumStories: %i\n",numStories];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumRows:   %i\n",numRows];
    debugMsg = [debugMsg stringByAppendingFormat:@"OldestRank: %i\n",oldestStoryRank];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumDays:   %i\n",numDaysToShow];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumShowStories: %i\n",numStoriesToShow];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumFeeds:   %i\n",numFeeds];
    debugMsg = [debugMsg stringByAppendingFormat:@"outFeeds:   %i\n",outstandingFeedsToParse];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumPMStories:  %i\n",numPMStories];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumUPMStories: %i\n",numReadPMStories];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumMyStories: %i\n",numMyStories];
    debugMsg = [debugMsg stringByAppendingFormat:@"NumTwitter: %i\n",numTwitterStories];
    
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

- (int)NumberOfDaysBetweenDate:(NSDate *)firstDate andSecondDate:(NSDate *)secondDate
{
    NSDate *fromDate;
    NSDate *toDate;
    
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:firstDate];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:secondDate];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}
- (int)NumberOfHoursBetweenDate:(NSDate *)firstDate andSecondDate:(NSDate *)secondDate
{
    NSDate *fromDate;
    NSDate *toDate;
    
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSHourCalendarUnit startDate:&fromDate
                 interval:NULL forDate:firstDate];
    [calendar rangeOfUnit:NSHourCalendarUnit startDate:&toDate
                 interval:NULL forDate:secondDate];
    
    NSDateComponents *difference = [calendar components:NSHourCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference hour];
}

-(void)sendStoryViaEmail:(Story *)storyToSend 
{
    if(storyToSend == nil)
        return;
    
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    mailer.mailComposeDelegate = self;
    
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
    if([[segue identifier] isEqualToString:@"StoryDetail"]){
        
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
    else if ([[segue identifier] isEqualToString:@"FeedManagement"]) {
        FeedsTestViewController *feedView = (FeedsTestViewController *)[segue destinationViewController];
        
        feedView.feeds = self.feeds;
        feedView.parentTableView = self;
        feedView.PM = PM;
    }
    else if ([[segue identifier] isEqualToString:@"openFacebook"]) {
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
        [self UpdateFeedRank:storyFeed];
        
        //Set duration read
        if(openedDate != nil)
        {
            NSTimeInterval diff = [openedDate timeIntervalSinceDate:[NSDate date]];
            int durationRead = -(int)diff;
            if(durationRead > self.maxAllowableStoryTimeRead)
                durationRead = self.maxAllowableStoryTimeRead;
            
            [PM SetStoryDurationRead:story.storyID toDuration:durationRead];
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
    //[self SortTableView];
}

- (void)twitterIsDone
{
    [self loadingIsCompleted];
}

- (void)refreshTwitter
{
    //[self UpdateFeedRank:self.twitterFeed];
    
    [twitterEngine fetchDataWithSelector:@selector(AddTweetAsStory:) withCompletionHandler:@selector(TweetRetrievalCompleted) withCaller:self count:50];
    
    //Update story count and 'Loading' string labels
    [self updatePromptText];
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
    [self initialPopulateFeeds];
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
        [self UpdateStoryRank:entry];
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

- (IBAction)btnCancelLoad:(id)sender {
    self.stopLoading = true;
    [self cancelParsing];
    [self.pullToReloadHeaderView setLastUpdatedDate: [NSDate date]];
    [self.pullToReloadHeaderView finishReloading:self.tableView animated:YES];
}

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
- (IBAction)swipeCellLeft:(id)sender {
    
}

- (void)handleSwipeRTL:(UISwipeGestureRecognizer *)recognizer {
    //    if((recognizer == nil) || (recognizer.view.tag < 1))
    //        return;
    //    int rowIndex = recognizer.view.tag;
    //    Story *swipedStory = [_allEntries objectAtIndex:rowIndex];
    //    NSLog(@"%@",swipedStory.title);
    //    
    //    [self MarkStoryAsRead:swipedStory withOpenedDate:[NSDate date] noRankUpdate:true];
    //    
    //    NSLog(@"Before: %i",_allEntries.count);
    //    [_allEntries removeObjectAtIndex:rowIndex];
    //    NSLog(@"After: %i",_allEntries.count);
    //    [self.tableView reloadData];
}

- (void)handleSwipeLTR:(UISwipeGestureRecognizer *)recognizer {  
    //    NSLog(@"%d = %d |%i",recognizer.direction,recognizer.state,recognizer.view.tag);
}

-(void) pullDownToReloadAction {	
    [self performSelector:@selector(refresh)];
}


- (IBAction)btnDebugInfo:(id)sender {
    [self ShowDebugAlert];
}

@end
