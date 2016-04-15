//
//  FlickrPhotoInfo.m
//  FlickrAlbum
//
//  Created by Lina Yi.
//  Copyright © 2016 xxx. All rights reserved.
//

#import "FlickrPhotoInfo.h"

@implementation FlickrPhotoInfo

- (instancetype)initWithID:(NSString*)ID secret:(NSString*)secret server:(NSString*)server farm:(NSString*)farm title:(NSString*)title {
    self = [super init];
    if (self) {
        self.ID = ID;
        self.secret = secret;
        self.server = server;
        self.farm = farm;
        self.title = title;
    }
    return self;
}


- (NSString*)constructUrlWithPhotoSize:(PhotoSize)size {
    NSString *sizeStr = @"s";
    switch (size) {
        case PhotoSizeMedium:
            sizeStr = @"m";
            break;
        case PhotoSizeBig:
            sizeStr = @"b";
            break;
        default:
            sizeStr = @"s";
            break;
    }
    // construct http WithPhotoSize
    return [NSString stringWithFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_%@.jpg", _farm, _server, _ID, _secret, sizeStr];
}

// fetchImageWithSize
- (void)fetchImageWithSize:(PhotoSize)size completion:(void (^)(FlickrPhotoInfo* photoInfo))completion {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        NSString *url = [self constructUrlWithPhotoSize:size];
        // get image data from server
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        dispatch_async(dispatch_get_main_queue(), ^{
            // dispatch_get_main_queue，image data
            UIImage *image = [UIImage imageWithData:imageData];
            if (size == PhotoSizeMedium) {
                _thumbnail = image;
            } else {
                _largeImage = image;
            }
            // block
            completion(self);
        });
    });
}

@end
