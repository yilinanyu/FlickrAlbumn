//
//  FlickrPhotoInfo.h
//  FlickrAlbum
//
//  Created by Lina Yi.
//  Copyright © 2016 xxx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef enum {
    PhotoSizeSmall = 0,
    PhotoSizeMedium = 1,
    PhotoSizeBig = 2,
} PhotoSize;

// jason data
@interface FlickrPhotoInfo : NSObject

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *secret;
@property (nonatomic, strong) NSString *server;
@property (nonatomic, strong) NSString *farm;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic, strong) UIImage *largeImage;

- (instancetype)initWithID:(NSString*)ID secret:(NSString*)secret server:(NSString*)server farm:(NSString*)farm title:(NSString*)title;


- (NSString*)constructUrlWithPhotoSize:(PhotoSize)size;

// fetchImageWithSize
- (void)fetchImageWithSize:(PhotoSize)size completion:(void (^)(FlickrPhotoInfo* photoInfo))completion;
@end
