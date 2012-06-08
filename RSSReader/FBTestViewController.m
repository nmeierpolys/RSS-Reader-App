//
//  FBTestViewController.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FBTestViewController.h"
#import "GDataXMLNode.h"
#import "GDataXMLElement-Extras.h"
#import "Story.h"
#import "Feed.h"
#import "Persistence.h"

@interface FBTestViewController ()

@end

@implementation FBTestViewController

@synthesize facebook = _facebook;
@synthesize offset = _offset;
@synthesize lastDate = _lastDate;
@synthesize PM = _PM;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.offset = 0;
    }
    return self;
}
- (void)request:(FBRequest *)request didLoad:(id)result
{
    //NSLog(@"Response: %@",result);
    NSDictionary *resultArr = (NSDictionary *)result;
    NSDictionary *data = (NSDictionary *)[resultArr objectForKey:@"data"];
    int count=0;
    for(id element in data)
    {
        id from = (id)[element objectForKey:@"from"];
        NSString *author = [from objectForKey:@"name"];
        NSString *message = [element objectForKey:@"message"];
        NSString *story = [element objectForKey:@"story"];
        NSString *description = [element objectForKey:@"description"];
        NSString *type = [element objectForKey:@"type"];
        NSString *dateUpdated = [element objectForKey:@"updated_time"];
        NSString *picturePath = [element objectForKey:@"picture"];
        NSString *linkPath = [element objectForKey:@"link"];
        NSString *id = [element objectForKey:@"id"];
        NSString *profileImagePath = [element objectForKey:@""];
        
        NSLog(@"%i",++count);
        NSString *stringToShow;
        NSString *title;
        if([type compare:@"status"] == NSOrderedSame)
        {
            if(message.length > 0)
                stringToShow = message;
            else if(story.length > 0)
                stringToShow = story;
            else 
                stringToShow = description;
            
            if(stringToShow.length > 42)
                title = [[stringToShow substringToIndex:42] stringByAppendingString:@"..."];
            else
                title = stringToShow;
        }
        else if([type compare:@"photo"] == NSOrderedSame)
        {
            stringToShow = [NSString stringWithFormat:@"%@\n%@",picturePath,description];
            title = story;
        }
        else if([type compare:@"link"] == NSOrderedSame)
        {
            stringToShow = [NSString stringWithFormat:@"%@\n%@",linkPath,description];
            title = story;
        }

        self.lastDate = dateUpdated;
        
        //Feed
        Feed *storyFeed = [self.PM GetFeedByURLPath:author];
        if(storyFeed == nil)
        {
            storyFeed = [[Feed alloc] initWithName:author url:author type:4];
            storyFeed.image = [self SaveImageAndGetPathFromURLString:profileImagePath];
            storyFeed = [self.PM AddFeedAndGetNewFeed:storyFeed];
        }
        
        Story *newStory = [[Story alloc] initWithEmpty];
        
        //Author
        newStory.author = author;
        
        //Title
        newStory.title = title;
        
        //Body
        newStory.body = [newStory BodyWithURLsAsLinks:stringToShow];
        
        //Feed ID
        newStory.feedID = storyFeed.feedID;
        
        //Url
        newStory.url = id;
        
        //Source
        newStory.source = @"Facebook";
        
        //Image Path
        newStory.imagePath = storyFeed.image;
        
        
        newStory = [self.PM AddStoryAndGetNewStory:newStory];
        
        NSLog(@"%i/n%@",count,newStory);
    }
    //NSLog(@"%@",resultArr);
}

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

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error 
{
    NSLog(@"Error: %@",error);
}

- (IBAction)btnLoad:(id)sender {
    [self loadFacebookStories];
}

- (void)loadFacebookStories
{
    if(self.facebook != nil)
    {
        self.offset = 25;
        NSString *path = [NSString stringWithFormat:@"me/home?limit=%i",50];
        if(self.lastDate.length > 0)
        {
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            NSDate *date = [formatter dateFromString:self.lastDate];
            
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            NSString * unixTime = [[NSString alloc] initWithFormat:@"%0.0f", timeInterval];
            path = [path stringByAppendingFormat:@"&until=%@",unixTime];
        }
        
        [self.facebook requestWithGraphPath:path andDelegate:self];
    }
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
@end
