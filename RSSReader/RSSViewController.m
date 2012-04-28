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

@interface RSSViewController ()

@end

@implementation RSSViewController
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

- (void)viewDidLoad
{
    [super viewDidLoad]; 
    
	// Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"Stories";
    _allEntries = [NSMutableArray array];
    self.feeds = [NSMutableArray array];
    [self updatePromptText];
    self.queue = [[NSOperationQueue alloc] init];
    alwaysIncludeCount = 10;
    PM = [[Persistence alloc] init];
    //[self initialPopulateFeeds];
    //[PM ClearStories];
    self.orderBy = 1;
    self.numStoriesToShow = 100;
    self.numDaysToShow = 3;
    twitterEngine = [[TwitterEngine alloc] init];
    hasInitialized = false;
    self.feeds = [PM GetAllFeeds];
    
    //[self.twitterEngine fetchDataWithSelector:@selector(AddTweetAsStory:) withCaller:self];
    //[self refresh];
}

- (void)viewDidAppear:(BOOL)animated
{
    if(hasInitialized)
        return;
    hasInitialized = true;
    [self loadSqlStoriesIntoTable];
}

- (void)InitializeTwitterFeed
{
    self.twitterFeed = [PM GetFeedByURLPath:@"Twitter"];
    if(self.twitterFeed == nil)
    {
        self.twitterFeed = [[Feed alloc] initWithName:@"Twitter" url:@"Twitter" type:2];
        [PM AddFeed:self.twitterFeed];
        self.twitterFeed = [PM GetLastFeed];
        [self UpdateFeedRank:self.twitterFeed];
        [PM SetFeedRank:self.twitterFeed.feedID toRank:self.twitterFeed.rank];
    }
}

- (void)AddTweetAsStory:(Story *)tweetStory
{
    tweetStory.feedID = self.twitterFeed.feedID;
    
    if(![PM StoryExistsInDB:tweetStory])
    {
        tweetStory = [PM AddStoryAndGetNewStory:tweetStory];
        [self UpdateStoryRank:tweetStory];
        
        [self insertOrderedStoryWithAnimation:tweetStory];
    }
    if(twitterEngine.requestCompleted)
    {
        if(self.outstandingFeedsToParse > 0)
            self.outstandingFeedsToParse--;
        [self updatePromptText];
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
    self.feeds = PM.feeds; 
}

- (void)initialPopulateFeeds
{
    [PM ClearFeeds];
    [self InitializeTwitterFeed];
    [PM AddFeed:[[Feed alloc] initWithName:@"Vikes Geek" 
                                       url:@"http://vikesgeek.blogspot.com/feeds/posts/default" 
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
    [PM AddFeed:[[Feed alloc] initWithName:@"ThansCorner" 
                                       url:@"http://www.thanscorner.info/feed" 
                                      type:1
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Dodgy Coder" 
                                       url:@"http://www.dodgycoder.net/feeds/posts/default?alt=rss" 
                                      type:1
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"xkcd" 
                                       url:@"http://xkcd.com/rss.xml" 
                                      type:1
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Engadget" 
                                       url:@"http://www.engadget.com/rss.xml" 
                                      type:1
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Lifehacker" 
                                       url:@"http://lifehacker.com/top/index.xml" 
                                      type:1
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"10x Software Development" 
                                       url:@"http://feeds.feedburner.com/10xSoftwareDevelopment" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Digital Photography School" 
                                       url:@"http://feeds.feedburner.com/DigitalPhotographySchool" 
                                      type:1 
                                        rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Gawker: Valleywag" 
                                       url:@"http://feeds.gawker.com/valleywag/full" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"GraphJam" 
                                       url:@"http://feeds.feedburner.com/GraphJam" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Joel on Software" 
                                       url:@"http://www.joelonsoftware.com/rss.xml" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Ars Technica" 
                                       url:@"http://feeds.arstechnica.com/arstechnica/index/" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Geeking with Greg" 
                                       url:@"http://glinden.blogspot.com/feeds/posts/default" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Money and Investing" 
                                       url:@"http://feeds.feedburner.com/MoneyAndInvesting" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Official Google Blog" 
                                       url:@"http://googleblog.blogspot.com/feeds/posts/default" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"St. Olaf News Releases" 
                                       url:@"http://www.stolaf.edu/news/index.cfm?fuseaction=RSS" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"TechCrunch" 
                                       url:@"http://feeds.feedburner.com/Techcrunch" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"The Happiness Project" 
                                       url:@"http://feeds.feedburner.com/TheHappinessProject" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"The Long Now Blog" 
                                       url:@"http://blog.longnow.org/feed/" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Very Small Array" 
                                       url:@"http://www.verysmallarray.com/?feed=rss2" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"UW Engineering" 
                                       url:@"http://www.engr.wisc.edu/news/feeds/RR.xml" 
                                      type:1 
                                      rank:1]];
    [PM AddFeed:[[Feed alloc] initWithName:@"Hacker News Summary"
                                       url:@"http://fulltextrssfeed.com/news.ycombinator.com/rss" 
                                      type:1 
                                      rank:1]];
    self.feeds = PM.feeds; 
}

- (void)updatePromptText
{
    int numStories = _allEntries.count;
    self.labelCount.text = [NSString stringWithFormat:@"%i Stories",numStories];
    if(self.outstandingFeedsToParse < 1)
        self.labelStatus.text = @"";
    else
        self.labelStatus.text = @"Loading..";
    
    if(self.outstandingFeedsToParse < 1)
    {
        [self.pullToReloadHeaderView setLastUpdatedDate: [NSDate date]];
        [self.pullToReloadHeaderView finishReloading:self.tableView animated:YES];
    }
}

- (void)enteringBackground
{
    [PM shutItDown];
}

- (void)enteringForeground
{
    [PM initializeDatabaseIfNeeded];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}



- (void)loadSqlStoriesIntoTable
{
    NSMutableArray *entries = [PM GetTopUnreadStories:self.orderBy numStories:self.numStoriesToShow];
    NSMutableArray *feeds = [PM GetAllFeeds];
    
    bool addStoryViaInsert = true;
    
    if(addStoryViaInsert)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            for (Feed *feed in feeds) {
                [self UpdateFeedRank:feed];
                [PM SetFeedRank:feed.feedID toRank:feed.rank];
            }
            
            for (Story *entry in entries) {
                [self UpdateStoryRank:entry];
                //[PM SetStoryRank:entry.storyID toRank:entry.rank];
            }
            
            for (Story *entry in entries) {
                [self insertOrderedStoryWithAnimation:entry];
            }  
            [self.tableView reloadData];
            [self updatePromptText];
        }];
    }
    else 
    {
        for (Feed *feed in feeds) {
            [self UpdateFeedRank:feed];
            [PM SetFeedRank:feed.feedID toRank:feed.rank];
        }
        
        for (Story *entry in entries) {
            [self UpdateStoryRank:entry];
            //[PM SetStoryRank:entry.storyID toRank:entry.rank];
        }
        _allEntries = entries;
        [self.tableView reloadData];
        [self updatePromptText];
    }
}

