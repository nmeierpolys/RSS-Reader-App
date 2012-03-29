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

- (void)viewDidLoad
{
    [super viewDidLoad]; 
    
	// Do any additional setup after loading the view, typically from a nib.
    tempStory = [[Story alloc] init];
    
    self.title = @"Feeds";
    self.allEntries = [NSMutableArray array];
    [self updatePromptText];
    self.queue = [[NSOperationQueue alloc] init];
    [self initialPopulateFeeds];
    alwaysIncludeCount = 3;
    PM = [[Persistence alloc] init];
    //[PM ClearDB];
    //[self loadSqlStoriesIntoTable];
    //[self refresh];
}

- (void)initialPopulateFeeds
{
    Feed *vikesFeed = [[Feed alloc] initWithName:@"Vikes Geek" url:@"http://vikesgeek.blogspot.com/feeds/posts/default" type:1];
    Feed *rayFeed = [[Feed alloc] initWithName:@"Ray Wenderlich" url:@"http://feeds.feedburner.com/RayWenderlich" type:1];
    Feed *vegasStartupsFeed = [[Feed alloc] initWithName:@"Las Vegas Startups" url:@"http://feeds.feedburner.com/LasVegasStartups" type:1];
    Feed *thansCornerFeed = [[Feed alloc] initWithName:@"ThansCorner" url:@"http://www.thanscorner.info/rss" type:1];
    Feed *dodgyCoderFeed = [[Feed alloc] initWithName:@"Dodgy Coder" url:@"http://www.dodgycoder.net/feeds/posts/default?alt=rss" type:1];
    Feed *xkcdFeed = [[Feed alloc] initWithName:@"xkcd" url:@"http://xkcd.com/rss.xml" type:1];
    Feed *engadgetFeed = [[Feed alloc] initWithName:@"Engadget" url:@"http://www.engadget.com/rss.xml" type:1];
    
    self.feeds = [NSMutableArray arrayWithObjects:vikesFeed, 
                  rayFeed,
                  vegasStartupsFeed,
                  thansCornerFeed,
                  dodgyCoderFeed,
                  xkcdFeed,
                  engadgetFeed,
                  nil];   
}

- (void)updatePromptText
{
    NSLog([NSString stringWithFormat:@"%i",self.outstandingFeedsToParse]);
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
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
//    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)loadSqlStoriesIntoTable
{
    self.allEntries = PM.stories;
    for (Story *entry in self.allEntries) {
        if(![self.allEntries containsObject:entry])
        {
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        }
    }
    [self updatePromptText];
}

- (void)refresh {
    NSLog(@"Refresh - loading feed stories");
    NSLog([NSString stringWithFormat:@"%i",self.outstandingFeedsToParse]);
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

- (void)requestFinished:(ASIHTTPRequest *)request {
    [_queue addOperationWithBlock:^{
        
        NSError *error;
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:[request responseData] 
                                                               options:0 error:&error];
        if (doc == nil) { 
            NSLog(@"Failed to parse %@", request.url);
        } else {
            
            NSMutableArray *entries = [NSMutableArray array];
            
            [self parseFeed:doc.rootElement entries:entries];                
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                for (Story *entry in entries) {
                    int insertIdx = [_allEntries indexForInsertingObject:entry sortedUsingBlock:^(id a, id b) {
                        Story *entry1 = (Story *) a;
                        Story *entry2 = (Story *) b;
                        return [entry1.dateCreated compare:entry2.dateCreated];
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
    }];
    
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

- (void)parseFeed:(GDataXMLElement *)rootElement entries:(NSMutableArray *)entries {   
    if ([rootElement.name compare:@"rss"] == NSOrderedSame) {
        [self parseRss:rootElement entries:entries];
    } else if ([rootElement.name compare:@"feed"] == NSOrderedSame) {                       
        [self parseAtom:rootElement entries:entries];
    } else {
        NSLog(@"Unsupported root element: %@", rootElement.name);
    }    
}

- (void)parseRss:(GDataXMLElement *)rootElement entries:(NSMutableArray *)entries {
    
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
                                    alwaysInclude:(storyCount < alwaysIncludeCount)];
            
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
                                        storyID:0];
    return entry;
}

- (void)parseAtom:(GDataXMLElement *)rootElement entries:(NSMutableArray *)entries {
    
    NSString *blogTitle = [rootElement valueForChild:@"title"];                    
    
    NSArray *items = [rootElement elementsForName:@"entry"];
    bool alwaysInclude = YES;
    int storyCount = 0;
    for (GDataXMLElement *item in items) {
        storyCount++;
        Story *entry = [self parseItemToStory:item 
                                withBlogTitle:blogTitle 
                                     itemType:2 
                                alwaysInclude:(storyCount == alwaysIncludeCount)];
        if(entry == nil)
            return;
        
        bool storyExists = [PM StoryExistsInDB:entry];
        if(!storyExists)
        {
            entry = [PM AddStoryAndGetNewStory:entry];
            [entries addObject:entry];
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
    
    UIColor *textColor;
    if(story.isRead)
        textColor = [UIColor grayColor];
    else
        textColor = [UIColor blackColor];
    
    cell.textLabel.textColor = textColor;
    cell.detailTextLabel.textColor = textColor;
    
    
	cell.textLabel.text = [NSString stringWithFormat:@"%i - %@",story.storyID, story.title];
	cell.detailTextLabel.text = story.source;
    
    return cell;
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
    }
}
 
- (void)MarkStoryAsRead:(Story *)story
{
    [PM MarkStoryAsRead:story.storyID];
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
    NSLog([NSString stringWithFormat:@"Cur: %i   Next:  %i",self.selectedRow,nextRow]);
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
    [PM ClearDB];
    self.allEntries = [NSMutableArray array];
    [self.tableView reloadData];
    [self updatePromptText];
}
- (IBAction)btnRefresh:(id)sender {
    [self refresh];
}
@end
