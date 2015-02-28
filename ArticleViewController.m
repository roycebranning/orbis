//
//  ArticleViewController.m
//  Orbis
//
//  Created by Michael Krumdick on 2/28/15.
//  Copyright (c) 2015 ND Fresh Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ArticleViewController.h"

@interface UITableViewController ()


@end

@implementation UITableViewController

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView reloadData];
    
    self.view = tableView;
}


@end