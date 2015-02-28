//
//  ViewController.h
//  Orbis
//
//  Created by Michael Krumdick on 2/27/15.
//  Copyright (c) 2015 ND Fresh Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WhirlyGlobeComponent.h>

@interface ViewController : UIViewController <WhirlyGlobeViewControllerDelegate,MaplyViewControllerDelegate>
@property (strong, nonatomic) NSString *lastSelect;
@property (strong, nonatomic) NSMutableArray *listOfArticles;

@end

