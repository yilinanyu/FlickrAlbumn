//
//  FlickrPhotoCell.h
//  FlickrAlbum
//
//  Created by Lina Yi.
//  Copyright © 2016 xxx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlickrPhotoInfo.h"

@interface FlickrPhotoCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;   

@property (nonatomic, strong) FlickrPhotoInfo *photoInfo;

@end
