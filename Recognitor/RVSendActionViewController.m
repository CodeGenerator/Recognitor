//
//  RVSendActionViewController.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVSendActionViewController.h"
#import "RVSendActionViewModel.h"

@interface RVSendActionViewController () <RVSendActionViewModelDelegate>

@property (nonatomic, strong) RVSendActionViewModel *viewModel;
@property (nonatomic, strong) UIImageView *sendPreviewView;
@property (nonatomic, strong) UIActivityIndicatorView *sendingIndicator;

@end

@implementation RVSendActionViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  return [self initWithViewModel:nil];
}

- (instancetype)initWithViewModel:(RVSendActionViewModel *)viewModel
{
  NSParameterAssert(viewModel != nil);
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = viewModel;
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Отмена"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(cancelSending)];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Отправить"
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(send)];
    rightBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    self.navigationItem.title = @"Отправка";
  }
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  
  self.sendPreviewView = [UIImageView new];
  self.sendPreviewView.clipsToBounds = YES;
  self.sendPreviewView.contentMode = UIViewContentModeScaleAspectFill;
  self.sendPreviewView.alpha = 0.0f;
  self.sendPreviewView.layer.borderColor = [UIColor blackColor].CGColor;
  self.sendPreviewView.layer.borderWidth = 0.5f;
  
  self.sendPreviewView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                                    UIViewAutoresizingFlexibleRightMargin);
  
  self.sendingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  [self.sendingIndicator sizeToFit];
  [self.sendPreviewView addSubview:self.sendingIndicator];
  
  [self.view addSubview:self.sendPreviewView];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.viewModel.delegate = self;
  if (self.viewModel.image != nil && self.sendPreviewView.image == nil) {
    [self presentPreviewForSend:self.viewModel.image];
  }
}

- (void)presentPreviewForSend:(UIImage *)image
{
  const CGFloat kSideMargin = 70.0f;
  const CGFloat kTopMargin = 20.0f;
  
  self.sendPreviewView.image = self.viewModel.image;
  
  CGRect imageFrame = CGRectZero;
  imageFrame.origin = CGPointMake(kSideMargin, kTopMargin);
  imageFrame.size.width = self.view.bounds.size.width - 2 * kSideMargin;
  imageFrame.size.height = imageFrame.size.width * image.size.height / image.size.width;
  
  self.sendPreviewView.frame = CGRectIntegral(imageFrame);
  self.sendingIndicator.center = CGPointMake(self.sendPreviewView.bounds.size.width / 2,
                                             self.sendPreviewView.bounds.size.height / 2);
  [UIView animateWithDuration:0.5 animations:^{
    self.sendPreviewView.alpha = 1.0f;
  } completion:^(BOOL finished) {
    self.navigationItem.rightBarButtonItem.enabled = YES;
  }];
  
}

- (void)cancelSending
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)send
{
  [self.viewModel sendAction];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  self.viewModel.delegate = nil;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}

- (void)viewModelDidPrepareImage:(RVSendActionViewModel *)viewModel
{
  [self presentPreviewForSend:self.viewModel.image];
}

- (void)viewModelDidStartUploading:(RVSendActionViewModel *)viewModel
{
  [self.sendingIndicator startAnimating];
  self.navigationItem.leftBarButtonItem.enabled = NO;
  self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewModelDidFinishUploading:(RVSendActionViewModel *)viewModel
{
  [self.sendingIndicator stopAnimating];
  self.navigationItem.leftBarButtonItem.enabled = YES;
  self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)viewModel:(RVSendActionViewModel *)viewModel didReceiveError:(NSError *)error
{
  [self.sendingIndicator stopAnimating];
  self.navigationItem.leftBarButtonItem.enabled = YES;
  self.navigationItem.rightBarButtonItem.enabled = YES;
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Ошибка"
                                                      message:error.localizedDescription
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles: nil];
  [alertView show];
}

@end
