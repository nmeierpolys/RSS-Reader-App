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
@synthesize lowerLimitDate;
@synthesize alwaysIncludeCount = _alwaysIncludeCount;
@synthesize outstandingFeedsToParse = _outstandingFeedsToParse;
@synthesize selectedRow = _selectedRow;
@synthesize orderBy = _orderBy;
@synthesize numStoriesToShow = _numStoriesToShow;

- (void)viewDidLoad
{
    [super viewDidLoad]; 
    
	// Do any additional setup after loading the view, typically from a nib.
    tempStory = [[Story alloc] init];
    
    self.title = @"Feeds";
    self.allEntries = [NSMutableArray array];
    self.feeds = [NSMutableArray array];
    [self updatePromptText];
    self.queue = [[NSOperationQueue alloc] init];
    alwaysIncludeCount = 10;
    PM = [[Persistence alloc] init];
    [self initialPopulateFeeds];
    //[PM ClearStories];
    self.orderBy = 1;
    self.numStoriesToShow = 100;
    [self loadSqlStoriesIntoTable];
    //[self refresh];
}

- (void)initialPopulateFeeds
{
    [PM ClearFeeds];
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
                                       url:@"http://fusion.stolaf.edu/news/index.cfm?fuseaction=RSS" 
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
    NSLog(@"# Stories:  %@", [NSString stringWithFormat:@"%i",self.outstandingFeedsToParse]);
    int numStories = self.allEntries.count;
    self.labelCount.text = [NSString stringWithFormat:@"%i Stories",numStories];
    if(self.outstandingFeedsToParse < 1)
        self.labelStatus.text = @"";
    else
        self.labelStatus.text = @"Loading..";
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
    
    bool addStoryViaInsert = false;
    
    if(addStoryViaInsert)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            for (Feed *feed in feeds) {
                int newRank = [self ComputeFeedRank:feed];
                feed.rank = newRank;
                [PM SetFeedRank:feed.feedID toRank:newRank];
            }
            
            for (Story *entry in entries) {
                entry.rank = [self ComputeStoryRank:entry];
                [PM SetStoryRank:entry.storyID toRank:entry.rank];
            }
            
            for (Story *entry in entries) {
                int insertIdx = [self.allEntries indexForInsertingObject:entry sortedUsingBlock:^(id a, id b) {
                    Story *entry1 = (Story *) a;
                    Story *entry2 = (Story *) b;;
                    return [self compareStory:entry1 withStory:entry2];
                }];     
                if(entry != nil)
                {
                    [self.allEntries insertObject:entry atIndex:insertIdx];
                    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:insertIdx inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
                }
            }  
            [self.tableView reloadData];
            [self updatePromptText];
        }];
    }
    else 
    {
        for (Feed *feed in feeds) {
            int newRank = [self ComputeFeedRank:feed];
            feed.rank = newRank;
            [PM SetFeedRank:feed.feedID toRank:newRank];
        }
        
        for (Story *entry in entries) {
            entry.rank = [self ComputeStoryRank:entry];
            [PM SetStoryRank:entry.storyID toRank:entry.rank];
        }
        self.allEntries = entries;
        [self.tableView reloadData];
        [self updatePromptText];
    }
}

- (void)refresh {
    NSLog(@"Refresh - loading feed stories");
    NSLog(@"%@", [NSString stringWithFormat:@"%i",self.outstandingFeedsToParse]);
    lowerLimitDate = [NSDate dateWithTimeIntervalSinceNow:-1*60*60*24*2];
    for (Feed *feed in _feeds) {
        self.outstandingFeedsToParse++;
        NSURL *url = [NSURL URLWithString:feed.url];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setDelegate:self];
        [_queue addOperation:request];
    }    
    [self updatePromptText];
}

- (int)GetFeedIDFromURL:(NSURL *)url
{
    NSString *urlString = url.absoluteString;
    Feed *feed  = [PM GetFeedByURLPath:urlString];
    return feed.feedID;
}

- (int)ComputeFeedRank:(Feed *)feed
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
    int numReadStories = [PM GetNumFeedStories:feed.feedID limitedToRead:true];
    
    float fractionRead;
    if(numFeedStoriesTotal > 0)
        fractionRead = numReadStories / numFeedStoriesTotal;
    int rankFromFractionRead = fractionRead * 10;
    
    
    //Bonus for lots read
    int rankFromBonusForLotsRead = 0;
    if(numReadStories > 10)
        rankFromBonusForLotsRead = 5;
    
    rank = rank + rankFromNumStoriesPerDay + rankFromFractionRead;
    return rank;
}

