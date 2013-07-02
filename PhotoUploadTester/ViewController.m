//
//  ViewController.m
//  PhotoUploadTester
//
//  Created by Adam Hinz on 6/19/13.
//  Copyright (c) 2013 Adam Hinz. All rights reserved.
//

#import "ViewController.h"
#import "AHTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

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
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return d;
}

- (BOOL)assetInDateRange:(ALAsset *)asset {
    NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
    NSDate *createDate = [self createOrGetAppStartDate];
    NSComparisonResult diff = [createDate compare:assetDate];
    return diff == NSOrderedAscending;
}

- (void)syncSendPhoto:(ALAsset *)asset {
    self.activeDownloadAsset = asset;
    [self.table performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    
    NSMutableURLRequest *r = [[NSMutableURLRequest alloc] init];
    [r setURL:[NSURL URLWithString:@"http://adamhinz.com:5000/photo"]];
    
    UIImage* image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]];
    
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    
    [r setHTTPBody:data];
    [r setHTTPMethod:@"POST"];
    [r setValue:@"image/jpeg" forHTTPHeaderField:@"content-type"];
    
    NSURLResponse *resp;
    NSError *error;
    
    [NSURLConnection sendSynchronousRequest:r returningResponse:&resp error:&error];
    [self markAsDownloaded:asset];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAssets) name: UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)updateAssets {
    [self.downloadedAssets removeAllObjects];
    [self.pendingAssets removeAllObjects];
    
    [self.table reloadData];
    
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                                   if (asset && [self assetInDateRange:asset]) {
                                       [self.downloadedAssets insertObject:asset atIndex:0];
                                       if (![self downloadedAsset:asset]) {
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
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //static NSString *identifier = @"cell";
    
    AHTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCellId"];
    /*
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
     */
    
    ALAsset *a1, *a2;
//    if (indexPath.section == 0) {
//        a1 = [self.pendingAssets objectAtIndex:indexPath.row*2];
//        a2 = [self.pendingAssets objectAtIndex:indexPath.row*2 + 1];
//    } else {
    a1 = [self.downloadedAssets objectAtIndex:indexPath.row*2];
    a2 = nil;
    
    if (indexPath.row*2 + 1 < [self.downloadedAssets count]) {
        a2 = [self.downloadedAssets objectAtIndex:indexPath.row*2 + 1];
    }
//    }
    
    cell.left.image = [[UIImage alloc] initWithCGImage:[a1 thumbnail]];
    cell.right.image = [[UIImage alloc] initWithCGImage:[a2 thumbnail]];
    
    if (a1 && [self.pendingAssets containsObject:a1]) {
        cell.left.layer.borderColor = self.activeDownloadAsset == a1 ? [UIColor yellowColor].CGColor : [UIColor redColor].CGColor;
        cell.left.layer.borderWidth = 3.0f;
    } else {
        cell.left.layer.borderWidth = 0.0f;
    }
    
    if (a2 && [self.pendingAssets containsObject:a2]) {
        cell.right.layer.borderColor = self.activeDownloadAsset == a2 ? [UIColor yellowColor].CGColor : [UIColor redColor].CGColor;
        cell.right.layer.borderWidth = 3.0f;
    } else {
        cell.right.layer.borderWidth = 0.0f;
    }
    
    //NSURL *u = [a valueForProperty:ALAssetPropertyAssetURL];
    //NSString *s = [u description];
    //[cell.textLabel setText:s];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 149.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ALAsset *a;
//    if (indexPath.section == 2) {
//        [[NSUserDefaults standardUserDefaults] setObject:[[NSArray alloc] init] forKey:photoDownloads];
//        [self updateAssets];
//        return;
//    } else if (indexPath.section == 0) {
//        a = [self.pendingAssets objectAtIndex:indexPath.row];
//    } else {
//        a = [self.downloadedAssets objectAtIndex:indexPath.row];
//    }
    a = [self.downloadedAssets objectAtIndex:indexPath.row];
    
    CGImageRef image = [[a defaultRepresentation] fullResolutionImage];
    UIImageView *iview = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:image]];
    
    UIViewController *iviewc = [[UIViewController alloc] init];
    iviewc.view = iview;
    
    [[self navigationController] pushViewController:iviewc animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [downloadedAssets count] / 2 + ([downloadedAssets count] % 2);
//    if (section == 0) {
//        return [pendingAssets count] / 2 + ([pendingAssets count] % 2);
//    } else if (section == 1) {
//        return [downloadedAssets count] / 2 + ([downloadedAssets count] % 2);
//    } else {
//        return 1;
//    }
}

@end