-(void)insertOrderedStoryWithAnimation:(Story *)newStory
{
    if((newStory != nil) && (![_allEntries containsObject:newStory]))
    {   
        int insertIdx = [_allEntries indexForInsertingObject:newStory sortedUsingBlock:^(id a, id b) {
            return [self compareStory:(Story *)a withStory:(Story *)b];
        }];     
        [_allEntries insertObject:newStory atIndex:insertIdx];
        //NSLog(newStory.title);
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:insertIdx inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        [self updatePromptText];
    }
}

-(void) pullDownToReloadAction {	
    [self performSelector:@selector(refresh)];
}

- (void)refresh {
    //Update lastUpdated property
    self.stopLoading = false;
    self.lastUpdated = [NSDate date];
    
    //Set earliest date to pick up stories from
    lowerLimitDate = [NSDate dateWithTimeIntervalSinceNow:-1*60*60*24*numDaysToShow];
    
    //Kick off request for each feed
    for (Feed *feed in _feeds) {
        self.outstandingFeedsToParse++;
        if(feed.type == 2)
        {
            self.outstandingFeedsToParse--;
            //[PM SetFeedRank:self.twitterFeed.feedID toRank:[self ComputeFeedRank:self.twitterFeed]];
            //[twitterEngine fetchDataWithSelector:@selector(AddTweetAsStory:) withCaller:self count:60];
        }
        else {
            NSURL *url = [NSURL URLWithString:feed.url];
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
            [request setDelegate:self];
            [_queue addOperation:request];
        }
    }    
    
    //Update story count and 'Loading' string labels
    [self updatePromptText];
}

- (int)GetFeedIDFromURL:(NSURL *)url
{
    NSString *urlString = url.absoluteString;
    Feed *feed  = [PM GetFeedByURLPath:urlString];
    return feed.feedID;
}

