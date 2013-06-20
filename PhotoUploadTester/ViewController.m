//
//  ViewController.m
//  PhotoUploadTester
//
//  Created by Adam Hinz on 6/19/13.
//  Copyright (c) 2013 Adam Hinz. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize downloadedAssets, pendingAssets, table, activeDownloadAsset, library, queue;

static NSString *photoDownloads = @"downloadedphotos";

- (BOOL)downloadedAsset:(ALAsset *)asset {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSArray *downloaded = [defs arrayForKey:photoDownloads];
    
    NSURL *u = [asset valueForProperty:ALAssetPropertyAssetURL];
    
    return u && [downloaded containsObject:[u absoluteString]];
}

-(void)markAsDownloaded:(ALAsset *)asset {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSArray *downloaded = [defs objectForKey:photoDownloads];
    
    if (downloaded == nil) {
        downloaded = [[NSArray alloc] init];
    }
    
    NSURL *u = [asset valueForProperty:ALAssetPropertyAssetURL];
    NSString *url = [u absoluteString];
    
    [defs setObject:[downloaded arrayByAddingObject:url] forKey:photoDownloads];
    [defs synchronize];
}

- (NSDate *)createOrGetAppStartDate {
    NSDate *d = [[NSUserDefaults standardUserDefaults] objectForKey:@"appstart"];
    
    if (!d) {
        d = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setValue:d forKey:@"appstart"];
    }
    
    return d;
}

- (BOOL)assetInDateRange:(ALAsset *)asset {
    NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
    
    return [[self createOrGetAppStartDate] compare:assetDate] == NSOrderedAscending;
}

- (void)syncSendPhoto:(ALAsset *)asset {
    self.activeDownloadAsset = asset;
    [self.table performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    
    NSMutableURLRequest *r = [[NSMutableURLRequest alloc] init];
    [r setURL:[NSURL URLWithString:@"http://localhost:5000/photo"]];
    
    UIImage* image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]];
    
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    
    [r setHTTPBody:data];
    [r setHTTPMethod:@"POST"];
    [r setValue:@"image/jpeg" forHTTPHeaderField:@"content-type"];
    
    NSURLResponse *resp;
    NSError *error;
    
    [NSURLConnection sendSynchronousRequest:r returningResponse:&resp error:&error];
    [self markAsDownloaded:asset];
    [self.downloadedAssets addObject:asset];
    [self.pendingAssets removeObject:asset];
    self.activeDownloadAsset = nil;
    
    [self.table performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.queue = [[NSOperationQueue alloc] init];
    self.library = [[ALAssetsLibrary alloc] init];
    
    self.downloadedAssets = [[NSMutableArray alloc] init];
    self.pendingAssets = [[NSMutableArray alloc] init];
    
    [self updateAssets];
}

- (void)updateAssets {
    [self.downloadedAssets removeAllObjects];
    [self.pendingAssets removeAllObjects];
    
    [self.table reloadData];
    
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                                   if (asset && [self assetInDateRange:asset]) {
                                       if ([self downloadedAsset:asset]) {
                                           [self.downloadedAssets addObject:asset];
                                       } else {
                                           [self.pendingAssets addObject:asset];
                                           [self.queue addOperationWithBlock:^{
                                               [self syncSendPhoto:asset];
                                           }];
                                       }
                                   }
                               }];
                               [self.table performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                               
                           }
                         failureBlock:^(NSError *error) {
                             NSLog(@"Failed");
                         }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    if (indexPath.section == 2) {
        [cell.textLabel setText:@"Reset"];
        return cell;
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
    if (indexPath.section == 2) {
        [[NSUserDefaults standardUserDefaults] setObject:[[NSArray alloc] init] forKey:photoDownloads];
        [self updateAssets];
        return;
    } else if (indexPath.section == 0) {
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
    } else if (section == 1){
        return @"Downloaded";
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [pendingAssets count];
    } else if (section == 1) {
        return [downloadedAssets count];
    } else {
        return 1;
    }
}

@end
