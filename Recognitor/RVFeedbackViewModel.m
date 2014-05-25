//
//  RVFeedbackViewModel.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVFeedbackViewModel.h"
#import "RVBackend.h"


@interface RVFeedbackViewModel ()

@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, copy, readwrite) NSString *predictedNumber;
@property (nonatomic, assign, readwrite) BOOL statisticsIsAvailable;
@property (nonatomic, assign, readwrite) NSUInteger blameCounter;

@end


@implementation RVFeedbackViewModel

- (instancetype)init
{
  return [self initWithImage:nil predictedNumber:nil];
}

- (instancetype)initWithImage:(UIImage *)image predictedNumber:(NSString *)predictedNumber
{
  self = [super init];
  if (self) {
    _image = image;
    _predictedNumber = [predictedNumber copy];
  }
  
  return self;
}

- (NSError *)invalidNumberError
{
  NSError *error = [NSError errorWithDomain:@"RVFeedbackViewModel"
                                       code:0
                                   userInfo:@{NSLocalizedDescriptionKey : @"Неверный формат номера"}];
  return error;
}

- (void)swearActionWithPlateNumber:(NSString *)plateNumber
{
  self.statisticsIsAvailable = NO;
  [self.delegate viewModelDidStartSwearingProcess:self];
  if (![[RVBackend sharedInstance] isValidPlateNumber:plateNumber]) {
    
    [self.delegate viewModel:self didReceiveError:[self invalidNumberError]];
    return;
  }
  
  [[RVBackend sharedInstance] blamePlateNumber:plateNumber completion:^(NSError *error) {
    if (error != nil) {
      [self.delegate viewModel:self didReceiveError:error];
      return;
    }
    
    [[RVBackend sharedInstance] blameStatisticsForPlateNumber:plateNumber completion:^(NSUInteger blameCounter, NSError *error) {
      if (error == nil) {
        self.statisticsIsAvailable = YES;
        self.blameCounter = blameCounter;
      }
      
      [self.delegate viewModelDidFinishSwearingProcess:self];
    }];
  }];
}

@end
