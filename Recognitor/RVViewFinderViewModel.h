//
//  RVViewFinderViewModel.h
//  Recognitor
//
//  Created by Mikhail Korobkin on 23/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol RVViewFinderViewModelDelegate;


@interface RVViewFinderViewModel : NSObject

@property (nonatomic, weak) UIViewController<RVViewFinderViewModelDelegate> *delegate;

@property (nonatomic, strong, readonly) CALayer *previewLayer;

@property (nonatomic, assign, readonly) BOOL cameraIsInitialized;

- (instancetype)init;

- (void)controllerWillAppear;

- (void)controllerDidDisappear;

- (void)captureImage;

@end


@protocol RVViewFinderViewModelDelegate <NSObject>

@required

- (void)viewModelDidFinishInitialization:(RVViewFinderViewModel *)viewModel;

@end