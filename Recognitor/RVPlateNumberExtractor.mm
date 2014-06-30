//
//  RVPlateNumberExtractor.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 27/05/14.
//  Copyright (c) 2014 Recognitor. All rights reserved.
//

#import <vector>
#import <opencv2/opencv.hpp>
#import "RVPlateNumberExtractor.h"

struct RVTransformRatio
{
  CGFloat width, height;
};

struct RVTRansformConstraints
{
  CGFloat left, right, top, bottom;
};

@implementation RVPlateNumberExtractor

+ (NSString *)pathToCascadeFile
{
  return [[NSBundle mainBundle] pathForResource:@"haarcascade_russian_plate_number.xml" ofType:nil];
}

+ (unsigned char *)planar8RawDataFromImage:(UIImage *)image
                                      size:(CGSize)size
{
  const NSUInteger kBitsPerPixel = 8;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
  
  NSUInteger elementsCount = (NSUInteger)size.width * (NSUInteger)size.height;
  unsigned char *rawData = (unsigned char *)calloc(elementsCount, 1);
  
  NSUInteger bytesPerRow = (NSUInteger)size.width;
  
  CGContextRef context = CGBitmapContextCreate(rawData,
                                               size.width,
                                               size.height,
                                               kBitsPerPixel,
                                               bytesPerRow,
                                               colorSpace,
                                               kCGImageAlphaNone);
  CGColorSpaceRelease(colorSpace);
  
  UIGraphicsPushContext(context);
  
  CGContextTranslateCTM(context, 0.0f, size.height);
  CGContextScaleCTM(context, 1.0f, -1.0f);
  
  [image drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
  
  UIGraphicsPopContext();
  
  CGContextRelease(context);
  return rawData;
}

+ (UIImage *)cropImageFromImage:(UIImage *)image withRect:(CGRect)rect
{
  UIImage *croppedImage = nil;
  
  @autoreleasepool {
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0);
    [image drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y) blendMode:kCGBlendModeCopy alpha:1.0f];
    croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  }
  
  return croppedImage;
}

+ (CGRect)enlargeRect:(CGRect)rect
                ratio:(RVTransformRatio)ratio
          constraints:(RVTRansformConstraints)constraints
{
  CGFloat hSizeIncreaseAmount = rect.size.width * (ratio.width - 1.0f);
  CGFloat vSizeIncreaseAmount = rect.size.height * (ratio.height - 1.0f);
  CGRect enlargedRect = CGRectMake(rect.origin.x - hSizeIncreaseAmount / 2,
                                   rect.origin.y - vSizeIncreaseAmount / 2,
                                   rect.size.width + hSizeIncreaseAmount,
                                   rect.size.height + vSizeIncreaseAmount);
  
  enlargedRect.origin.x = MAX(enlargedRect.origin.x, constraints.left);
  enlargedRect.origin.y = MAX(enlargedRect.origin.y, constraints.top);
  enlargedRect.size.width = MIN(enlargedRect.origin.x + enlargedRect.size.width, constraints.right) - enlargedRect.origin.x;
  enlargedRect.size.height = MIN(enlargedRect.origin.y + enlargedRect.size.height, constraints.bottom) - enlargedRect.origin.y;
  
  return enlargedRect;
}

+ (void)extractFromImage:(UIImage *)image completion:(void (^)(NSArray *plateImages))completion
{
  const CGFloat kMaxSideSizeForCascade = 800;
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSTimeInterval beginOperationTime = CACurrentMediaTime();
    NSString *cascadeFilePathString = [self pathToCascadeFile];
    const char *cascadeFilePath = [cascadeFilePathString UTF8String];
    
    CGFloat imageAspect = image.size.width / image.size.height;
    CGSize imageSizeForCascade = CGSizeZero;
    if (imageAspect > 1.0f) {
      imageSizeForCascade = CGSizeMake(kMaxSideSizeForCascade, kMaxSideSizeForCascade / imageAspect);
    } else {
      imageSizeForCascade = CGSizeMake(kMaxSideSizeForCascade * imageAspect, kMaxSideSizeForCascade);
    }
    unsigned char *rawImageData = [self planar8RawDataFromImage:image size:imageSizeForCascade];
    cv::Mat cvImage(imageSizeForCascade.height, imageSizeForCascade.width, CV_8UC1, rawImageData);
    
    std::vector<cv::Rect> plates;
    cv::CascadeClassifier plateClassifier(cascadeFilePath);
    
    NSLog(@"pt1: %f", CACurrentMediaTime() - beginOperationTime);
    
    plateClassifier.detectMultiScale(cvImage, plates, 1.1, 10, 5, cv::Size(70, 21), cv::Size(imageSizeForCascade.width, imageSizeForCascade.height));
    
    NSLog(@"pt2: %f", CACurrentMediaTime() - beginOperationTime);
    NSMutableArray *plateImages = [NSMutableArray arrayWithCapacity:plates.size()];
    
    CGSize imageSize = image.size;
    @autoreleasepool {
      for (std::vector<cv::Rect>::iterator it = plates.begin(); it != plates.end(); it++) {
        CGRect rectToCropFrom = CGRectMake(it->x * imageSize.width / imageSizeForCascade.width,
                                           it->y * imageSize.height / imageSizeForCascade.height,
                                           it->width * imageSize.width / imageSizeForCascade.width,
                                           it->height * imageSize.height / imageSizeForCascade.height);
        
        CGRect enlargedRect = [self enlargeRect:rectToCropFrom
                                          ratio:{.width = 1.2f, .height = 1.3f}
                                    constraints:{.left = 0.0f, .top = 0.0f, .right = imageSize.width, .bottom = imageSize.height}];
        UIImage *croppedImage = [self cropImageFromImage:image withRect:enlargedRect];
        [plateImages addObject:croppedImage];
      }
    }
    
    free(rawImageData);
    
    NSLog(@"Extract operation time in sec: %f", CACurrentMediaTime() - beginOperationTime);
    NSLog(@"plates: %u", plates.size());
    
    if (completion != nil) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(plateImages);
      });
    }
  });
}

@end
