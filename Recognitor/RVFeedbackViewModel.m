//
//  RVFeedbackViewModel.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVFeedbackViewModel.h"


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

- (void)swearActionWithPlateNumber:(NSString *)plateNumber
{
  [self.delegate viewModelDidStartSwearingProcess:self];
}

@end
