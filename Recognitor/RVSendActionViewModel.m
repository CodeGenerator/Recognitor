//
//  RVSendActionViewModel.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 24/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
//

#import "RVSendActionViewModel.h"
#import "RVBackend.h"

#import "RVFeedbackViewController.h"
#import "RVFeedbackViewModel.h"

@interface RVSendActionViewModel ()

@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, strong, readwrite) UIImage *image;


@end

@implementation RVSendActionViewModel

- (instancetype)initWithImageData:(NSData *)imageData
{
  self = [super init];
  if (self) {
    [self decodedImageFromData:imageData completion:^(UIImage *decodedImage) {
      self.imageData = UIImageJPEGRepresentation(decodedImage, 0.9f);
      dispatch_async(dispatch_get_main_queue(), ^{
        self.image = decodedImage;
        [self.delegate viewModelDidPrepareImage:self];
      });
    }];
  }
  
  return self;
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

- (void)presentFeedbackViewControllerWithPlateNumber:(NSString *)plateNumber
{
  RVFeedbackViewModel *viewModel = [[RVFeedbackViewModel alloc] initWithImage:self.image predictedNumber:plateNumber];
  RVFeedbackViewController * viewController = [[RVFeedbackViewController alloc] initWithViewModel:viewModel];
  [self.delegate.navigationController pushViewController:viewController animated:YES];
}

- (void)sendAction
{
  [self.delegate viewModelDidStartUploading:self];
  [[RVBackend sharedInstance] recognizePlateNumberFromData:self.imageData completion:^(NSString *plateNumber, NSError *error) {
    if (plateNumber != nil) {
      [self.delegate viewModelDidFinishUploading:self];
      [self presentFeedbackViewControllerWithPlateNumber:plateNumber];
      
    } else {
      [self.delegate viewModel:self didReceiveError:error];
    }
  }];
}

@end
