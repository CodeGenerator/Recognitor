//
//  RVFeedbackViewModel.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 Recognitor. All rights reserved.
//

#import "RVFeedbackViewModel.h"
#import "RVPlateNumber.h"
#import "RVBackend.h"

NSString *const kRecognitionStateKeyPath = @"recognitionState";


@interface RVFeedbackViewModel ()

@property (nonatomic, assign, readwrite) BOOL statisticsIsAvailable;
@property (nonatomic, assign, readwrite) NSUInteger blameCounter;

@property (nonatomic, strong) RVPlateNumber *plateObject;

@end


@implementation RVFeedbackViewModel

- (instancetype)init
{
  return [self initWithPlateObject:nil];
}

- (instancetype)initWithPlateObject:(RVPlateNumber *)plateObject
{
  NSParameterAssert(plateObject != nil);
  self = [super init];
  if (self) {
    _plateObject = plateObject;
    [_plateObject addObserver:self forKeyPath:kRecognitionStateKeyPath options:0 context:NULL];
  }
  
  return self;
}

- (void)dealloc
{
  [_plateObject removeObserver:self forKeyPath:kRecognitionStateKeyPath];
}

- (NSError *)invalidNumberError
{
  NSError *error = [NSError errorWithDomain:@"RVFeedbackViewModel"
                                       code:0
                                   userInfo:@{NSLocalizedDescriptionKey : @"Неверный формат номера"}];
  return error;
}

- (BOOL)recognizing
{
  return self.plateObject.recognitionState == RVPlateNumberRecognitionStateRecognizing;
}

- (NSString *)plateNumber
{
  return self.plateObject.string;
}

- (UIImage *)image
{
  return self.plateObject.image;
}

- (void)swearActionWithPlateNumber:(NSString *)plateNumber
{
  self.statisticsIsAvailable = NO;
  [self.delegate viewModelDidStartSwearingProcess:self];
  if (![[RVBackend sharedInstance] isValidPlateNumber:plateNumber]) {
    
    [self.delegate viewModel:self didReceiveError:[self invalidNumberError]];
    return;
  }
  
  self.plateObject.string = plateNumber;
  [self.plateObject blameWithCompletion:^(BOOL success) {
    if (!success) {
      [self.delegate viewModel:self didReceiveError:self.plateObject.lastError];
      return;
    }
    
    [self.plateObject requestBlameCountWithCompletion:^(BOOL success, NSUInteger blameCount) {
      if (success) {
        self.statisticsIsAvailable = YES;
        self.blameCounter = blameCount;
        [self.delegate viewModelDidFinishSwearingProcess:self];
      }
    }];
  }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(RVPlateNumber *)plateObject
                        change:(NSDictionary *)change
                       context:(void *)context
{
  [self.delegate viewModelDidChangeRecognizingState:self];
}

@end
