//
//  ViewController.h
//  PhotoUploadTester
//
//  Created by Adam Hinz on 6/19/13.
//  Copyright (c) 2013 Adam Hinz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (strong) NSOperationQueue *queue;
@property (strong) ALAsset *activeDownloadAsset;
@property (strong) NSMutableArray *downloadedAssets;
@property (strong) NSMutableArray *pendingAssets;
@property (strong) IBOutlet UITableView *table;
@property (strong) ALAssetsLibrary *library;

@end
