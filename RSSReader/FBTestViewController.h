//
//  FBTestViewController.h
//  RSSReader
//
//  Created by Nathaniel Meierpolys on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import "Persistence.h"

@interface FBTestViewController : UIViewController <FBRequestDelegate>
{
    Facebook *facebook;
    int offset;
    NSString *lastDate;
    Persistence *PM;
}

@property (nonatomic, retain) Facebook *facebook;
@property (nonatomic) int offset;
@property (nonatomic, retain) NSString *lastDate;
@property (nonatomic, retain) Persistence *PM;

- (IBAction)btnLoad:(id)sender;
@end
