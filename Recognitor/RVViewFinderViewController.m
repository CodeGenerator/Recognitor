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
  
  UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(viewWasTappedWithRecognizer:)];
  [self.view addGestureRecognizer:tapRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.viewModel.delegate = self;
  if (self.viewModel.cameraIsInitialized) {
    [self configurePreviewLayer];
  }
  [self.viewModel controllerWillAppear];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  
  self.viewModel.delegate = nil;
  [self.viewModel controllerDidDisappear];
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

- (void)viewWasTappedWithRecognizer:(UITapGestureRecognizer *)tapRecognizer
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
