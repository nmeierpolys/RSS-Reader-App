//
//  Feed.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Feed : NSObject {
    NSString *name;
    NSString *url;
    int type;
}

@property (retain) NSString *name;
@property (retain) NSString *url;
@property int type;

- (id)initWithName:(NSString *)newName
               url:(NSString *)newUrl
              type:(int)newType;

@end
