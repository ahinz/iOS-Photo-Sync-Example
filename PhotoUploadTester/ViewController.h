//
//  ViewController.h
//  PhotoUploadTester
//
//  Created by Adam Hinz on 6/19/13.
//  Copyright (c) 2013 Adam Hinz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (strong,nonatomic) NSArray *downloadedAssets;
@property (strong,nonatomic) NSArray *pendingAssets;
@property (strong,nonatomic) IBOutlet UITableView *table;

@end
