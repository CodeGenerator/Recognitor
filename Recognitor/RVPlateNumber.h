//
//  RVPlateNumber.h
//  Recognitor
//
//  Created by Mikhail Korobkin on 30/05/14.
//  Copyright (c) 2014 Recognitor. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RVPlateNumberRecognitionState)
{
  RVPlateNumberRecognitionStateUnknown = 0,
  RVPlateNumberRecognitionStateRecognized,
  RVPlateNumberRecognitionStateRecognizing,
  RVPlateNumberRecognitionStateCanceling,
  RVPlateNumberRecognitionStateNotRecognized
};

@interface RVPlateNumber : NSObject

@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, copy) NSString *string;
@property (nonatomic, assign, readonly) RVPlateNumberRecognitionState recognitionState;
@property (nonatomic, strong, readonly) NSError *lastError;

- (instancetype)initWithImage:(UIImage *)image;

- (void)recognize;

- (void)cancelRecognition;

- (void)blameWithCompletion:(void(^)(BOOL success))completion;

- (void)requestBlameCountWithCompletion:(void(^)(BOOL success, NSUInteger blameCount))completion;

@end
