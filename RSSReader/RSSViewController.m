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

@interface RSSViewController ()

@end

@implementation RSSViewController
@synthesize btnGET = _btnGET;
@synthesize textBody = _textBody;
@synthesize textTitle = _textTitle;
@synthesize toolbar = _toolbar;
@synthesize allEntries = _allEntries;
@synthesize feeds = _feeds;
@synthesize queue = _queue;
@synthesize PM = _PM;
@synthesize lowerLimitDate;
@synthesize alwaysIncludeCount = _alwaysIncludeCount;

- (void)viewDidLoad
{
    [super viewDidLoad]; 
    
	// Do any additional setup after loading the view, typically from a nib.
    tempStory = [[Story alloc] init];
    
    self.title = @"Feeds";
    self.allEntries = [NSMutableArray array];
    [self updatePromptText];
    self.queue = [[NSOperationQueue alloc] init];
    self.feeds = [NSArray arrayWithObjects:
                  @"http://vikesgeek.blogspot.com/feeds/posts/default",
                  @"http://www.thanscorner.info/rss",
                  @"http://feeds.feedburner.com/RayWenderlich",
                  @"http://feeds.feedburner.com/LasVegasStartups",
                  @"http://www.dodgycoder.net/feeds/posts/default?alt=rss",
                  @"http://xkcd.com/rss.xml",
                  @"http://www.engadget.com/rss.xml",
                  nil];   
    alwaysIncludeCount = 3;
    PM = [[Persistence alloc] init];
    [PM ClearDB];
    //[self loadSqlStoriesIntoTable];
    //[self refresh];
}

- (void)updatePromptText
{
    int numStories = self.allEntries.count;
    self.toolbar.prompt = [@"Stories: " stringByAppendingFormat:@"%i",numStories];
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
    lowerLimitDate = [NSDate dateWithTimeIntervalSinceNow:-1*60*60*24*2];
    
    for (NSString *feed in _feeds) {
        NSURL *url = [NSURL URLWithString:feed];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setDelegate:self];
        [_queue addOperation:request];
    }    
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
                [entries addObject:entry];
                [PM AddStory:entry];
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
                                        isDirty:NO];
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
            [entries addObject:entry];
            [PM AddStory:entry];
        }
        
    }      
    
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    NSError *error = [request error];
    NSLog(@"Error: %@", error);
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
	cell.textLabel.text = story.title;
	cell.detailTextLabel.text = story.source;
    
    return cell;
}

//Send the cell-specific information to the detail view in a Story object
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([[segue identifier] isEqualToString:@"StoryDetail"]){
        
        //Get a reference to the detail view we're loading
        StoryDetailViewController *detailView = (StoryDetailViewController *)[segue destinationViewController];
        
        //Get the selected Story object
        NSIndexPath *myIndexPath = [self.tableView indexPathForSelectedRow];
        Story *detailStory = [self.allEntries objectAtIndex:[myIndexPath row]];
        
        //Set the story object on the detail view
        detailView.currentStory = detailStory;
    }
}

- (void)viewDidUnload
{
    [self setBtnGET:nil];
    [self setTextBody:nil];
    [self setToolbar:nil];
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

- (IBAction)btnRefresh:(id)sender {
    [self refresh];
}
@end