- (void)UpdateFeedRank:(Feed *)feed
{
    if(feed == nil)
        return 0;
    
    int rank = 0;

    //Total number of feed stories
    int numFeedStoriesTotal = [PM GetNumFeedStories:feed.feedID limitedToRead:NO];
    
    //Total days since the feed's first post (on record)
    NSDate *earliestDate = [PM GetEarliestFeedStoryCreatedDate:feed.feedID];
    int numDaysSinceFirstFeedPost = [self NumberOfDaysBetweenDate:earliestDate andSecondDate:[NSDate date]];
    
    //Total number of feed stories per day (on average) + 1 to include today's stories
    float numFeedStoriesPerDay = (float)numFeedStoriesTotal / (numDaysSinceFirstFeedPost + 1);
    
    int rankFromNumStoriesPerDay = 0;
    if(numFeedStoriesPerDay > 0)
        rankFromNumStoriesPerDay = (int)1/numFeedStoriesPerDay;
    if(rankFromNumStoriesPerDay > 10)
        rankFromNumStoriesPerDay = 10;
    else if((rankFromNumStoriesPerDay < 1) && (rankFromNumStoriesPerDay > 0))
        rankFromNumStoriesPerDay = 1;
    
    
    //Total number of read stories
    int numReadStories = [PM GetNumFeedStories:feed.feedID limitedToRead:YES];
    
    float fractionRead;
    if(numFeedStoriesTotal > 0)
        fractionRead = (float)numReadStories / numFeedStoriesTotal;
    int rankFromFractionRead = fractionRead * 20;
    //NSLog(@"NumRead:%i  NumTotal:%i",numReadStories,numFeedStoriesTotal);
    
    
    //Bonus for lots read
    int rankFromBonusForLotsRead = 0;
    if(numReadStories > 10)
        rankFromBonusForLotsRead = 5;
    
    //Amount of time spent reading
    int totalSecondsRead = [PM GetTotalFeedReadTime:feed.feedID];
    int rankFromTotalSecondsRead = totalSecondsRead / 10;
    
    feed.rank = rank + rankFromNumStoriesPerDay + rankFromFractionRead + rankFromTotalSecondsRead;
    
    //NSLog(@"Num/Day:%i  FractionRead:%i  SecRead:%i  Total:%i",
    //      rankFromNumStoriesPerDay,
      //    rankFromFractionRead,
        //  rankFromTotalSecondsRead);
}

- (void)UpdateStoryRank:(Story *)story
{
    int rank;
    Feed *storyFeed = [PM GetFeedByID:story.feedID];
    
    int feedRank = storyFeed.rank;
    
    //Total number of feed stories
    int numFeedStoriesTotal = [PM GetNumFeedStories:story.feedID limitedToRead:NO];
    
    //Total days since the feed's first post (on record)
    NSDate *earliestDate = [PM GetEarliestFeedStoryCreatedDate:story.feedID];
    int numDaysSinceFirstFeedPost = [self NumberOfDaysBetweenDate:earliestDate andSecondDate:[NSDate date]];
    
    //Total number of feed stories per day (on average) + 1 to include today's stories
    float numFeedStoriesPerDay = (float)numFeedStoriesTotal / (numDaysSinceFirstFeedPost + 1);
    
    
    //Days since created
    int numDaysSinceCreated = [self NumberOfDaysBetweenDate:story.dateCreated andSecondDate:[NSDate date]];
    
    if(numDaysSinceCreated > 10)
        numDaysSinceCreated = 10;
    
    int rankFromNumDaysSinceCreated = 10-numDaysSinceCreated;
    
    
    //Consider Feed 
    
    story.rank = feedRank + rankFromNumDaysSinceCreated*2;
    //NSLog(@"ID: %i, Rank: %i, F-rank: %i, 10-NumDays: %i",story.storyID,rank,feedRank,rankFromNumDaysSinceCreated);
    //return rank;
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

- (void)updateArrayRanks
{
    int numStories = _allEntries.count;
    Story *thisStory;
    for (int i=0; i<numStories; i++) {
        thisStory = [_allEntries objectAtIndex:i];
        [self UpdateStoryRank:thisStory];
    }
}


- (void)requestFinished:(ASIHTTPRequest *)request {
        int blogID = 1;
        blogID = [self GetFeedIDFromURL:[request url]];
        NSError *error;
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:[request responseData] 
                                                               options:0 error:&error];
        
        if(!self.stopLoading)
        {
            if (doc == nil) {
                NSLog(@"Failed to parse %@", request.url);
            } else {
                
                NSMutableArray *entries = [[NSMutableArray alloc] init];
                //NSMutableArray *entries = [NSMutableArray array];
                
                [self parseFeed:doc.rootElement entries:entries blogID:blogID];                
                
                Feed *thisFeed = [PM GetFeedByID:blogID];
                [self UpdateFeedRank:thisFeed];
                [PM SetFeedRank:blogID toRank:thisFeed.rank];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    //NSLog(@"%i",blogID);
                    for (Story *entry in entries) {
                        [self insertOrderedStoryWithAnimation:entry];
                    }  
                }];
            }
        }
        self.outstandingFeedsToParse--;
        [self updatePromptText];
    
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
        if(entry1.rank > entry2.rank)
            result = NSOrderedDescending;
        else if(entry1.rank < entry2.rank)
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

