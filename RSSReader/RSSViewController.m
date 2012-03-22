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
@synthesize allEntries = _allEntries;
@synthesize feeds = _feeds;
@synthesize queue = _queue;
@synthesize PM = _PM;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    tempStory = [[Story alloc] init];
    
    self.title = @"Feeds";
    self.allEntries = [NSMutableArray array];
    self.queue = [[NSOperationQueue alloc] init];
    self.feeds = [NSArray arrayWithObjects:
                  @"http://vikesgeek.blogspot.com/feeds/posts/default",
                  @"http://www.thanscorner.info/rss",
                  nil];   
    PM = [[Persistence alloc] init];
    [PM ClearDB];
    [self loadSqlStoriesIntoTable];
    [self refresh];
}

- (void)loadSqlStoriesIntoTable
{
    self.allEntries = PM.stories;
}

- (void)refresh {
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
            
            //[self testPrint:doc];
            
            [self parseFeed:doc.rootElement entries:entries];                
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                for (Story *entry in entries) {
                    
                    int insertIdx = [_allEntries indexForInsertingObject:entry sortedUsingBlock:^(id a, id b) {
                        Story *entry1 = (Story *) a;
                        Story *entry2 = (Story *) b;
                        return [entry1.dateCreated compare:entry2.dateCreated];
                    }];           
                    [PM AddStory:entry];
                    Story *newEntry = [PM GetLastStory];
                    if(newEntry != nil)
                    {
                        [_allEntries insertObject:newEntry atIndex:insertIdx];
                        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:insertIdx inSection:0]] 
                                              withRowAnimation:UITableViewRowAnimationRight];
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
        for (GDataXMLElement *item in items) {
            
            NSString *articleTitle = [item valueForChild:@"title"];
            NSString *articleUrl = [item valueForChild:@"link"];            
            NSString *articleDateString = [item valueForChild:@"pubDate"];      
            NSString *articleContent = [item valueForChild:@"content"];
            NSDate *articleDate = [NSDate dateFromInternetDateTimeString:articleDateString formatHint:DateFormatHintRFC822];
            
            Story *entry = [[Story alloc] initWithTitle:articleTitle
                                                 author:@"n/a"
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
            [entries addObject:entry];
            
        }      
    }
    
}

- (void)parseAtom:(GDataXMLElement *)rootElement entries:(NSMutableArray *)entries {
    
    NSString *blogTitle = [rootElement valueForChild:@"title"];                    
    
    NSArray *items = [rootElement elementsForName:@"entry"];
    for (GDataXMLElement *item in items) {
        
        NSString *articleTitle = [item valueForChild:@"title"];
        NSString *articleUrl = nil;
        NSString *articleContent = [item valueForChild:@"content"];
        NSArray *links = [item elementsForName:@"link"];        
        for(GDataXMLElement *link in links) {
            NSString *rel = [[link attributeForName:@"rel"] stringValue];
            NSString *type = [[link attributeForName:@"type"] stringValue]; 
            if ([rel compare:@"alternate"] == NSOrderedSame && 
                [type compare:@"text/html"] == NSOrderedSame) {
                articleUrl = [[link attributeForName:@"href"] stringValue];
            }
        }
        
        NSString *articleDateString = [item valueForChild:@"updated"];  
        NSDate *articleDate = [NSDate dateFromInternetDateTimeString:articleDateString formatHint:DateFormatHintRFC3339];

        
        Story *entry = [[Story alloc] initWithTitle:articleTitle
                                             author:@"n/a"
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
        [entries addObject:entry];
        
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
	cell.detailTextLabel.text = story.GetDateCreatedString;
    
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

@end
