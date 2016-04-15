//
//  ViewController.m
//  FlickrAlbum
//
//  Created by Lina Yi.
//  Copyright © 2016 xxx. All rights reserved.
//

#import "ViewController.h"
#import "FlickrPhotoCell.h"
#import "FlickrPhotoMgr.h"
#import "ConfigViewController.h"

static NSString * const CellReuseIdentifier = @"FlickrCell";

#define CollectionView_Top 64
#define REFRESH_HEADER_HEIGHT 52.0f

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *searchBar;    // search bar
@property (nonatomic, strong) UICollectionView *collectionView; // collectionView

@property (nonatomic, strong) FlickrPhotoMgr *flickrMgr;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, assign) NSUInteger perPageCount;

@property (nonatomic, assign) BOOL isDragging;

@property (nonatomic, strong) UIView *refreshHeaderView;
@property (nonatomic, strong) UILabel *refreshLabel;
@property (nonatomic, strong) UIActivityIndicatorView *refreshSpinner;
@property (nonatomic, assign) BOOL isRefreshing;

@property (nonatomic, strong) UIView *loadFooterView;
@property (nonatomic, strong) UILabel *loadLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadSpinner;
@property (nonatomic, assign) BOOL isLoading;

// scrolling
@property (nonatomic, strong) NSString *textPull;
@property (nonatomic, strong) NSString *textPush;
@property (nonatomic, strong) NSString *textRelease;
@property (nonatomic, strong) NSString *textLoading;

@property (nonatomic, strong) NSString *curSearchText;

@property (nonatomic, assign) CGFloat itemWidth;  //  Cell width

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.photos = [NSMutableArray new];
    

    self.searchBar.delegate = self;
    
    // collectionView
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumInteritemSpacing = 0.f;
    flowLayout.minimumLineSpacing = 2.f;
    
    CGFloat collectionViewHeight = CGRectGetHeight(self.view.frame)-CollectionView_Top;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CollectionView_Top, CGRectGetWidth(self.view.frame), collectionViewHeight) collectionViewLayout:flowLayout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;     // collectionView alwaysBounceVertical
    
    [self.view addSubview:self.collectionView];
    

    [self addPullToRefreshHeader];
    [self setupStrings];
    

    [self.collectionView registerClass:[FlickrPhotoCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *albumCol = [defaults objectForKey:Key_AlbumCol];
    if (!albumCol) {
        albumCol = [NSNumber numberWithInt:Default_AlbumCol];
        [defaults setObject:albumCol forKey:Key_AlbumCol];
    }
    
    
    NSNumber *loadPage = [defaults objectForKey:Key_LoadPage];
    if (!loadPage) {
        loadPage = [NSNumber numberWithInt:Default_LoadPage];
        [defaults setObject:loadPage forKey:Key_LoadPage];
    }
    
    CGFloat spacingWidth = 2.f;
    CGFloat lineSpacingWidth = spacingWidth * ([albumCol intValue] - 1);
    
    // width and height of every image
    self.itemWidth = (CGRectGetWidth(self.view.frame) - lineSpacingWidth) / [albumCol intValue];
    
    CGFloat collectionViewHeight = CGRectGetHeight(self.view.frame)-CollectionView_Top;
    NSUInteger perPageRow = (NSUInteger)(collectionViewHeight / self.itemWidth);
    self.perPageCount = (perPageRow * [albumCol intValue]) * [loadPage intValue];
    
    self.flickrMgr = [FlickrPhotoMgr getInstance];
    

    [self.flickrMgr getFlickrFirstPage:self.perPageCount completion:^(NSArray *photos) {
        [self.photos addObjectsFromArray:photos];
        [self.collectionView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//configealbum
- (IBAction)configAlbum:(id)sender
{
    ConfigViewController *configVC = [ConfigViewController new];
    [self.navigationController pushViewController:configVC animated:YES];
}

- (void)setupStrings
{
    self.textPull = @"Drop-down refresh...";
    self.textPush = @"Drop-up load...";
    self.textRelease = @"Refresh release...";
    self.textLoading = @"Loading...";
}

- (void)addPullToRefreshHeader
{
    // refreshHeaderView
    self.refreshHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, CGRectGetWidth(self.collectionView.frame), REFRESH_HEADER_HEIGHT)];
    self.refreshHeaderView.backgroundColor = [UIColor clearColor];
    
    self.refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.collectionView.frame), REFRESH_HEADER_HEIGHT)];
    self.refreshLabel.backgroundColor = [UIColor clearColor];
    self.refreshLabel.font = [UIFont boldSystemFontOfSize:12.0];
    self.refreshLabel.textAlignment = NSTextAlignmentCenter;
    
    CGFloat spinnerWidth = 20;
    self.refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.refreshSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT-spinnerWidth)/2.f), floorf((REFRESH_HEADER_HEIGHT-spinnerWidth)/2.f), spinnerWidth, spinnerWidth);
    self.refreshSpinner.hidesWhenStopped = YES;
    
    [self.refreshHeaderView addSubview:self.refreshLabel];
    [self.refreshHeaderView addSubview:self.refreshSpinner];
    [self.collectionView addSubview:self.refreshHeaderView];
    
    // loadFooterView
    self.loadFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.collectionView.frame)-REFRESH_HEADER_HEIGHT, CGRectGetWidth(self.collectionView.frame), REFRESH_HEADER_HEIGHT)];
    self.loadFooterView.backgroundColor = [UIColor clearColor];
    self.loadFooterView.hidden = YES;
    
    self.loadLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.collectionView.frame), REFRESH_HEADER_HEIGHT)];
    self.loadLabel.backgroundColor = [UIColor clearColor];
    self.loadLabel.font = [UIFont boldSystemFontOfSize:12.0];
    self.loadLabel.textAlignment = NSTextAlignmentCenter;
    
    self.loadSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT-spinnerWidth)/2.f), (REFRESH_HEADER_HEIGHT-spinnerWidth)/2.f, spinnerWidth, spinnerWidth);
    self.loadSpinner.hidesWhenStopped = YES;
    
    [self.loadFooterView addSubview:self.loadLabel];
    [self.loadFooterView addSubview:self.loadSpinner];
    [self.view insertSubview:self.loadFooterView belowSubview:self.collectionView];
}