- (void)StoryRetrievalComplete
{
    [self updatePromptText];
    [self loadSqlStoriesIntoTable];
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
            //NSLog(entry.title);
            if(entry == nil)
                return;
            
            bool storyExists = [PM StoryExistsInDB:entry];
            if(!storyExists)
            {
                entry = [PM AddStoryAndGetNewStory:entry];
                if(entry != nil)
                    [entries addObject:entry];
            }
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
                    durationRead:0];
    [self UpdateStoryRank:entry];
    return entry;
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
            //[entries addObject:entry];
        }
        
    }      
    
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    
    NSError *error = [request error];
    self.outstandingFeedsToParse--;
}


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
        return 60;
    }
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
        rankLabel.text = [NSString stringWithFormat:@"%i",story.rank];
        
        UILabel *authorLabel = (UILabel *)[cell viewWithTag:103];
        authorLabel.text = [@"@" stringByAppendingString:story.author];
        
        UILabel *createdLabel = (UILabel *)[cell viewWithTag:104];
        createdLabel.text = [story GetDateCreatedString];
        
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
        rankLabel.text = [NSString stringWithFormat:@"%i",story.rank];
        
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
        
    return cell;
}

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
    NSString *emailBody = [NSString stringWithFormat:@"%@\n\n<br><br><b>%@</b><br>%@\n\n<br><br>%@",header,storyToSend.title,[storyToSend GetDateCreatedString],storyToSend.body];
    
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
        
        //[self MarkStoryAsRead:detailStory];
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
}
- (void)MarkCurrentStoryAsReadWithOpenedDate:(NSDate *)openedDate
{
    [self MarkStoryAsRead:[self GetSelectedStory] withOpenedDate:openedDate];
}
 
- (void)MarkStoryAsRead:(Story *)story withOpenedDate:(NSDate *)openedDate
{
    //Mark as read
    [PM MarkStoryAsRead:story.storyID];
    story.isRead = true;
    
    //Update Feed rank
    Feed *storyFeed = [PM GetFeedByID:story.feedID];
    storyFeed.timesRead++;
    [self UpdateFeedRank:storyFeed];
    [PM SetFeedRank:storyFeed.feedID toRank:storyFeed.rank];
    
    //Set duration read
    if(openedDate != nil)
    {
        NSTimeInterval diff = [openedDate timeIntervalSinceDate:[NSDate date]];
        int durationRead = -(int)diff;
        [PM SetStoryDurationRead:story.storyID toDuration:durationRead];
    }
    
    //Update Story rank
    [self UpdateStoryRank:story];
    [PM SetStoryRank:story.storyID toRank:story.rank];
    
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

- (void)applicationWillTerminate
{
//    NSLog(@"TerminatingView");
//    for (Story *entry in _allEntries) {
//        [self UpdateStoryRank:entry];
//        [PM SetStoryRank:entry.storyID toRank:entry.rank];
//    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)btnClear:(id)sender {
    [PM ClearStories];
    _allEntries = [NSMutableArray array];
    [self.tableView reloadData];
    [self updatePromptText];
}

- (IBAction)btnReFeed:(id)sender {
    [PM ClearFeeds];
    [self initialPopulateFeeds];
}

- (IBAction)btnLoadMoreStories:(id)sender {
    [twitterEngine getNextOldestTweets:@selector(AddTweetAsStory:) withCaller:self count:50];
}

- (IBAction)btnCancelLoad:(id)sender {
    self.stopLoading = true;
    [self.pullToReloadHeaderView setLastUpdatedDate: [NSDate date]];
    [self.pullToReloadHeaderView finishReloading:self.tableView animated:YES];
}

- (IBAction)btnSort:(id)sender {
    [self updateArrayRanks];
    [self sortArray];
    [self.tableView reloadData];
}

- (IBAction)btnSend:(id)sender {
}

- (IBAction)btnRefresh:(id)sender {
    [self refresh];
}
@end