- (int)ComputeStoryRank:(Story *)story
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
    //NSLog(@"%i",numDaysSinceCreated);
    
    if(numDaysSinceCreated > 10)
        numDaysSinceCreated = 10;
    
    int rankFromNumDaysSinceCreated = 10-numDaysSinceCreated;
    
    
    //Consider Feed 
    
    rank = feedRank + rankFromNumDaysSinceCreated*2;
    //NSLog(@"ID: %i, Rank: %i, F-rank: %i, 10-NumDays: %i",story.storyID,rank,feedRank,rankFromNumDaysSinceCreated);
    return rank;
}


- (void)requestFinished:(ASIHTTPRequest *)request {
    [_queue addOperationWithBlock:^{
        int blogID = 1;
        blogID = [self GetFeedIDFromURL:[request url]];
        //NSLog(request.url.absoluteString);
        NSError *error;
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:[request responseData] 
                                                               options:0 error:&error];
        if (doc == nil) {
            NSLog(@"Failed to parse %@", request.url);
        } else {
            
            NSMutableArray *entries = [NSMutableArray array];
            
            [self parseFeed:doc.rootElement entries:entries blogID:blogID];                
            
            Feed *thisFeed = [PM GetFeedByID:blogID];
            [PM SetFeedRank:blogID toRank:[self ComputeFeedRank:thisFeed]];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                for (Story *entry in entries) {
                    int insertIdx = [_allEntries indexForInsertingObject:entry sortedUsingBlock:^(id a, id b) {
                        Story *entry1 = (Story *) a;
                        Story *entry2 = (Story *) b;
                        return [self compareStory:entry1 withStory:entry2];
                    }];     
                    if(entry != nil)
                    {
                        [_allEntries insertObject:entry atIndex:insertIdx];
                        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:insertIdx inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
                        
                        [self updatePromptText];
                    }
                }  
            }];
        }
        self.outstandingFeedsToParse--;
        [self updatePromptText];
        //if(self.outstandingFeedsToParse < 1)
        //    [self loadSqlStoriesIntoTable];
    }];
    
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
            
            NSLog(@"title is %@", title.stringValue);
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
                                         feedID:blogID];
    
    entry.rank = [self ComputeStoryRank:entry];
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
    //NSLog(@"Error: %@", error);
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView 
                             dequeueReusableCellWithIdentifier:@"StoryCell"];
	Story *story = [self.allEntries objectAtIndex:indexPath.row];
    //[story Print];
    UIColor *textColor;
    if(story.isRead)
        textColor = [UIColor grayColor];
    else
        textColor = [UIColor blackColor];
    
    cell.textLabel.textColor = textColor;
    cell.detailTextLabel.textColor = textColor;
    
    Feed *parentFeed = [PM GetFeedByID:story.feedID];
    
    //Actually set the text here
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
	titleLabel.text = [NSString stringWithFormat:@"%i - %@",story.storyID, story.title];
    
	UILabel *subtitleLabel = (UILabel *)[cell viewWithTag:101];
	subtitleLabel.text = story.source;
    
	UILabel *rankLabel = (UILabel *)[cell viewWithTag:102];
	rankLabel.text = [NSString stringWithFormat:@"Rank: %i",story.rank];
    
	//UILabel *createdLabel = (UILabel *)[cell viewWithTag:103];
	//createdLabel.text = [story GetDateCreatedString];
    
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
    //createdLabel.textColor = textColor;
    //retrievedLabel.textColor = textColor;
    
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

//Send the cell-specific information to the detail view in a Story object
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([[segue identifier] isEqualToString:@"StoryDetail"]){
        
        //Get a reference to the detail view we're loading
        StoryDetailViewController *detailView = (StoryDetailViewController *)[segue destinationViewController];
        
        [self UpdateSelectedRowValue];
        Story *detailStory = [self GetSelectedStory];  
        
        if (detailStory == nil)
            return;
        
        [self MarkStoryAsRead:detailStory];
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
 
- (void)MarkStoryAsRead:(Story *)story
{
    [PM MarkStoryAsRead:story.storyID];
    Feed *storyFeed = [PM GetFeedByID:story.feedID];
    storyFeed.timesRead++;
    storyFeed.rank = [self ComputeFeedRank:storyFeed];
    story.isRead = true;
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
    Story *selectedStory = [self.allEntries objectAtIndex:self.selectedRow];
    
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
    if((self.selectedRow + 2) > (self.allEntries.count))
        nextRow = self.selectedRow;
    else
        nextRow = self.selectedRow + 1;   
    self.selectedRow = nextRow;
}

- (void)viewDidUnload
{
    [self setBtnGET:nil];
    [self setTextBody:nil];
    [self setToolbar:nil];
    [self setLabelStatus:nil];
    [self setLabelCount:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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
    self.allEntries = [NSMutableArray array];
    [self.tableView reloadData];
    [self updatePromptText];
}

- (IBAction)btnReFeed:(id)sender {
    [PM ClearFeeds];
    [self initialPopulateFeeds];
}
- (IBAction)btnRefresh:(id)sender {
    [self refresh];
}
@end
