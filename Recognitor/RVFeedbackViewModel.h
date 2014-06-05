//
//  RVFeedbackViewModel.h
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import <Foundation/Foundation.h>


@class RVPlateNumber;
@protocol RVFeedbackModelDelegate;


@interface RVFeedbackViewModel : NSObject

@property (nonatomic, weak) id<RVFeedbackModelDelegate> delegate;

@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, copy, readonly) NSString *plateNumber;
@property (nonatomic, assign, readonly) BOOL statisticsIsAvailable;
@property (nonatomic, assign, readonly) NSUInteger blameCounter;
@property (nonatomic, assign, readonly) BOOL recognizing;

- (instancetype)initWithPlateObject:(RVPlateNumber *)plateObject;

- (void)swearActionWithPlateNumber:(NSString *)plateNumber;

@end


@protocol RVFeedbackModelDelegate <NSObject>

@required

- (void)viewModelDidStartSwearingProcess:(RVFeedbackViewModel *)viewModel;

- (void)viewModelDidFinishSwearingProcess:(RVFeedbackViewModel *)viewModel;

- (void)viewModelDidChangeRecognizingState:(RVFeedbackViewModel *)viewModel;

- (void)viewModel:(RVFeedbackViewModel *)viewModel didReceiveError:(NSError *)error;

@end