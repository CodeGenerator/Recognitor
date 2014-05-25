//
//  RVSendActionViewModel.h
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol RVSendActionViewModelDelegate;


@interface RVSendActionViewModel : NSObject

@property (nonatomic, weak) UIViewController<RVSendActionViewModelDelegate>* delegate;

@property (nonatomic, strong, readonly) UIImage *image;

- (instancetype)initWithImageData:(NSData *)imageData;

- (void)sendAction;

@end


@protocol RVSendActionViewModelDelegate <NSObject>

@required

- (void)viewModelDidPrepareImage:(RVSendActionViewModel *)viewModel;

- (void)viewModelDidStartUploading:(RVSendActionViewModel *)viewModel;

- (void)viewModelDidFinishUploading:(RVSendActionViewModel *)viewModel;

- (void)viewModel:(RVSendActionViewModel *)viewModel didReceiveError:(NSError *)error;

@end
