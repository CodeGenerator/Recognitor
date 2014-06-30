//
//  RVFeedbackViewController.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 Recognitor. All rights reserved.
//

#import "RVFeedbackViewController.h"
#import "RVFeedbackViewModel.h"


static NSString *const kBlamePattern = @"Обозвали раз: %u";


@interface RVFeedbackViewController () <UITextFieldDelegate, RVFeedbackModelDelegate>

@property (nonatomic, strong) RVFeedbackViewModel *viewModel;
@property (nonatomic, strong) UIImageView *previewView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UILabel *plateTextLabel;
@property (nonatomic, strong) UITextField *plateNumberView;
@property (nonatomic, strong) UILabel *blameCounterLabel;
@property (nonatomic, strong) UIActivityIndicatorView *plateNumberLoadingView;
@property (nonatomic, assign) CGFloat textLabelOffset;

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
    rightBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    
    self.navigationItem.title = @"Обозвать";
  }
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor lightBackgroundColor];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  [self configurePreviewView];
  [self configurePlateTextField];
  [self configureBlameCounterLabel];
  
  UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(viewWasTapped:)];
  [self.view addGestureRecognizer:tapRecognizer];
}

- (void)viewWasTapped:(UITapGestureRecognizer *)recognizer
{
  [self.plateNumberView resignFirstResponder];
}

- (void)layoutElementsForKeyboardNotification:(NSNotification *)notification
                                       offset:(CGFloat)offset
{
  NSDictionary *userInfo = notification.userInfo;
  
  NSNumber *duration = userInfo[UIKeyboardAnimationDurationUserInfoKey];
  NSNumber *curve = userInfo[UIKeyboardAnimationCurveUserInfoKey];
  
  [UIView animateKeyframesWithDuration:[duration doubleValue] delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState|[curve integerValue] animations:^{
    self.previewView.center = CGPointMake(self.previewView.center.x,
                                          self.previewView.center.y + offset);
    self.plateTextLabel.center = CGPointMake(self.plateTextLabel.center.x,
                                             self.plateTextLabel.center.y + offset);
    self.plateNumberView.center = CGPointMake(self.plateNumberView.center.x,
                                              self.plateNumberView.center.y + offset);
  } completion:nil];
  
  
}

- (void)keyboardWillShow:(NSNotification *)notification
{
  const CGFloat kKeyboardTopMargin = 20.0f;
  
  NSDictionary *userInfo = notification.userInfo;
  CGRect keyboardRect = [self.view convertRect:[userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue]
                                      fromView:[UIApplication sharedApplication].keyWindow];
  
  CGFloat plateTextLabelBottomBorder = self.plateTextLabel.frame.origin.y + self.plateTextLabel.bounds.size.height;
  CGFloat keyboardTopBorder = keyboardRect.origin.y;
  
  self.textLabelOffset = MAX(plateTextLabelBottomBorder + kKeyboardTopMargin - keyboardTopBorder, 0.0f);
  
  [self layoutElementsForKeyboardNotification:notification offset:-self.textLabelOffset];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
  [self layoutElementsForKeyboardNotification:notification offset:self.textLabelOffset];
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
  self.previewView.layer.borderWidth = 1.0f;
  self.previewView.layer.borderColor = [UIColor lightTextColor].CGColor;
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
  const CGFloat kPlateLabelLeftMargin = 30.0f;
  const CGFloat kPlateTextFieldLeftGap = 20.0f;
  const CGFloat kPlateTextFieldRightMargin = 30.0f;
  
  
  self.plateTextLabel = [UILabel new];
  self.plateTextLabel.font = [UIFont systemFontOfSize:24.0f];
  self.plateTextLabel.text = @"Номер:";
  self.plateTextLabel.textColor = [UIColor lightTextColor];
  [self.plateTextLabel sizeToFit];
  self.plateTextLabel.center = CGPointMake(kPlateLabelLeftMargin + self.plateTextLabel.bounds.size.width / 2,
                                      self.previewView.frame.origin.y + self.previewView.bounds.size.height +
                                      kPlateLabelTopMargin + self.plateTextLabel.bounds.size.height / 2);
  [self.view addSubview:self.plateTextLabel];
  
  self.plateNumberView = [UITextField new];
  self.plateNumberView.text = self.viewModel.plateNumber;
  self.plateNumberView.textColor = self.plateTextLabel.textColor;
  self.plateNumberView.font = self.plateTextLabel.font;
  [self.plateNumberView sizeToFit];
  CGFloat plateNumberViewOffsetX = (self.plateTextLabel.frame.origin.x + self.plateTextLabel.bounds.size.width +
                                    kPlateTextFieldLeftGap);
  self.plateNumberView.frame = CGRectMake(plateNumberViewOffsetX,
                                          self.plateTextLabel.center.y - self.plateNumberView.bounds.size.height / 2,
                                          self.view.bounds.size.width - kPlateTextFieldRightMargin -
                                          plateNumberViewOffsetX,
                                          self.plateNumberView.bounds.size.height);
  
  self.plateNumberView.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
  self.plateNumberView.autocorrectionType = UITextAutocorrectionTypeNo;
  self.plateNumberView.spellCheckingType = UITextSpellCheckingTypeNo;
  self.plateNumberView.textAlignment = NSTextAlignmentCenter;
  
  self.plateNumberView.layer.borderWidth = 1.0f;
  self.plateNumberView.layer.borderColor = [UIColor lightTextColor].CGColor;
  
  [self.view addSubview:self.plateNumberView];
  
  self.plateNumberView.delegate = self;
  
  self.plateNumberLoadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  [self.plateNumberLoadingView sizeToFit];
  self.plateNumberLoadingView.center = self.plateNumberView.center;
  [self.view addSubview:self.plateNumberLoadingView];
}

- (void)configureBlameCounterLabel
{
  const CGFloat kTopGap = 30.0f;
  
  self.blameCounterLabel = [UILabel new];
  self.blameCounterLabel.font = [UIFont systemFontOfSize:24.0f];
  self.blameCounterLabel.text = kBlamePattern;
  self.blameCounterLabel.textColor = [UIColor lightTextColor];
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
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
  [self configureViewsForRecognitionState];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  self.viewModel.delegate = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewModelDidStartSwearingProcess:(RVFeedbackViewModel *)viewModel
{
  [self.indicatorView startAnimating];
  
  self.navigationItem.leftBarButtonItem.enabled = NO;
  self.navigationItem.rightBarButtonItem.enabled = NO;
  self.plateNumberView.enabled = NO;
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

- (void)configureViewsForRecognitionState
{
  BOOL recognizing = self.viewModel.recognizing;
  self.navigationItem.rightBarButtonItem.enabled = !recognizing;
  self.plateNumberView.hidden = recognizing;
  if (recognizing) {
    [self.plateNumberLoadingView startAnimating];
  } else {
    [self.plateNumberLoadingView stopAnimating];
    self.plateNumberView.text = self.viewModel.plateNumber;
  }
}

- (void)viewModelDidChangeRecognizingState:(RVFeedbackViewModel *)viewModel
{
  [self configureViewsForRecognitionState];
}

- (void)viewModel:(RVFeedbackViewModel *)viewModel didReceiveError:(NSError *)error
{
  [self.indicatorView stopAnimating];
  
  self.navigationItem.leftBarButtonItem.enabled = YES;
  self.navigationItem.rightBarButtonItem.enabled = YES;
  self.plateNumberView.enabled = YES;
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Ошибка"
                                                      message:error.localizedDescription
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles: nil];
  [alertView show];
}


@end