// call scrollViewWillBeginDragging when draging collectionview
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // serch bar quit
    [self.searchBar resignFirstResponder];
    
    if (self.isRefreshing ||self.isLoading) {
        return;
    }
    self.isDragging = YES;
}

// draging collectionView
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.isRefreshing) {
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0)
            self.collectionView.contentInset = UIEdgeInsetsZero;
        else if (scrollView.contentOffset.y >= -REFRESH_HEADER_HEIGHT)
            self.collectionView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (self.isDragging) {
        // updragheight
        CGFloat upDragHeight = scrollView.contentOffset.y + CGRectGetHeight(self.collectionView.frame) - scrollView.contentSize.height;
        
        if (scrollView.contentOffset.y < 0) {   // scroll
            // Update the arrow direction and label
            [UIView animateWithDuration:0.25 animations:^{
                if (scrollView.contentOffset.y < -REFRESH_HEADER_HEIGHT) {
                    // User is scrolling above the header
                    self.refreshLabel.text = self.textRelease;
                } else {
                    // User is scrolling somewhere within the header
                    self.refreshLabel.text = self.textPull;
                }
            }];
        } else if (upDragHeight > 0) {  // drag
            [UIView animateWithDuration:0.25 animations:^{
                if (upDragHeight > REFRESH_HEADER_HEIGHT) {
                    self.loadLabel.text = self.textRelease;
                } else {
                    self.loadFooterView.hidden = NO;
                    self.loadLabel.text = self.textPush;
                }
            }];
        } else {
            self.loadFooterView.hidden = YES;
        }
    }
}

// finish draging collectionView
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.isLoading) {
        return;
    }
    
    self.isDragging = NO;
    
    //upDragHeight
    CGFloat upDragHeight = scrollView.contentOffset.y + CGRectGetHeight(self.collectionView.frame) - scrollView.contentSize.height;
    
    if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT) {
        // startRefreshing
        [self startRefreshing];
    } else if (upDragHeight > REFRESH_HEADER_HEIGHT) {
        // startLoading
        [self startLoading];
    }
}

