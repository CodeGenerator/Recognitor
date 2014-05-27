//
//  RVPlateNumberExtractor.m
//  Recognitor
//
//  Created by Mikhail Korobkin on 27/05/14.
//  Copyright (c) 2014 NeoSmartVision. All rights reserved.
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
{
  const NSUInteger kBitsPerPixel = 8;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
  
  CGSize imageSize = image.size;
  NSUInteger elementsCount = (NSUInteger)imageSize.width * (NSUInteger)imageSize.height;
  unsigned char *rawData = (unsigned char *)calloc(elementsCount, 1);
  
  NSUInteger bytesPerRow = (NSUInteger)imageSize.width;
  
  CGContextRef context = CGBitmapContextCreate(rawData,
                                               imageSize.width,
                                               imageSize.height,
                                               kBitsPerPixel,
                                               bytesPerRow,
                                               colorSpace,
                                               kCGImageAlphaNone);
  CGColorSpaceRelease(colorSpace);
  
  UIGraphicsPushContext(context);
  
  CGContextTranslateCTM(context, 0.0f, imageSize.height);
  CGContextScaleCTM(context, 1.0f, -1.0f);
  
  [image drawAtPoint: CGPointZero blendMode:kCGBlendModeCopy alpha:1.0f];
  
  UIGraphicsPopContext();
  
  CGContextRelease(context);
  return rawData;
}

+ (UIImage *)cropImageFromImage:(UIImage *)image withRect:(CGRect)rect
{
  UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0);
  [image drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y) blendMode:kCGBlendModeCopy alpha:1.0f];
  UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return croppedImage;
}

+ (CGRect)rectFromCVRect:(cv::Rect &)rect
{
  return CGRectMake(rect.x, rect.y, rect.width, rect.height);
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
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *cascadeFilePathString = [self pathToCascadeFile];
    const char *cascadeFilePath = [cascadeFilePathString UTF8String];
    
    unsigned char *rawImageData = [self planar8RawDataFromImage:image];
    CGSize imageSize = image.size;
    cv::Mat cvImage(imageSize.height, imageSize.width, CV_8UC1, rawImageData);
    
    std::vector<cv::Rect> plates;
    cv::CascadeClassifier plateClassifier(cascadeFilePath);
    
    plateClassifier.detectMultiScale(cvImage, plates, 1.1, 10, 5, cv::Size(70, 21), cv::Size(imageSize.width, imageSize.height));
    NSMutableArray *plateImages = [NSMutableArray arrayWithCapacity:plates.size()];
    
    @autoreleasepool {
      for (std::vector<cv::Rect>::iterator it = plates.begin(); it != plates.end(); it++) {
        CGRect rectToCropFrom = [self rectFromCVRect:*it];
        CGRect enlargedRect = [self enlargeRect:rectToCropFrom
                                          ratio:{.width = 1.2f, .height = 1.3f}
                                    constraints:{.left = 0.0f, .top = 0.0f, .right = imageSize.width, .bottom = imageSize.height}];
        UIImage *croppedImage = [self cropImageFromImage:image withRect:enlargedRect];
        [plateImages addObject:croppedImage];
      }
    }
    
    free(rawImageData);
    
    if (completion != nil) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(plateImages);
      });
    }
  });
}

@end
