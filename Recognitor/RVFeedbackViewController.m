//
//  RVFeedbackViewController.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVFeedbackViewController.h"
#import "RVFeedbackViewModel.h"

@interface RVFeedbackViewController () <UITextFieldDelegate, RVFeedbackModelDelegate>

@property (nonatomic, strong) RVFeedbackViewModel *viewModel;
@property (nonatomic, strong) UIImageView *previewView;
@property (nonatomic, strong) UITextField *plateNumberView;
@property (nonatomic, strong) UILabel *blameCounterLabel;

@end

@implementation RVFeedbackViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  return [self initWithViewModel:nil];
}

- (instancetype)initWithViewModel:(RVFeedbackViewModel *)viewModel
{
  NSParameterAssert(viewModel != nil);
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = viewModel;
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Отмена"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(cancelSwearing)];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Мудак"
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(swear)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
  }
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  [self configurePreviewView];
  [self configurePlateTextField];
  [self configureBlameCounterLabel];
}

- (void)cancelSwearing
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)swear
{
  [self.viewModel swearActionWithPlateNumber:self.plateNumberView.text];
}

- (void)configurePreviewView
{
  const CGFloat kTopMargin = 20.0f;
  const CGFloat kSideMargin = 20.0f;
  const CGFloat kMaxSideSize = MAX(self.view.bounds.size.height / 2 - kTopMargin - 40.0f, self.view.bounds.size.width - 2 * kSideMargin);
  
  CGSize originalImageSize = self.viewModel.image.size;
  CGSize resultImageSize = CGSizeZero;
  CGFloat aspectRatio = originalImageSize.width / originalImageSize.height;
  if (aspectRatio > 1.0f) {
    resultImageSize = CGSizeMake(kMaxSideSize, kMaxSideSize / aspectRatio);
  } else {
    resultImageSize = CGSizeMake(kMaxSideSize * aspectRatio, kMaxSideSize);
  }
  
  self.previewView = [[UIImageView alloc] initWithImage:self.viewModel.image];
  CGRect imageFrame = CGRectMake((self.view.bounds.size.width - resultImageSize.width) / 2,
                                 kTopMargin,
                                 resultImageSize.width,
                                 resultImageSize.height);
  self.previewView.frame = imageFrame;
  [self.view addSubview:self.previewView];
  
}

- (void)configurePlateTextField
{
  const CGFloat kPlateLabelTopMargin = 20.0f;
  const CGFloat kPlateTextFieldLeftGap = 20.0f;
  
  UILabel *plateTextLabel = [UILabel new];
  plateTextLabel.font = [UIFont systemFontOfSize:24.0f];
  plateTextLabel.text = @"Номер:";
  plateTextLabel.textColor = [UIColor blackColor];
  [plateTextLabel sizeToFit];
  plateTextLabel.center = CGPointMake(self.previewView.frame.origin.x + plateTextLabel.bounds.size.width / 2,
                                      self.previewView.frame.origin.y + self.previewView.bounds.size.height +
                                      kPlateLabelTopMargin + plateTextLabel.bounds.size.height / 2);
  [self.view addSubview:plateTextLabel];
  
  self.plateNumberView = [UITextField new];
  self.plateNumberView.text = self.viewModel.predictedNumber;
  self.plateNumberView.textColor = plateTextLabel.textColor;
  self.plateNumberView.font = plateTextLabel.font;
  [self.plateNumberView sizeToFit];
  CGFloat plateNumberViewOffsetX = (plateTextLabel.frame.origin.x + plateTextLabel.bounds.size.width +
                                    kPlateTextFieldLeftGap);
  self.plateNumberView.frame = CGRectMake(plateNumberViewOffsetX,
                                          plateTextLabel.center.y - self.plateNumberView.bounds.size.height / 2,
                                          self.previewView.frame.origin.x + self.previewView.bounds.size.width -
                                          plateNumberViewOffsetX,
                                          self.plateNumberView.bounds.size.height);
  
  self.plateNumberView.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
  self.plateNumberView.autocorrectionType = UITextAutocorrectionTypeNo;
  self.plateNumberView.spellCheckingType = UITextSpellCheckingTypeNo;
  
  [self.view addSubview:self.plateNumberView];
  
  self.plateNumberView.delegate = self;
}

- (void)configureBlameCounterLabel
{
  NSString *const kBlamePattern = @"Уже обозвали раз: %d";
  const CGFloat kTopGap = 30.0f;
  
  self.blameCounterLabel = [UILabel new];
  self.blameCounterLabel.font = [UIFont systemFontOfSize:24.0f];
  self.blameCounterLabel.text = kBlamePattern;
  self.blameCounterLabel.textColor = [UIColor blackColor];
  [self.blameCounterLabel sizeToFit];
  self.blameCounterLabel.frame = CGRectMake(self.previewView.frame.origin.x,
                                            self.plateNumberView.frame.origin.y + self.plateNumberView.bounds.size.height +
                                            kTopGap,
                                            self.previewView.bounds.size.width,
                                            self.blameCounterLabel.bounds.size.height);
  self.blameCounterLabel.alpha = 0.0f;
  [self.view addSubview:self.blameCounterLabel];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.viewModel.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  self.viewModel.delegate = nil;
}

- (void)viewModelDidStartSwearingProcess:(RVFeedbackViewModel *)viewModel
{
  self.navigationItem.leftBarButtonItem.enabled = NO;
  self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewModelDidFinishSwearingProcess:(RVFeedbackViewModel *)viewModel
{
  
}

- (void)viewModel:(RVFeedbackViewModel *)viewModel didReceiveError:(NSError *)error
{
  
}


@end
