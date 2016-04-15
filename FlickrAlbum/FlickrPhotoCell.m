//
//  FlickrPhotoCell.m
//  FlickrAlbum
//
//  Created by Lina Yi.
//  Copyright © 2016 xxx. All rights reserved.
//

#import "FlickrPhotoCell.h"

@implementation FlickrPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:self.imageView];
    }
    return self;
}

- (void)prepareForReuse {
    _photoInfo = nil;
}

// Cell
- (void)setPhotoInfo:(FlickrPhotoInfo *)photoInfo {
    self.imageView.frame = self.bounds;
    _photoInfo = photoInfo;
    // if cell has no image, download
    if (!_photoInfo.thumbnail) {
        __weak FlickrPhotoCell *weakSelf = self;
        _imageView.image = nil;
        [_photoInfo fetchImageWithSize:PhotoSizeMedium completion:^(FlickrPhotoInfo *photoInfo) {
            __strong FlickrPhotoCell *strongSelf = weakSelf;
            if (strongSelf && strongSelf.photoInfo && [strongSelf.photoInfo.ID isEqualToString:photoInfo.ID]) {
                strongSelf.imageView.image = photoInfo.thumbnail;
            }
        }];
    } else {
        _imageView.image = _photoInfo.thumbnail;
    }
}

@end
