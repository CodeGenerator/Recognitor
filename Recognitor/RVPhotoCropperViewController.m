//
//  RVPhotoCropperViewController.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 28/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVPhotoCropperViewController.h"
#import "RVPhotoCropperViewModel.h"
#import "RVCropSelectionView.h"

typedef NS_ENUM(NSUInteger, RVCornerType)
{
  RVCornerTypeLU = 0,
  RVCornerTypeRU,
  RVCornerTypeLB,
  RVCornerTypeRB,
  
  RVCornerTypeCount
};

@interface RVPhotoCropperViewController () <RVPhotoCropperViewModelDelegate>

@property (nonatomic, strong) RVPhotoCropperViewModel *viewModel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@property (nonatomic, strong) RVCropSelectionView *selectionView;
@property (nonatomic, assign) RVCornerType selectedCorner;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;

@property (nonatomic, strong) UIImageView *imageView;

@end


@implementation RVPhotoCropperViewController

- (instancetype)initWithViewModel:(RVPhotoCropperViewModel *)viewModel
{
  NSParameterAssert(viewModel != nil);
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = viewModel;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Выбрать" style:UIBarButtonItemStylePlain target:self action:@selector(didSelectRectToCrop)];
    self.navigationItem.title = @"Выделите номер";
  }
  
  return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  return [self initWithViewModel:nil];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.view.backgroundColor = [UIColor lightBackgroundColor];
  
  [self configureImageView];
  [self configureLoadingIndicator];
  [self configureSelectionView];
  
  self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(pannedWithRecognizer:)];
  self.panRecognizer.maximumNumberOfTouches = 1;
  [self.view addGestureRecognizer:self.panRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.viewModel.delegate = self;
  
  if (self.viewModel.image != nil) {
    [self showImageWithSelectionFrameAnimated:NO];
  }
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  self.viewModel.delegate = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
  return UIStatusBarStyleLightContent;
}

- (void)configureImageView
{
  self.imageView = [UIImageView new];
  self.imageView.contentMode = UIViewContentModeScaleAspectFill;
  self.imageView.clipsToBounds = YES;
  self.imageView.alpha = 0.0f;
  
  [self.view addSubview:self.imageView];
}

- (void)configureLoadingIndicator
{
  self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  self.loadingIndicator.center = CGPointMake(self.view.bounds.size.width / 2,
                                             self.view.bounds.size.height / 2);
  [self.view addSubview:self.loadingIndicator];
  
  [self.loadingIndicator startAnimating];
}

- (void)configureSelectionView
{
  self.selectionView = [[RVCropSelectionView alloc] init];
  self.selectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.selectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent: 0.5f];
  [self.imageView addSubview:self.selectionView];
  
  self.panRecognizer.enabled = NO;
}

- (void)showImageWithSelectionFrameAnimated:(BOOL)animated
{
  const NSTimeInterval kAnimationDuration = 0.3;
  const CGFloat kVerticalMinMargin = 20.0f;
  const CGFloat kSelectionFrameMargin = 10.0f;
  
  UIImage *image = self.viewModel.image;
  CGSize imageSize = image.size;
  CGSize parentViewSize = self.view.bounds.size;
  
  // How much we should compress image size to fit the constraints
  CGFloat horizontalCompressionRate = imageSize.width / parentViewSize.width;
  CGFloat verticalCompressionRate = imageSize.height / (parentViewSize.height - 2 * kVerticalMinMargin);
  
  CGFloat resultCompressionRate = MAX(horizontalCompressionRate, verticalCompressionRate);
  CGSize resultViewSize = CGSizeMake(imageSize.width / resultCompressionRate,
                                      imageSize.height / resultCompressionRate);
  
  self.imageView.frame = CGRectMake((parentViewSize.width - resultViewSize.width) / 2,
                                    (parentViewSize.height - resultViewSize.height) / 2,
                                    resultViewSize.width,
                                    resultViewSize.height);
  self.imageView.image = image;
  self.selectionView.frame = self.imageView.bounds;
  self.selectionView.selectionFrame = CGRectMake(kSelectionFrameMargin,
                                                 kSelectionFrameMargin,
                                                 resultViewSize.width - 2 * kSelectionFrameMargin,
                                                 resultViewSize.height - 2 * kSelectionFrameMargin);
  [self.loadingIndicator stopAnimating];
  if (!animated) {
    self.imageView.alpha = 1.0f;
    self.panRecognizer.enabled = YES;
    return;
  }
  
  [UIView animateWithDuration:kAnimationDuration animations:^{
    self.imageView.alpha = 1.0f;
  } completion:^(BOOL finished) {
    self.panRecognizer.enabled = YES;
  }];
}

