//
//  FBEngine.m
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FBEngine.h"
#import "FBTestViewController.h"
#import "GDataXMLNode.h"
#import "GDataXMLElement-Extras.h"
#import "Story.h"
#import "Feed.h"
#import "Persistence.h"
#import "Facebook.h"

@implementation FBEngine

@synthesize facebook = _facebook;
@synthesize offset = _offset;
@synthesize lastDate = _lastDate;
@synthesize PM = _PM;
@synthesize methodForAddingStory = _methodForAddingStory;
@synthesize caller = _caller;

- (id)init
{
    if(self = [super init])
    {
        [self loadFacebook];
    }
    
    return self;
}

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
                                @"friends_about_me",
                                @"friends_photos",
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

- (void)GetFBUserInfo:(NSString *)userIDStr
{
    if(userIDStr == nil)
        return;
    
    if(self.facebook != nil)
    {
        NSString *path = [NSString stringWithFormat:@"%@?fields=picture,name&type=large",userIDStr];
        NSLog(@"%@",path);
        [self.facebook requestWithGraphPath:path andDelegate:self];
    } 
}

- (void)request:(FBRequest *)request didLoad:(id)result
{
    if([self StringContainsSubstring:request.url hasSubstring:@"me/home"])
        [self ParsePostResult:request didLoad:result];
    else
        [self ParseUserPictureResult:request didLoad:result];
}
       
- (bool)StringContainsSubstring:(NSString *)testString hasSubstring:(NSString *)testSubstring
{
    NSRange textRange;
    textRange =[testString rangeOfString:testSubstring];
    
    if(textRange.location != NSNotFound)
        return true;
    return false;
}


- (void)ParseUserPictureResult:(FBRequest *)request didLoad:(id)result
{
    if(result == nil)
        return;
    
    NSDictionary *resultArr = (NSDictionary *)result;
    NSString *urlStr = [resultArr objectForKey:@"picture"];
    NSString *name = [resultArr objectForKey:@"name"];
    NSURL  *url = [NSURL URLWithString:urlStr];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    NSString *filePath = @"";
    NSRange rangeOfDelimiter = [urlStr rangeOfString:@"/" options:NSBackwardsSearch];
    NSString *fileName = [urlStr substringFromIndex:rangeOfDelimiter.location+1];
    if (urlData)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];  
        filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,fileName];
        [urlData writeToFile:filePath atomically:YES];
    }
    NSLog(@"%@",filePath);
    [self.PM SetFeedImagePath:filePath forFeedUrl:name];
}

- (void)ParseUserResult:(FBRequest *)request didLoad:(id)result
{
    UIImage *imageView = [[UIImage alloc] initWithData:result];
    
    NSDictionary *resultArr = (NSDictionary *)result;
    NSDictionary *data = (NSDictionary *)[resultArr objectForKey:@"data"];
    int count=0;
    NSLog(@"%@",data);
    
}

- (void)ParsePostResult:(FBRequest *)request didLoad:(id)result
{

    //NSLog(@"Response: %@",result);
    NSDictionary *resultArr = (NSDictionary *)result;
    NSDictionary *data = (NSDictionary *)[resultArr objectForKey:@"data"];
    int count=0;
    for(id element in data)
    {
        id from = (id)[element objectForKey:@"from"];
        NSString *author = [from objectForKey:@"name"];
        NSString *authorID = [from objectForKey:@"id"];
        NSString *message = [element objectForKey:@"message"];
        NSString *story = [element objectForKey:@"story"];
        NSString *description = [element objectForKey:@"description"];
        NSString *type = [element objectForKey:@"type"];
        NSString *dateUpdated = [element objectForKey:@"updated_time"];
        NSString *picturePath = [element objectForKey:@"picture"];
        NSString *linkPath = [element objectForKey:@"link"];
        NSString *id = [element objectForKey:@"id"];
        NSString *profileImagePath = @"http://www.freesmileys.org/emoticons/emoticon-cartoon-002.gif";
        NSString *caption = [element objectForKey:@"caption"];
        NSString *name = [element objectForKey:@"name"];
        NSString *source = [element objectForKey:@"source"];
        
        [self GetFBUserInfo:authorID];
        
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
            
            title = [NSString stringWithFormat:@"%@: %@",@"status",title];
        }
        else if([type compare:@"photo"] == NSOrderedSame)
        {
            stringToShow = [NSString stringWithFormat:@"%@\n%@",picturePath,message];
            title = story;
            
            title = [NSString stringWithFormat:@"%@: %@",@"photo",title];
        }
        else if([type compare:@"link"] == NSOrderedSame)
        {
            stringToShow = [NSString stringWithFormat:@"%@\n%@",linkPath,message];
            title = [self MakeHTMLLinkWithURL:name andName:@"Link"];
            
            title = [NSString stringWithFormat:@"%@: %@",@"link",title];
        }
        else if([type compare:@"checkin"] == NSOrderedSame)
        {
            stringToShow = message;
            title = name;
            
            title = [NSString stringWithFormat:@"%@: %@",@"checkin",title];
        }
        else if([type compare:@"video"] == NSOrderedSame)
        {
            stringToShow = source;
            title = name;
        }
        
        self.lastDate = dateUpdated;
        
        Story *newStory = [[Story alloc] initWithEmpty];
        
        //Author
        newStory.author = author;
        
        //Title
        newStory.title = title;
        
        //Body
        newStory.body = [newStory BodyWithURLsAsLinks:stringToShow];
        
        //Url
        newStory.url = author;
        
        //Source
        newStory.source = @"Facebook";
        
        //Image Path
        //newStory.imagePath = profileImagePath;
        
        //Date Created
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        //[df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        newStory.dateCreated = [df dateFromString:dateUpdated];
        
        methodForAddingStory = self.methodForAddingStory;
        
        [self.caller performSelector:methodForAddingStory withObject:newStory];
        
    }
}

- (NSString *)MakeHTMLLinkWithURL:(NSString *)url andName:(NSString *)name
{
    return [NSString stringWithFormat:@"<a href='%@'>%@</a>",url,name];
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
            NSLog(@"%@",unixTime);
        }
        [self.facebook requestWithGraphPath:path andDelegate:self];
    }
}

- (void)fetchDataWithSelector:(SEL)selector withCompletionHandler:(SEL)complSelector withCaller:(id)caller count:(int)count
{
}

@end
