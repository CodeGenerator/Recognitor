//
//  RVPhotoCropperViewModel.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 28/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVPhotoCropperViewModel.h"

@interface RVPhotoCropperViewModel ()

@property (nonatomic, strong, readwrite) UIImage *image;

@end


@implementation RVPhotoCropperViewModel

- (instancetype)initWithImageData:(NSData *)imageData
{
  NSParameterAssert(imageData != nil);
  
  self = [super init];
  if (self) {
    [self decodedImageFromData:imageData completion:^(UIImage *decodedImage) {
      dispatch_async(dispatch_get_main_queue(), ^{
        self.image = decodedImage;
        [self.delegate viewModelDidPrepareImage:self];
      });
    }];
  }
  
  return self;
}

- (instancetype)init
{
  return [self initWithImageData:nil];
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
    
    if (self.completion != nil) {
      dispatch_async(dispatch_get_main_queue(), ^{
        self.completion(croppedImage);
      });
    }
  });
}

@end