- (CGFloat)distanceForPoint1:(CGPoint)point1 point2:(CGPoint)point2
{
  return powf(point1.x - point2.x, 2.0f) + powf(point1.y - point2.y, 2.0f);
}

- (RVCornerType)cornerTypeForPoint:(CGPoint)point
{
  CGRect selectionFrame = self.selectionView.selectionFrame;
  
  CGFloat distances[RVCornerTypeCount];
  distances[RVCornerTypeLU] = [self distanceForPoint1:point point2:selectionFrame.origin];
  distances[RVCornerTypeRU] = [self distanceForPoint1:point point2:CGPointMake(selectionFrame.origin.x + selectionFrame.size.width,
                                                                               selectionFrame.origin.y)];
  distances[RVCornerTypeLB] = [self distanceForPoint1:point point2:CGPointMake(selectionFrame.origin.x,
                                                                               selectionFrame.origin.y + selectionFrame.size.height)];
  distances[RVCornerTypeRB] = [self distanceForPoint1:point point2:CGPointMake(selectionFrame.origin.x + selectionFrame.size.width,
                                                                               selectionFrame.origin.y + selectionFrame.size.height)];
  RVCornerType closestPoint = RVCornerTypeLU;
  for (RVCornerType corner = RVCornerTypeLU + 1; corner < RVCornerTypeCount; corner++) {
    if (distances[corner] < distances[closestPoint]) {
      closestPoint = corner;
    }
  }
  
  return closestPoint;
}

- (void)changeSelectionFrameWithNewCornerPosition:(CGPoint)position
{
  const CGFloat kMinimumSideSize = 10.0f;
  
  CGRect selectionFrame = self.selectionView.selectionFrame;
  CGSize sizeChange = CGSizeZero;
  switch (self.selectedCorner) {
    case RVCornerTypeLU:
    {
      CGPoint previousPosition = selectionFrame.origin;
      sizeChange = CGSizeMake(previousPosition.x - position.x,
                              previousPosition.y - position.y);
      selectionFrame.origin = position;
      break;
    }
    case RVCornerTypeRU:
    {
      CGPoint previousPosition = CGPointMake(selectionFrame.origin.x + selectionFrame.size.width,
                                             selectionFrame.origin.y);
      sizeChange = CGSizeMake(position.x - previousPosition.x,
                              previousPosition.y - position.y);
      selectionFrame.origin.y = position.y;
      break;
    }
    case RVCornerTypeLB:
    {
      CGPoint previousPosition = CGPointMake(selectionFrame.origin.x,
                                             selectionFrame.origin.y + selectionFrame.size.height);
      sizeChange = CGSizeMake(previousPosition.x - position.x,
                              position.y - previousPosition.y);
      selectionFrame.origin.x = position.x;
      break;
    }
    case RVCornerTypeRB:
    {
      CGPoint previousPosition = CGPointMake(selectionFrame.origin.x + selectionFrame.size.width,
                                             selectionFrame.origin.y + selectionFrame.size.height);
      sizeChange = CGSizeMake(position.x - previousPosition.x,
                              position.y - previousPosition.y);
      break;
    }
    default:
      NSAssert(nil, @"Wrong corner");
      break;
  }
  
  selectionFrame.size.width += sizeChange.width;
  selectionFrame.size.height += sizeChange.height;
  
  if (selectionFrame.size.width < kMinimumSideSize ||
      selectionFrame.size.height < kMinimumSideSize) {
    return;
  }
  
  self.selectionView.selectionFrame = selectionFrame;
}

- (void)pannedWithRecognizer:(UIPanGestureRecognizer *)recognizer
{
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    self.selectedCorner = [self cornerTypeForPoint:[recognizer locationInView:self.imageView]];
  }
  
  if (recognizer.state == UIGestureRecognizerStateBegan ||recognizer.state == UIGestureRecognizerStateChanged) {
    CGPoint touchPoint = [recognizer locationInView:self.imageView];
    [self changeSelectionFrameWithNewCornerPosition:touchPoint];
  }
}

- (void)didSelectRectToCrop
{
  CGFloat compressionRatio = self.viewModel.image.size.width / self.imageView.bounds.size.width;
  CGRect viewSelectionFrame = self.selectionView.selectionFrame;
  CGRect imageSelectionFrame = CGRectMake(viewSelectionFrame.origin.x * compressionRatio,
                                          viewSelectionFrame.origin.y * compressionRatio,
                                          viewSelectionFrame.size.width * compressionRatio,
                                          viewSelectionFrame.size.height * compressionRatio);
  [self.viewModel selectedRectForCrop:imageSelectionFrame];
}

#pragma mark - RVPhotoCropperViewModelDelegate implementation

- (void)viewModelDidPrepareImage:(RVPhotoCropperViewModel *)viewModel
{
  [self showImageWithSelectionFrameAnimated:YES];
}


@end
