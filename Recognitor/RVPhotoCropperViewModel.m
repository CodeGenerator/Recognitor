//
//  RVPhotoCropperViewModel.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 28/05/14.
//  Copyright (c) 2014 Recognitor. All rights reserved.
//

#import "RVPhotoCropperViewModel.h"
#import "RVFeedbackViewController.h"
#import "RVFeedbackViewModel.h"
#import "RVPlateNumber.h"

@interface RVPhotoCropperViewModel ()

@property (nonatomic, strong, readwrite) UIImage *image;

@end


@implementation RVPhotoCropperViewModel

- (instancetype)initWithOriginalImage:(UIImage *)originalImage
{
  NSParameterAssert(originalImage != nil);
  
  self = [super init];
  if (self) {
    _image = originalImage;
  }
  
  return self;
}

- (instancetype)init
{
  return [self initWithOriginalImage:nil];
}

- (void)decodedImageFromData:(NSData *)imageData completion:(void(^)(UIImage *decodedImage))completion
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    UIImage *decodedImage = nil;
    
    @autoreleasepool {
      UIImage *image = [UIImage imageWithData:imageData];
      UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
      [image drawAtPoint:CGPointZero];
      decodedImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
    
    if (completion != nil) {
      completion(decodedImage);
    }
  });
}

- (void)selectedRectForCrop:(CGRect)rect
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0);
    [self.image drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y) blendMode:kCGBlendModeCopy alpha:1.0];
    
    UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.completion != nil) {
        self.completion(croppedImage);
      }
      
      RVPlateNumber *plateObject = [[RVPlateNumber alloc] initWithImage:croppedImage];
      [plateObject recognize];
      [self presentFeedbackViewControllerWithPlateObject:plateObject];
    });
  });
  }

- (void)presentFeedbackViewControllerWithPlateObject:(RVPlateNumber *)plateObject
{
  RVFeedbackViewModel *viewModel = [[RVFeedbackViewModel alloc] initWithPlateObject:plateObject];
  RVFeedbackViewController * viewController = [[RVFeedbackViewController alloc] initWithViewModel:viewModel];
  [self.delegate.navigationController pushViewController:viewController animated:YES];
}

@end
