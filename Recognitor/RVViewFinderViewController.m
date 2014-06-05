//
//  RVViewFinderViewController.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 23/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "RVViewFinderViewController.h"
#import "RVViewFinderViewModel.h"


@interface RVViewFinderViewController () <RVViewFinderViewModelDelegate>

@property (nonatomic, strong) RVViewFinderViewModel *viewModel;
@property (nonatomic, assign) BOOL cameraLayerWasConfigured;
@property (nonatomic, strong) UIButton *captureButton;

@end

@implementation RVViewFinderViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  return [self initWithViewModel:nil];
}

- (instancetype)initWithViewModel:(RVViewFinderViewModel *)viewModel
{
  NSParameterAssert(viewModel != nil);
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = viewModel;
  }
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  
  [self createCaptureButton];
}

- (void)createCaptureButton
{
  const CGFloat kBottomMargin = 20.0f;
  
  self.captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
  
  UIImage *captureButtonImage = [UIImage imageNamed:@"capture-button"];
  [self.captureButton setImage:captureButtonImage forState:UIControlStateNormal];
  
  UIImage *captureButtonImageHighlighted = [UIImage imageNamed:@"capture-button-hovered"];
  [self.captureButton setImage:captureButtonImageHighlighted forState:UIControlStateHighlighted];
  
  [self.captureButton sizeToFit];
  self.captureButton.center = CGPointMake(self.view.bounds.size.width / 2,
                                          self.view.bounds.size.height - kBottomMargin -
                                          self.captureButton.bounds.size.height / 2);
  [self.view addSubview:self.captureButton];
  
  [self.captureButton addTarget:self action:@selector(captureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.viewModel.delegate = self;
  if (self.viewModel.cameraIsInitialized) {
    [self configurePreviewLayer];
  }
  [self.viewModel controllerWillAppear];
  
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(orientationDidChange:)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:nil];
  [self applyOrientation:[UIDevice currentDevice].orientation];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  
  self.viewModel.delegate = nil;
  [self.viewModel controllerDidDisappear];
  
  [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)orientationDidChange:(NSNotificationCenter *)notification
{
  [self applyOrientation:[UIDevice currentDevice].orientation];
}

- (void)applyOrientation:(UIDeviceOrientation)orientation
{
  UIInterfaceOrientation interfaceOrientationToApply = UIInterfaceOrientationPortrait;
  if (UIDeviceOrientationIsValidInterfaceOrientation(orientation)) {
    interfaceOrientationToApply = (UIInterfaceOrientation)orientation;
  }
  
  CGFloat captureButtonRotationAngel = 0.0f;
  switch (interfaceOrientationToApply) {
    case UIInterfaceOrientationPortrait:
      captureButtonRotationAngel = 0.0f;
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      captureButtonRotationAngel = M_PI;
      break;
    case UIInterfaceOrientationLandscapeLeft:
      captureButtonRotationAngel = -M_PI_2;
      break;
    case UIInterfaceOrientationLandscapeRight:
      captureButtonRotationAngel = M_PI_2;
      break;
      
    default:
      NSAssert(nil, @"Wrong orientation");
      break;
  }
  
  [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
    self.captureButton.transform = CGAffineTransformMakeRotation(captureButtonRotationAngel);
  } completion:nil];
}

- (void)configurePreviewLayer
{
  if (self.cameraLayerWasConfigured) {
    return;
  }
  self.cameraLayerWasConfigured = YES;
  
  self.viewModel.previewLayer.frame = CGRectMake(0.0f,
                                                 0.0f,
                                                 self.view.layer.bounds.size.width,
                                                 self.view.layer.bounds.size.height);
  self.view.layer.masksToBounds = YES;
  [self.view.layer insertSublayer:self.viewModel.previewLayer atIndex:0];
  
}

- (BOOL)shouldAutorotate
{
  return NO;
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (void)captureButtonPressed:(id)sender
{
  if (!self.viewModel.cameraIsInitialized) {
    return;
  }
  
  [self.viewModel captureImage];
}

#pragma mark - RVViewFinderViewModelDelegate implementation

- (void)viewModelDidFinishInitialization:(RVViewFinderViewModel *)viewModel
{
  [self configurePreviewLayer];
}

@end
