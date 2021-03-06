//
//  RVPlateSelectionViewModel.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 Recognitor. All rights reserved.
//

#import "RVPlateSelectionViewModel.h"

#import "RVFeedbackViewController.h"
#import "RVFeedbackViewModel.h"

#import "RVPhotoCropperViewController.h"
#import "RVPhotoCropperViewModel.h"

#import "RVPlateNumber.h"


static NSString * const kRecognitionStateKeyPath = @"recognitionState";


@interface RVPlateSelectionViewModel ()

@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) NSArray *plateObjects;

@end

@implementation RVPlateSelectionViewModel

- (instancetype)initWithOriginalImage:(UIImage *)originalImage plates:(NSArray *)plates
{
  self = [super init];
  if (self) {
    _originalImage = originalImage;
    _plateObjects = plates;
    
    NSUInteger platesCount = [plates count];
    if (platesCount > 0) {
      [plates addObserver:self
       toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, platesCount)]
               forKeyPath:kRecognitionStateKeyPath
                  options:0
                  context:NULL];
    }
  }
  
  return self;
}

- (void)dealloc
{
  NSUInteger platesCount = [_plateObjects count];
  if (platesCount > 0) {
    [_plateObjects removeObserver:self
             fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, platesCount)]
                       forKeyPath:kRecognitionStateKeyPath];
  }
  
  [self cancelRecognitionForNumbers:_plateObjects];
}

- (void)selectOptionAtIndex:(NSUInteger)index
{
  if (index == [self.plateObjects count]) {
    [self presentPhotoCropper];
    return;
  }
  
  RVPlateNumber *plateNumber = self.plateObjects[index];
  NSMutableArray *plateNumbersToCancel = [self.plateObjects mutableCopy];
  [plateNumbersToCancel removeObjectAtIndex:index];
  [self cancelRecognitionForNumbers:plateNumbersToCancel];
  
  [self presentFeedbackViewControllerWithPlateObject:plateNumber];
}

- (RVPlateViewState)plateViewStateAtIndex:(NSUInteger)index
{
  RVPlateNumber *plateNumer = self.plateObjects[index];
  switch (plateNumer.recognitionState) {
    case RVPlateNumberRecognitionStateUnknown:
      return RVPlateViewStateError;
      
    case RVPlateNumberRecognitionStateCanceling:
    case RVPlateNumberRecognitionStateRecognizing:
      return RVPlateViewStateProcessing;
      
    case RVPlateNumberRecognitionStateNotRecognized:
    case RVPlateNumberRecognitionStateRecognized:
      return RVPlateViewStateTextAvailable;
      
    default:
      return RVPlateViewStateError;
  }
}

- (NSString *)plateTextAtIndex:(NSUInteger)index
{
  RVPlateNumber *plateNumer = self.plateObjects[index];
  if (plateNumer.recognitionState == RVPlateNumberRecognitionStateRecognized)
  {
    return plateNumer.string;
  }
  
  return @"";
}

- (UIImage *)plateImageAtIndex:(NSUInteger)index
{
  RVPlateNumber *plateNumer = self.plateObjects[index];
  return plateNumer.image;
}

- (NSUInteger)numberOfPlates
{
  return [self.plateObjects count];
}

- (void)presentPhotoCropper
{
  RVPhotoCropperViewModel *viewModel = [[RVPhotoCropperViewModel alloc] initWithOriginalImage:self.originalImage];
  viewModel.completion = ^(UIImage *croppedImage) {
    [self cancelRecognitionForNumbers:self.plateObjects];
  };
  
  RVPhotoCropperViewController *viewController = [[RVPhotoCropperViewController alloc] initWithViewModel:viewModel];

  UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Назад"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:nil
                                                                    action:nil];
  self.delegate.navigationItem.backBarButtonItem = backButtonItem;
  [self.delegate.navigationController pushViewController:viewController animated:YES];
}

- (void)cancelRecognitionForNumbers:(NSArray *)plateNumbers
{
  for (RVPlateNumber *plateNumber in plateNumbers) {
    [plateNumber cancelRecognition];
  }
}

- (void)didPressCancel
{
  [self cancelRecognitionForNumbers:self.plateObjects];
  [self.delegate dismissViewControllerAnimated:YES completion:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(RVPlateNumber *)plateNumber
                        change:(NSDictionary *)change
                       context:(void *)context
{
  NSUInteger plateIndex = [self.plateObjects indexOfObject:plateNumber];
  NSAssert(plateIndex != NSNotFound, @"wrong index");
  
  [self.delegate viewModel:self didChangePlateStateAtIndex:plateIndex];
  
  if (plateNumber.recognitionState == RVPlateNumberRecognitionStateUnknown && plateNumber.lastError != nil) {
    [self.delegate viewModel:self didReceiveError:plateNumber.lastError];
  }
}

- (void)presentFeedbackViewControllerWithPlateObject:(RVPlateNumber *)plateObject
{
  RVFeedbackViewModel *viewModel = [[RVFeedbackViewModel alloc] initWithPlateObject:plateObject];
  RVFeedbackViewController * viewController = [[RVFeedbackViewController alloc] initWithViewModel:viewModel];
  [self.delegate.navigationController pushViewController:viewController animated:YES];
}


@end
