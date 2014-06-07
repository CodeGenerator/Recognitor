//
//  RVSendActionViewModel.h
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol RVSendActionViewModelDelegate;

typedef NS_ENUM(NSUInteger, RVPlateViewState)
{
  RVPlateViewStateTextAvailable = 0,
  RVPlateViewStateProcessing,
  RVPlateViewStateError
};


@interface RVSendActionViewModel : NSObject

@property (nonatomic, weak) UIViewController<RVSendActionViewModelDelegate>* delegate;

- (instancetype)initWithOriginalImage:(UIImage *)originalImage plates:(NSArray *)plates;

- (void)selectOptionAtIndex:(NSUInteger)index;

- (RVPlateViewState)plateViewStateAtIndex:(NSUInteger)index;

- (NSString *)plateTextAtIndex:(NSUInteger)index;

- (UIImage *)plateImageAtIndex:(NSUInteger)index;

- (NSUInteger)numberOfPlates;

- (void)didPressCancel;


@end


@protocol RVSendActionViewModelDelegate <NSObject>

@required

- (void)viewModel:(RVSendActionViewModel *)viewModel didChangePlateStateAtIndex:(NSUInteger)index;

- (void)viewModel:(RVSendActionViewModel *)viewModel didReceiveError:(NSError *)error;

@end
