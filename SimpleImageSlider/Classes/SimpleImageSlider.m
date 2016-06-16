//
//  SimpleImageSlider.m
//  Pods
//
//  Created by Christian Hatch on 5/31/16.
//
//

#import "SimpleImageSlider.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <Masonry/Masonry.h>

@interface UIImageView (SimpleImageSlider)

- (void)setImageAnimated:(UIImage *)image;
- (void)setImageAnimatedWithURL:(NSURL *)imageURL placeholder:(UIImage *)placeholder;

@end







const CGFloat ImageOffset = 0;

@interface SimpleImageSlider () <UIScrollViewDelegate>
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic) BOOL isObserving;
@property (nonatomic) CGFloat originalTopInset;
@property (nonatomic) CGFloat originalYOffset;
@property (nonatomic) CGFloat parallaxHeight;
@end


@implementation SimpleImageSlider

#pragma mark - Initialization

+ (instancetype)imageSliderWithFrame:(CGRect)frame imageURLs:(NSArray *)imageURLs
{
    SimpleImageSlider *slider = [[SimpleImageSlider alloc] initWithFrame:frame];
    slider.imageURLs = imageURLs;
    return slider;
}

+ (instancetype)imageSliderWithFrame:(CGRect)frame images:(NSArray<UIImage *> *)images
{
    SimpleImageSlider *slider = [[SimpleImageSlider alloc] initWithFrame:frame];
    slider.images = images;
    return slider;
}

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.isObserving = NO;
    self.pagingEnabled = YES;
    self.showsHorizontalScrollIndicator = NO;
    self.backgroundColor = [UIColor clearColor];
    self.delegate = self;
}

#pragma mark - Helpers

- (NSInteger)currentPage
{
    CGFloat pageWidth = self.frame.size.width;
    NSUInteger page = floor((self.contentOffset.x - (pageWidth + ImageOffset) / 2.0f) / (pageWidth + ImageOffset)) + 1;
    return page;
}


#pragma mark - Main Method

- (void)updateUI
{
    //bail if we don't have any data
    if ([self proxyData] == nil) {
        return;
    }

    //first clear out all extant imageviews
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    //get sizes
    CGFloat height = self.frame.size.height;
    CGFloat width = self.frame.size.width;
    
        //iterate through the imageobjects and create an imageview
    for (int i = 0; i < [self proxyData].count; i++) {
        
        CGFloat leadingEdge = i * width + ImageOffset;
        CGFloat imageViewWidth = width - ImageOffset - ImageOffset;
        
        //create frame size & position
        CGRect imageSize = CGRectMake(leadingEdge,
                                      0,
                                      imageViewWidth,
                                      height);
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:imageSize];
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        imgView.backgroundColor = [UIColor colorWithHue:0 saturation:0 brightness:0.83 alpha:1];
        imgView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [self addSubview:imgView];
        
        if ([self proxyData] == self.images) {
            //get image
            UIImage *image = self.images[i];
            [imgView setImageAnimated:image];
        }
        else if ([self proxyData] == self.imageURLs) {
            //get imageurl
            NSURL *imageURL = self.imageURLs[i];
            [imgView setImageAnimatedWithURL:imageURL placeholder:nil];
        }
        
    }
    
    CGFloat sizeWidth = ([self proxyData].count * width) + (ImageOffset * [self proxyData].count) - ImageOffset;
    self.contentSize = CGSizeMake(sizeWidth, height);
}


#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self) {
        self.pageControl.currentPage = [self currentPage];
    }
}

- (void)changePage:(UIPageControl *)pageControl
{
    CGRect imagesFrame = self.frame;
    imagesFrame.origin.x = imagesFrame.size.width * pageControl.currentPage;
    imagesFrame.origin.y = 0;
    [self scrollRectToVisible:imagesFrame animated:YES];
}

#pragma mark - Setters

- (void)setImageURLs:(NSArray *)imageURLs
{
    if (_imageURLs != imageURLs) {
        _imageURLs = imageURLs;
        
        [self updateUI];
        [self setupPageControl];
    }
}

- (void)setImages:(NSArray *)images
{
    if (_images != images) {
        _images = images;
        
        [self updateUI];
        [self setupPageControl];
    }
}

#pragma mark - Getters

- (NSArray *)proxyData {
    if (self.images != nil) {
        return self.images;
    }
    if (self.imageURLs != nil) {
        return self.imageURLs;
    }
    return nil;
}

#pragma mark - Private Methods

- (void)didMoveToSuperview {
    if (self.superview != nil) {
        [self setupPageControl];
    }
}

