//
//  RVPhotoCropperViewModel.h
//  Recognitor
//
//  Created by Mikhail Korobkin on 28/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^RVPhotoCropperViewModelCompletionBlock)(UIImage *selectedImage);

@protocol RVPhotoCropperViewModelDelegate;


@interface RVPhotoCropperViewModel : NSObject

@property (nonatomic, weak) UIViewController<RVPhotoCropperViewModelDelegate> *delegate;

@property (nonatomic, copy) RVPhotoCropperViewModelCompletionBlock completion;

@property (nonatomic, strong, readonly) UIImage *image;

- (instancetype)initWithOriginalImage:(UIImage *)originalImage;

- (void)selectedRectForCrop:(CGRect)rect;

@end


@protocol RVPhotoCropperViewModelDelegate <NSObject>

@required

@end
