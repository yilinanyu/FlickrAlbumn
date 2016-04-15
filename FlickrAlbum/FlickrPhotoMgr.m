//
//  FlickrPhotoMgr.m
//  FlickrAlbum
//
//  Created by Lina Yi.
//  Copyright © 2016 xxx. All rights reserved.
//

#import "FlickrPhotoMgr.h"
#import "FlickrPhotoInfo.h"

@interface FlickrPhotoMgr ()

@property (nonatomic, assign) NSUInteger currentPage;   // current page, when scrolls plus 1
@property (nonatomic, assign) NSUInteger totalPage;     // total page

@property (nonatomic, strong) NSString *searchText;     // search text

@property (nonatomic, assign) CGRect oldFrame;          // when viewing the original pages, make node on the original location used for animation

@end

@implementation FlickrPhotoMgr

+ (instancetype)getInstance
{
    static FlickrPhotoMgr *s_mgr = nil;
    static dispatch_once_t onceTokenAudio;
    dispatch_once(&onceTokenAudio, ^{
        s_mgr = [FlickrPhotoMgr new];
    });
    
    return s_mgr;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _currentPage = 1;
        _totalPage = 0;
    }
    return self;
}

// by Flickr API get Flickr Data
/***************************************************
URL，"https://api.flickr.com/services/rest/"
 "https://www.flickr.com/services/api/"
 api_key :
 per_page :
 page :
 text :
 format=json :
 **************************************************/
- (void)getFlickrAlbumWithPage:(NSUInteger)curPage perPageCount:(NSUInteger)perPageCount isSearch:(BOOL)isSearch completion:(void(^)(NSArray *photos))completion
{
    NSString *urlStr = nil;
    if (isSearch) {
        urlStr = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=86997f23273f5a518b027e2c8c019b0f&text=%@&per_page=%lu&page=%lu&format=json&nojsoncallback=1&extras=url_q,url_z", self.searchText, perPageCount, curPage];
    } else {
        urlStr = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.interestingness.getList&api_key=86997f23273f5a518b027e2c8c019b0f&per_page=%lu&page=%lu&format=json&nojsoncallback=1&extras=url_q,url_z", perPageCount, curPage];
    }
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    //creat URL request
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // sendAsynchronous URL Request，get JOSN data includes the image information
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        /**
         *change the data to dictionary
         *data: data need to be implement
         *options    NSJSONReadingMutableContainers
         NSJSONReadingMutableLeaves
         NSJSONReadingAllowFragments
         *
         */
        if (data) {
            // CHANGE JOSN DATA to dictionary
            NSMutableDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"%@",responseObject);
            
            // parse dictionary，put photo information into photos list，
            _totalPage = [responseObject[@"photos"][@"pages"] unsignedIntegerValue];
            NSArray *arr = responseObject[@"photos"][@"photo"];
            NSMutableArray *photos = [NSMutableArray array];
            [arr enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                FlickrPhotoInfo *photoInfo = [[FlickrPhotoInfo alloc] initWithID:obj[@"id"]
                                                                          secret:obj[@"secret"]
                                                                          server:obj[@"server"]
                                                                            farm:obj[@"farm"]
                                                                           title:obj[@"title"]];
                [photos addObject:photoInfo];
            }];
            // completion
            completion(photos);
        }
    }];
}

////////////////////////////////////////////////////////////////////////////////

- (void)getFlickrFirstPage:(NSUInteger)perPageCount completion:(void (^)(NSArray *))completion
{
    _currentPage = 1;
    [self getFlickrAlbumWithPage:_currentPage perPageCount:perPageCount isSearch:NO completion:completion];
}

- (void)getFlickrNextPage:(NSUInteger)perPageCount completion:(void (^)(NSArray *))completion
{
    [self getFlickrAlbumWithPage:++_currentPage perPageCount:perPageCount isSearch:NO completion:completion];
}

////////////////////////////////////////////////////////////////////////////////

- (void)searchFlickrForText:(NSString*)text perPageCount:(NSUInteger)perPageCount completion:(void(^)(NSArray *photos))completion
{
    self.searchText = text;
    _currentPage = 1;
    [self getFlickrAlbumWithPage:_currentPage perPageCount:perPageCount isSearch:YES completion:completion];
}

- (void)searchFlickrNextPage:(NSUInteger)perPageCount Completion:(void(^)(NSArray *photos))completion
{
    [self getFlickrAlbumWithPage:++_currentPage perPageCount:perPageCount isSearch:YES completion:completion];
}

///////////////////////////////////////////////////////////////////////////////
// pop up a window to show large image, firstly zoom the thumbimage, then dispatch queue to download large image
// after downloading the large image, change to the large image, we can see a blured image firesly, then change clearly
// thumbImageView : Cell
// photoInfo :
- (void)showOriginImageWithThumb:(UIImageView *)thumbImageView andPhotoInfo:(FlickrPhotoInfo *)photoInfo
{
    // window
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    
    
    UIImage *image = thumbImageView.image;
    self.oldFrame = [thumbImageView convertRect:thumbImageView.bounds toView:window];   // old frame position
    backgroundView.backgroundColor = [UIColor blackColor];  // black backgroud color
    backgroundView.alpha = 0;
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:self.oldFrame];
    imageView.image = image;
    imageView.tag = 1;
    [backgroundView addSubview:imageView];
    [window addSubview:backgroundView];
    
    // add UITapGestureRecognizer to backgroundView call hideImage
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideImage:)];
    [backgroundView addGestureRecognizer: tap];
    
    // animate the small iamge to the mainScreen and backgroud alpah change
    [UIView animateWithDuration:0.3 animations:^{
        imageView.frame = CGRectMake(0,([UIScreen mainScreen].bounds.size.height-image.size.height*[UIScreen mainScreen].bounds.size.width/image.size.width)/2, [UIScreen mainScreen].bounds.size.width, image.size.height*[UIScreen mainScreen].bounds.size.width/image.size.width);
        
        backgroundView.alpha = 1;
    } completion:^(BOOL finished) {
        // end animate，begin download
        [self loadOriginImage:imageView photoInfo:photoInfo];
    }];
}

// UITapGestureRecognizer change to oldFrame
- (void)hideImage:(UITapGestureRecognizer*)tap
{
    UIView *backgroundView = tap.view;
    UIImageView *imageView = (UIImageView*)[tap.view viewWithTag:1];
    [UIView animateWithDuration:0.3 animations:^{
        // change to the oldFrame
        imageView.frame = self.oldFrame;
        backgroundView.alpha = 0;
    } completion:^(BOOL finished) {
        //removeFromSuperview
        [backgroundView removeFromSuperview];
    }];
}

// loadOriginImage
- (void)loadOriginImage:(UIImageView *)imageView photoInfo:(FlickrPhotoInfo *)cellPhotoInfo
{
    if (!cellPhotoInfo.largeImage) {
        [cellPhotoInfo fetchImageWithSize:PhotoSizeBig completion:^(FlickrPhotoInfo *photoInfo) {
            if (photoInfo.largeImage) {
                imageView.image = photoInfo.largeImage;
            }
        }];
    } else {
        imageView.image = cellPhotoInfo.largeImage;
    }
}

@end
