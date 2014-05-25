//
//  RVFeedbackViewModel.h
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol RVFeedbackModelDelegate;


@interface RVFeedbackViewModel : NSObject

@property (nonatomic, weak) id<RVFeedbackModelDelegate> delegate;

@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, copy, readonly) NSString *predictedNumber;
@property (nonatomic, assign, readonly) BOOL statisticsIsAvailable;
@property (nonatomic, assign, readonly) NSUInteger blameCounter;

- (instancetype)initWithImage:(UIImage *)image predictedNumber:(NSString *)predictedNumber;

- (void)swearActionWithPlateNumber:(NSString *)plateNumber;

@end


@protocol RVFeedbackModelDelegate <NSObject>

@required

- (void)viewModelDidStartSwearingProcess:(RVFeedbackViewModel *)viewModel;

- (void)viewModelDidFinishSwearingProcess:(RVFeedbackViewModel *)viewModel;

- (void)viewModel:(RVFeedbackViewModel *)viewModel didReceiveError:(NSError *)error;

@end