#pragma mark - refreshing
// startRefreshing
- (void)startRefreshing
{
    self.isRefreshing = YES;
    
    // Show the header
    [UIView animateWithDuration:0.3 animations:^{
        self.collectionView.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
        self.refreshLabel.text = self.textLoading;
        [self.refreshSpinner startAnimating];
    }];
    
    // Refresh action!
    [self refreshAlbum];
}

// stopRefreshing

- (void)stopRefreshing
{
    self.isRefreshing = NO;
    // Hide the header
    [UIView animateWithDuration:0.3 animations:^{
        self.collectionView.contentInset = UIEdgeInsetsZero;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(stopRefreshingComplete)];
    }];
}

// stopRefreshingComplete
- (void)stopRefreshingComplete
{
    // Reset the header
    self.refreshLabel.text = self.textPull;
    [self.refreshSpinner stopAnimating];
}

- (void)refreshAlbum
{
    if (self.curSearchText.length > 0) {
        // searching mode
        [self.flickrMgr searchFlickrForText:self.curSearchText perPageCount:self.perPageCount completion:^(NSArray *photos) {
            [self.photos removeAllObjects];
            [self.photos addObjectsFromArray:photos];
            [self.collectionView reloadData];
            // stopRefreshing after get Flickr data
            [self performSelector:@selector(stopRefreshing) withObject:nil afterDelay:0.5];
        }];
    } else {
        // non searching mode
        [self.flickrMgr getFlickrFirstPage:self.perPageCount completion:^(NSArray *photos) {
            [self.photos removeAllObjects];
            [self.photos addObjectsFromArray:photos];
            [self.collectionView reloadData];
            
            [self performSelector:@selector(stopRefreshing) withObject:nil afterDelay:0.5];
        }];
    }
}

#pragma mark - startLoading
- (void)startLoading
{
    self.isLoading = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, REFRESH_HEADER_HEIGHT, 0);
        self.loadLabel.text = self.textLoading;
        [self.loadSpinner startAnimating];
    }];
    
    [self loadAlbum];
}

// stopLoading
- (void)stopLoading
{
    self.isLoading = NO;
    // Hide the header
    [UIView animateWithDuration:0.3 animations:^{
        self.collectionView.contentInset = UIEdgeInsetsZero;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(stopLoadingComplete)];
    }];
}

// stoploading Complete
- (void)stopLoadingComplete
{
    self.loadLabel.text = self.textPush;
    [self.loadSpinner stopAnimating];
}

- (void)loadAlbum
{
    if (self.curSearchText.length > 0) {
        [self.flickrMgr searchFlickrNextPage:self.perPageCount Completion:^(NSArray *photos) {
            [self.photos addObjectsFromArray:photos];
            [self.collectionView reloadData];
            [self stopLoading];
        }];
    } else {
        [self.flickrMgr getFlickrNextPage:self.perPageCount completion:^(NSArray *photos) {
            [self.photos addObjectsFromArray:photos];
            [self.collectionView reloadData];
            [self stopLoading];
        }];
    }
}

#pragma mark - UITextFieldDelegate
// call this fuction after Return button
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
 
    [self.searchBar resignFirstResponder];
    // save current search text and remove the white space
    self.curSearchText = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // search begin
    [self refreshAlbum];
    
    return YES;
}

#pragma mark - UICollectionViewDataSource
// collectionView how many Item
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
}

// Item
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FlickrPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    cell.photoInfo = self.photos[indexPath.item];
    return cell;
}

#pragma mark - UICollectionViewDelegate
// collectionView call fuction to get the width and height
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    return CGSizeMake(self.itemWidth, self.itemWidth);
}

// click on Item，view large image
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FlickrPhotoCell *cell = (FlickrPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    FlickrPhotoInfo *photoInfo = self.photos[indexPath.row];
    
    // show large image with simple animation 
    [self.flickrMgr showOriginImageWithThumb:cell.imageView andPhotoInfo:photoInfo];
}

@end
