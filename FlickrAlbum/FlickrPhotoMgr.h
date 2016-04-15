//
//  FlickrPhotoMgr.h
//  FlickrAlbum
//
//  Created by Lina Yi.
//  Copyright © 2016 xxx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define Key_AlbumCol @"AlbumCol"        // Key : image number in each row
#define Key_LoadPage @"LoadPage"        // Key : image pages number every loadpage

#define Default_AlbumCol 4      // Value : default number of images in each row
#define Default_LoadPage 2      // Value : default number of pages every load page

@class FlickrPhotoInfo;

@interface FlickrPhotoMgr : NSObject

+ (instancetype)getInstance;

// Flickr：flickr.interestingness.getList
// https://www.flickr.com/services/api/flickr.interestingness.getList.html
- (void)getFlickrFirstPage:(NSUInteger)perPageCount completion:(void (^)(NSArray *))completion;     // first page
- (void)getFlickrNextPage:(NSUInteger)perPageCount completion:(void(^)(NSArray *photos))completion; // next page


// Flickr method：flickr.photos.search
// https://www.flickr.com/services/api/flickr.photos.search.html
// search api of flickr
- (void)searchFlickrForText:(NSString*)text perPageCount:(NSUInteger)perPageCount completion:(void(^)(NSArray *photos))completion;  //first page
- (void)searchFlickrNextPage:(NSUInteger)perPageCount Completion:(void(^)(NSArray *photos))completion;  // next page

// imagezoom with thumb
- (void)showOriginImageWithThumb:(UIImageView *)thumbImageView andPhotoInfo:(FlickrPhotoInfo *)photoInfo;

@end
