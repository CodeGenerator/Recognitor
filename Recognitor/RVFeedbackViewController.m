//
//  RVFeedbackViewController.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVFeedbackViewController.h"
#import "RVFeedbackViewModel.h"


static NSString *const kBlamePattern = @"Обозвали раз: %u";


@interface RVFeedbackViewController () <UITextFieldDelegate, RVFeedbackModelDelegate>

@property (nonatomic, strong) RVFeedbackViewModel *viewModel;
@property (nonatomic, strong) UIImageView *previewView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
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
                                                                         action:@selector(endSwearing)];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Мудак"
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(swear)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    self.navigationItem.title = @"Комментарий";
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

- (void)endSwearing
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
  
  self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  [self.indicatorView sizeToFit];
  self.indicatorView.center = CGPointMake(self.previewView.bounds.size.width / 2,
                                          self.previewView.bounds.size.height / 2);
  [self.previewView addSubview:self.indicatorView];
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
  self.blameCounterLabel.hidden = YES;
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
  [self.indicatorView startAnimating];
  
  self.navigationItem.leftBarButtonItem.enabled = NO;
  self.navigationItem.rightBarButtonItem.enabled = NO;
  self.blameCounterLabel.hidden = YES;
}

- (void)viewModelDidFinishSwearingProcess:(RVFeedbackViewModel *)viewModel
{
  if (self.viewModel.statisticsIsAvailable) {
    self.blameCounterLabel.text = [NSString stringWithFormat:kBlamePattern, self.viewModel.blameCounter];
    self.blameCounterLabel.hidden = NO;
  }
  
  [self.indicatorView stopAnimating];
  
  self.navigationItem.leftBarButtonItem = nil;
  self.navigationItem.hidesBackButton = YES;
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"ОК"
                                                                            style:UIBarButtonItemStyleDone
                                                                           target:self
                                                                           action:@selector(endSwearing)];
}

- (void)viewModel:(RVFeedbackViewModel *)viewModel didReceiveError:(NSError *)error
{
  [self.indicatorView stopAnimating];
  
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
