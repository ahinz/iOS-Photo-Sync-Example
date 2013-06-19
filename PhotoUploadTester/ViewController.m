//
//  ViewController.m
//  PhotoUploadTester
//
//  Created by Adam Hinz on 6/19/13.
//  Copyright (c) 2013 Adam Hinz. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()

@end

@implementation ViewController

@synthesize downloadedAssets, pendingAssets, table;

static NSString *photoDownloads = @"downloadedphotos";

- (BOOL)downloadedAsset:(ALAsset *)asset {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSDictionary *downloaded = [defs dictionaryForKey:photoDownloads];

    NSURL *u = [asset valueForProperty:ALAssetPropertyAssetURL];

    return u && [downloaded objectForKey:[u absoluteString]];
}

- (NSDate *)initAppStartDate {
  NSDate *d = [[NSUserDefaults standardUserDefaults] objectForKey:@"appstart"];

  if (!d) {
    d = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setValue:d forKey:@"appstart"];
  }

  return d;
}

- (BOOL)assetInDateRange:(ALAsset *)asset {
  NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];

  return [[self initAppStartDate] compare:assetDate] == NSOrderedAscending;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableArray *downloadedAssetsM = [NSMutableArray array];
    NSMutableArray *pendingAssetsM = [NSMutableArray array];
    self.downloadedAssets = downloadedAssetsM;
    self.pendingAssets = pendingAssetsM;

    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                                   if (asset && [self assetInDateRange:asset]) {
                                     if ([self downloadedAsset:asset]) {
                                       [downloadedAssetsM addObject:asset];
                                     } else {
                                       [pendingAssetsM addObject:asset];
                                     }
                                   }
                               }];
                               [self.table reloadData];

                           }
                         failureBlock:^(NSError *error) {

                         }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    ALAsset *a;
    if (indexPath.section == 0) {
      a = [self.pendingAssets objectAtIndex:indexPath.row];
    } else {
      a = [self.downloadedAssets objectAtIndex:indexPath.row];
    }

    NSURL *u = [a valueForProperty:ALAssetPropertyAssetURL];
    NSString *s = [u description];
    [cell.textLabel setText:s];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ALAsset *a;
    if (indexPath.section == 0) {
        a = [self.pendingAssets objectAtIndex:indexPath.row];
    } else {
        a = [self.downloadedAssets objectAtIndex:indexPath.row];
    }
    
    CGImageRef image = [[a defaultRepresentation] fullResolutionImage];
    UIImageView *iview = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:image]];

    UIViewController *iviewc = [[UIViewController alloc] init];
    iviewc.view = iview;

    [[self navigationController] pushViewController:iviewc animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Pending";
    } else {
        return @"Downloaded";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return [pendingAssets count];
  } else {
    return [downloadedAssets count];
  }
}

@end
