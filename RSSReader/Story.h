//
//  Story.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Story : NSObject {
    int storyID;
    NSString *title;
    NSString *author;
    NSString *body;
    NSString *source;
    NSString *url;
    NSDate *dateCreated;
    NSDate *dateRetrieved;
    bool isRead;
    NSString *imagePath;
    bool isFavorite;
    int rank;
    bool isDirty;
    int feedID;
    int durationRead;
    int feedRank;
}

@property (nonatomic) int storyID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSDate *dateCreated;
@property (nonatomic, copy) NSDate *dateRetrieved;
@property (nonatomic) bool isRead;
@property (nonatomic, copy) NSString *imagePath;
@property (nonatomic) bool isFavorite;
@property (nonatomic) int rank;
@property (nonatomic) bool isDirty;
@property (nonatomic) int feedID;
@property (nonatomic) int durationRead;
@property (nonatomic) int feedRank;


- (id)init;
- (id)initWithTitle:(NSString *)title 
             author:(NSString *)author 
               body:(NSString *)body 
             source:(NSString *)source 
                url:(NSString *)url 
        dateCreated:(NSDate *)dateCreated
      dateRetrieved:(NSDate *)dateRetrieved
             isRead:(bool)isRead
          imagePath:(NSString *)imagePath
         isFavorite:(bool)isFavorite
               rank:(int)rank
            isDirty:(bool)isDirty
            storyID:(int)newStoryID
             feedID:(int)newFeedID
       durationRead:(int)newDurationRead;
- (id)initWithID:(int)newStoryID 
           title:(NSString *)newTitle;
- (id)initWithDummyInfo;
- (id)initWithEmpty;
- (void)PopulateDummyData;
- (void)PopulateEmptyData;
- (NSString *)GetDateCreatedString;
- (NSString *)GetDateRetrievedString;
- (NSString *)IsCompleteStory;
- (void)Print;
- (NSComparisonResult)compare:(Story *)otherObject withMode:(int)mode;
- (NSString *)BodyWithURLsAsLinks:(NSString *)bodyToParse;;
@end