- (void)setupPageControl
{
    [self.pageControl removeFromSuperview];
    self.pageControl = nil;
    
    CGFloat height = 30;
    CGFloat width = self.superview.frame.size.width;
    CGFloat yOrigin = 5;
    
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0,
                                                                       yOrigin,
                                                                       width,
                                                                       height)];
    
    self.pageControl.numberOfPages = [self proxyData].count;
    self.pageControl.currentPage = 0;
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    self.pageControl.pageIndicatorTintColor = [UIColor darkGrayColor];
    [self.pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
    [self.superview addSubview:self.pageControl];
}













#pragma mark - Parallax

- (void)addParallaxEffectWithScrollView:(UIScrollView *)scrollView height:(CGFloat)height;
{
    NSLog(@"scrollview ORIGINAL content inset %@", NSStringFromUIEdgeInsets(scrollView.contentInset));
    NSLog(@"scrollview ORIGINAL content offset %@", NSStringFromCGPoint(scrollView.contentOffset));
    
    self.parallaxHeight = height;
    self.originalTopInset = scrollView.contentInset.top;
    self.originalYOffset = scrollView.contentOffset.y;
    
    //original values
//    scrollView.contentInset = UIEdgeInsetsMake(height, 0, 0, 0);
//    scrollView.contentOffset = CGPointMake(0, -height);

//    scrollView.contentInset = UIEdgeInsetsMake(self.originalTopInset+self.parallaxHeight, 0, 0, 0);
//    scrollView.contentInset = UIEdgeInsetsMake(self.originalTopInset+self.parallaxHeight+64, 0, 0, 0);
//    scrollView.contentOffset = CGPointMake(0, self.originalYOffset-self.parallaxHeight);
    
    [self setupPageControl];
    
    if (!self.isObserving) {
        [scrollView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:nil];
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [scrollView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
        self.isObserving = YES;
    }
    
    NSLog(@"scrollview NEW content inset %@", NSStringFromUIEdgeInsets(scrollView.contentInset));
    NSLog(@"scrollview NEW content offset %@", NSStringFromCGPoint(scrollView.contentOffset));
}

- (void)updateParallax:(UIScrollView *)scrollView
{
    NSLog(@"scrollview content inset %@", NSStringFromUIEdgeInsets(scrollView.contentInset));
    NSLog(@"scrollview content offset %@", NSStringFromCGPoint(scrollView.contentOffset));
    
    CGRect headerRect = CGRectMake(0, -self.parallaxHeight, scrollView.bounds.size.width, self.parallaxHeight);
    if (scrollView.contentOffset.y < 0) {
//        headerRect.origin.y = scrollView.contentOffset.y;
//        scrollView.contentInset = UIEdgeInsetsMake(self.originalTopInset+self.parallaxHeight+64, 0, 0, 0);
        headerRect.origin.y = scrollView.contentOffset.y+scrollView.contentInset.top-self.parallaxHeight;
        headerRect.size.height = -scrollView.contentOffset.y;
    }
    self.frame = headerRect;
}


#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) { //when the user scrolls, to change height of self
        [self updateParallax:object];
    }
    else if ([keyPath isEqualToString:@"contentInset"]) {
//        UIScrollView *scrollView = (UIScrollView *)object;
//        
//        UIEdgeInsets newInsets = [[change valueForKey:NSKeyValueChangeNewKey] UIEdgeInsetsValue];
//        self.originalTopInset = newInsets.top;
//        NSLog(@"NEW top inset %f", self.originalTopInset);
//        
//        NSLog(@"scrollview UPDATED content inset %@", NSStringFromUIEdgeInsets(scrollView.contentInset));
//        NSLog(@"scrollview UPDATED content offset %@", NSStringFromCGPoint(scrollView.contentOffset));
    }
    else if ([keyPath isEqualToString:@"frame"]) {
        [self layoutSubviews];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (self.isObserving) {
            //If enter this branch, it is the moment just before "APParallaxView's dealloc", so remove observer here
            [scrollView removeObserver:self forKeyPath:@"contentInset"];
            [scrollView removeObserver:self forKeyPath:@"contentOffset"];
            [scrollView removeObserver:self forKeyPath:@"frame"];
            self.isObserving = NO;
        }
    }
}

@end



























@implementation UIImageView (SimpleImageSlider)

- (void)setImageAnimated:(UIImage *)image
{
    [UIView transitionWithView:self
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ self.image = image; }
                    completion:nil];
}

- (void)setImageAnimatedWithURL:(NSURL *)imageURL placeholder:(UIImage *)placeholder;
{
    __block UIImageView *weakSelf = self;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageURL];

    [self setImageWithURLRequest:request
                placeholderImage:placeholder
                         success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) { [weakSelf setImageAnimated:image]; }
                         failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) { [weakSelf setImageAnimated:nil]; }];
}

@end


















