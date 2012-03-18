//
//  Story.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Story : NSObject {
    NSString *title;
    NSString *author;
    NSString *body;
    NSString *source;
    NSString *url;
    NSDate *dateCreated;
    NSDate *dateRetrieved;
    bool read;
}


@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSDate *dateCreated;
@property (nonatomic, copy) NSDate *dateRetrieved;
@property (nonatomic) bool read;

- (id)init;
- (id)initWithTitle:(NSString *)title 
             author:(NSString *)author 
               body:(NSString *)body 
             source:(NSString *)source 
                url:(NSString *)url 
        dateCreated:(NSDate *)dateCreated
               read:(bool)read;
- (void)PopulateDummyData;
- (void)PopulateEmptyData;
- (NSString *)GetDateCreatedString;
- (NSString *)GetDateRetrievedString;
@end
