//
//  AHTableViewCell.m
//  PhotoUploadTester
//
//  Created by Adam Hinz on 7/1/13.
//  Copyright (c) 2013 Adam Hinz. All rights reserved.
//

#import "AHTableViewCell.h"

@implementation AHTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
